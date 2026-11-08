/// One round-wide board: rebuilding a console cannot reset a mission or duplicate rewards.
GLOBAL_DATUM_INIT(solo_expeditions, /datum/solo_expedition_board, new)

/// Three offers and one active expedition, shared by all expedition consoles.
/datum/solo_expedition_board
	/// Current randomized offers.
	var/list/offers = list()
	/// Accepted offer, if any.
	var/datum/solo_expedition/active
	/// Monotonic offer identifier; stale UI actions cannot select replacement offers.
	var/serial = 0
	/// Earliest time another expedition can be accepted after abandonment.
	var/next_start = 0
	/// Number of rewards successfully claimed this round.
	var/completed = 0
	/// Most recent board feedback.
	var/status = "Choose an expedition. Bring mining protection, a GPS, and a way home."

/datum/solo_expedition_board/New()
	. = ..()
	roll_offers()

/datum/solo_expedition_board/Destroy()
	active = null
	QDEL_LIST(offers)
	return ..()

/// Always offer the siege alongside two different wilderness missions.
/datum/solo_expedition_board/proc/roll_offers()
	if(active)
		return FALSE
	QDEL_LIST(offers)
	offers = list()
	var/list/wilderness = shuffle(list("survey", "salvage", "hunt"))
	var/list/kinds = shuffle(list("siege", wilderness[1], wilderness[2]))
	for(var/kind in kinds)
		serial++
		var/datum/solo_expedition/mission = new(kind, "[serial]")
		offers += mission
	return TRUE

/// Accept only a current offer, and deploy it before advertising a destination.
/datum/solo_expedition_board/proc/accept_offer(id)
	if(active || world.time < next_start)
		return FALSE
	for(var/datum/solo_expedition/mission as anything in offers)
		if(mission.id != id)
			continue
		active = mission
		if(!mission.deploy())
			active = null
			status = "No clear site found for this mission. Check that the station or mining map is available."
			return FALSE
		status = "Expedition accepted. Follow the GPS signal [mission.gps_tag], then return here for your reward."
		return TRUE
	return FALSE

/// Abandon and clean up only expedition-owned objects, with a cooldown against reroll spam.
/datum/solo_expedition_board/proc/abandon(id)
	if(!active || active.id != id)
		return FALSE
	active = null
	next_start = world.time + 1 MINUTES
	roll_offers()
	status = "Expedition abandoned. New departures available in one minute."
	return TRUE

/// Claim exactly one server-defined reward, retiring the offer before spawning anything.
/datum/solo_expedition_board/proc/claim(id, reward, turf/delivery_turf)
	if(!active || active.id != id || active.state != "complete" || !delivery_turf)
		return FALSE
	if(!istext(reward) || !(reward in active.reward_options))
		return FALSE
	var/list/choice = active.reward_options[reward]
	var/reward_type = choice["type"]
	if(!ispath(reward_type, /obj/item))
		return FALSE
	active.state = "claimed"
	active = null
	completed++
	new reward_type(delivery_turf)
	roll_offers()
	status = "Reward delivered. Three new expeditions are available."
	return TRUE

/// A generated wilderness objective and the objects that belong exclusively to it.
/datum/solo_expedition
	/// Unique offer identifier, supplied by the board.
	var/id
	/// Survey, salvage, hunt, or station boarding-pod siege.
	var/kind
	/// Offer title.
	var/title
	/// Player-facing objective instructions.
	var/description
	/// Difficulty from one to four; sieges exclusively award mythical tier-four loot.
	var/difficulty
	/// Server-owned reward choices, fixed when the offer is generated.
	var/list/reward_options = list()
	/// Duration of the on-site interaction.
	var/work_time
	/// Lifecycle: offered, active, complete, failed, or claimed.
	var/state = "offered"
	/// Unique GPS signal for the deployed site.
	var/gps_tag
	/// Deployed objective beacon.
	var/obj/structure/expedition_beacon/beacon
	/// All mission-owned fauna, retained for cleanup.
	var/list/guards = list()
	/// Fauna whose deaths have not yet been verified.
	var/list/living_guards = list()
	/// Recovered evidence; only this exact object can complete a salvage contract.
	var/obj/item/expedition_evidence/evidence
	/// Number of verified target deaths.
	var/kills = 0
	/// Number of fauna originally deployed.
	var/target_count = 0
	/// Number of siege waves dispatched (maximum three).
	var/waves_sent = 0
	/// TRUE once disabled by the player or exhausted after the final wave.
	var/deployment_disabled = FALSE
	/// The pending siege-wave timer, cancelled on cleanup or sabotage.
	var/wave_timer
	/// Number of blocked deployment retries, bounded to avoid endless missions.
	var/blocked_retries = 0

