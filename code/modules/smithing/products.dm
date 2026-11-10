/obj/item/katana/forged
	desc = "A station-forged katana with a folded edge and a wrapped grip."
	force = 24
	block_chance = 30

/obj/item/claymore/forged
	desc = "A long, heavy blade with a broad crossguard, forged for powerful swings."
	force = 27
	block_chance = 25
	w_class = WEIGHT_CLASS_BULKY

/obj/item/claymore/forged_broadsword
	name = "broadsword"
	desc = "A broad, straight blade with a stout guard and a balanced grip."
	icon_state = "claymore_old"
	force = 25
	block_chance = 35

/obj/item/claymore/shortsword/forged
	desc = "A compact forged blade for close work and tight passages."

/obj/item/knife/combat/forged_dagger
	name = "dagger"
	desc = "A narrow, double-edged dagger with a simple forged guard."
	force = 15

/obj/item/shield/roman/forged
	name = "forged shield"
	desc = "A hand-forged metal shield with a rolled rim and a reinforced grip."
	max_integrity = 100
	block_chance = 35

/obj/item/clothing/suit/armor/vest/cuirass/forged
	name = "forged chestplate"
	desc = "Shaped and quenched metal plates fitted to protect the torso."

/obj/item/clothing/head/helmet/knight/forged
	name = "forged helmet"
	desc = "A closed steel helmet with a narrow eye slit and a padded liner."

/obj/item/carpenter_hammer/forged_warhammer
	name = "warhammer"
	desc = "A heavy forged striking head on a reinforced haft."
	icon_state = "hammeron"
	inhand_icon_state = "hammeron"
	worn_icon_state = "hammeron"
	force = 28
	w_class = WEIGHT_CLASS_BULKY

/obj/item/seed_sieve
	name = "seed sieve"
	desc = "A fine forged mesh that separates seeds from harvested produce. Use it on produce in your other hand or on a nearby surface."
	icon = 'icons/obj/food/containers.dmi'
	icon_state = "tray"
	w_class = WEIGHT_CLASS_SMALL
	/// Seeds produced per item of viable produce.
	var/seed_count = 2

/obj/item/seed_sieve/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if((!istype(interacting_with, /obj/item/food/grown) && !istype(interacting_with, /obj/item/grown)) || SHOULD_SKIP_INTERACTION(interacting_with, src, user))
		return NONE
	var/obj/item/produce = interacting_with
	if(!produce.get_plant_seed())
		user.balloon_alert(user, "no viable seeds!")
		return ITEM_INTERACT_BLOCKING
	if(produce.loc == user)
		if(!user.temporarilyRemoveItemFromInventory(produce, newloc = drop_location()))
			return ITEM_INTERACT_BLOCKING
	else if(!isturf(produce.loc))
		return ITEM_INTERACT_BLOCKING
	// seedify copies the plant's actual seed, including its genes. Its count is inclusive.
	if(!length(seedify(produce, seed_count - 1, null, null)))
		return ITEM_INTERACT_BLOCKING
	user.balloon_alert(user, "seeds sifted")
	return ITEM_INTERACT_SUCCESS

/obj/item/smithing_blank/proc/finish_item(obj/item/finished)
	if(!masterwork)
		return
	finished.name = "masterwork [finished.name]"
	if(istype(finished, /obj/item/seed_sieve))
		var/obj/item/seed_sieve/sieve = finished
		sieve.seed_count = 3
	else if(istype(finished, /obj/item/clothing))
		finished.set_armor(finished.get_armor().generate_new_with_modifiers(list(MELEE = 8)))
	else if(istype(finished, /obj/item/shield))
		finished.block_chance += 8
	else
		finished.force += 4

/// A finite bath infusion. Weapons deliver a dose on an unblocked strike.
/// Armor slowly delivers its reagent while worn in the proper slot.
/datum/component/smithing_infusion
	var/armor_slot
	var/next_dose = 0

/datum/component/smithing_infusion/Initialize(armor_slot = NONE)
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE
	src.armor_slot = armor_slot
	RegisterSignal(parent, COMSIG_ATOM_EXAMINE, PROC_REF(show_infusion))
	if(armor_slot)
		START_PROCESSING(SSobj, src)
	else
		RegisterSignal(parent, COMSIG_ITEM_ATTACK_ZONE, PROC_REF(on_strike))

/datum/component/smithing_infusion/Destroy(force)
	STOP_PROCESSING(SSobj, src)
	return ..()

/datum/component/smithing_infusion/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_ATOM_EXAMINE, COMSIG_ITEM_ATTACK_ZONE))
	return ..()

/datum/component/smithing_infusion/proc/show_infusion(obj/item/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	if(source.reagents.total_volume <= 0)
		examine_list += span_notice("Its reagent infusion is spent.")
		return
	var/datum/reagent/infusion = source.reagents.get_master_reagent()
	examine_list += span_notice("Infused with [infusion.name] ([round(source.reagents.total_volume, 0.1)] units left).")

/datum/component/smithing_infusion/proc/on_strike(obj/item/source, mob/living/target, mob/living/user)
	SIGNAL_HANDLER
	if(iscarbon(target) && target.stat != DEAD)
		source.reagents.trans_to(target, 1, methods = INJECT, transferred_by = user)

/datum/component/smithing_infusion/process(seconds_per_tick)
	var/obj/item/armor = parent
	if(armor.reagents.total_volume <= 0)
		return PROCESS_KILL
	var/mob/living/carbon/wearer = armor.loc
	if(!istype(wearer) || wearer.stat == DEAD || wearer.get_item_by_slot(armor_slot) != armor || world.time < next_dose)
		return
	next_dose = world.time + 3 SECONDS
	armor.reagents.trans_to(wearer, 0.5, methods = INJECT, show_message = FALSE)
