/// One round-wide board: rebuilding a console cannot reset a mission or duplicate rewards.
GLOBAL_DATUM_INIT(solo_expeditions, /datum/solo_expedition_board, new)

/// Six category offers and one active expedition, shared by all expedition consoles.
/datum/solo_expedition_board
	/// Current randomized offers.
	var/list/offers = list()
	/// Accepted offer, if any.
	var/datum/solo_expedition/active
	/// Monotonic offer identifier; stale UI actions cannot select replacement offers.
	var/serial = 0
	/// Earliest time another expedition can be accepted after abandonment.
	var/next_start = 0
	/// Number of assignments successfully closed this round.
	var/completed = 0
	/// Most recent board feedback.
	var/status = "Central Command tasking uplink established. Review the briefs and prepare before accepting an assignment."

/datum/solo_expedition_board/New()
	. = ..()
	roll_offers()

/datum/solo_expedition_board/Destroy()
	active = null
	QDEL_LIST(offers)
	return ..()

/// Keep one randomized wilderness offer per tier and one offer for each station breach.
/datum/solo_expedition_board/proc/roll_offers()
	if(active)
		return FALSE
	QDEL_LIST(offers)
	offers = list()
	for(var/tier in 1 to 3)
		serial++
		var/datum/solo_expedition/mission = new(pick("survey", "salvage", "hunt"), "[serial]", tier)
		offers += mission
	for(var/kind in list("siege", "necropolis", "xenomorph"))
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
		status = "Central Command acknowledges your acceptance. Assigned location: [mission.destination_room]. Tracking signal: [mission.gps_tag]. Follow the field orders. [mission.kind == "xenomorph" ? "No rewards are assigned." : "Completion authorizes requisition clearance."]"
		return TRUE
	return FALSE

/// Abandon and clean up only expedition-owned objects, with a cooldown against reroll spam.
/datum/solo_expedition_board/proc/abandon(id)
	if(!active || active.id != id)
		return FALSE
	active = null
	next_start = world.time + 1 MINUTES
	roll_offers()
	status = "Withdrawal acknowledged by Central Command. Requisition clearance forfeited. New tasking available in one minute."
	return TRUE

/// Close a completed science assignment without granting any reward.
/datum/solo_expedition_board/proc/finish(id)
	if(!active || active.id != id || active.kind != "xenomorph" || active.state != "complete")
		return FALSE
	active = null
	completed++
	roll_offers()
	status = "Xenomorph containment recorded. No rewards issued. Updated tasking is available."
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
	status = "Central Command has released your selected requisition. Collect it beside the terminal. Updated tasking is now available."
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
	/// Mission authority shown consistently in the briefing and announcements.
	var/issuer = "Central Command - Special Assignments Office"
	/// Operational requirements kept separate from the narrative briefing.
	var/list/orders = list()
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
	/// Deployment room, retained after the pod or beacon is destroyed.
	var/destination_room = "Not deployed"
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

