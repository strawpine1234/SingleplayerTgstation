/// Offer variety, stale actions, premature claims, and duplicate reward protection.
/datum/unit_test/expedition_console

/datum/unit_test/expedition_console/Run()
	var/datum/solo_expedition_board/board = new
	TEST_ASSERT_EQUAL(length(board.offers), 3, "Exactly three expeditions must be offered.")
	var/list/kinds = list()
	for(var/datum/solo_expedition/mission as anything in board.offers)
		kinds |= mission.kind
		TEST_ASSERT(mission.difficulty >= 1 && mission.difficulty <= 3, "Difficulty must be within the advertised range.")
	TEST_ASSERT_EQUAL(length(kinds), 3, "The board must offer three distinct objective types.")
	TEST_ASSERT(!board.accept_offer("invalid"), "An arbitrary client offer ID must not deploy a mission.")
	var/datum/solo_expedition/selected = board.offers[1]
	var/old_id = selected.id
	selected.difficulty = 1
	selected.configure_rewards()
	board.active = selected
	selected.state = "active"
	TEST_ASSERT(!board.roll_offers(), "Active expeditions must prevent rerolls.")
	TEST_ASSERT(!board.claim(old_id, "talisman", run_loc_floor_bottom_left), "Incomplete missions must not pay out.")
	selected.state = "complete"
	TEST_ASSERT(!board.claim(old_id, "forged_reward", run_loc_floor_bottom_left), "Unknown rewards must be rejected.")
	TEST_ASSERT_EQUAL(board.active, selected, "Rejected claims must preserve the mission.")
	TEST_ASSERT(!board.claim(old_id, "blade", run_loc_floor_bottom_left), "A higher-tier reward must not be claimable from an easier offer.")
	TEST_ASSERT(board.claim(old_id, "talisman", run_loc_floor_bottom_left), "Completed expedition must pay out.")
	TEST_ASSERT_EQUAL(board.completed, 1, "A successful claim must be recorded once.")
	TEST_ASSERT(!board.claim(old_id, "talisman", run_loc_floor_bottom_left), "Duplicate claims must not pay out.")
	TEST_ASSERT_EQUAL(length(board.offers), 3, "A reward must generate three fresh offers.")
	TEST_ASSERT(!board.accept_offer(old_id), "A stale offer ID must not select a replacement mission.")
	var/obj/item/immortality_talisman/payment = locate() in run_loc_floor_bottom_left
	TEST_ASSERT_NOTNULL(payment, "The chosen artifact must be delivered.")
	qdel(payment)
	selected = board.offers[1]
	board.active = selected
	TEST_ASSERT(board.abandon(selected.id), "Active expedition must be abandonable.")
	TEST_ASSERT(board.next_start > world.time, "Abandonment must enforce a departure cooldown.")
	selected = board.offers[1]
	TEST_ASSERT(!board.accept_offer(selected.id), "New offers must respect the cooldown.")
	qdel(board)