/datum/solo_expedition/New(mission_kind, mission_id)
	. = ..()
	kind = mission_kind
	id = mission_id
	difficulty = kind == "siege" ? 4 : rand(1, 3)
	configure_rewards()
	work_time = (10 + difficulty * 5) SECONDS
	gps_tag = "EXP-[id]"
	var/site_name = pick("Cinder", "Echo", "Horizon", "Pioneer", "Wayfarer", "Prospector")
	switch(kind)
		if("siege")
			title = "[site_name] boarding pod siege"
			description = "A hostile pod will dock at a clear station location. You have 45 seconds to prepare, followed by at most three waves (2, 2, and 3 boarders), 40 seconds apart. Disable its deployment controls with a 12-second interaction after the first wave, or destroy it, to stop reinforcements. Eliminate every deployed boarder to claim a mythical reward. Destroying the pod before any boarders deploy fails the mission."
		if("survey")
			title = "[site_name] geological survey"
			description = "Reach the beacon and remain beside it while collecting a geological survey. Return to a console afterward. No additional guards are deployed; native wildlife and weather remain dangerous."
		if("salvage")
			title = "Recover the [site_name] flight recorder"
			description = "Reach the guarded beacon and extract its flight recorder. Bring the recorder back and use it on an expedition console. You may evade the guards."
		if("hunt")
			title = "[site_name] fauna suppression"
			description = "Kill the marked expedition fauna, then interact with the beacon to verify the site. Return to a console afterward. Only these assigned targets count."

/// Draw three different rewards once; reopening the UI cannot reroll an offer.
/datum/solo_expedition/proc/configure_rewards()
	if(length(reward_options))
		return FALSE
	var/list/pool = get_reward_pool(difficulty)
	var/list/remaining_ids = list()
	for(var/reward_id in pool)
		remaining_ids += reward_id
	for(var/index in 1 to min(3, length(remaining_ids)))
		var/reward_id = pick_n_take(remaining_ids)
		reward_options[reward_id] = pool[reward_id]
	return TRUE

