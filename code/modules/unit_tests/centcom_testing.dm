/// Harmless event used to exercise the real manual launch API.
/datum/round_event_control/centcom_testing_unit_test
	name = "CentCom console unit test"
	typepath = /datum/round_event/centcom_testing_unit_test
	category = EVENT_CATEGORY_FRIENDLY
	min_players = 999
	max_occurrences = 0
	earliest_start = 1 DAYS
	alert_observers = FALSE

/datum/round_event/centcom_testing_unit_test
	end_when = 10
	var/setup_ran = FALSE
	var/start_ran = FALSE

/datum/round_event/centcom_testing_unit_test/setup()
	setup_ran = TRUE

/datum/round_event/centcom_testing_unit_test/start()
	start_ran = TRUE

/datum/unit_test/centcom_testing/Run()
	var/saved_manual_mode = SSevents.manual_testing_only
	var/saved_schedule = SSevents.scheduled
	var/saved_next_test = SSevents.next_test_time
	SSevents.manual_testing_only = TRUE
	SSevents.scheduled = world.time - 1
	var/original_events = length(SSevents.running)
	SSevents.checkEvent()
	SSevents.spawnEvent()
	TEST_ASSERT_EQUAL(length(SSevents.running), original_events, "Natural scheduling must not launch events in manual mode.")
	TEST_ASSERT_EQUAL(SSevents.scheduled, world.time - 1, "Manual mode must skip automatic rescheduling.")
	SSevents.scheduled = saved_schedule
	SSevents.manual_testing_only = saved_manual_mode

	for(var/datum/round_event_control/control as anything in SSevents.control)
		if(control.name)
			TEST_ASSERT_EQUAL(SSevents.testing_events["[control.type]"], control, "The console must catalogue every named event control.")
	var/list/bands = list(CENTCOM_TEST_MINOR, CENTCOM_TEST_MODERATE, CENTCOM_TEST_MAJOR, CENTCOM_TEST_CATASTROPHIC, CENTCOM_TEST_MISC)
	for(var/id in SSevents.testing_events)
		var/datum/round_event_control/control = SSevents.testing_events[id]
		TEST_ASSERT(control.get_testing_severity() in bands, "Every trial must belong to a console tab.")
		if(ispath(control.typepath, /datum/round_event/ghost_role))
			TEST_ASSERT_EQUAL(control.get_testing_severity(), CENTCOM_TEST_MISC, "Ghost-controlled roles must appear in Misc.")

	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/consistent)
	var/obj/machinery/computer/centcom_testing/console = allocate(/obj/machinery/computer/centcom_testing)
	TEST_ASSERT_EQUAL(console.circuit.build_path, /obj/machinery/computer/centcom_testing, "The circuit board must rebuild the testing console.")
	TEST_ASSERT_NULL(SSevents.run_testing_event("not-an-event", user), "Unknown client event IDs must be rejected.")
	var/id = "[/datum/round_event_control/centcom_testing_unit_test]"
	var/datum/round_event_control/control = SSevents.testing_events[id]
	TEST_ASSERT_NOTNULL(control, "Test control must be registered.")
	SSevents.next_test_time = 0
	var/datum/round_event/centcom_testing_unit_test/trial = SSevents.run_testing_event(id, user)
	TEST_ASSERT_NOTNULL(trial, "Manual tests must bypass random population, time, and occurrence limits.")
	TEST_ASSERT(trial.setup_ran, "Manual tests must use normal event setup.")
	TEST_ASSERT(trial in SSevents.running, "Manual tests must join normal event processing.")
	TEST_ASSERT_NULL(SSevents.run_testing_event(id, user), "Repeated requests must not duplicate an active trial.")
	trial.process(2)
	TEST_ASSERT(trial.start_ran, "The event must start through normal subsystem processing.")
	trial.kill()
	qdel(trial)
	SSevents.next_test_time = saved_next_test