/datum/solo_expedition/New(mission_kind, mission_id, mission_tier)
	. = ..()
	kind = mission_kind
	id = mission_id
	difficulty = is_station_defense() ? 4 : (isnum(mission_tier) ? clamp(round(mission_tier), 1, 3) : rand(1, 3))
	configure_rewards()
	work_time = (10 + difficulty * 5) SECONDS
	gps_tag = "EXP-[id]"
	var/site_name = pick("Cinder", "Echo", "Horizon", "Pioneer", "Wayfarer", "Prospector")
	switch(kind)
		if("xenomorph")
			title = "Operation [site_name]: Xenomorph Containment"
			description = "Science monitoring has detected a xenomorph burrow beneath the station. Contain the queen and her reinforcements before they overrun the base. No requisition rewards are assigned to this operation."
			orders = list(
				"Accept to open a burrow in an eligible station room. A hostile queen emerges immediately; follow the assigned room and GPS signal.",
				"Three reinforcement waves each contain 2-4 random hunters, bruisers, or sentinels. The first arrives after 30 seconds, with 30 seconds between subsequent waves. No additional queens emerge.",
				"After the first reinforcement wave, seal the burrow with a 12-second uninterrupted interaction, or destroy it to stop reinforcements. Eliminate the queen and every released xenomorph.",
				"Destroying the burrow before the first reinforcement wave invalidates the assignment. No mission rewards are currently available.",
			)
		if("necropolis")
			title = "Operation [site_name]: Necropolis Containment"
			description = "Central Command's monitoring stations have detected a spatial disturbance consistent with Lavaland's Necropolis. An incursion into the station is imminent. Secure the manifestation site and prevent its creatures from reaching occupied departments. Successful containment authorizes the release of a relic from Command's recovered-artifact reserve."
			orders = list(
				"On acceptance, Command will confirm the room and GPS signal. You have 45 seconds before the first creatures emerge through the intact decking.",
				"Expect up to three waves of 3, 4, and 5 Lavaland creatures, with 40 seconds between waves.",
				"After the first wave, interact with the tendril for 12 uninterrupted seconds to seal it, or destroy it to halt reinforcements. Eliminate every creature already released.",
				"Threat verification requires a confirmed emergence. Destroying the tendril before its first wave invalidates this assignment.",
				"Await Command's containment announcement, then return to an expedition terminal and select one authorized relic.",
			)
		if("siege")
			title = "Operation [site_name]: Syndicate Breach Raid"
			description = "Central Command's Signals Intelligence office has intercepted a Syndicate insertion order targeting this station. You are authorized to intercept the boarding party and neutralize its deployment pod. Command has approved the release of a captured prototype to personnel who successfully repel the incursion."
			orders = list(
				"Accept the tasking to receive the confirmed breach room and GPS signal. The pod's deployment bay opens 45 seconds after contact is established.",
				"Expect up to three waves of 2, 2, and 3 boarders, with 40 seconds between waves. Each wave includes an armed gunner.",
				"After the first wave, disable the pod with a 12-second uninterrupted interaction, or destroy it to prevent further deployments. Eliminate all boarders already on the station.",
				"Threat verification requires a confirmed deployment. Destroying the pod before its first wave invalidates this assignment.",
				"Await Command's all-clear, then return to an expedition terminal and select one authorized prototype.",
			)
		if("survey")
			title = "[site_name] Survey Commission"
			description = "Central Command's Resource Assessment office requires ground-truth measurements before approving further extraction in this sector. A survey instrument will be positioned at your assigned coordinates. Reach it, complete the field readings, and return with the work certified."
			orders = list(
				"Follow the assigned GPS signal using your normal mining transport. Carry suitable environmental protection and arrange your return journey.",
				"Interact with the survey beacon and remain beside it for [work_time / (1 SECONDS)] uninterrupted seconds to complete the readings.",
				"This is a survey assignment, not a clearance order. Account for native wildlife and weather.",
				"Return to an expedition terminal once the readings are complete and select one authorized requisition.",
			)
		if("salvage")
			title = "[site_name] Recorder Recovery"
			description = "A contracted survey flight failed to deliver its final telemetry package. Central Command has traced the flight recorder's recovery beacon to hostile fauna territory. Retrieve the recorder intact so the loss can be investigated; clearing the surrounding wildlife is at your discretion."
			orders = list(
				"Travel to the assigned GPS signal with appropriate mining protection and a way home.",
				"Evade or eliminate the creatures at the recovery site. Interact with the beacon for [work_time / (1 SECONDS)] uninterrupted seconds to extract the recorder.",
				"Carry the recovered recorder back and use it on a powered expedition terminal. Only the assigned recorder satisfies this order.",
				"After the terminal acknowledges receipt, select one authorized requisition.",
			)
		if("hunt")
			title = "[site_name] Route Clearance"
			description = "Hostile fauna are obstructing a route designated for future survey operations. Central Command's Expedition Security office has authorized a targeted clearance. Remove the designated threats and submit an on-site verification before requesting your requisition."
			orders = list(
				"Travel to the assigned GPS beacon with mining protection, combat equipment, and a return plan.",
				"Eliminate every creature carrying this assignment's EXP identifier. Unrelated wildlife does not count toward clearance.",
				"Once the designated targets are dead, interact with the beacon for [work_time / (1 SECONDS)] uninterrupted seconds to verify the site.",
				"Return to an expedition terminal after verification and select one authorized requisition.",
			)

/// The station-defense missions share finite-wave, sabotage, death-tracking and cleanup rules.
/datum/solo_expedition/proc/is_station_defense()
	return kind == "siege" || kind == "necropolis" || kind == "xenomorph"

/// Wave numbers are one-based; no fourth wave can be dispatched.
/datum/solo_expedition/proc/get_station_wave_size(wave_number)
	if(wave_number < 1 || wave_number > 3)
		return 0
	if(kind == "xenomorph")
		return rand(2, 4)
	if(kind == "necropolis")
		return wave_number + 2
	return wave_number == 3 ? 3 : 2

