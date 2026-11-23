/// One-use genetic insurance. The stored mind, never a new player identity, receives the replacement body.
/obj/machinery/second_chance
	name = "Second Chance reconstruction pod"
	desc = "A genetic insurance printer. Swipe your personal ID, sample your DNA, and register for one automatic reconstruction."
	icon = 'icons/obj/machines/second_chance.dmi'
	icon_state = "idle"
	density = TRUE
	circuit = /obj/item/circuitboard/machine/second_chance
	idle_power_usage = 100
	active_power_usage = 1500
	var/datum/experimental_cloning_record/profile
	var/datum/mind/insured_mind
	var/datum/bank_account/account
	var/datum/weakref/enrolling_user
	var/list/saved_access
	var/saved_assignment
	var/registered = FALSE
	var/death_pending = FALSE
	var/printing = FALSE
	var/paid = FALSE
	var/finish_at = 0
	var/status = "Swipe your personal ID to begin enrollment."

/obj/machinery/second_chance/Destroy()
	refund()
	QDEL_NULL(profile)
	insured_mind = null
	account = null
	return ..()

/obj/machinery/second_chance/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(!istype(tool, /obj/item/card/id/advanced))
		return ..()
	var/obj/item/card/id/advanced/card = tool
	if(registered || printing || !ishuman(user) || !user.mind || !is_operational || panel_open)
		balloon_alert(user, "enrollment unavailable")
		return ITEM_INTERACT_BLOCKING
	if(card != user.get_idcard(TRUE) || !card.registered_account || IS_DEPARTMENTAL_CARD(card) || card.registered_name != user.real_name)
		balloon_alert(user, "use your personal ID")
		return ITEM_INTERACT_BLOCKING
	QDEL_NULL(profile)
	enrolling_user = WEAKREF(user)
	insured_mind = user.mind
	account = card.registered_account
	saved_access = card.GetAccess().Copy()
	saved_assignment = card.assignment
	status = "ID accepted. Use the interface to sample your DNA."
	playsound(src, 'sound/machines/second_chance_scan.wav', 40, FALSE)
	ui_interact(user)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/second_chance/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SecondChance", name)
		ui.open()

/obj/machinery/second_chance/ui_data(mob/user)
	return list("status" = status, "name" = profile?.name, "registered" = registered, "sampled" = !!profile, "printing" = printing, "remaining" = max(0, finish_at - world.time) / 10, "owner" = enrolling_user?.resolve() == user, "operational" = is_operational && !panel_open)

/obj/machinery/second_chance/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/living/carbon/human/user = ui.user
	if(!ishuman(user) || user != enrolling_user?.resolve() || user.stat != STABLE || IS_UNCONSCIOUS(user) || !user.can_perform_action(src) || !is_operational || panel_open || registered)
		return FALSE
	switch(action)
		if("sample")
			if(!user.dna || !user.mind || user.mind != insured_mind)
				return FALSE
			QDEL_NULL(profile)
			profile = new
			profile.create_profile(user)
			status = "DNA sample verified. Confirm enrollment to arm one reconstruction."
			playsound(src, 'sound/machines/second_chance_scan.wav', 40, FALSE)
			return TRUE
		if("register")
			return enroll(user)
	return FALSE

/obj/machinery/second_chance/proc/enroll(mob/living/carbon/human/user)
	if(!profile || insured_mind != user.mind || QDELETED(account) || registered || user.stat == DEAD)
		return FALSE
	registered = TRUE
	RegisterSignal(user, COMSIG_LIVING_DEATH, PROC_REF(on_insured_death))
	status = "Enrollment armed for [profile.name]. One reconstruction costs 50 credits, charged on activation."
	begin_processing()
	update_appearance()
	return TRUE

/obj/machinery/second_chance/proc/on_insured_death(mob/living/source, gibbed)
	SIGNAL_HANDLER
	death_pending = TRUE
	UnregisterSignal(source, COMSIG_LIVING_DEATH)
	addtimer(CALLBACK(src, PROC_REF(check_reconstruction)), 1)

