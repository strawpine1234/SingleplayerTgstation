// Autonomous surgical capsule for singleplayer use.
// Accepts a bodypart, organ, implant case, or filled implanter.
// Performs a replacement/installation after ten seconds.
/obj/machinery/sleeper/autodoc
	name = "autodoc"
	desc = "An automated surgical capsule. Insert an organ, replacement limb, or loaded implant case/implanter, then enter and activate the ten-second procedure."
	icon = 'icons/obj/machines/sleeper.dmi'
	icon_state = "sleeper"
	base_icon_state = "sleeper"
	controls_inside = TRUE
	deconstructable = TRUE
	/// The item stored for the next procedure.
	var/obj/item/surgical_payload
	/// True between starting and finishing the ten-second procedure.
	var/operating = FALSE
	var/procedure_duration = 10 SECONDS
	var/status_text = "Ready for a surgical payload."

/obj/machinery/sleeper/autodoc/Initialize(mapload)
	. = ..()
	occupant_typecache = typecacheof(/mob/living/carbon/human)

/obj/machinery/sleeper/autodoc/Destroy()
	surgical_payload = null // The parent handles inventory disposal.
	return ..()

/obj/machinery/sleeper/autodoc/examine(mob/user)
	. = ..()
	. += span_notice("Use a limb, organ, filled implanter, or implant case on [src] to load it.")
	. += span_notice("Click the chamber to manage the payload, enter it, or begin the ten-second procedure.")

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
	data["duration"] = procedure_duration / (1 SECONDS)
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
	return FALSE

/obj/machinery/sleeper/autodoc/proc/begin_surgery()
	if(operating || state_open || !ishuman(occupant) || !surgical_payload || !is_operational)
		return FALSE
	var/mob/living/carbon/human/patient = occupant
	if(!can_operate(patient))
		status_text = "Cannot operate: payload incompatible with patient."
		to_chat(patient, span_warning("[src] cannot use the loaded item on your anatomy."))
		return FALSE
	operating = TRUE
	status_text = "Surgery in progress (10 seconds)."
	visible_message(span_notice("[src] seals its surgical instruments around [patient]."))
	addtimer(CALLBACK(src, PROC_REF(finish_procedure), patient, surgical_payload), procedure_duration)
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

/obj/machinery/sleeper/autodoc/proc/finish_procedure(mob/living/carbon/human/patient, obj/item/loaded_item)
	if(QDELETED(src))
		return
	operating = FALSE
	if(occupant != patient || !patient || surgical_payload != loaded_item || !is_operational || !can_operate(patient))
		status_text = "Procedure cancelled: patient, payload, or power unavailable."
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
