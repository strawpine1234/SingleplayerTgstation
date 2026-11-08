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
		var/list/pool = mission.get_reward_pool(mission.difficulty)
		for(var/reward_id in mission.reward_options)
			TEST_ASSERT(reward_id in pool, "Rewards must belong to the mission's tier.")
	TEST_ASSERT_EQUAL(length(kinds), 3, "The board must offer three distinct objective types.")
	TEST_ASSERT("siege" in kinds, "A siege offer must always be available.")
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
	var/list/full_pool = selected.get_reward_pool(selected.difficulty)
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
	TEST_ASSERT(/obj/item/debug/omnitool/expedition_mythic::toolspeed < /obj/item/debug/omnitool::toolspeed, "Mythical omnitool must work faster.")
	TEST_ASSERT(/obj/item/storm_staff/expedition_mythic::max_thunder_charges > /obj/item/storm_staff::max_thunder_charges, "Mythical staff must hold more charges.")
	TEST_ASSERT(/obj/item/hierophant_club/expedition_mythic::force > /obj/item/hierophant_club::force, "Mythical club must hit harder.")
	TEST_ASSERT(/obj/item/melee/cleaving_saw/expedition_mythic::open_force > /obj/item/melee/cleaving_saw::open_force, "Mythical saw must hit harder when opened.")

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
