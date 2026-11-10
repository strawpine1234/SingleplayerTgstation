// Adapted from Nova Sector's AGPL-3.0 reagent_forging module. See the Blacksmith guide for provenance.
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
	if(!length(seedify(produce, 1, null, null)))
		return ITEM_INTERACT_BLOCKING
	user.balloon_alert(user, "seeds sifted")
	return ITEM_INTERACT_SUCCESS

// Nova assembles quenched blades with wood and armor from quenched plates.
// Claymores, broadswords, and shortswords keep their local item types.
GLOBAL_LIST_INIT(smithing_assembly_patterns, list(
	"Katana" = list("parts" = list("Katana blade" = 1), "wood" = 2, "strikes" = 6, "output" = /obj/item/katana/forged),
	"Claymore" = list("parts" = list("Claymore blade" = 1), "wood" = 2, "strikes" = 6, "output" = /obj/item/claymore/forged),
	"Broadsword" = list("parts" = list("Broadsword blade" = 1), "wood" = 2, "strikes" = 6, "output" = /obj/item/claymore/forged_broadsword),
	"Dagger" = list("parts" = list("Dagger blade" = 1), "wood" = 2, "strikes" = 6, "output" = /obj/item/knife/combat/forged_dagger),
	"Shortsword" = list("parts" = list("Shortsword blade" = 1), "wood" = 2, "strikes" = 6, "output" = /obj/item/claymore/shortsword/forged),
	"Warhammer" = list("parts" = list("Warhammer head" = 1), "wood" = 2, "strikes" = 6, "output" = /obj/item/carpenter_hammer/forged_warhammer),
	"Shield" = list("parts" = list("Plate" = 5), "strikes" = 10, "output" = /obj/item/shield/roman/forged),
	"Chestplate" = list("parts" = list("Plate" = 6), "strikes" = 12, "output" = /obj/item/clothing/suit/armor/vest/cuirass/forged),
	"Helmet" = list("parts" = list("Plate" = 4), "strikes" = 8, "output" = /obj/item/clothing/head/helmet/knight/forged),
	"Seed Sieve" = list("parts" = list("Plate" = 1, "Chain" = 2), "strikes" = 10, "output" = /obj/item/seed_sieve),
))

/obj/structure/smithing_station/bench
	name = "smithing workbench"
	desc = "Load quenched parts and wood. Use a forging hammer to assemble a pattern. Click the bench to collect the result or right-click to unload parts."
	icon_state = "crafting_bench_empty"
	frame_type = /obj/item/smithing_frame/bench
	var/selected_pattern
	var/assembly_strikes = 0
	var/obj/item/assembled_item

/obj/structure/smithing_station/bench/examine(mob/user)
	. = ..()
	if(assembled_item?.loc == src)
		. += span_notice("[assembled_item] is ready to collect.")
	if(selected_pattern)
		var/list/recipe = GLOB.smithing_assembly_patterns[selected_pattern]
		. += span_notice("Assembling [lowertext(selected_pattern)] with [assembly_strikes]/[recipe["strikes"]] strikes complete.")

/obj/structure/smithing_station/bench/attack_hand(mob/living/user, list/modifiers)
	if(..())
		return TRUE
	if(assembled_item?.loc == src)
		var/obj/item/result = assembled_item
		assembled_item = null
		user.put_in_hands(result)
	else
		user.balloon_alert(user, "load parts and use a hammer")
	return TRUE

/obj/structure/smithing_station/bench/attack_hand_secondary(mob/user, list/modifiers)
	if(busy || !user.can_perform_action(src))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	for(var/obj/item/item as anything in contents)
		item.forceMove(drop_location())
	assembled_item = null
	selected_pattern = null
	assembly_strikes = 0
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/structure/smithing_station/bench/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(busy || assembled_item?.loc == src)
		user.balloon_alert(user, busy ? "workbench in use!" : "collect the finished item!")
		return ITEM_INTERACT_BLOCKING
	if(istype(tool, /obj/item/carpenter_hammer/smithing))
		INVOKE_ASYNC(src, PROC_REF(assemble), user, tool)
		return ITEM_INTERACT_SUCCESS
	var/obj/item/smithing_blank/part = tool
	if(istype(part) && !part.quenched)
		user.balloon_alert(user, "quench this part first!")
		return ITEM_INTERACT_BLOCKING
	if(istype(part) || istype(tool, /obj/item/stack/sheet/mineral/wood))
		if(!user.temporarilyRemoveItemFromInventory(tool, newloc = src))
			return ITEM_INTERACT_BLOCKING
		user.balloon_alert(user, "part loaded")
		return ITEM_INTERACT_SUCCESS
	return ..()

