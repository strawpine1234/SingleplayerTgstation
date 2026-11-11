/// Central Command's manual event catalogue. Event IDs are resolved only against server-owned controls.
/obj/machinery/computer/centcom_testing
	name = "CentCom Testing Initiative console"
	desc = "Central Command's station-scale testing uplink. Select a severity band and authorize a live trial."
	circuit = /obj/item/circuitboard/computer/centcom_testing
	var/last_result = "CentCom Testing Initiative online. Select a trial when the station is ready."

/obj/machinery/computer/centcom_testing/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CentComTesting", name)
		ui.open()

/obj/machinery/computer/centcom_testing/ui_data(mob/user)
	var/list/events = list()
	for(var/id in SSevents.testing_events)
		var/datum/round_event_control/event = SSevents.testing_events[id]
		events += list(list(
			"id" = id,
			"name" = event.name,
			"description" = event.description || "A live CentCom trial using standard station event procedures.",
			"category" = event.category || "Special",
			"severity" = event.get_testing_severity(),
			"blocked" = SSevents.testing_event_block_reason(event),
		))
	return list("events" = events, "status" = last_result)

/obj/machinery/computer/centcom_testing/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(action != "test" || !is_operational || !isliving(usr) || !usr.can_perform_action(src))
		return FALSE
	var/datum/round_event_control/event = SSevents.testing_events[params["id"]]
	if(!event)
		return FALSE
	var/reason = SSevents.testing_event_block_reason(event)
	if(reason)
		last_result = reason
		return TRUE
	var/datum/round_event/trial = SSevents.run_testing_event(params["id"], usr)
	last_result = trial ? "CentCom authorized [event.name]. The trial is underway; normal deployment and participant requirements apply." : "CentCom could not authorize this trial."
	return TRUE

/// Manual tests ignore random-selection population, timing, holiday, and occurrence limits.
/// Event setup and processing still use the normal event APIs and default options.
/datum/controller/subsystem/events/proc/run_testing_event(id, mob/user)
	var/datum/round_event_control/event = testing_events[id]
	if(!event || testing_event_block_reason(event))
		return null
	next_test_time = world.time + 2 SECONDS
	log_game("CentCom Testing Initiative: [key_name(user)] requested [event.name] ([event.type]).")
	return event.run_event(event_cause = "the CentCom Testing Initiative")

/datum/controller/subsystem/events/proc/testing_event_block_reason(datum/round_event_control/event)
	if(!event || !ispath(event.typepath, /datum/round_event))
		return "This trial is unavailable."
	if(!event.valid_for_map())
		return "This trial is incompatible with the current station map."
	if(SSticker.current_state != GAME_STATE_PLAYING)
		return "Trials are available during an active round."
	if(world.time < next_test_time)
		return "The testing uplink is preparing for another trial."
	for(var/datum/round_event/running_event as anything in running)
		if(running_event.type == event.typepath)
			return "This event is already running."
	return null

/datum/round_event_control
	/// Optional override for particularly mild or destructive variants.
	var/testing_severity

/datum/round_event_control/proc/get_testing_severity()
	if(ispath(typepath, /datum/round_event/ghost_role))
		return CENTCOM_TEST_MISC
	if(testing_severity)
		return testing_severity
	switch(category)
		if(EVENT_CATEGORY_FRIENDLY, EVENT_CATEGORY_BUREAUCRATIC, EVENT_CATEGORY_JANITORIAL, EVENT_CATEGORY_HOLIDAY)
			return CENTCOM_TEST_MINOR
		if(EVENT_CATEGORY_ENTITIES, EVENT_CATEGORY_INVASION, EVENT_CATEGORY_SPACE, EVENT_CATEGORY_WIZARD, EVENT_CATEGORY_ANOMALIES)
			return CENTCOM_TEST_MAJOR
	return CENTCOM_TEST_MODERATE

/datum/round_event_control/mice_migration
	testing_severity = CENTCOM_TEST_MINOR
/datum/round_event_control/space_dust
	testing_severity = CENTCOM_TEST_MINOR
/datum/round_event_control/heart_attack
	testing_severity = CENTCOM_TEST_MAJOR
/datum/round_event_control/earthquake
	testing_severity = CENTCOM_TEST_CATASTROPHIC
/datum/round_event_control/meteor_wave/catastrophic
	testing_severity = CENTCOM_TEST_CATASTROPHIC
/datum/round_event_control/scrubber_overflow/catastrophic
	testing_severity = CENTCOM_TEST_CATASTROPHIC
/datum/round_event_control/scrubber_overflow/every_vent
	testing_severity = CENTCOM_TEST_CATASTROPHIC
/datum/round_event_control/portal_storm_syndicate
	testing_severity = CENTCOM_TEST_CATASTROPHIC
/datum/round_event_control/portal_storm_narsie
	testing_severity = CENTCOM_TEST_CATASTROPHIC
/datum/round_event_control/wizard/lava
	testing_severity = CENTCOM_TEST_CATASTROPHIC
/datum/round_event_control/wizard/blobies
	testing_severity = CENTCOM_TEST_CATASTROPHIC

/datum/round_event_control/wizard/imposter
	testing_severity = CENTCOM_TEST_MISC
/datum/round_event_control/wizard/possession
	testing_severity = CENTCOM_TEST_MISC
/datum/round_event_control/wizard/ghost
	testing_severity = CENTCOM_TEST_MISC
