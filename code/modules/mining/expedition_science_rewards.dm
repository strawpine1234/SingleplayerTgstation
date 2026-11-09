/// Science T4 artifacts use the normal gun, implant, storage and shapechange lifecycles.
GLOBAL_LIST_EMPTY(expedition_sequenced_species)

/datum/solo_expedition/proc/get_science_reward_pool()
	return list(
		"science_neurotoxin" = list("name" = "Royal Neurotoxin Synthesizer", "description" = /obj/item/gun/energy/recharge/ebow/science_royal::desc, "type" = /obj/item/gun/energy/recharge/ebow/science_royal),
		"science_sequencer" = list("name" = "Xenobiological Sequencer", "description" = /obj/item/science_sequencer::desc, "type" = /obj/item/science_sequencer),
		"science_symbiote" = list("name" = "Regenerative Symbiote", "description" = /obj/item/implanter/science_symbiote::desc, "type" = /obj/item/implanter/science_symbiote),
		"science_phase" = list("name" = "Phase Displacement Belt", "description" = /obj/item/science_phase_belt::desc, "type" = /obj/item/science_phase_belt),
		"science_backpack" = list("name" = "Infinite Horizon Backpack", "description" = /obj/item/storage/backpack/holding/science_vault::desc, "type" = /obj/item/storage/backpack/holding/science_vault),
		"science_slime" = list("name" = "Hyperenergized Slime Core", "description" = /obj/item/science_slime_core::desc, "type" = /obj/item/science_slime_core),
	)

/obj/item/gun/energy/recharge/ebow/science_royal
	name = "Royal Neurotoxin Synthesizer"
	desc = "A mythical xenobiology dart launcher. Synthesizes one tranquilizer dart every eight seconds, without ammunition or charging. A dart inflicts 70 stamina damage and puts an organic target to sleep for four seconds unless completely blocked. Does not damage tissue; robotic and mineral targets cannot be sedated."
	icon = 'icons/obj/mining_zones/science_mythical.dmi'
	icon_state = "neurotoxin"
	base_icon_state = "neurotoxin"
	no_charge_state = "neurotoxin"
	inhand_icon_state = "crossbow"
	ammo_type = list(/obj/item/ammo_casing/energy/bolt/science_royal)
	recharge_time = 8 SECONDS

/obj/item/ammo_casing/energy/bolt/science_royal
	projectile_type = /obj/projectile/energy/bolt/science_royal
	select_name = "royal tranquilizer"

/obj/projectile/energy/bolt/science_royal
	name = "royal tranquilizer dart"
	damage = 0
	stamina = 70
	eyeblur = 0
	knockdown = 0
	slur = 0

/obj/projectile/energy/bolt/science_royal/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	if(blocked >= 100 || !isliving(target))
		return
	var/mob/living/victim = target
	if(victim.stat != DEAD && (victim.mob_biotypes & MOB_ORGANIC) && !(victim.mob_biotypes & (MOB_ROBOTIC|MOB_MINERAL)))
		victim.Sleeping(4 SECONDS)

/obj/item/science_sequencer
	name = "Xenobiological Sequencer"
	desc = "A mythical biological scanner. Use on an organic creature or corpse for a three-second sequence. Reports health, temperature and basic attack strength. Each previously unsequenced creature type awards 500 station research points, once per round across all sequencers."
	icon = 'icons/obj/mining_zones/science_mythical.dmi'
	icon_state = "sequencer"
	w_class = WEIGHT_CLASS_SMALL
	item_flags = NOBLUDGEON
	var/scanning = FALSE

/obj/item/science_sequencer/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!isliving(interacting_with))
		return NONE
	var/mob/living/target = interacting_with
	if(scanning)
		balloon_alert(user, "sequencer busy!")
		return ITEM_INTERACT_BLOCKING
	if(!(target.mob_biotypes & (MOB_ORGANIC|MOB_SLIME)) || (target.mob_biotypes & (MOB_ROBOTIC|MOB_MINERAL)))
		balloon_alert(user, "no biological sequence!")
		return ITEM_INTERACT_BLOCKING
	. = ITEM_INTERACT_SUCCESS
	scanning = TRUE
	balloon_alert(user, "sequencing...")
	var/success = do_after(user, 3 SECONDS, target = target)
	if(QDELETED(src))
		return
	scanning = FALSE
	if(!success || QDELETED(target) || !user.is_holding(src))
		return
	to_chat(user, span_notice("[target]: health [round(target.health)]/[target.maxHealth], body temperature [round(target.bodytemperature)] K. [target.stat == DEAD ? "Specimen is dead." : "Specimen is alive."]"))
	if(isbasicmob(target))
		var/mob/living/basic/specimen = target
		to_chat(user, span_notice("Observed melee force: [specimen.melee_damage_lower]-[specimen.melee_damage_upper]."))
	if(target.type in GLOB.expedition_sequenced_species)
		to_chat(user, span_notice("This creature type has already been sequenced. No additional research is awarded."))
		return
	var/datum/techweb/science/research = locate(/datum/techweb/science) in SSresearch.techwebs
	if(!research)
		to_chat(user, span_warning("No station research network is available. The sequence has not been submitted; try again later."))
		return
	GLOB.expedition_sequenced_species += target.type
	research.adjust_points(TECHWEB_POINT_TYPE_GENERIC, 500)
	to_chat(user, span_boldnotice("Novel biological sequence uploaded: 500 research points awarded."))