/// Resolve the exact objects and stack amounts a Nova assembly recipe needs.
/obj/structure/smithing_station/bench/proc/get_plan(list/recipe)
	var/list/plan = list()
	var/list/parts = recipe["parts"]
	for(var/part_kind in parts)
		var/needed = parts[part_kind]
		for(var/obj/item/smithing_blank/part in contents)
			if(!part.quenched || part.part_kind != part_kind)
				continue
			plan[part] = 1
			needed--
			if(!needed)
				break
		if(needed)
			return null
	var/wood_needed = recipe["wood"] || 0
	if(wood_needed)
		for(var/obj/item/stack/sheet/mineral/wood/planks in contents)
			var/take = min(planks.get_amount(), wood_needed)
			if(take <= 0)
				continue
			plan[planks] = take
			wood_needed -= take
			if(!wood_needed)
				break
		if(wood_needed)
			return null
	return plan

/obj/structure/smithing_station/bench/proc/assemble(mob/living/user, obj/item/tool)
	if(busy || assembled_item?.loc == src)
		return
	var/list/choices = list()
	for(var/pattern in GLOB.smithing_assembly_patterns)
		if(get_plan(GLOB.smithing_assembly_patterns[pattern]))
			choices += pattern
	if(!length(choices))
		user.balloon_alert(user, "load the required parts first!")
		return
	busy = TRUE
	var/pattern = selected_pattern
	if(!(pattern in choices))
		pattern = length(choices) == 1 ? choices[1] : tgui_input_list(user, "Choose what to assemble.", "Smithing Workbench", choices)
	if(!pattern || QDELETED(src) || QDELETED(user) || !user.is_holding(tool) || !user.can_perform_action(src))
		busy = FALSE
		return
	if(pattern != selected_pattern)
		selected_pattern = pattern
		assembly_strikes = 0
	var/list/recipe = GLOB.smithing_assembly_patterns[pattern]
	var/skill_modifier = user.mind?.get_skill_modifier(/datum/skill/smithing, SKILL_SPEED_MODIFIER) || 1
	while(assembly_strikes < recipe["strikes"])
		if(!do_after(user, skill_modifier * tool.toolspeed * 1 SECONDS, src) || QDELETED(src) || !user.is_holding(tool))
			busy = FALSE
			return
		assembly_strikes++
		playsound(src, 'sound/items/smithing/forge.ogg', 40, TRUE)
	if(finish_pattern(pattern))
		user.mind?.adjust_experience(/datum/skill/smithing, 30)
		user.balloon_alert(user, "item crafted")
	busy = FALSE

/// Recheck the loaded ingredients when assembly completes, then consume them once.
/obj/structure/smithing_station/bench/proc/finish_pattern(pattern)
	var/list/recipe = GLOB.smithing_assembly_patterns[pattern]
	if(!recipe || assembled_item?.loc == src)
		return FALSE
	var/list/plan = get_plan(recipe)
	if(!plan)
		return FALSE
	var/list/metals = list()
	for(var/obj/item/smithing_blank/part in plan)
		for(var/material in part.custom_materials)
			metals[material] += part.custom_materials[material]
	for(var/obj/item/ingredient as anything in plan)
		if(istype(ingredient, /obj/item/stack))
			var/obj/item/stack/stack = ingredient
			stack.use(plan[ingredient])
		else
			qdel(ingredient)
	var/output_type = recipe["output"]
	assembled_item = new output_type(src)
	assembled_item.material_flags |= MATERIAL_COLOR | MATERIAL_ADD_PREFIX | MATERIAL_EFFECTS
	assembled_item.set_custom_materials(metals)
	if(!istype(assembled_item, /obj/item/seed_sieve))
		var/armor_slot = NONE
		if(istype(assembled_item, /obj/item/clothing/head))
			armor_slot = ITEM_SLOT_HEAD
		else if(istype(assembled_item, /obj/item/clothing/suit))
			armor_slot = ITEM_SLOT_OCLOTHING
		assembled_item.AddComponent(/datum/component/smithing_infusion, armor_slot)
	selected_pattern = null
	assembly_strikes = 0
	return TRUE