/// Separate, non-overlapping artifact pools for the three difficulty tiers.
/datum/solo_expedition/proc/get_reward_pool(tier)
	switch(tier)
		if(1)
			return list(
				"warp" = list("name" = "Linked warp cube pair", "description" = "Two linked cubes for teleporting between their locations. Normal teleport restrictions apply.", "type" = /obj/item/warp_cube/red),
				"talisman" = list("name" = "Immortality Talisman", "description" = "A rare artifact granting temporary invulnerability on a cooldown.", "type" = /obj/item/immortality_talisman),
				"modkit" = list("name" = "Rapid Repeater design disk", "description" = "An unusual kinetic-accelerator upgrade blueprint for your research console.", "type" = /obj/item/disk/design_disk/modkit_disc/rapid_repeater),
				"lantern" = list("name" = "Wisp lantern", "description" = "A rare lantern with a friendly wisp that can orbit its owner.", "type" = /obj/item/wisp_lantern),
				"babel" = list("name" = "Book of Babel", "description" = "Read this ancient tome to learn every language. Consumed when read.", "type" = /obj/item/book_of_babel),
				"paradox" = list("name" = "Linked paradox bag pair", "description" = "Two rare bags sharing the same storage space.", "type" = /obj/item/shared_storage/red),
			)
		if(2)
			return list(
				"resurrection" = list("name" = "Resurrection crystal", "description" = "Activate it to gain a second chance after death. Cannot save you from complete bodily destruction.", "type" = /obj/item/resurrection_crystal),
				"eye" = list("name" = "Eye of God", "description" = "A powerful vision and scanning artifact. Equipping it binds it to you.", "type" = /obj/item/clothing/glasses/godeye),
				"club" = list("name" = "Hierophant club", "description" = "The Hierophant's rare weapon, with its normal attacks and beacon abilities.", "type" = /obj/item/hierophant_club),
				"saw" = list("name" = "Cleaving saw", "description" = "The blood-drunk miner's transforming weapon, effective against fauna.", "type" = /obj/item/melee/cleaving_saw),
				"rod" = list("name" = "Rod of Asclepius", "description" = "A powerful healing relic. Activation binds it to your hand and requires a nonviolence oath.", "type" = /obj/item/rod_of_asclepius),
				"flight" = list("name" = "Flight potion", "description" = "A rare wing-granting elixir for compatible humanoid bodies.", "type" = /obj/item/reagent_containers/cup/bottle/potion/flight),
			)
		if(3)
			return list(
				"blade" = list("name" = "High-frequency blade", "description" = "An exceptional energy blade normally unavailable from ordinary station production.", "type" = /obj/item/highfrequencyblade),
				"armour" = list("name" = "Godslayer armour", "description" = "Legendary protective armour with a powerful emergency healing effect.", "type" = /obj/item/clothing/suit/hooded/cloak/godslayer),
				"omnitool" = list("name" = "Omnitool", "description" = "An admin-only multipurpose engineering tool, awarded here as expedition treasure.", "type" = /obj/item/debug/omnitool),
				"voice" = list("name" = "Divine vocal cords", "description" = "The Colossus's Voice of God organ. Requires surgical installation.", "type" = /obj/item/organ/vocal_cords/colossus),
				"berserker" = list("name" = "Berserker armour", "description" = "Rare rage-fuelled armour; can be empowered with drake remains. Not initially spaceworthy.", "type" = /obj/item/clothing/suit/hooded/berserker),
				"storms" = list("name" = "Staff of storms", "description" = "Legion's lightning staff, with its normal storm and thunder abilities.", "type" = /obj/item/storm_staff),
			)
		if(4)
			return list(
				"mythic_blade" = list("name" = "Worldsplitter", "description" = "Mythical high-frequency blade: 40 force and 60% block chance instead of 10 and 25%.", "type" = /obj/item/highfrequencyblade/expedition_mythic),
				"mythic_armour" = list("name" = "Aegis of the Undying", "description" = "Godslayer armour with 1,000 emergency healing and a one-minute cooldown instead of ten minutes.", "type" = /obj/item/clothing/suit/hooded/cloak/godslayer/expedition_mythic),
				"mythic_tool" = list("name" = "Architect's Hand", "description" = "Mythical omnitool with a 0.02 tool-time multiplier, five times faster than the original.", "type" = /obj/item/debug/omnitool/expedition_mythic),
				"mythic_staff" = list("name" = "Tempest Sovereign", "description" = "Storm staff with twelve lightning charges and five-second charging instead of three charges and fifteen seconds.", "type" = /obj/item/storm_staff/expedition_mythic),
				"mythic_club" = list("name" = "Sovereign's Sceptre", "description" = "Hierophant club with 60 melee force, four times the original, retaining its teleport and blast abilities.", "type" = /obj/item/hierophant_club/expedition_mythic),
				"mythic_saw" = list("name" = "Beastbane", "description" = "Mythical cleaving saw: 35 closed force, 50 open force, and 60 bonus force against mining fauna and bosses.", "type" = /obj/item/melee/cleaving_saw/expedition_mythic),
			)
	return list()

/datum/solo_expedition/Destroy()
	if(wave_timer)
		deltimer(wave_timer)
		wave_timer = null
	// Unregister first: deleting targets during cleanup must not report failure or kills.
	for(var/mob/living/guard as anything in guards)
		if(!QDELETED(guard))
			UnregisterSignal(guard, list(COMSIG_LIVING_DEATH, COMSIG_QDELETING))
			// Carbon corpses remain available for looting, surgery, or revival.
			if(!iscarbon(guard) || guard.stat != DEAD)
				qdel(guard)
	guards.Cut()
	living_guards = null
	if(beacon)
		beacon.mission = null
	QDEL_NULL(beacon)
	if(evidence)
		evidence.mission = null
	QDEL_NULL(evidence)
	return ..()

/// Only natural, clear mining terrain outside ruin interiors and base areas is eligible.
/datum/solo_expedition/proc/valid_site_turf(turf/candidate)
	if(!isasteroidturf(candidate) || candidate.is_blocked_turf())
		return FALSE
	var/area/site_area = get_area(candidate)
	return istype(site_area, /area/lavaland/surface/outdoors/unexplored) || istype(site_area, /area/icemoon/underground/unexplored)

