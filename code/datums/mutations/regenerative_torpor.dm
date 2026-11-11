/datum/mutation/regenerative_torpor
	name = "Regenerative Torpor"
	desc = "The subject can enter a deep, vulnerable torpor to repair organic tissue and organs. Requires food and a safe place to rest; cannot replace missing limbs or organs."
	quality = POSITIVE
	instability = POSITIVE_INSTABILITY_MAJOR
	difficulty = 16
	text_gain_indication = span_notice("You feel able to retreat into a deeply restorative sleep.")
	text_lose_indication = span_notice("Your restorative instinct fades.")
	power_path = /datum/action/cooldown/regenerative_torpor
	energy_coeff = 1

/datum/mutation/regenerative_torpor/on_losing(mob/living/carbon/human/owner)
	. = ..()
	if(!.)
		owner.remove_status_effect(/datum/status_effect/regenerative_torpor)

/datum/action/cooldown/regenerative_torpor
	name = "Regenerative Torpor"
	desc = "Sleep helplessly for two minutes while repairing organic tissue and organs. Consumes nutrition and ends early if you become starving. Does not protect you from attacks or environmental hazards."
	button_icon = 'icons/mob/actions/actions_changeling.dmi'
	button_icon_state = "fleshmend"
	check_flags = AB_CHECK_CONSCIOUS | AB_CHECK_INCAPACITATED
	cooldown_time = 5 MINUTES

/datum/action/cooldown/regenerative_torpor/Activate(atom/target)
	if(!ishuman(owner))
		return FALSE
	var/mob/living/carbon/human/sleeper = owner
	if(sleeper.nutrition < NUTRITION_LEVEL_HUNGRY)
		to_chat(sleeper, span_warning("You need to eat before entering regenerative torpor."))
		return FALSE
	if(!sleeper.apply_status_effect(/datum/status_effect/regenerative_torpor))
		return FALSE
	StartCooldown()
	return TRUE

/datum/status_effect/regenerative_torpor
	id = "regenerative_torpor"
	duration = 2 MINUTES
	tick_interval = 1 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/regenerative_torpor
	show_duration = TRUE
	remove_on_fullheal = TRUE
	/// Organic wounds close one at a time, rather than disappearing on activation.
	var/wound_recovery = 0

/datum/status_effect/regenerative_torpor/on_apply()
	if(!ishuman(owner) || owner.stat == DEAD)
		return FALSE
	owner.visible_message(span_notice("[owner] settles into a deep, motionless sleep."), span_notice("You surrender to regenerative torpor. You will be helpless until it ends."))
	ADD_TRAIT(owner, TRAIT_KNOCKEDOUT, TRAIT_STATUS_EFFECT(id))
	return TRUE

/datum/status_effect/regenerative_torpor/tick(seconds_between_ticks)
	var/mob/living/carbon/human/sleeper = owner
	if(sleeper.stat == DEAD || sleeper.nutrition <= NUTRITION_LEVEL_STARVING)
		qdel(src)
		return
	sleeper.adjust_nutrition(-0.5 * seconds_between_ticks)
	sleeper.heal_overall_damage(brute = 2 * seconds_between_ticks, burn = 2 * seconds_between_ticks, required_bodytype = BODYTYPE_ORGANIC)
	sleeper.adjust_tox_loss(-seconds_between_ticks)
	sleeper.adjust_oxy_loss(-seconds_between_ticks)
	for(var/obj/item/organ/organ as anything in sleeper.organs)
		if(organ.organ_flags & ORGAN_ORGANIC)
			organ.apply_organ_damage(-0.5 * seconds_between_ticks)

	wound_recovery += seconds_between_ticks
	if(wound_recovery >= 30)
		wound_recovery = 0
		for(var/datum/wound/wound as anything in sleeper.all_wounds)
			if(wound.limb.bodytype & BODYTYPE_ORGANIC)
				wound.remove_wound()
				break

/datum/status_effect/regenerative_torpor/on_remove()
	REMOVE_TRAIT(owner, TRAIT_KNOCKEDOUT, TRAIT_STATUS_EFFECT(id))
	if(owner.stat != DEAD)
		to_chat(owner, span_notice("Your regenerative torpor ends."))

/atom/movable/screen/alert/status_effect/regenerative_torpor
	name = "Regenerative Torpor"
	desc = "Your body is repairing itself while you lie helpless. Stay fed and out of danger."
	icon_state = "fleshmend"