/obj/item/implanter/science_symbiote
	name = "Regenerative Symbiote injector"
	desc = "A mythical single-use implant injector. Use on yourself or another human to implant a regenerative symbiote. While the host is well fed, it repairs 1.5 brute and 1.5 burn damage per second, consuming three nutrition per second of healing. Does not revive, replace limbs or heal starvation."
	icon = 'icons/obj/mining_zones/science_mythical.dmi'
	icon_state = "symbiote"
	imp_type = /obj/item/implant/science_symbiote

/obj/item/implanter/science_symbiote/update_icon_state()
	icon_state = "symbiote"

/obj/item/implanter/science_symbiote/examine(mob/user)
	. = ..()
	. += imp ? "The symbiote is ready for implantation." : "The injector is empty."

/obj/item/implant/science_symbiote
	name = "regenerative symbiote"
	actions_types = null
	implant_info = "Passively repairs brute and burn injuries while the human host is well fed. Consumes nutrition while healing."

/obj/item/implant/science_symbiote/can_be_implanted_in(mob/living/target)
	return ishuman(target)

/obj/item/implant/science_symbiote/implant(mob/living/target, mob/user, silent = FALSE, force = FALSE)
	. = ..()
	if(. && !QDELETED(src) && imp_in)
		START_PROCESSING(SSobj, src)

/obj/item/implant/science_symbiote/removed(mob/living/source, silent = FALSE, special = FALSE)
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/implant/science_symbiote/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/implant/science_symbiote/process(seconds_per_tick)
	var/mob/living/carbon/human/host = imp_in
	if(!istype(host))
		return PROCESS_KILL
	if(host.stat == DEAD || host.nutrition <= NUTRITION_LEVEL_HUNGRY || istype(host.loc, /mob/living/basic/slime/science_form))
		return
	if(host.get_brute_loss() <= 0 && host.get_fire_loss() <= 0)
		return
	host.heal_bodypart_damage(1.5 * seconds_per_tick, 1.5 * seconds_per_tick)
	host.adjust_nutrition(-3 * seconds_per_tick)

/obj/item/science_phase_belt
	name = "Phase Displacement Belt"
	desc = "A mythical wearable phase generator. Equip on your belt and use the Phase Displacement action to pass through obstacles for four seconds, followed by a 2.5-second reentry. Thirty-second cooldown. Restricted areas can block phasing. Reentry uses a clear location along your path or your departure point."
	icon = 'icons/obj/mining_zones/science_mythical.dmi'
	icon_state = "phase_belt"
	worn_icon = 'icons/mob/clothing/belt.dmi'
	worn_icon_state = "utility"
	inhand_icon_state = "utility"
	lefthand_file = 'icons/mob/inhands/equipment/belt_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/belt_righthand.dmi'
	slot_flags = ITEM_SLOT_BELT
	action_slots = ITEM_SLOT_BELT
	actions_types = list(/datum/action/cooldown/spell/jaunt/ethereal_jaunt/science_phase)

/datum/action/cooldown/spell/jaunt/ethereal_jaunt/science_phase
	name = "Phase Displacement"
	desc = "Phase through obstacles for four seconds, then rematerialize safely. Requires the displacement belt."
	button_icon = 'icons/obj/mining_zones/science_mythical.dmi'
	button_icon_state = "phase_belt"
	spell_requirements = NONE
	cooldown_time = 30 SECONDS
	jaunt_duration = 4 SECONDS
	can_be_shared = FALSE
	var/turf/phase_origin

/datum/action/cooldown/spell/jaunt/ethereal_jaunt/science_phase/get_caster_from_target(atom/target)
	return owner

/datum/action/cooldown/spell/jaunt/ethereal_jaunt/science_phase/do_jaunt(mob/living/cast_on)
	phase_origin = get_turf(cast_on)
	return ..()