/// Bounded random search; never modifies existing terrain, buildings, or lava.
/datum/solo_expedition/proc/find_site()
	var/list/mining_levels = SSmapping.levels_by_trait(ZTRAIT_MINING)
	if(!length(mining_levels) || world.maxx < 50 || world.maxy < 50)
		return null
	for(var/attempt in 1 to 500)
		var/turf/center = locate(rand(20, world.maxx - 20), rand(20, world.maxy - 20), pick(mining_levels))
		if(!valid_site_turf(center))
			continue
		var/valid = TRUE
		for(var/turf/nearby in range(1, center))
			if(!valid_site_turf(nearby))
				valid = FALSE
				break
		if(!valid)
			continue
		for(var/obj/machinery/nearby_machine in range(10, center))
			valid = FALSE
			break
		for(var/mob/living/nearby_mob in range(10, center))
			valid = FALSE
			break
		if(valid)
			return center
	return null

/// Deploy a beacon and a randomized encounter only after a safe site is found.
/datum/solo_expedition/proc/deploy()
	if(state != "offered")
		return FALSE
	var/turf/site = kind == "siege" ? find_siege_site() : find_site()
	if(!site)
		return FALSE
	state = "active"
	if(kind == "siege")
		beacon = new /obj/structure/expedition_beacon/siege(site, src)
		beacon.visible_message(span_danger("A hostile boarding pod docks! Its deployment bay will open in 45 seconds!"))
		wave_timer = addtimer(CALLBACK(src, PROC_REF(dispatch_siege_wave)), 45 SECONDS, TIMER_STOPPABLE)
		return TRUE
	beacon = new(site, src)
	if(kind == "survey")
		return TRUE
	target_count = difficulty + (kind == "hunt" ? 1 : 0)
	var/list/spawn_turfs = list()
	for(var/turf/candidate in orange(1, site))
		spawn_turfs += candidate
	var/ice_site = istype(get_area(site), /area/icemoon)
	for(var/index in 1 to target_count)
		var/mob_type = ice_site ? /mob/living/basic/mining/wolf : pick(/mob/living/basic/mining/watcher, /mob/living/basic/mining/goliath)
		var/mob/living/guard = new mob_type(pick_n_take(spawn_turfs))
		guard.name = "[guard.name] ([gps_tag])"
		guards += guard
		living_guards += guard
		RegisterSignal(guard, COMSIG_LIVING_DEATH, PROC_REF(target_died))
		RegisterSignal(guard, COMSIG_QDELETING, PROC_REF(target_deleted))
	return TRUE

/// Count a target at most once, including creatures that delete themselves after death.
/datum/solo_expedition/proc/target_died(mob/living/source, gibbed)
	SIGNAL_HANDLER
	if(!(source in living_guards))
		return
	living_guards -= source
	kills++
	UnregisterSignal(source, list(COMSIG_LIVING_DEATH, COMSIG_QDELETING))
	check_siege_completion()

/// A missing live hunt target is a failure, never a free kill (e.g. a mining map reset).
/datum/solo_expedition/proc/target_deleted(mob/living/source)
	SIGNAL_HANDLER
	living_guards -= source
	guards -= source
	if((kind == "hunt" || kind == "siege") && state == "active")
		state = "failed"
		stop_siege_deployment()

/// Find an unoccupied station floor with at least three free deployment exits.
/datum/solo_expedition/proc/find_siege_site()
	if(!length(GLOB.the_station_areas))
		return null
	for(var/attempt in 1 to 30)
		var/turf/open/floor/site = get_safe_random_station_turf()
		if(!istype(site) || !is_station_level(site.z) || site.is_blocked_turf())
			continue
		var/occupied = FALSE
		for(var/mob/living/nearby in range(5, site))
			occupied = TRUE
			break
		if(occupied)
			continue
		var/free_exits = 0
		for(var/turf/open/floor/exit in orange(1, site))
			if(is_station_level(exit.z) && !exit.is_blocked_turf())
				free_exits++
		if(free_exits >= 3)
			return site
	return null

