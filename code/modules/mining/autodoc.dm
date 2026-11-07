// Autonomous surgical capsule for singleplayer use.
// Accepts a bodypart, organ, implant case, or filled implanter.
// Servo upgrades speed up replacement, installation, and implant removal.
/obj/machinery/sleeper/autodoc
	name = "autodoc"
	desc = "An automated surgical capsule. Insert an organ, replacement limb, or loaded implant case/implanter, then enter and activate the procedure. Upgraded servos speed up surgery."
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	base_icon_state = "sleeper"
	controls_inside = TRUE
	deconstructable = TRUE
	circuit = /obj/item/circuitboard/machine/sleeper/autodoc
	/// The item stored for the next procedure.
	var/obj/item/surgical_payload
	/// True between starting and finishing a procedure.
	var/operating = FALSE
	/// Procedure time at the current servo tier; ten seconds with basic parts.
	var/procedure_duration = 10 SECONDS
	var/status_text = "Ready for a surgical payload."
	/// Sound played only while a procedure is active.
	var/datum/looping_sound/autodoc/operating_sound
	/// Stoppable completion timer, cancelled on interruption.
	var/procedure_timer

/obj/machinery/sleeper/autodoc/Initialize(mapload)
	. = ..()
	occupant_typecache = typecacheof(/mob/living/carbon/human)
	operating_sound = new(src)

/obj/machinery/sleeper/autodoc/Destroy()
	stop_procedure()
	QDEL_NULL(operating_sound)
	surgical_payload = null // The parent handles inventory disposal.
	return ..()

/obj/machinery/sleeper/autodoc/examine(mob/user)
	. = ..()
	. += span_notice("Use a limb, organ, filled implanter, or implant case on [src] to load it.")
	. += span_notice("Click the chamber to manage the payload, enter it, or begin a procedure.")
	. += span_notice("Current procedure time: [round(procedure_duration / (1 SECONDS), 0.1)] seconds. Upgrade the servo to operate faster.")
	. += span_notice("Close the empty chamber, then use a screwdriver to open its maintenance hatch. Use a part replacer to upgrade it or a crowbar to disassemble it.")

/// Recalculate speed from installed parts, including after construction or RPED upgrades.
/obj/machinery/sleeper/autodoc/RefreshParts()
	. = ..()
	var/servo_rating = 1
	for(var/datum/stock_part/servo/servo in component_parts)
		servo_rating = max(servo_rating, servo.tier)
	procedure_duration = initial(procedure_duration) / servo_rating

/obj/machinery/sleeper/autodoc/exchange_parts(mob/user, obj/item/storage/part_replacer/replacer_tool)
	if(operating)
		to_chat(user, span_warning("Wait for [src] to finish operating before replacing its parts."))
		return FALSE
	return ..()

/obj/machinery/sleeper/autodoc/can_crowbar_deconstruct()
	return !operating && !occupant && ..()

/obj/machinery/sleeper/autodoc/proc/get_implant()
	if(istype(surgical_payload, /obj/item/implanter))
		var/obj/item/implanter/injector = surgical_payload
		return injector.imp
	if(istype(surgical_payload, /obj/item/implantcase))
		var/obj/item/implantcase/case = surgical_payload
		return case.imp
	if(istype(surgical_payload, /obj/item/implant))
		return surgical_payload
	return null

/obj/machinery/sleeper/autodoc/proc/is_supported_payload(obj/item/tool)
	if(istype(tool, /obj/item/bodypart))
		return TRUE
	if(istype(tool, /obj/item/organ))
		return TRUE
	if(istype(tool, /obj/item/implanter))
		var/obj/item/implanter/injector = tool
		return !!injector.imp
	if(istype(tool, /obj/item/implantcase))
		var/obj/item/implantcase/case = tool
		return !!case.imp
	if(istype(tool, /obj/item/implant))
		return TRUE
	return FALSE

/obj/machinery/sleeper/autodoc/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(!is_supported_payload(tool))
		return ..()
	if(operating || surgical_payload)
		to_chat(user, span_warning("[src] already has a surgical payload or is in use."))
		return ITEM_INTERACT_BLOCKING
	if(!user.transferItemToLoc(tool, src))
		to_chat(user, span_warning("You cannot release [tool]."))
		return ITEM_INTERACT_BLOCKING
	surgical_payload = tool
	status_text = "Loaded: [tool.name]."
	to_chat(user, span_notice("You load [tool] into [src]."))
	return ITEM_INTERACT_SUCCESS

