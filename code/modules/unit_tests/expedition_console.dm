/// Offer variety, stale actions, premature claims, and duplicate reward protection.
/datum/unit_test/expedition_console

/datum/unit_test/expedition_console/Run()
	var/datum/solo_expedition_board/board = new
	TEST_ASSERT_EQUAL(length(board.offers), 3, "Exactly three expeditions must be offered.")
	var/list/kinds = list()
	for(var/datum/solo_expedition/mission as anything in board.offers)
		kinds |= mission.kind
		TEST_ASSERT(mission.difficulty >= 1 && mission.difficulty <= 4, "Difficulty must be within the advertised range.")
		TEST_ASSERT_EQUAL(length(mission.reward_options), 3, "Each offer must draw exactly three rewards.")
		var/list/pool = mission.get_mission_reward_pool()
		for(var/reward_id in mission.reward_options)
			TEST_ASSERT(reward_id in pool, "Rewards must belong to the mission's tier.")
	TEST_ASSERT_EQUAL(length(kinds), 3, "The board must offer three distinct objective types.")
	TEST_ASSERT("siege" in kinds, "A siege offer must always be available.")
	TEST_ASSERT("necropolis" in kinds, "A Necropolis breach must always be available.")
	TEST_ASSERT(!board.accept_offer("invalid"), "An arbitrary client offer ID must not deploy a mission.")
	var/datum/solo_expedition/selected = board.offers[1]
	var/old_id = selected.id
	var/chosen_reward = selected.reward_options[1]
	var/list/chosen_definition = selected.reward_options[chosen_reward]
	var/reward_type = chosen_definition["type"]
	TEST_ASSERT(!selected.configure_rewards(), "An existing offer must not reroll its rewards.")
	TEST_ASSERT_EQUAL(selected.reward_options[1], chosen_reward, "Repeated configuration must preserve the choices.")
	board.active = selected
	selected.state = "active"
	TEST_ASSERT(!board.roll_offers(), "Active expeditions must prevent rerolls.")
	TEST_ASSERT(!board.claim(old_id, chosen_reward, run_loc_floor_bottom_left), "Incomplete missions must not pay out.")
	selected.state = "complete"
	TEST_ASSERT(!board.claim(old_id, "forged_reward", run_loc_floor_bottom_left), "Unknown rewards must be rejected.")
	TEST_ASSERT_EQUAL(board.active, selected, "Rejected claims must preserve the mission.")
	var/list/full_pool = selected.get_mission_reward_pool()
	for(var/reward_id in full_pool)
		if(!(reward_id in selected.reward_options))
			TEST_ASSERT(!board.claim(old_id, reward_id, run_loc_floor_bottom_left), "A valid but unoffered reward must not be claimable.")
	TEST_ASSERT(board.claim(old_id, chosen_reward, run_loc_floor_bottom_left), "Completed expedition must pay out.")
	TEST_ASSERT_EQUAL(board.completed, 1, "A successful claim must be recorded once.")
	TEST_ASSERT(!board.claim(old_id, chosen_reward, run_loc_floor_bottom_left), "Duplicate claims must not pay out.")
	TEST_ASSERT_EQUAL(length(board.offers), 3, "A reward must generate three fresh offers.")
	TEST_ASSERT(!board.accept_offer(old_id), "A stale offer ID must not select a replacement mission.")
	var/obj/item/payment = locate(reward_type) in run_loc_floor_bottom_left
	TEST_ASSERT_NOTNULL(payment, "The chosen artifact must be delivered.")
	qdel(payment)
	selected = board.offers[1]
	board.active = selected
	TEST_ASSERT(board.abandon(selected.id), "Active expedition must be abandonable.")
	TEST_ASSERT(board.next_start > world.time, "Abandonment must enforce a departure cooldown.")
	selected = board.offers[1]
	TEST_ASSERT(!board.accept_offer(selected.id), "New offers must respect the cooldown.")
	qdel(board)

/// The three pools must remain disjoint and large enough to provide real variety.
/datum/unit_test/expedition_reward_pools

/datum/unit_test/expedition_reward_pools/Run()
	var/datum/solo_expedition/mission = new("survey", "test")
	var/list/all_ids = list()
	var/list/all_types = list()
	for(var/tier in 1 to 4)
		var/list/pool = mission.get_reward_pool(tier)
		TEST_ASSERT_EQUAL(length(pool), 6, "Each tier must have six reward candidates.")
		for(var/reward_id in pool)
			var/list/definition = pool[reward_id]
			TEST_ASSERT(!(reward_id in all_ids), "Reward IDs must not overlap across tiers.")
			TEST_ASSERT(!(definition["type"] in all_types), "Reward items must not overlap across tiers.")
			TEST_ASSERT(ispath(definition["type"], /obj/item), "Rewards must be valid item types.")
			all_ids += reward_id
			all_types += definition["type"]
	qdel(mission)