/// Dispatch at most seven boarders in three waves. Blocked exits get bounded retries.
/datum/solo_expedition/proc/dispatch_siege_wave()
	wave_timer = null
	if(kind != "siege" || state != "active" || deployment_disabled || waves_sent >= 3 || QDELETED(beacon))
		return FALSE
	var/list/exits = list()
	for(var/turf/open/floor/exit in orange(1, beacon))
		if(is_station_level(exit.z) && !exit.is_blocked_turf())
			exits += exit
	var/wave_size = waves_sent == 2 ? 3 : 2
	if(length(exits) < wave_size)
		blocked_retries++
		if(blocked_retries >= 6)
			state = "failed"
			stop_siege_deployment()
		else
			wave_timer = addtimer(CALLBACK(src, PROC_REF(dispatch_siege_wave)), 5 SECONDS, TIMER_STOPPABLE)
		return FALSE
	blocked_retries = 0
	waves_sent++
	for(var/index in 1 to wave_size)
		var/mob_type = index == wave_size ? /mob/living/carbon/human/expedition_boarder/gunner : /mob/living/carbon/human/expedition_boarder
		var/mob/living/boarder = new mob_type(pick_n_take(exits))
		boarder.name = "[boarder.name] ([gps_tag])"
		guards += boarder
		living_guards += boarder
		target_count++
		RegisterSignal(boarder, COMSIG_LIVING_DEATH, PROC_REF(target_died))
		RegisterSignal(boarder, COMSIG_QDELETING, PROC_REF(target_deleted))
	beacon.visible_message(span_danger("[beacon] deploys boarding wave [waves_sent] of 3!"))
	beacon.update_appearance()
	if(waves_sent >= 3)
		stop_siege_deployment()
	else
		wave_timer = addtimer(CALLBACK(src, PROC_REF(dispatch_siege_wave)), 40 SECONDS, TIMER_STOPPABLE)
	return TRUE

/// Stop reinforcements; spawned boarders must still be defeated.
/datum/solo_expedition/proc/stop_siege_deployment()
	deployment_disabled = TRUE
	if(wave_timer)
		deltimer(wave_timer)
		wave_timer = null
	check_siege_completion()
	beacon?.update_appearance()

/// Completion cannot occur until at least one wave has deployed and all targets are dead.
/datum/solo_expedition/proc/check_siege_completion()
	if(kind == "siege" && state == "active" && deployment_disabled && waves_sent > 0 && target_count > 0 && !length(living_guards) && kills == target_count)
		state = "complete"

/// Serialize only player-facing data; no client-provided reward values or completion states.
/datum/solo_expedition/proc/get_mission_data()
	var/turf/site = get_turf(beacon)
	var/list/rewards = list()
	for(var/reward_id in reward_options)
		var/list/choice = reward_options[reward_id]
		rewards += list(list("id" = reward_id, "name" = choice["name"], "description" = choice["description"]))
	return list(
		"id" = id,
		"kind" = kind,
		"title" = title,
		"description" = description,
		"difficulty" = difficulty,
		"rewards" = rewards,
		"work_seconds" = work_time / (1 SECONDS),
		"state" = state,
		"gps" = gps_tag,
		"coordinates" = site ? "[site.x], [site.y], [site.z]" : null,
		"kills" = kills,
		"targets" = target_count,
		"waves" = waves_sent,
		"deployment_disabled" = deployment_disabled,
		"recovered" = !isnull(evidence),
	)

/// In-world objective; the mission owns its lifetime and GPS component.
/obj/structure/expedition_beacon
	name = "expedition beacon"
	desc = "A remote expedition instrument. Interact with it to perform the assigned field work."
	icon = 'icons/obj/devices/tracker.dmi'
	icon_state = "gps-c"
	anchored = TRUE
	density = FALSE
	max_integrity = 200
	/// Owning expedition.
	var/datum/solo_expedition/mission
	/// Prevent concurrent field-work interactions from producing duplicate evidence.
	var/working = FALSE

/obj/structure/expedition_beacon/Initialize(mapload, datum/solo_expedition/owner)
	. = ..()
	mission = owner
	if(mission)
		name = "expedition beacon ([mission.gps_tag])"
		AddComponent(/datum/component/gps, mission.gps_tag)
	set_light(2, 1, LIGHT_COLOR_BLUE)

/obj/structure/expedition_beacon/Destroy()
	if(mission)
		mission.beacon = null
		if(mission.state == "active" && !mission.evidence)
			mission.state = "failed"
	mission = null
	return ..()

/obj/structure/expedition_beacon/examine(mob/user)
	. = ..()
	if(mission)
		. += span_notice(mission.description)
		. += span_notice("Assigned fauna eliminated: [mission.kills]/[mission.target_count].")