/// Only finite-spawn fauna are used: none can generate untracked broods or extra waves.
/datum/solo_expedition/proc/get_station_wave_mob(index, wave_size)
	if(kind == "xenomorph")
		return pick(/mob/living/basic/alien/expedition_hunter, /mob/living/basic/alien/drone/expedition, /mob/living/basic/alien/sentinel/expedition)
	if(kind == "necropolis")
		return pick(/mob/living/basic/mining/watcher, /mob/living/basic/mining/goliath, /mob/living/basic/mining/basilisk)
	return index == wave_size ? /mob/living/carbon/human/expedition_boarder/gunner : /mob/living/carbon/human/expedition_boarder

/// Draw three different rewards once; reopening the UI cannot reroll an offer.
/datum/solo_expedition/proc/configure_rewards()
	if(kind == "xenomorph")
		return FALSE
	if(length(reward_options))
		return FALSE
	var/list/pool = get_mission_reward_pool()
	var/list/remaining_ids = list()
	for(var/reward_id in pool)
		remaining_ids += reward_id
	for(var/index in 1 to min(3, length(remaining_ids)))
		var/reward_id = pick_n_take(remaining_ids)
		reward_options[reward_id] = pool[reward_id]
	return TRUE

/// Mission-specific pools take precedence; the original mythical pool remains available unchanged.
/datum/solo_expedition/proc/get_mission_reward_pool()
	if(kind == "xenomorph")
		return list()
	if(kind == "siege" && difficulty == 4)
		return get_syndicate_reward_pool()
	return get_reward_pool(difficulty)

/// Exclusive assault, defence, and infiltration loot for the Syndicate breach raid.
/datum/solo_expedition/proc/get_syndicate_reward_pool()
	return list(
		"syndicate_sword" = list("name" = "Red Verdict", "description" = /obj/item/melee/energy/sword/saber/red/expedition_syndicate::desc, "type" = /obj/item/melee/energy/sword/saber/red/expedition_syndicate),
		"syndicate_shield" = list("name" = "Crimson Bulwark", "description" = /obj/item/shield/energy/expedition_syndicate::desc, "type" = /obj/item/shield/energy/expedition_syndicate),
		"syndicate_carbine" = list("name" = "Blackstar Carbine", "description" = /obj/item/gun/energy/laser/expedition_syndicate::desc, "type" = /obj/item/gun/energy/laser/expedition_syndicate),
		"syndicate_armour" = list("name" = "Ghost Legion assault set", "description" = /obj/item/clothing/suit/armor/vest/expedition_syndicate::desc, "type" = /obj/item/clothing/suit/armor/vest/expedition_syndicate),
		"syndicate_sequencer" = list("name" = "Skeleton Protocol", "description" = /obj/item/card/emag/bluespace/expedition_syndicate::desc, "type" = /obj/item/card/emag/bluespace/expedition_syndicate),
		"syndicate_projector" = list("name" = "Phantom Relay", "description" = /obj/item/chameleon/expedition_syndicate::desc, "type" = /obj/item/chameleon/expedition_syndicate),
	)