/// Belt destruction/removal must not strand a wearer in a wall or in the phase holder.
/datum/action/cooldown/spell/jaunt/ethereal_jaunt/science_phase/Remove(mob/living/remove_from)
	var/obj/effect/dummy/phased_mob/spell_jaunt/holder = remove_from.loc
	if(istype(holder))
		var/turf/safe = phase_origin
		for(var/turf/candidate as anything in exit_point_list)
			if(!candidate.is_blocked_turf_ignore_climbable())
				safe = candidate
				break
		if(safe)
			holder.forceMove(safe)
			end_jaunt(remove_from, holder, safe)
	return ..()

/datum/storage/bag_of_holding/science_vault
	max_slots = 1000
	max_total_storage = 10000
	max_specific_storage = WEIGHT_CLASS_GIGANTIC
	screen_max_rows = 5

/obj/item/storage/backpack/holding/science_vault
	name = "Infinite Horizon Backpack"
	desc = "A mythical stabilized bluespace backpack. Holds up to 1,000 items and 10,000 combined weight, including gigantic items. Alt-click to search and retrieve any stored item, including items beyond the normal inventory grid. Normal bag-of-holding nesting hazards still apply."
	icon = 'icons/obj/mining_zones/science_mythical.dmi'
	icon_state = "backpack"
	worn_icon_state = "bag_of_holding"
	storage_type = /datum/storage/bag_of_holding/science_vault

/obj/item/storage/backpack/holding/science_vault/click_alt(mob/living/user)
	if(!can_access_vault(user))
		return CLICK_ACTION_BLOCKING
	var/list/items_by_label = list()
	var/index = 0
	for(var/obj/item/stored in atom_storage.real_location)
		items_by_label["[++index]. [stored.name]"] = stored
	if(!length(items_by_label))
		balloon_alert(user, "backpack empty!")
		return CLICK_ACTION_BLOCKING
	var/choice = tgui_input_list(user, "Search the full contents and select an item to retrieve.", name, items_by_label)
	if(!choice || QDELETED(src))
		return CLICK_ACTION_BLOCKING
	return retrieve_vault_item(user, items_by_label[choice]) ? CLICK_ACTION_SUCCESS : CLICK_ACTION_BLOCKING

/obj/item/storage/backpack/holding/science_vault/proc/can_access_vault(mob/living/user)
	return !QDELETED(user) && atom_storage && atom_storage.locked == STORAGE_NOT_LOCKED \
		&& (loc == user || isturf(loc)) && user.can_perform_action(src, NEED_DEXTERITY|FORBID_TELEKINESIS_REACH)

/// Validate again after the picker returns: the bag or chosen item may have moved.
/obj/item/storage/backpack/holding/science_vault/proc/retrieve_vault_item(mob/living/user, obj/item/chosen)
	if(!can_access_vault(user) || QDELETED(chosen) || chosen.loc != atom_storage.real_location)
		return FALSE
	if(!atom_storage.attempt_remove(chosen, get_turf(user)))
		return FALSE
	user.put_in_hands(chosen)
	return TRUE

/obj/item/science_slime_core
	name = "Hyperenergized Slime Core"
	desc = "A mythical living core. Activate in your hand to absorb it and permanently gain Slime Metamorphosis: transform into a slime and back at will, without charges. Uses the same action in either form, with a one-second transition cooldown. Damage carries between forms; death in slime form is fatal. Your original body and equipment return when you revert."
	icon = 'icons/obj/mining_zones/science_mythical.dmi'
	icon_state = "slime_core"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/science_slime_core/attack_self(mob/living/user, list/modifiers)
	if(!ishuman(user) || user.incapacitated)
		return
	if(locate(/datum/action/cooldown/spell/shapeshift/science_slime) in user.actions)
		balloon_alert(user, "already absorbed!")
		return
	var/datum/action/cooldown/spell/shapeshift/science_slime/metamorphosis = new(user)
	metamorphosis.Grant(user)
	to_chat(user, span_boldnotice("You absorb the hyperenergized core. Use Slime Metamorphosis to transform and to return to your original body."))
	qdel(src)

/datum/action/cooldown/spell/shapeshift/science_slime
	name = "Slime Metamorphosis"
	desc = "Transform into a slime or return to your original body. Damage is shared between forms."
	button_icon = 'icons/obj/mining_zones/science_mythical.dmi'
	button_icon_state = "slime_core"
	spell_requirements = NONE
	invocation_type = INVOCATION_NONE
	cooldown_time = 1 SECONDS
	possible_shapes = list(/mob/living/basic/slime/science_form)
	can_be_shared = FALSE

/// A controlled form, not an infinite source of offspring or extract cores.
/mob/living/basic/slime/science_form
	name = "hyperenergized slime"
	hunger_disabled = TRUE
	cores = 0
	color = "#B1CFFF"

/mob/living/basic/slime/science_form/Initialize(mapload, new_type, new_life_stage)
	. = ..(mapload)
	QDEL_NULL(ai_controller)
	QDEL_NULL(evolve_action)
	QDEL_NULL(reproduce_action)