/obj/structure/expedition_beacon/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(!mission || mission.state != "active" || working || !ishuman(user) || !user.can_perform_action(src))
		return
	if(mission.kind == "hunt" && mission.kills < mission.target_count)
		balloon_alert(user, "assigned fauna still alive!")
		return
	if(mission.evidence)
		balloon_alert(user, "recorder already recovered!")
		return
	working = TRUE
	balloon_alert(user, "performing field work...")
	var/finished = do_after(user, mission.work_time, target = src)
	if(QDELETED(src))
		return
	working = FALSE
	if(!finished || !mission || mission.state != "active")
		return
	if(mission.kind == "salvage")
		mission.evidence = new /obj/item/expedition_evidence(drop_location(), mission)
		user.put_in_hands(mission.evidence)
		to_chat(user, span_notice("Recorder recovered. Use it on an expedition console to submit it."))
	else
		mission.state = "complete"
		to_chat(user, span_notice("Field work complete. Return to an expedition console and choose your reward."))

/// A destructible siege deployment system; sabotage and destruction stop future waves.
/obj/structure/expedition_beacon/siege
	name = "hostile boarding pod"
	desc = "A hostile deployment pod. After its first wave, interact with it for twelve seconds to disable reinforcements, or destroy it."
	icon = 'icons/obj/supplypods.dmi'
	icon_state = "darkpod"
	pixel_x = SUPPLYPOD_X_OFFSET
	density = TRUE
	max_integrity = 300

/obj/structure/expedition_beacon/siege/Initialize(mapload, datum/solo_expedition/owner)
	. = ..()
	if(mission)
		name = "hostile boarding pod ([mission.gps_tag])"
	set_light(3, 1, COLOR_RED)
	update_appearance()

/obj/structure/expedition_beacon/siege/update_overlays()
	. = ..()
	if(!mission || !mission.waves_sent)
		// Preserve the fins in front of the hatch, as the normal supply pod renderer does.
		var/icon/hatch = new(icon, "darkpod_door")
		var/icon/fins = new(icon, "mask_topfin")
		fins.MapColors(0,0,0,1, 0,0,0,1, 0,0,0,1, 1,1,1,0, 0,0,0,1)
		fins.SwapColor("#ffffffff", null)
		fins.Blend(COLOR_BLACK, ICON_SUBTRACT)
		hatch.Blend(fins, ICON_ADD)
		. += hatch
	. += mutable_appearance(icon, "syndicate")
	var/glow = mission?.deployment_disabled ? "pod_glow_blue" : "pod_glow_red"
	. += mutable_appearance(icon, glow)
	. += emissive_appearance(icon, glow, src)

/obj/structure/expedition_beacon/siege/update_icon_state()
	set_light(3, 1, mission?.deployment_disabled ? LIGHT_COLOR_BLUE : COLOR_RED)
	return ..()

/obj/structure/expedition_beacon/siege/attack_hand(mob/living/user, list/modifiers)
	if(!mission || mission.state != "active" || working || !ishuman(user) || !user.can_perform_action(src))
		return
	if(!mission.waves_sent)
		balloon_alert(user, "controls sealed until first deployment!")
		return
	if(mission.deployment_disabled)
		balloon_alert(user, "defeat remaining boarders!")
		return
	working = TRUE
	balloon_alert(user, "disabling deployment...")
	var/success = do_after(user, 12 SECONDS, target = src)
	if(QDELETED(src))
		return
	working = FALSE
	if(success && mission && mission.state == "active")
		mission.stop_siege_deployment()
		visible_message(span_notice("[user] disables [src]'s deployment system!"))

/obj/structure/expedition_beacon/siege/Destroy()
	if(mission)
		var/datum/solo_expedition/owner = mission
		owner.beacon = null
		mission = null
		if(owner.state == "active" && !owner.waves_sent)
			owner.state = "failed"
		owner.stop_siege_deployment()
	return ..()

/// Real human boarders use the same organs, wounds, blood, critical states and corpses as crew.
/mob/living/carbon/human/expedition_boarder
	name = "boarding raider"
	faction = list(ROLE_SYNDICATE)
	ai_controller = /datum/ai_controller/monkey/angry/expedition_boarder
	/// Equipment role; gunner is otherwise an ordinary human.
	var/is_gunner = FALSE
	/// Prevent NPC ranged fire from exceeding the original siege firing interval.
	var/next_siege_shot = 0

/mob/living/carbon/human/expedition_boarder/Initialize(mapload)
	. = ..()
	real_name = name
	equipOutfit(/datum/outfit/expedition_boarder)
	if(is_gunner)
		put_in_hands(new /obj/item/gun/ballistic/automatic/pistol(src))
	else
		put_in_hands(new /obj/item/knife/combat/survival(src))
	ai_controller.set_blackboard_key(BB_MONKEY_GUN_NEURONS_ACTIVATED, is_gunner)