/// Stopping reinforcements is necessary but insufficient: all deployed targets must die.
/datum/unit_test/expedition_siege_completion

/datum/unit_test/expedition_siege_completion/Run()
	var/datum/solo_expedition/mission = new("siege", "siege_test")
	TEST_ASSERT_EQUAL(mission.difficulty, 4, "Sieges must award mythical-tier rewards.")
	TEST_ASSERT_EQUAL(length(mission.reward_options), 3, "Sieges must draw three mythical choices.")
	mission.state = "active"
	mission.wave_timer = addtimer(CALLBACK(mission, TYPE_PROC_REF(/datum/solo_expedition, dispatch_siege_wave)), 10 MINUTES, TIMER_STOPPABLE)
	mission.stop_siege_deployment()
	TEST_ASSERT_NULL(mission.wave_timer, "Sabotage must cancel the pending deployment timer.")
	TEST_ASSERT(!mission.dispatch_siege_wave(), "Disabled deployment must not spawn another wave.")
	TEST_ASSERT_EQUAL(mission.state, "active", "Stopping an unopened pod must not grant completion.")
	mission.waves_sent = 1
	mission.target_count = 1
	var/mob/living/target = allocate(/mob/living/carbon/human/consistent)
	mission.guards += target
	mission.living_guards += target
	mission.check_siege_completion()
	TEST_ASSERT_EQUAL(mission.state, "active", "Living boarders must prevent completion.")
	mission.target_died(target, FALSE)
	TEST_ASSERT_EQUAL(mission.state, "complete", "The last verified kill after sabotage should complete the mission.")
	mission.target_died(target, FALSE)
	TEST_ASSERT_EQUAL(mission.kills, 1, "Duplicate death notifications must not count twice.")
	qdel(mission)
	mission = new("siege", "failed_siege_test")
	mission.state = "active"
	mission.waves_sent = 1
	mission.target_count = 1
	target = allocate(/mob/living/carbon/human/consistent)
	mission.guards += target
	mission.living_guards += target
	mission.target_deleted(target)
	TEST_ASSERT_EQUAL(mission.state, "failed", "Deleting a live boarder must fail, not complete, the mission.")
	TEST_ASSERT(mission.deployment_disabled, "Failure must stop future waves.")
	qdel(mission)

/// Mythical variants must actually improve the statistics advertised in their reward cards.
/datum/unit_test/expedition_mythical_stats

/datum/unit_test/expedition_mythical_stats/Run()
	TEST_ASSERT(/obj/item/highfrequencyblade/expedition_mythic::force > /obj/item/highfrequencyblade::force, "Mythical blade must be stronger.")
	TEST_ASSERT(/obj/item/highfrequencyblade/expedition_mythic::block_chance > /obj/item/highfrequencyblade::block_chance, "Mythical blade must block more often.")
	TEST_ASSERT(/obj/item/clothing/suit/hooded/cloak/godslayer/expedition_mythic::effect_cooldown_time < /obj/item/clothing/suit/hooded/cloak/godslayer::effect_cooldown_time, "Mythical armour must recharge faster.")
	TEST_ASSERT_EQUAL(/obj/item/organ/vocal_cords/colossus/expedition_mythic::base_multiplier, 3 * /obj/item/organ/vocal_cords/colossus::base_multiplier, "Mythical vocal cords must have triple command power.")
	TEST_ASSERT(/obj/item/storm_staff/expedition_mythic::max_thunder_charges > /obj/item/storm_staff::max_thunder_charges, "Mythical staff must hold more charges.")
	TEST_ASSERT(/obj/item/hierophant_club/expedition_mythic::force > /obj/item/hierophant_club::force, "Mythical club must hit harder.")
	TEST_ASSERT(/obj/item/melee/cleaving_saw/expedition_mythic::open_force > /obj/item/melee/cleaving_saw::open_force, "Mythical saw must hit harder when opened.")

/// Mythical icons must cover every reward and survive the normal transformation lifecycle.
/datum/unit_test/expedition_mythical_art