// Adapted from Nova's reagent weapon and clothing components. The imbued
// reagents regenerate. The loading reservoir is discarded after imbuing.
/datum/component/smithing_infusion
	var/armor_slot
	var/next_dose = 0
	var/list/imbued_reagents = list()
	var/static/list/blocked_reagents = typecacheof(list(
		/datum/reagent/inverse,
		/datum/reagent/pax,
		/datum/reagent/teslium,
		/datum/reagent/toxin/acid,
		/datum/reagent/phlogiston,
		/datum/reagent/napalm,
		/datum/reagent/thermite,
		/datum/reagent/medicine/earthsblood,
		/datum/reagent/medicine/ephedrine,
		/datum/reagent/medicine/epinephrine,
	))

/datum/component/smithing_infusion/Initialize(armor_slot = NONE)
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE
	src.armor_slot = armor_slot
	var/obj/item/gear = parent
	gear.create_reagents(250, REFILLABLE | INJECTABLE | TRANSPARENT)
	RegisterSignal(parent, COMSIG_ATOM_EXAMINE, PROC_REF(show_infusion))
	if(!armor_slot)
		RegisterSignal(parent, COMSIG_ITEM_ATTACK_ZONE, PROC_REF(on_strike))

/datum/component/smithing_infusion/Destroy(force)
	STOP_PROCESSING(SSobj, src)
	return ..()

/datum/component/smithing_infusion/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_ATOM_EXAMINE, COMSIG_ITEM_ATTACK_ZONE))
	return ..()

/datum/component/smithing_infusion/proc/seal_infusion()
	if(length(imbued_reagents))
		return FALSE
	var/obj/item/gear = parent
	for(var/datum/reagent/chemical as anything in gear.reagents.reagent_list)
		if(chemical.volume >= 100 && !is_type_in_typecache(chemical, blocked_reagents))
			imbued_reagents += chemical.type
			if(length(imbued_reagents) >= 2)
				break
	if(!length(imbued_reagents))
		return FALSE
	gear.add_atom_colour(mix_color_from_reagents(gear.reagents.reagent_list), FIXED_COLOUR_PRIORITY)
	gear.reagents.clear_reagents()
	gear.reagents.flags &= ~(REFILLABLE | INJECTABLE)
	if(armor_slot)
		START_PROCESSING(SSobj, src)
	return TRUE

/datum/component/smithing_infusion/proc/show_infusion(obj/item/source, mob/user, list/examine_list)
	SIGNAL_HANDLER
	if(!length(imbued_reagents))
		examine_list += span_notice("Fill this with at least 100 units of an eligible reagent, then use it on a hot reagent forge.")
		return
	var/list/chemical_names = list()
	for(var/datum/reagent/chemical as anything in imbued_reagents)
		chemical_names += initial(chemical.name)
	examine_list += span_notice("Permanently imbued with [english_list(chemical_names)].")

/datum/component/smithing_infusion/proc/on_strike(obj/item/source, mob/living/target, mob/living/user)
	SIGNAL_HANDLER
	if(!iscarbon(target) || target.stat == DEAD || !length(imbued_reagents))
		return
	for(var/chemical in imbued_reagents)
		target.reagents?.add_reagent(chemical, 1)
	source.take_damage(2 * length(imbued_reagents))

/datum/component/smithing_infusion/process(seconds_per_tick)
	var/obj/item/armor = parent
	var/mob/living/carbon/wearer = armor.loc
	if(!istype(wearer) || wearer.stat == DEAD || wearer.get_item_by_slot(armor_slot) != armor || world.time < next_dose)
		return
	next_dose = world.time + 3 SECONDS
	for(var/chemical in imbued_reagents)
		wearer.reagents?.add_reagent(chemical, 0.5)

/datum/skill/smithing
	name = "Smithing"
	title = "Smithy"
	desc = "The desperate artist who strives after the flames of the forge."
	modifiers = list(
		SKILL_SPEED_MODIFIER = list(1, 0.95, 0.9, 0.85, 0.75, 0.6, 0.5),
		SKILL_PROBS_MODIFIER = list(10, 15, 20, 25, 30, 35, 40)
	)
	skill_item_path = /obj/item/clothing/neck/cloak/skill_reward/smithing

/obj/item/clothing/neck/cloak/skill_reward/smithing
	name = "legendary smithy's cloak"
	desc = "Worn by the most skilled smithies, this legendary cloak is only attainable by knowing every inch of the blacksmith's forge. \
	This status symbol represents a being who has forged some of the finest weapons and armors."
	icon = 'icons/obj/smithing/cloaks.dmi'
	worn_icon = 'icons/mob/smithing/neck.dmi'
	icon_state = "smithingcloak"
	associated_skill_path = /datum/skill/smithing