/mob/living/carbon/human/expedition_boarder/gunner
	name = "boarding gunner"
	is_gunner = TRUE

/// Ordinary wearable armour and weapons can be removed from the resulting body.
/datum/outfit/expedition_boarder
	name = "Expedition boarding raider"
	uniform = /obj/item/clothing/under/syndicate
	suit = /obj/item/clothing/suit/armor/vest
	head = /obj/item/clothing/head/helmet
	mask = /obj/item/clothing/mask/balaclava
	shoes = /obj/item/clothing/shoes/combat
	gloves = /obj/item/clothing/gloves/combat

/// Carbon-compatible combat AI: normal item attacks and movement, without monkey pranks.
/datum/ai_controller/monkey/angry/expedition_boarder
	behavior_tree_json = null
	behavior_nodes = list(
		BT_DESC_TYPE = /datum/bt_node/composite/sequence,
		BT_DESC_CHILDREN = list(
			list(BT_DESC_TYPE = /datum/bt_node/ai_behavior/expedition_acquire_target),
			list(
				BT_DESC_TYPE = /datum/bt_node/composite/parallel,
				"failure_policy" = BT_PARALLEL_FAILURE_CHILD_ONE,
				"success_policy" = BT_PARALLEL_SUCCESS_CHILD_ONE,
				"repeat_secondary" = TRUE,
				"repeat_secondary_delay" = 0.2 SECONDS,
				"finish_on_primary" = TRUE,
				BT_DESC_CHILDREN = list(
					list(BT_DESC_TYPE = /datum/bt_node/ai_behavior/monkey_attack_mob/expedition, "target_key" = BB_CURRENT_TARGET),
					list(BT_DESC_TYPE = /datum/bt_node/ai_behavior/agile_melee_movement, "target_key" = BB_CURRENT_TARGET, "standoff_max" = 4),
				),
			),
		),
	)

/// Select a nearby conscious enemy, respecting team membership and line of sight.
/datum/bt_node/ai_behavior/expedition_acquire_target

/datum/bt_node/ai_behavior/expedition_acquire_target/perform(seconds_per_tick, datum/ai_controller/controller)
	var/mob/living/pawn = controller.pawn
	var/mob/living/closest
	for(var/mob/living/candidate in oview(9, pawn))
		if(IS_UNCONSCIOUS_OR_CRIT(candidate) || pawn.faction_check_atom(candidate))
			continue
		if(!closest || get_dist(pawn, candidate) < get_dist(pawn, closest))
			closest = candidate
	if(!closest)
		controller.clear_blackboard_key(BB_CURRENT_TARGET)
		pawn.set_combat_mode(FALSE)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	controller.set_blackboard_key(BB_CURRENT_TARGET, closest)
	pawn.set_combat_mode(TRUE)
	return AI_BEHAVIOR_INSTANT | AI_BEHAVIOR_SUCCEEDED

/// Use normal carbon weapon interactions; raiders keep knives rather than throwing them away.
/datum/bt_node/ai_behavior/monkey_attack_mob/expedition

/datum/bt_node/ai_behavior/monkey_attack_mob/expedition/monkey_attack(datum/ai_controller/controller, mob/living/target, seconds_per_tick, disarm, holding_weapon)
	var/mob/living/carbon/human/expedition_boarder/boarder = controller.pawn
	if(QDELETED(target) || IS_UNCONSCIOUS_OR_CRIT(target) || boarder.faction_check_atom(target))
		return FALSE
	if(get_dist(boarder, target) > 1)
		var/obj/item/gun/gun = boarder.is_holding_item_of_type(/obj/item/gun)
		if(!gun || !gun.can_shoot() || world.time < boarder.next_siege_shot)
			return FALSE
		boarder.next_siege_shot = world.time + 2.5 SECONDS
		boarder.face_atom(target)
		controller.ai_interact(target = target, combat_mode = TRUE)
		return TRUE
	return ..()

/// Mythical artifacts use existing abilities with explicitly stronger statistics.
/obj/item/highfrequencyblade/expedition_mythic
	name = "Worldsplitter"
	desc = "A mythical resonating blade. Four times the normal cutting force and a 60% parry chance."
	force = 40
	block_chance = 60