/datum/unit_test/expedition_mythical_art/Run()
	var/datum/solo_expedition/mission = new("necropolis", "art_test")
	var/list/pool = mission.get_reward_pool(4) + mission.get_syndicate_reward_pool()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/consistent)
	for(var/reward_id in pool)
		var/list/reward = pool[reward_id]
		var/obj/item/item = allocate(reward["type"])
		TEST_ASSERT_EQUAL(item.icon, 'icons/obj/mining_zones/mythical_items.dmi', "Every mythical reward must use the dedicated artwork.")
		TEST_ASSERT(icon_exists(item.icon, item.icon_state), "[item] must have an initial inventory sprite.")
		if(item.worn_icon)
			TEST_ASSERT(icon_exists(item.worn_icon, item.worn_icon_state || item.icon_state), "[item] must retain its worn sprite.")
		var/datum/component/transforming/transformer = item.GetComponent(/datum/component/transforming)
		if(transformer)
			transformer.do_transform(item, user)
			TEST_ASSERT(icon_exists(item.icon, item.icon_state), "[item] must have an activated/unfolded sprite.")
			TEST_ASSERT(icon_exists(item.lefthand_file, item.inhand_icon_state), "[item] must have an activated left-hand sprite.")
			TEST_ASSERT(icon_exists(item.righthand_file, item.inhand_icon_state), "[item] must have an activated right-hand sprite.")
			transformer.do_transform(item, user)
			TEST_ASSERT(icon_exists(item.icon, item.icon_state), "[item] must have a sprite after deactivation.")
	var/obj/item/clothing/head/hooded/cloakhood/godslayer/expedition_mythic/hood = allocate(/obj/item/clothing/head/hooded/cloakhood/godslayer/expedition_mythic)
	TEST_ASSERT(icon_exists(hood.icon, hood.icon_state), "Aegis must have matching hood artwork.")
	TEST_ASSERT(icon_exists(hood.worn_icon, hood.worn_icon_state), "The matching Aegis hood must display when worn.")
	var/obj/item/clothing/head/helmet/expedition_syndicate/helmet = allocate(/obj/item/clothing/head/helmet/expedition_syndicate)
	TEST_ASSERT(icon_exists(helmet.icon, helmet.icon_state), "Ghost Legion must have a matching helmet sprite.")
	TEST_ASSERT(icon_exists(helmet.worn_icon, helmet.worn_icon_state || helmet.icon_state), "Ghost Legion's helmet must display when worn.")
	qdel(mission)

/// Organic resonance must reach humans, pets and stun-immune fauna without reaching its bearer or machines.
/datum/unit_test/expedition_necropolis_voice