/obj/machinery/sleeper/autodoc/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/sleeper/autodoc/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Autodoc", name)
		ui.open()

/obj/machinery/sleeper/autodoc/ui_data()
	var/list/data = list()
	data["patient"] = occupant ? occupant.name : null
	data["payload"] = surgical_payload ? surgical_payload.name : null
	data["operating"] = operating
	data["open"] = state_open
	data["status"] = status_text
	data["duration"] = round(procedure_duration / (1 SECONDS), 0.1)
	data["healing_duration"] = round(get_procedure_duration(heal_damage = TRUE) / (1 SECONDS), 0.1)
	return data

/obj/machinery/sleeper/autodoc/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("enter")
			if(operating || occupant || !state_open || !ishuman(usr) || !Adjacent(usr))
				return FALSE
			close_machine(usr)
			if(occupant == usr && surgical_payload)
				begin_surgery()
			return TRUE
		if("exit")
			if(operating || !occupant)
				return FALSE
			open_machine()
			return TRUE
		if("eject")
			if(operating || !surgical_payload)
				return FALSE
			surgical_payload.forceMove(drop_location())
			surgical_payload = null
			status_text = "Payload ejected."
			return TRUE
		if("start")
			return begin_surgery()
		if("remove_implants")
			return begin_surgery(remove_implants = TRUE)
		if("heal_damage")
			return begin_surgery(heal_damage = TRUE)
	return FALSE

/// Healing takes twice the servo-adjusted duration of an installation or removal.
/obj/machinery/sleeper/autodoc/proc/get_procedure_duration(heal_damage = FALSE)
	return procedure_duration * (heal_damage ? 2 : 1)

/// Start a timed installation, implant removal, or full damage treatment.
/obj/machinery/sleeper/autodoc/proc/begin_surgery(remove_implants = FALSE, heal_damage = FALSE)
	if(operating || state_open || panel_open || !ishuman(occupant) || !is_operational)
		return FALSE
	if(remove_implants && heal_damage)
		return FALSE
	var/mob/living/carbon/human/patient = occupant
	if(remove_implants && !length(patient.implants))
		status_text = "No implants to remove."
		return FALSE
	if(!remove_implants && !heal_damage && !can_operate(patient))
		status_text = "Cannot operate: payload incompatible with patient."
		to_chat(patient, span_warning("[src] cannot use the loaded item on your anatomy."))
		return FALSE
	operating = TRUE
	operating_sound.start()
	var/duration = get_procedure_duration(heal_damage)
	status_text = "[heal_damage ? "Healing" : "Surgery"] in progress ([round(duration / (1 SECONDS), 0.1)] seconds)."
	visible_message(span_notice("[src] seals its surgical instruments around [patient]."))
	procedure_timer = addtimer(CALLBACK(src, PROC_REF(finish_procedure), patient, surgical_payload, remove_implants, heal_damage), duration, TIMER_STOPPABLE)
	return TRUE

/obj/machinery/sleeper/autodoc/proc/can_operate(mob/living/carbon/human/patient)
	if(!patient || !surgical_payload || QDELETED(surgical_payload))
		return FALSE
	if(istype(surgical_payload, /obj/item/bodypart))
		var/obj/item/bodypart/limb = surgical_payload
		return limb.body_zone && limb.can_attach_limb(patient)
	if(istype(surgical_payload, /obj/item/organ))
		var/obj/item/organ/organ = surgical_payload
		return organ.slot && organ.useable && !(organ.organ_flags & ORGAN_UNUSABLE) && !!patient.get_bodypart(deprecise_zone(organ.zone))
	var/obj/item/implant/implant = get_implant()
	return implant && implant.can_be_implanted_in(patient)