/obj/item/clothing/suit/hooded/cloak/godslayer/expedition_mythic
	name = "Aegis of the Undying"
	desc = "Mythical godslayer armour. Emergency healing is doubled and recharges in one minute."
	heal_amount = 1000
	effect_cooldown_time = 1 MINUTES

/obj/item/debug/omnitool/expedition_mythic
	name = "Architect's Hand"
	desc = "A mythical omnitool with a 0.02 tool-time multiplier. Use it in hand to choose a tool mode."
	toolspeed = 0.02

/obj/item/storm_staff/expedition_mythic
	name = "Tempest Sovereign"
	desc = "A mythical storm staff holding twelve lightning charges, with five-second charging."
	max_thunder_charges = 12
	thunder_charges = 12
	thunder_charge_time = 5 SECONDS

/obj/item/hierophant_club/expedition_mythic
	name = "Sovereign's Sceptre"
	desc = "A mythical Hierophant relic. Four times the original melee force, with its familiar blast and teleport powers."
	force = 60

/obj/item/melee/cleaving_saw/expedition_mythic
	name = "Beastbane"
	desc = "A mythical cleaving saw with 35 closed force, 50 open force, and 60 bonus force against mining fauna and bosses."
	force = 35
	open_force = 50
	faction_bonus_force = 60

/// Unique salvage proof, bound to one offer and consumed when submitted.
/obj/item/expedition_evidence
	name = "expedition flight recorder"
	desc = "A recovered flight recorder. Submit it by using it on an expedition console."
	icon = 'icons/obj/devices/tracker.dmi'
	icon_state = "gps-c"
	w_class = WEIGHT_CLASS_SMALL
	/// Owning expedition, cleared before intentional deletion.
	var/datum/solo_expedition/mission

/obj/item/expedition_evidence/Initialize(mapload, datum/solo_expedition/owner)
	. = ..()
	mission = owner
	if(mission)
		name = "flight recorder ([mission.gps_tag])"

/obj/item/expedition_evidence/Destroy()
	if(mission)
		mission.evidence = null
		if(mission.state == "active")
			mission.state = "failed"
	mission = null
	return ..()

/// Buildable console for accepting expeditions and collecting one reward on return.
/obj/machinery/computer/expedition
	name = "expedition mission console"
	desc = "Offers remote mining-planet expeditions with a choice of rewards. Bring a GPS, appropriate protection, and transport."
	circuit = /obj/item/circuitboard/computer/expedition

/obj/machinery/computer/expedition/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ExpeditionConsole", name)
		ui.open()

/obj/machinery/computer/expedition/ui_data(mob/user)
	var/datum/solo_expedition_board/board = GLOB.solo_expeditions
	var/list/data = list("status" = board.status, "completed" = board.completed)
	data["cooldown"] = max(0, ceil((board.next_start - world.time) / (1 SECONDS)))
	data["active"] = board.active?.get_mission_data()
	var/list/offers = list()
	for(var/datum/solo_expedition/mission as anything in board.offers)
		offers += list(mission.get_mission_data())
	data["offers"] = offers
	return data

/obj/machinery/computer/expedition/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(!is_operational || !ishuman(usr) || !usr.can_perform_action(src))
		return FALSE
	var/datum/solo_expedition_board/board = GLOB.solo_expeditions
	switch(action)
		if("accept")
			board.accept_offer(params["id"])
			return TRUE
		if("abandon")
			return board.abandon(params["id"])
		if("claim")
			return board.claim(params["id"], params["reward"], drop_location())
	return FALSE

/obj/machinery/computer/expedition/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(!istype(tool, /obj/item/expedition_evidence))
		return ..()
	if(!is_operational || !user.can_perform_action(src))
		return ITEM_INTERACT_BLOCKING
	var/obj/item/expedition_evidence/recorder = tool
	var/datum/solo_expedition/mission = GLOB.solo_expeditions.active
	if(!mission || mission.state != "active" || recorder != mission.evidence || recorder.mission != mission)
		balloon_alert(user, "not the assigned recorder!")
		return ITEM_INTERACT_BLOCKING
	if(!user.transferItemToLoc(recorder, src))
		return ITEM_INTERACT_BLOCKING
	mission.state = "complete"
	mission.evidence = null
	recorder.mission = null
	qdel(recorder)
	GLOB.solo_expeditions.status = "Flight recorder submitted. Choose your expedition reward."
	to_chat(user, span_notice("Flight recorder submitted. Open the console to choose your reward."))
	return ITEM_INTERACT_SUCCESS