/datum/unit_test/expedition_necropolis_voice/Run()
	var/mob/living/carbon/human/speaker = allocate(/mob/living/carbon/human/consistent, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/person = allocate(/mob/living/carbon/human/consistent, run_loc_floor_bottom_left)
	var/mob/living/basic/pet/dog/corgi/pet = allocate(/mob/living/basic/pet/dog/corgi, run_loc_floor_bottom_left)
	pet.setMaxHealth(100) // Keep the pet alive so its damage counter does not cap at its original health.
	var/mob/living/basic/mining/goliath/monster = allocate(/mob/living/basic/mining/goliath, run_loc_floor_bottom_left)
	var/mob/living/basic/machine = allocate(/mob/living/basic, run_loc_floor_bottom_left)
	machine.mob_biotypes = MOB_ROBOTIC
	ADD_TRAIT(person, TRAIT_DEAF, REF(src))
	ADD_TRAIT(monster, TRAIT_STUNIMMUNE, REF(src))
	var/obj/item/organ/vocal_cords/colossus/expedition_mythic/cords = allocate(/obj/item/organ/vocal_cords/colossus/expedition_mythic)
	TEST_ASSERT(cords.Insert(speaker, special = TRUE, movement_flags = DELETE_IF_REPLACED), "The mythical organ must support normal surgical installation.")
	cords.speak_with("SUFFER")
	TEST_ASSERT_EQUAL(cords.next_command, world.time + 1 MINUTES, "The organ must retain the normal damage-command cooldown.")
	TEST_ASSERT_EQUAL(person.get_brute_loss(), 45, "Organic humans must receive triple the normal command effect, even when deaf.")
	TEST_ASSERT_EQUAL(pet.get_brute_loss(), 45, "Organic pets must be affected without a client or human anatomy.")
	TEST_ASSERT_EQUAL(monster.get_brute_loss(), 45, "Organic monsters must be affected.")
	TEST_ASSERT_EQUAL(speaker.get_brute_loss(), 0, "The speaker must never affect themselves.")
	TEST_ASSERT_EQUAL(machine.get_brute_loss(), 0, "Robotic targets must be excluded.")
	// Ignore chat spam throttling for subsequent checks of the shared command pipeline.
	voice_of_god("HALT", speaker, null, base_multiplier = 3, include_speaker = TRUE, forced = "unit test", ignore_spam = TRUE, organic_resonance = TRUE)
	TEST_ASSERT(monster.IsImmobilized(), "Resonance must bypass ordinary organic stun immunity.")
	TEST_ASSERT(!speaker.IsImmobilized(), "Even include_speaker cannot override the organ's self-exclusion.")
	TEST_ASSERT(!machine.IsImmobilized(), "Resonance must never control a machine.")
	monster.SetImmobilized(0, ignore_canstun = TRUE)
	voice_of_god("HALT", speaker, null, forced = "unit test", ignore_spam = TRUE)
	TEST_ASSERT(!monster.IsImmobilized(), "Ordinary divine vocal cords must retain normal immunity checks.")

/// Boarders have crew anatomy and persistent corpses, with verified mission death tracking.
/datum/unit_test/expedition_carbon_boarders

/datum/unit_test/expedition_carbon_boarders/Run()
	var/mob/living/carbon/human/expedition_boarder/boarder = allocate(/mob/living/carbon/human/expedition_boarder)
	TEST_ASSERT_NOTNULL(boarder.get_organ_slot(ORGAN_SLOT_BRAIN), "Boarders must have a real brain.")
	TEST_ASSERT_NOTNULL(boarder.get_organ_slot(ORGAN_SLOT_HEART), "Boarders must have a real heart.")
	TEST_ASSERT_EQUAL(length(boarder.bodyparts), 6, "Boarders must have normal human limbs.")
	TEST_ASSERT_NOTNULL(boarder.ai_controller, "Carbon boarders must retain hostile AI.")
	TEST_ASSERT(length(boarder.ai_controller.behavior_nodes), "Hostile AI must build its combat tree.")
	boarder.adjust_brute_loss(20)
	boarder.adjust_fire_loss(10)
	boarder.adjust_oxy_loss(5)
	TEST_ASSERT(boarder.get_brute_loss() > 0, "Boarders must take normal bodypart damage.")
	TEST_ASSERT(boarder.get_fire_loss() > 0, "Boarders must take burn damage.")
	TEST_ASSERT(boarder.get_oxy_loss() > 0, "Boarders must take oxygen damage.")
	var/datum/solo_expedition/mission = new("siege", "carbon_test")
	mission.state = "active"
	mission.waves_sent = 1
	mission.target_count = 1
	mission.deployment_disabled = TRUE
	mission.guards += boarder
	mission.living_guards += boarder
	// Register from the mission so the real death signal updates the correct owner.
	mission.RegisterSignal(boarder, COMSIG_LIVING_DEATH, TYPE_PROC_REF(/datum/solo_expedition, target_died))
	boarder.death(FALSE)
	TEST_ASSERT_EQUAL(boarder.stat, DEAD, "Lethal injury must produce a normal dead human.")
	TEST_ASSERT(!QDELETED(boarder), "Death must not delete the body.")
	TEST_ASSERT_EQUAL(mission.state, "complete", "Real carbon death must count toward mission completion.")
	qdel(mission)
	TEST_ASSERT(!QDELETED(boarder), "Mission cleanup must preserve a dead boarder's body.")
	TEST_ASSERT_NOTNULL(boarder.get_organ_slot(ORGAN_SLOT_BRAIN), "The corpse must retain its organs.")

/// Raid loot is exclusive, while the original generic mythical pool remains intact.
/datum/unit_test/expedition_syndicate_rewards

/datum/unit_test/expedition_syndicate_rewards/Run()
	var/datum/solo_expedition/raid = new("siege", "syndicate_pool_test")
	var/list/general_pool = raid.get_reward_pool(4)
	var/list/raid_pool = raid.get_mission_reward_pool()
	TEST_ASSERT_EQUAL(length(general_pool), 6, "The original mythical pool must be retained.")
	TEST_ASSERT("mythic_blade" in general_pool, "Worldsplitter must remain in the general mythical pool.")
	TEST_ASSERT_EQUAL(length(raid_pool), 6, "The raid must have six exclusive mythical rewards.")
	TEST_ASSERT_EQUAL(length(raid.reward_options), 3, "The raid must draw exactly three choices.")
	for(var/reward_id in raid_pool)
		TEST_ASSERT(!(reward_id in general_pool), "Raid and generic mythical IDs must not overlap.")
		var/list/definition = raid_pool[reward_id]
		TEST_ASSERT(ispath(definition["type"], /obj/item), "Raid rewards must be valid items.")
		for(var/general_id in general_pool)
			var/list/general_definition = general_pool[general_id]
			TEST_ASSERT_NOTEQUAL(definition["type"], general_definition["type"], "Raid rewards must be separate item variants.")
	for(var/reward_id in raid.reward_options)
		TEST_ASSERT(reward_id in raid_pool, "The raid must never draw generic mythical loot.")
	var/datum/solo_expedition/other = new("hunt", "general_pool_test")
	other.difficulty = 4
	var/list/other_pool = other.get_mission_reward_pool()
	TEST_ASSERT("mythic_blade" in other_pool, "Other tier-four mission types must use the original mythical pool.")
	TEST_ASSERT(!("syndicate_sword" in other_pool), "Other mission types must not receive raid-exclusive loot.")
	qdel(other)
	qdel(raid)

/// Necropolis breaches use the original mythical pool, bounded 3/4/5 waves and intact floors.
/datum/unit_test/expedition_necropolis

/datum/unit_test/expedition_necropolis/Run()
	var/datum/solo_expedition/mission = new("necropolis", "necro_test")
	TEST_ASSERT_EQUAL(mission.difficulty, 4, "Necropolis breaches must be tier four.")
	TEST_ASSERT(mission.is_station_defense(), "Necropolis breaches must share station-defense lifecycle rules.")
	TEST_ASSERT_EQUAL(mission.get_station_wave_size(1), 3, "The first wave must contain three creatures.")
	TEST_ASSERT_EQUAL(mission.get_station_wave_size(2), 4, "The second wave must contain four creatures.")
	TEST_ASSERT_EQUAL(mission.get_station_wave_size(3), 5, "The third wave must contain five creatures.")
	TEST_ASSERT_EQUAL(mission.get_station_wave_size(4), 0, "There must be no fourth wave.")
	var/list/pool = mission.get_mission_reward_pool()
	TEST_ASSERT_EQUAL(length(pool), 6, "The Necropolis pool must retain all six original mythical items.")
	TEST_ASSERT("mythic_blade" in pool, "The original mythical blade must be available.")
	TEST_ASSERT(!("syndicate_sword" in pool), "Necropolis missions must not offer Syndicate-only rewards.")
	TEST_ASSERT_EQUAL(length(mission.reward_options), 3, "The mission must offer three locked mythical choices.")
	for(var/reward_id in mission.reward_options)
		TEST_ASSERT(reward_id in pool, "Necropolis reward choices must come from the original pool.")
	var/turf/floor = run_loc_floor_bottom_left
	var/original_type = floor.type
	var/original_icon_state = floor.icon_state
	mission.beacon = allocate(/obj/structure/expedition_beacon/siege/necropolis, floor, mission)
	TEST_ASSERT_EQUAL(get_turf(mission.beacon), floor, "The tendril must stand on the original floor turf.")
	TEST_ASSERT_EQUAL(floor.type, original_type, "Emergence must not change the floor type.")
	TEST_ASSERT_EQUAL(floor.icon_state, original_icon_state, "Emergence must not change the floor appearance.")
	qdel(mission.beacon)
	TEST_ASSERT(!QDELETED(floor), "Destroying the tendril must not delete the floor.")
	TEST_ASSERT_EQUAL(floor.type, original_type, "Destroying the tendril must not create a chasm.")
	qdel(mission)
	mission = new("necropolis", "necro_completion_test")
	mission.state = "active"
	mission.waves_sent = 1
	mission.target_count = 3
	mission.kills = 3
	mission.check_siege_completion()
	TEST_ASSERT_EQUAL(mission.state, "active", "The breach must not complete while reinforcements are enabled.")
	mission.stop_siege_deployment()
	TEST_ASSERT_EQUAL(mission.state, "complete", "Sealing the breach after verified kills must complete it.")
	TEST_ASSERT_NULL(mission.beacon, "Completed breaches must not retain their objective.")
	TEST_ASSERT(!mission.dispatch_siege_wave(), "Completed breaches must not spawn more creatures.")
	qdel(mission)