/// Complete a procedure after rechecking the patient, power, and payload.
/obj/machinery/sleeper/autodoc/proc/finish_procedure(mob/living/carbon/human/patient, obj/item/loaded_item, remove_implants = FALSE, heal_damage = FALSE)
	if(QDELETED(src))
		return
	procedure_timer = null
	stop_procedure()
	if(occupant != patient || QDELETED(patient) || state_open || !is_operational || (!remove_implants && !heal_damage && (surgical_payload != loaded_item || !can_operate(patient))))
		status_text = "Procedure cancelled: patient, payload, or power unavailable."
		return

	if(heal_damage)
		// Heal in place so installed prosthetics, organs, and implants are preserved.
		for(var/obj/item/organ/organ as anything in patient.organs)
			organ.set_organ_damage(0)
		patient.set_heartattack(FALSE)
		patient.fully_heal(HEAL_DAMAGE | HEAL_WOUNDS | HEAL_BLOOD)
		status_text = "Healing complete: internal and external damage repaired."
		visible_message(span_notice("[src] chimes as the treatment finishes successfully."))
		return

	if(remove_implants)
		var/removed_count = 0
		// Removal mutates the implant list and may delete the implant itself.
		var/list/implants = patient.implants?.Copy()
		for(var/obj/item/implant/implant as anything in implants)
			if(QDELETED(patient) || occupant != patient || !is_operational)
				break
			if(QDELETED(implant) || implant.imp_in != patient)
				continue
			implant.removed(patient)
			if(!QDELETED(implant) && implant.imp_in == patient)
				continue
			removed_count++
			if(QDELETED(implant))
				continue
			var/obj/item/implantcase/case = new(drop_location())
			case.imp = implant
			implant.forceMove(case)
			case.update_appearance()
		status_text = "Implant removal complete: [removed_count] removed."
		return

	var/success = FALSE
	if(istype(loaded_item, /obj/item/bodypart))
		var/obj/item/bodypart/new_limb = loaded_item
		success = new_limb.replace_limb(patient)
	else if(istype(loaded_item, /obj/item/organ))
		var/obj/item/organ/new_organ = loaded_item
		success = new_organ.Insert(patient)
	else
		var/obj/item/implant/implant = get_implant()
		if(implant)
			success = implant.implant(patient, patient)
			if(success && istype(loaded_item, /obj/item/implanter))
				var/obj/item/implanter/injector = loaded_item
				injector.imp = null
				injector.update_appearance()
			else if(success && istype(loaded_item, /obj/item/implantcase))
				var/obj/item/implantcase/case = loaded_item
				case.imp = null
				case.update_appearance()

	if(success)
		status_text = "Surgery complete: [loaded_item.name]."
		visible_message(span_notice("[src] chimes as the surgery finishes successfully."))
		if(istype(loaded_item, /obj/item/bodypart) || istype(loaded_item, /obj/item/organ) || istype(loaded_item, /obj/item/implant))
			surgical_payload = null // These items are now owned by the patient.
	else
		status_text = "Surgery failed: implant or replacement was rejected."
		to_chat(patient, span_warning("[src] cannot complete the requested surgery."))

/obj/machinery/sleeper/autodoc/container_resist_act(mob/living/user)
	if(operating)
		to_chat(user, span_warning("The autodoc is operating. The chamber is temporarily locked."))
		return
	return ..()

/obj/machinery/sleeper/autodoc/relaymove(mob/living/user, direction)
	if(operating)
		return
	return ..()

/obj/machinery/sleeper/autodoc/open_machine(drop = TRUE, density_to_set = FALSE)
	if(operating)
		return
	return ..()

/obj/machinery/sleeper/autodoc/click_alt(mob/user)
	if(operating)
		return CLICK_ACTION_BLOCKING
	return ..()

/// Stop operation and audio, preventing a cancelled timer from completing a later surgery.
/obj/machinery/sleeper/autodoc/proc/stop_procedure()
	if(procedure_timer)
		deltimer(procedure_timer)
		procedure_timer = null
	operating = FALSE
	operating_sound?.stop()

/obj/machinery/sleeper/autodoc/on_set_is_operational(old_value)
	. = ..()
	if(operating && !is_operational)
		stop_procedure()
		status_text = "Procedure interrupted: power or machine unavailable."

/obj/machinery/sleeper/autodoc/set_occupant(atom/movable/new_occupant)
	if(operating && new_occupant != occupant)
		stop_procedure()
		status_text = "Procedure interrupted: patient unavailable."
	return ..()

/// The reagent grinder's sound, using a token so stopping cuts off playback for all listeners.
/datum/looping_sound/autodoc
	mid_sounds = 'sound/machines/blender.ogg'
	mid_length = 2 SECONDS
	volume = 50
	use_sound_tokens = TRUE