/obj/machinery/second_chance/proc/refund()
	if(paid)
		account?.adjust_money(50, "Second Chance interrupted reconstruction refund")
	paid = FALSE
	printing = FALSE
	finish_at = 0

/obj/machinery/second_chance/process(seconds_per_tick)
	if(!registered || !death_pending)
		return
	if(insured_mind?.current && insured_mind.current.stat != DEAD)
		refund()
		registered = FALSE
		death_pending = FALSE
		status = "Reconstruction cancelled: the registered mind is already alive. Swipe an ID to enroll again."
		update_appearance()
		return
	if(!is_operational || panel_open || machine_stat & BROKEN)
		if(printing)
			refund()
			status = "Reconstruction interrupted. Payment refunded; awaiting power and a closed hatch."
			update_appearance()
		return
	if(!printing)
		if(QDELETED(insured_mind) || QDELETED(account) || !account.adjust_money(-50, "Second Chance reconstruction"))
			status = "Awaiting a valid registered mind and 50 credits in the linked account."
			return
		paid = TRUE
		printing = TRUE
		finish_at = world.time + 5 SECONDS
		status = "Reconstructing registered subject."
		playsound(src, 'sound/machines/second_chance_print.wav', 55, FALSE)
		addtimer(CALLBACK(src, PROC_REF(finish_print)), 5 SECONDS)
		update_appearance()

/obj/machinery/second_chance/proc/finish_print()
	if(!printing || world.time < finish_at)
		return
	if(!is_operational || panel_open || machine_stat & BROKEN || QDELETED(insured_mind) || (insured_mind.current && insured_mind.current.stat != DEAD))
		refund()
		update_appearance()
		return
	var/turf/destination
	for(var/turf/open/floor/candidate in orange(1, src))
		if(!candidate.is_blocked_turf())
			destination = candidate
			break
	if(!destination)
		refund()
		status = "Clear a floor tile next to the pod. Payment refunded."
		update_appearance()
		return
	var/mob/living/carbon/human/body = new(destination)
	profile.apply_profile(body)
	body.set_mob_height(profile.height)
	insured_mind.transfer_to(body, TRUE)
	body.equip_to_slot_or_del(new /obj/item/clothing/under/color/grey(body), ITEM_SLOT_ICLOTHING)
	var/obj/item/card/id/advanced/card = new(body)
	card.registered_name = profile.name
	card.assignment = saved_assignment
	card.access = saved_access.Copy()
	card.set_account(account)
	card.update_label()
	body.equip_to_slot_or_del(card, ITEM_SLOT_ID)
	paid = FALSE
	printing = FALSE
	registered = FALSE
	death_pending = FALSE
	finish_at = 0
	status = "Reconstruction complete. Swipe your ID to enroll for another second chance."
	playsound(src, 'sound/machines/second_chance_complete.wav', 50, FALSE)
	log_game("Second Chance reconstructed [key_name(body)] for 50 credits at [AREACOORD(src)].")
	update_appearance()

/obj/machinery/second_chance/update_icon_state()
	icon_state = printing ? "printing" : (is_operational ? (registered ? "armed" : "idle") : "off")
	return ..()

/obj/machinery/second_chance/screwdriver_act(mob/living/user, obj/item/tool)
	if(printing)
		return ITEM_INTERACT_BLOCKING
	return default_deconstruction_screwdriver(user, tool)

/obj/machinery/second_chance/crowbar_act(mob/living/user, obj/item/tool)
	if(registered)
		balloon_alert(user, "registration armed")
		return ITEM_INTERACT_BLOCKING
	return default_deconstruction_crowbar(user, tool)

/obj/machinery/second_chance/power_change()
	. = ..()
	if(printing && !is_operational)
		refund()
		status = "Power interrupted. Payment refunded; reconstruction will retry when power returns."
		update_appearance()

/obj/machinery/second_chance/proc/check_reconstruction()
	process()