/// Separate general-purpose artifact pools, including the original six tier-four rewards.
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
				"blade" = list("name" = "High-frequency blade", "description" = "A resonant sword whose humming edge worries at the bonds of whatever it touches. Wield it in both hands for sweeping cuts.", "type" = /obj/item/highfrequencyblade),
				"armour" = list("name" = "Godslayer armour", "description" = "Legendary protective armour with a powerful emergency healing effect.", "type" = /obj/item/clothing/suit/hooded/cloak/godslayer),
				"omnitool" = list("name" = "Omnitool", "description" = "An unlisted engineering prototype with an articulated head for every field task. Use it in hand to choose a tool mode.", "type" = /obj/item/debug/omnitool),
				"voice" = list("name" = "Divine vocal cords", "description" = "The Colossus's Voice of God organ. Requires surgical installation.", "type" = /obj/item/organ/vocal_cords/colossus),
				"berserker" = list("name" = "Berserker armour", "description" = "Rare rage-fuelled armour; can be empowered with drake remains. Not initially spaceworthy.", "type" = /obj/item/clothing/suit/hooded/berserker),
				"storms" = list("name" = "Staff of storms", "description" = "Legion's lightning staff, with its normal storm and thunder abilities.", "type" = /obj/item/storm_staff),
			)
		if(4)
			return list(
				"mythic_blade" = list("name" = "Worldsplitter", "description" = /obj/item/highfrequencyblade/expedition_mythic::desc, "type" = /obj/item/highfrequencyblade/expedition_mythic),
				"mythic_armour" = list("name" = "Aegis of the Undying", "description" = /obj/item/clothing/suit/hooded/cloak/godslayer/expedition_mythic::desc, "type" = /obj/item/clothing/suit/hooded/cloak/godslayer/expedition_mythic),
				"mythic_voice" = list("name" = "Vox of the Necropolis", "description" = /obj/item/organ/vocal_cords/colossus/expedition_mythic::desc, "type" = /obj/item/organ/vocal_cords/colossus/expedition_mythic),
				"mythic_staff" = list("name" = "Tempest Sovereign", "description" = /obj/item/storm_staff/expedition_mythic::desc, "type" = /obj/item/storm_staff/expedition_mythic),
				"mythic_club" = list("name" = "Sovereign's Sceptre", "description" = /obj/item/hierophant_club/expedition_mythic::desc, "type" = /obj/item/hierophant_club/expedition_mythic),
				"mythic_saw" = list("name" = "Beastbane", "description" = /obj/item/melee/cleaving_saw/expedition_mythic::desc, "type" = /obj/item/melee/cleaving_saw/expedition_mythic),
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
	var/turf/site = is_station_defense() ? find_siege_site() : find_site()
	if(!site)
		return FALSE
	var/area/destination = get_area(site)
	destination_room = destination.name
	state = "active"
	if(kind == "xenomorph")
		beacon = new /obj/structure/expedition_beacon/siege/xenomorph(site, src)
		var/list/exits = list()
		for(var/turf/open/floor/exit in orange(1, site))
			if(is_station_level(exit.z) && !exit.is_blocked_turf())
				exits += exit
		var/mob/living/basic/alien/queen/expedition/queen = new(pick(exits))
		track_station_hostile(queen)
		beacon.visible_message(span_danger("A xenomorph burrow opens and a queen emerges! Reinforcements will arrive in 30 seconds!"))
		wave_timer = addtimer(CALLBACK(src, PROC_REF(dispatch_siege_wave)), 30 SECONDS, TIMER_STOPPABLE)
		priority_announce("A xenomorph queen has emerged from a burrow in [destination_room]. Three reinforcement waves are expected at 30-second intervals. Contain the infestation. Tracking signal: [gps_tag]. No requisition rewards are assigned.", "Xenomorph Containment Order", sender_override = issuer, has_important_message = TRUE)
		return TRUE
	if(kind == "necropolis")
		beacon = new /obj/structure/expedition_beacon/siege/necropolis(site, src)
		beacon.visible_message(span_danger("A necropolis tendril bursts through the floor! Lavaland creatures will emerge in 45 seconds!"))
		wave_timer = addtimer(CALLBACK(src, PROC_REF(dispatch_siege_wave)), 45 SECONDS, TIMER_STOPPABLE)
		priority_announce("Central Command confirms a Necropolis manifestation in [destination_room]. First emergence is expected in 45 seconds. Assigned personnel are to contain the breach. Tracking signal: [gps_tag].", "Necropolis Containment Order", sender_override = issuer, has_important_message = TRUE)
		return TRUE
	if(kind == "siege")
		beacon = new /obj/structure/expedition_beacon/siege(site, src)
		beacon.visible_message(span_danger("A hostile boarding pod docks! Its deployment bay will open in 45 seconds!"))
		wave_timer = addtimer(CALLBACK(src, PROC_REF(dispatch_siege_wave)), 45 SECONDS, TIMER_STOPPABLE)
		priority_announce("Central Command confirms a Syndicate insertion pod in [destination_room]. Its deployment bay opens in 45 seconds. Assigned personnel are to intercept the boarding party and neutralize its deployment system. Tracking signal: [gps_tag].", "Boarding Interception Order", sender_override = issuer, has_important_message = TRUE)
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
	if((kind == "hunt" || is_station_defense()) && state == "active")
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
		if(free_exits >= (kind == "necropolis" ? 5 : (kind == "xenomorph" ? 4 : 3)))
			return site
	return null

/// Dispatch at most seven boarders in three waves. Blocked exits get bounded retries.
/datum/solo_expedition/proc/dispatch_siege_wave()
	wave_timer = null
	if(!is_station_defense() || state != "active" || deployment_disabled || waves_sent >= 3 || QDELETED(beacon))
		return FALSE
	var/list/exits = list()
	for(var/turf/open/floor/exit in orange(1, beacon))
		if(is_station_level(exit.z) && !exit.is_blocked_turf())
			exits += exit
	var/wave_size = get_station_wave_size(waves_sent + 1)
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
		var/mob_type = get_station_wave_mob(index, wave_size)
		var/mob/living/boarder = new mob_type(pick_n_take(exits))
		track_station_hostile(boarder)
	beacon.visible_message(span_danger("[beacon] releases [kind == "siege" ? "boarding" : "creature"] wave [waves_sent] of 3!"))
	beacon.update_appearance()
	if(waves_sent >= 3)
		stop_siege_deployment()
	else
		wave_timer = addtimer(CALLBACK(src, PROC_REF(dispatch_siege_wave)), kind == "xenomorph" ? 30 SECONDS : 40 SECONDS, TIMER_STOPPABLE)
	return TRUE

/// Register the initial queen and every reinforcement with the same death/cleanup rules.
/datum/solo_expedition/proc/track_station_hostile(mob/living/hostile)
	hostile.name = "[hostile.name] ([gps_tag])"
	if(istype(hostile, /mob/living/basic/alien))
		var/mob/living/basic/alien/xeno = hostile
		xeno.can_plant_weeds = FALSE
		xeno.can_lay_eggs = FALSE
	guards += hostile
	living_guards += hostile
	target_count++
	RegisterSignal(hostile, COMSIG_LIVING_DEATH, PROC_REF(target_died))
	RegisterSignal(hostile, COMSIG_QDELETING, PROC_REF(target_deleted))

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
	if(is_station_defense() && state == "active" && deployment_disabled && waves_sent > 0 && target_count > 0 && !length(living_guards) && kills == target_count)
		state = "complete"
		if(wave_timer)
			deltimer(wave_timer)
			wave_timer = null
		var/encounter = kind == "xenomorph" ? "Xenomorph containment" : (kind == "necropolis" ? "Necropolis breach" : "Boarding pod siege")
		var/hostiles = kind == "xenomorph" ? "xenomorphs" : (kind == "necropolis" ? "Lavaland creatures" : "boarders")
		var/clearance = kind == "xenomorph" ? "No requisition rewards are assigned. Close the assignment at an expedition terminal." : "Requisition clearance is granted: report to an expedition terminal to select your authorized item."
		priority_announce("Central Command confirms that all assigned [hostiles] in [destination_room] have been eliminated. The [encounter] is complete. [clearance]", "[encounter] - All Clear", sender_override = issuer, has_important_message = TRUE)
		if(GLOB.solo_expeditions.active == src)
			GLOB.solo_expeditions.status = "[encounter] complete in [destination_room]. All [hostiles] are dead. [clearance]"
		var/obj/structure/expedition_beacon/pod = beacon
		beacon = null
		if(!QDELETED(pod))
			var/turf/site = get_turf(pod)
			pod.visible_message(span_notice("[pod] dissolves into a puff of shimmering bluespace dust!"))
			new /obj/effect/temp_visual/small_smoke/expedition_bluespace_dust(site)
			new /obj/effect/temp_visual/bluespace_fissure(site)
			playsound(site, 'sound/effects/phasein.ogg', 45, TRUE)
			// Detach first so deleting the completed objective cannot alter mission state.
			pod.mission = null
			qdel(pod)

/// Serialize only player-facing data; no client-provided reward values or completion states.
/datum/solo_expedition/proc/get_mission_data()
	var/turf/site = get_turf(beacon)
	var/reward_theme = "General tier [difficulty] relics"
	if(kind == "xenomorph")
		reward_theme = "No rewards assigned"
	else if(kind == "siege")
		reward_theme = "Captured Syndicate prototypes"
	else if(kind == "necropolis")
		reward_theme = "Recovered Necropolis relics"
	var/list/rewards = list()
	for(var/reward_id in reward_options)
		var/list/choice = reward_options[reward_id]
		rewards += list(list("id" = reward_id, "name" = choice["name"], "description" = choice["description"]))
	return list(
		"id" = id,
		"kind" = kind,
		"title" = title,
		"description" = description,
		"issuer" = issuer,
		"orders" = orders.Copy(),
		"difficulty" = difficulty,
		"reward_theme" = reward_theme,
		"rewards" = rewards,
		"work_seconds" = work_time / (1 SECONDS),
		"state" = state,
		"gps" = gps_tag,
		"room" = destination_room,
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
		for(var/order in mission.orders)
			. += span_notice(order)
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
		balloon_alert(user, mission.kind == "necropolis" ? "tendril still emerging!" : "controls sealed until first deployment!")
		return
	if(mission.deployment_disabled)
		balloon_alert(user, "defeat remaining hostiles!")
		return
	working = TRUE
	balloon_alert(user, mission.kind == "necropolis" ? "sealing the breach..." : "disabling deployment...")
	var/success = do_after(user, 12 SECONDS, target = src)
	if(QDELETED(src))
		return
	working = FALSE
	if(success && mission && mission.state == "active")
		visible_message(span_notice("[user] disables [src]'s deployment system!"))
		mission.stop_siege_deployment()

/obj/structure/expedition_beacon/siege/Destroy()
	if(mission)
		var/datum/solo_expedition/owner = mission
		owner.beacon = null
		mission = null
		if(owner.state == "active" && !owner.waves_sent)
			owner.state = "failed"
		owner.stop_siege_deployment()
	return ..()

/// Mission-controlled tendril visual: no spawner component, terrain replacement, or chasm on death.
/obj/structure/expedition_beacon/siege/necropolis
	name = "station necropolis tendril"
	desc = "A necropolis tendril erupting through an intact floor. After its first wave, interact for twelve seconds to seal it, or destroy it."
	icon = 'icons/mob/simple/lavaland/tendril.dmi'
	icon_state = "tendril"
	pixel_x = 0
	pixel_w = -8
	max_integrity = 300

/obj/structure/expedition_beacon/siege/necropolis/Initialize(mapload, datum/solo_expedition/owner)
	. = ..()
	if(mission)
		name = "necropolis tendril ([mission.gps_tag])"
	new /obj/effect/temp_visual/small_smoke(get_turf(src))
	alpha = 0
	pixel_y = -24
	animate(src, alpha = 255, pixel_y = 0, time = 1 SECONDS)

/obj/structure/expedition_beacon/siege/necropolis/update_overlays()
	// Deliberately omit the parent supply-pod door, insignia, and glow overlays.
	return list()

/// Visual burrow only: deployment stays bounded by the mission, with no independent spawner.
/obj/structure/expedition_beacon/siege/xenomorph
	name = "xenomorph burrow"
	desc = "A xenomorph tunnel through the decking. After its first reinforcement wave, interact for twelve seconds to seal it, or destroy it."
	icon = 'icons/mob/expedition/burrow.dmi'
	icon_state = "burrow"
	pixel_x = -16
	pixel_y = -8

/obj/structure/expedition_beacon/siege/xenomorph/Initialize(mapload, datum/solo_expedition/owner)
	. = ..()
	if(mission)
		name = "xenomorph burrow ([mission.gps_tag])"
	// No emergence animation or particles: the burrow is a single static frame.

/obj/structure/expedition_beacon/siege/xenomorph/update_overlays()
	return list()

/// Constant low green light makes the static rim readable in dark rooms.
/obj/structure/expedition_beacon/siege/xenomorph/update_icon_state()
	. = ..()
	set_light(2, 0.7, LIGHT_COLOR_GREEN)

/// Mission-specific sprites leave ordinary aliens and their AI/combat statistics unchanged.
/mob/living/basic/alien/expedition_hunter
	icon = 'icons/mob/expedition/xenomorphs.dmi'
	icon_state = "hunter"
	icon_living = "hunter"
	icon_dead = "hunter_dead"

/mob/living/basic/alien/drone/expedition
	name = "alien bruiser"
	health = 150
	maxHealth = 150
	icon = 'icons/mob/expedition/xenomorphs.dmi'
	icon_state = "drone"
	icon_living = "drone"
	icon_dead = "drone_dead"

/mob/living/basic/alien/sentinel/expedition
	icon = 'icons/mob/expedition/xenomorphs.dmi'
	icon_state = "sentinel"
	icon_living = "sentinel"
	icon_dead = "sentinel_dead"

/mob/living/basic/alien/queen/expedition
	icon = 'icons/mob/expedition/queen.dmi'
	icon_state = "queen"
	icon_living = "queen"
	icon_dead = "queen_dead"
	pixel_x = -16
	mob_size = MOB_SIZE_LARGE

/// Harmless visual dust: no smoke chemistry, damage, or teleportation of nearby entities.
/obj/effect/temp_visual/small_smoke/expedition_bluespace_dust
	name = "bluespace dust"
	color = COLOR_BLUE_LIGHT
	duration = 2 SECONDS

/obj/effect/temp_visual/small_smoke/expedition_bluespace_dust/Initialize(mapload)
	. = ..()
	transform = matrix() * 2
	animate(src, alpha = 0, time = duration)

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
	icon = 'icons/obj/mining_zones/mythical_items.dmi'
	lefthand_file = 'icons/mob/inhands/mythical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/mythical_righthand.dmi'
	slash_color = "#fff2c6"
	desc = "A pale seam of light runs along this resonant blade, singing softly whenever it passes near metal. The edge seems less interested in cutting matter than in persuading it to separate. Wield it in both hands to command its sweeping cuts."
	force = 40
	block_chance = 60

/obj/item/clothing/suit/hooded/cloak/godslayer/expedition_mythic
	name = "Aegis of the Undying"
	icon = 'icons/obj/mining_zones/mythical_items.dmi'
	worn_icon = 'icons/mob/clothing/mythical_items.dmi'
	hoodtype = /obj/item/clothing/head/hooded/cloakhood/godslayer/expedition_mythic
	desc = "Beneath these frost-dark plates, something ancient keeps a patient watch over the wearer. When its bearer falters, the armour releases a surge of restorative warmth. The presence must gather its strength before it can intervene again."
	heal_amount = 1000
	effect_cooldown_time = 1 MINUTES

/obj/item/clothing/head/hooded/cloakhood/godslayer/expedition_mythic
	name = "Aegis antlered helm"
	desc = "Ancient ivory horns rise above a skull bound in frost-dark plates. A patient amber light watches from its hollow eyes."
	icon = 'icons/obj/mining_zones/mythical_items.dmi'
	worn_icon = 'icons/mob/clothing/mythical_items.dmi'
	icon_state = "godslayer_hood"
	worn_icon_state = "godslayer_hood"

/obj/item/organ/vocal_cords/colossus/expedition_mythic
	name = "Vox of the Necropolis"
	icon = 'icons/obj/mining_zones/mythical_items.dmi'
	desc = "Obsidian filaments cradle a throat that still murmurs beneath its crust of ash. Once grafted into a living bearer, its ancient decrees resonate through nearby organic minds, beast and mortal alike. The speaker alone is spared. Requires surgical installation; use Voice of God to issue commands such as HALT, SUFFER, or HEAL. Its resonance reaches visible creatures within eight tiles, even those that cannot hear."
	base_multiplier = 3

/obj/item/organ/vocal_cords/colossus/expedition_mythic/speak_with(message)
	var/cooldown = voice_of_god(uppertext(message), owner, spans, base_multiplier, organic_resonance = TRUE)
	next_command = world.time + (cooldown * cooldown_mod)

/obj/item/storm_staff/expedition_mythic
	name = "Tempest Sovereign"
	icon = 'icons/obj/mining_zones/mythical_items.dmi'
	lefthand_file = 'icons/mob/inhands/mythical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/mythical_righthand.dmi'
	desc = "The air around this staff tastes of rain and hot copper. Captive lightning moves beneath its surface, eager for release. Direct its thunder at a distant target, or raise it to disperse a passing storm; its spent charge gradually returns."
	max_thunder_charges = 12
	thunder_charges = 12
	thunder_charge_time = 5 SECONDS

/obj/item/hierophant_club/expedition_mythic
	name = "Sovereign's Sceptre"
	icon = 'icons/obj/mining_zones/mythical_items.dmi'
	lefthand_file = 'icons/mob/inhands/mythical_64x64_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/mythical_64x64_righthand.dmi'
	desc = "Violet geometry shifts beneath the polished face of this heavy sceptre. Each strike carries the final authority of a long-dead ruler. Its surviving mechanisms can loose resonant blasts and fold the bearer back toward a placed beacon."
	force = 60

/obj/item/melee/cleaving_saw/expedition_mythic
	name = "Beastbane"
	icon = 'icons/obj/mining_zones/mythical_items.dmi'
	lefthand_file = 'icons/mob/inhands/mythical_64x64_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/mythical_64x64_righthand.dmi'
	desc = "Old hunting marks have been cut into the spine of this folding saw. Its teeth catch eagerly against the plated hides of the wastes. Unfold the blade into a long cleaver to sweep through the creatures gathered around you."
	force = 35
	open_force = 50
	faction_bonus_force = 60

/// Syndicate breach-raid mythical gear uses normal weapon, shield, armour and hacking APIs.
/obj/item/melee/energy/sword/saber/red/expedition_syndicate
	name = "Red Verdict"
	icon = 'icons/obj/mining_zones/mythical_items.dmi'
	lefthand_file = 'icons/mob/inhands/mythical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/mythical_righthand.dmi'
	desc = "An unmarked hilt fitted with a crimson focusing crystal. Once ignited, its narrow blade casts the room in the colour of a sealed execution order. Activate it before entering combat."
	active_force = 60
	block_chance = 70
	armour_penetration = 50

/obj/item/shield/energy/expedition_syndicate
	name = "Crimson Bulwark"
	icon = 'icons/obj/mining_zones/mythical_items.dmi'
	lefthand_file = 'icons/mob/inhands/mythical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/mythical_righthand.dmi'
	desc = "Overlapping layers of red hardlight unfold from a compact forearm unit. The field is designed to turn aside incoming blows and return compatible energy fire to its sender. Activate it before use; overwhelming attacks can still break through its defence."
	block_chance = 90
	reflection_probability = 90
	active_force = 25
	can_clumsy_use = TRUE

/obj/item/gun/energy/laser/expedition_syndicate
	name = "Blackstar Carbine"
	icon = 'icons/obj/mining_zones/mythical_items.dmi'
	lefthand_file = 'icons/mob/inhands/mythical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/mythical_righthand.dmi'
	desc = "A restricted-issue carbine with its serial number burned out of the receiver. A quiet internal generator continually replenishes the weapon's cell, while a dark focusing lens shapes each shot into a clean scarlet pulse."
	color = null
	projectile_damage_multiplier = 2
	selfcharge = TRUE
	charge_delay = 1
	self_charge_amount = 400
	fire_delay = 0.5 SECONDS

/datum/armor/expedition_syndicate_mythical
	melee = 80
	bullet = 80
	laser = 80
	energy = 80
	bomb = 70
	bio = 80
	fire = 100
	acid = 100
	wound = 50

/obj/item/clothing/suit/armor/vest/expedition_syndicate
	name = "Ghost Legion assault suit"
	icon = 'icons/obj/mining_zones/mythical_items.dmi'
	worn_icon = 'icons/mob/clothing/mythical_items.dmi'
	desc = "Flexible black plates ride over a fitted assault harness, shielding the torso and limbs without burdening the wearer. A matching helmet accompanies the suit. The set is intended for close boarding actions and is not sealed against vacuum."
	color = null
	armor_type = /datum/armor/expedition_syndicate_mythical
	body_parts_covered = CHEST|GROIN|ARMS|HANDS|LEGS|FEET
	slowdown = 0
	resistance_flags = FIRE_PROOF | ACID_PROOF

/obj/item/clothing/suit/armor/vest/expedition_syndicate/Initialize(mapload)
	. = ..()
	new /obj/item/clothing/head/helmet/expedition_syndicate(drop_location())

/obj/item/clothing/head/helmet/expedition_syndicate
	name = "Ghost Legion helmet"
	icon = 'icons/obj/mining_zones/mythical_items.dmi'
	worn_icon = 'icons/mob/clothing/mythical_items.dmi'
	desc = "A severe, featureless helmet issued with the Ghost Legion assault harness. Layered composites shield the head while leaving the wearer free to move. It is not vacuum-rated."
	color = null
	armor_type = /datum/armor/expedition_syndicate_mythical
	slowdown = 0
	resistance_flags = FIRE_PROOF | ACID_PROOF

/obj/item/card/emag/bluespace/expedition_syndicate
	name = "Skeleton Protocol"
	icon = 'icons/obj/mining_zones/mythical_items.dmi'
	lefthand_file = 'icons/mob/inhands/mythical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/mythical_righthand.dmi'
	desc = "A confiscated intrusion device carrying a library of forbidden machine instructions. Its transmitter can corrupt compatible safeguards from a distance without expending disposable charges. These are destructive overrides: compromised doors and machinery may not return to normal operation."

/obj/item/card/emag/bluespace/expedition_syndicate/Initialize(mapload)
	. = ..()
	type_blacklist = list()

/obj/item/chameleon/expedition_syndicate
	name = "Phantom Relay"
	icon = 'icons/obj/mining_zones/mythical_items.dmi'
	lefthand_file = 'icons/mob/inhands/mythical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/mythical_righthand.dmi'
	desc = "A stolen counterintelligence projector that wraps its operator in the likeness of a scanned object. Its image can be re-established as soon as a disruption clears, but impacts and physical contact still expose the person hiding inside. Scan an object, then use the projector in hand to assume its appearance."
	color = null

/obj/item/chameleon/expedition_syndicate/disrupt(delete_dummy = TRUE)
	. = ..()
	can_use = TRUE

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
	desc = "A secure tasking uplink to Central Command's Special Assignments Office. Review field orders, accept assignments, and collect authorized requisitions upon completion."
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
		if("finish")
			return board.finish(params["id"])
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
	GLOB.solo_expeditions.status = "Central Command acknowledges receipt of the assigned flight recorder. Requisition clearance granted; select one authorized item."
	to_chat(user, span_notice("Flight recorder submitted. Open the console to choose your reward."))
	return ITEM_INTERACT_SUCCESS
