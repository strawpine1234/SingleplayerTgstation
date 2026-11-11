// Adapted from Nova Sector's AGPL-3.0 reagent_forging module. See the Blacksmith guide for provenance.
/obj/item/katana/forged
	desc = "A station-forged katana with a folded edge and a wrapped grip."
	icon = 'icons/obj/smithing/forged_products.dmi'
	icon_state = "katana"
	lefthand_file = 'icons/mob/smithing/forged_products_lefthand.dmi'
	righthand_file = 'icons/mob/smithing/forged_products_righthand.dmi'
	inhand_icon_state = "katana"
	force = 24
	block_chance = 30

/obj/item/claymore/forged
	desc = "A long, heavy blade with a broad crossguard, forged for powerful swings."
	icon = 'icons/obj/smithing/forged_products.dmi'
	icon_state = "claymore"
	lefthand_file = 'icons/mob/smithing/forged_products_lefthand.dmi'
	righthand_file = 'icons/mob/smithing/forged_products_righthand.dmi'
	inhand_icon_state = "claymore"
	worn_icon_state = "claymore"
	force = 27
	block_chance = 25
	w_class = WEIGHT_CLASS_BULKY

/obj/item/claymore/forged_broadsword
	name = "broadsword"
	desc = "A broad, straight blade with a stout guard and a balanced grip."
	icon = 'icons/obj/smithing/forged_products.dmi'
	icon_state = "broadsword"
	lefthand_file = 'icons/mob/smithing/forged_products_lefthand.dmi'
	righthand_file = 'icons/mob/smithing/forged_products_righthand.dmi'
	inhand_icon_state = "broadsword"
	worn_icon_state = "claymore"
	force = 25
	block_chance = 35

/obj/item/claymore/shortsword/forged
	desc = "A compact forged blade for close work and tight passages."
	icon = 'icons/obj/smithing/forged_products.dmi'
	icon_state = "shortsword"
	lefthand_file = 'icons/mob/smithing/forged_products_lefthand.dmi'
	righthand_file = 'icons/mob/smithing/forged_products_righthand.dmi'
	inhand_icon_state = "shortsword"
	worn_icon_state = "shortsword"

/obj/item/knife/combat/forged_dagger
	name = "dagger"
	desc = "A narrow, double-edged dagger with a simple forged guard."
	icon = 'icons/obj/smithing/forged_products.dmi'
	icon_state = "dagger"
	lefthand_file = 'icons/mob/smithing/forged_products_lefthand.dmi'
	righthand_file = 'icons/mob/smithing/forged_products_righthand.dmi'
	inhand_icon_state = "dagger"
	worn_icon_state = "buckknife"
	force = 15

/obj/item/shield/roman/forged
	name = "forged shield"
	desc = "A hand-forged metal shield with a rolled rim and a reinforced grip."
	icon = 'icons/obj/smithing/forged_products.dmi'
	icon_state = "shield"
	lefthand_file = 'icons/mob/smithing/forged_products_lefthand.dmi'
	righthand_file = 'icons/mob/smithing/forged_products_righthand.dmi'
	inhand_icon_state = "shield"
	worn_icon_state = "roman_shield"
	max_integrity = 100
	block_chance = 35

/obj/item/clothing/suit/armor/vest/cuirass/forged
	name = "forged chestplate"
	desc = "Shaped and quenched metal plates fitted to protect the torso."
	icon = 'icons/obj/smithing/forged_products.dmi'
	icon_state = "chestplate"
	lefthand_file = 'icons/mob/smithing/forged_products_lefthand.dmi'
	righthand_file = 'icons/mob/smithing/forged_products_righthand.dmi'
	inhand_icon_state = "chestplate"
	worn_icon = 'icons/mob/smithing/forged_armor_worn.dmi'
	worn_icon_state = "chestplate"

/obj/item/clothing/head/helmet/knight/forged
	name = "forged helmet"
	desc = "A closed steel helmet with a narrow eye slit and a padded liner."
	icon = 'icons/obj/smithing/forged_products.dmi'
	icon_state = "helmet"
	lefthand_file = 'icons/mob/smithing/forged_products_lefthand.dmi'
	righthand_file = 'icons/mob/smithing/forged_products_righthand.dmi'
	inhand_icon_state = "helmet"
	worn_icon = 'icons/mob/smithing/forged_armor_worn.dmi'
	worn_icon_state = "helmet"

/obj/item/carpenter_hammer/forged_warhammer
	name = "warhammer"
	desc = "A heavy forged striking head on a reinforced haft."
	icon = 'icons/obj/smithing/forged_products.dmi'
	icon_state = "warhammer"
	lefthand_file = 'icons/mob/smithing/forged_products_lefthand.dmi'
	righthand_file = 'icons/mob/smithing/forged_products_righthand.dmi'
	inhand_icon_state = "warhammer"
	worn_icon_state = "hammeron"
	force = 28
	w_class = WEIGHT_CLASS_BULKY

/obj/item/seed_sieve
	name = "seed sieve"
	desc = "A fine forged mesh for sifting seed packets out of sand. Finer materials recover more seeds from each pile."
	icon = 'icons/obj/smithing/forged_products.dmi'
	icon_state = "seed_sieve"
	lefthand_file = 'icons/mob/smithing/forged_products_lefthand.dmi'
	righthand_file = 'icons/mob/smithing/forged_products_righthand.dmi'
	inhand_icon_state = "seed_sieve"
	w_class = WEIGHT_CLASS_SMALL
	/// Seed packets recovered per pile of sand. Set from the stock when forged.
	var/seed_yield = 2

/obj/item/seed_sieve/examine(mob/user)
	. = ..()
	. += span_notice("It recovers [seed_yield] random seed packets per pile of sand.")

/obj/item/seed_sieve/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	var/obj/item/stack/ore/glass/sand = interacting_with
	if(!istype(sand) || istype(sand, /obj/item/stack/ore/glass/concrete_powder) || SHOULD_SKIP_INTERACTION(sand, src, user))
		return NONE
	if(sand.loc != user && !isturf(sand.loc))
		return ITEM_INTERACT_BLOCKING
	var/turf/output = get_turf(sand)
	if(!output)
		return ITEM_INTERACT_BLOCKING

	var/static/list/seed_pool = valid_subtypesof(/obj/item/seeds)
	var/seed_count = min(seed_yield, length(seed_pool))
	if(!seed_count || !sand.use(1))
		return ITEM_INTERACT_BLOCKING
	var/list/choices = seed_pool.Copy()
	for(var/index in 1 to seed_count)
		var/seed_type = pick_n_take(choices)
		new seed_type(output)
	user.balloon_alert(user, "sifted [seed_count] seeds")
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

/// Modest handling and protection perks for pure stock, scaled by share in a mixed piece.
GLOBAL_LIST_INIT(smithing_material_perks, list(
	/datum/material/iron = list("durability" = 0.05),
	/datum/material/glass = list("edge" = 4),
	/datum/material/silver = list("guard" = 3),
	/datum/material/gold = list("guard" = 4, "speed" = 0.03),
	/datum/material/diamond = list("edge" = 8, "durability" = 0.1),
	/datum/material/uranium = list("throw" = 3, "durability" = 0.1),
	/datum/material/plasma = list("edge" = 5, "fire" = 5),
	/datum/material/bluespace = list("speed" = 0.1),
	/datum/material/bananium = list("throw" = 4, "speed" = 0.05),
	/datum/material/titanium = list("speed" = 0.06, "durability" = 0.1),
	/datum/material/runite = list("guard" = 4, "edge" = 3),
	/datum/material/plastic = list("speed" = 0.03, "fire" = 2),
	/datum/material/wood = list("speed" = 0.04),
	/datum/material/adamantine = list("durability" = 0.25),
	/datum/material/mythril = list("speed" = 0.08, "guard" = 5),
	/datum/material/hot_ice = list("fire" = 8, "speed" = 0.04),
	/datum/material/metalhydrogen = list("edge" = 6, "speed" = 0.05),
	/datum/material/sandstone = list("fire" = 4),
	/datum/material/snow = list("fire" = 3, "speed" = 0.02),
	/datum/material/runedmetal = list("guard" = 5, "fire" = 4),
	/datum/material/bronze = list("throw" = 2, "guard" = 2),
	/datum/material/paper = list("speed" = 0.05),
	/datum/material/cardboard = list("guard" = 1),
	/datum/material/bone = list("edge" = 3, "speed" = 0.02),
	/datum/material/bamboo = list("speed" = 0.06),
	/datum/material/zaukerite = list("edge" = 7, "fire" = 5),
	/datum/material/hauntium = list("guard" = 3, "fire" = 3),
	/datum/material/telecrystal = list("speed" = 0.07, "throw" = 3),
	/datum/material/alloy/plasteel = list("durability" = 0.2, "guard" = 3),
	/datum/material/alloy/plastitanium = list("durability" = 0.15, "fire" = 6),
	/datum/material/alloy/plasmaglass = list("edge" = 4, "fire" = 5),
	/datum/material/alloy/titaniumglass = list("edge" = 4, "speed" = 0.04),
	/datum/material/alloy/plastitaniumglass = list("edge" = 5, "fire" = 6),
	/datum/material/alloy/alien = list("durability" = 0.15, "edge" = 4, "speed" = 0.06),
	// Some sheets have no material datum or catalogue price. Set their rarity and perks here.
	/obj/item/stack/sheet/cloth = list("speed" = 0.03),
	/obj/item/stack/sheet/leather = list("guard" = 2),
	/obj/item/stack/sheet/durathread = list("damage" = 1, "durability" = 0.12),
	/obj/item/stack/sheet/mineral/coal = list("throw" = 1),
	/obj/item/stack/sheet/sinew = list("damage" = 2, "speed" = 0.05),
	/obj/item/stack/sheet/sinew/icewing = list("damage" = 3, "speed" = 0.07),
	/obj/item/stack/sheet/sinew/magmawing = list("damage" = 3, "fire" = 5),
	/obj/item/stack/sheet/animalhide/goliath_hide = list("damage" = 3, "guard" = 3, "durability" = 0.1),
	/obj/item/stack/sheet/animalhide/ashdrake = list("damage" = 8, "fire" = 8, "durability" = 0.15),
	/obj/item/stack/sheet/lessergem = list("damage" = 6, "edge" = 5, "guard" = 2),
	/obj/item/stack/sheet/greatergem = list("damage" = 9, "edge" = 7, "guard" = 3),
))

/obj/structure/smithing_station/bench
	name = "smithing workbench"
	desc = "Click with an empty hand to browse recipes or collect a finished item. Load quenched parts and wood, then use a forging hammer to assemble a pattern. Right-click to unload parts."
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
		SStgui.update_uis(src)
	else
		ui_interact(user)
	return TRUE

/obj/structure/smithing_station/bench/ui_state(mob/user)
	return GLOB.physical_state

/obj/structure/smithing_station/bench/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SmithingWorkbench", name)
		ui.open()

/obj/structure/smithing_station/bench/ui_static_data(mob/user)
	var/list/recipes = list()
	for(var/pattern in GLOB.smithing_assembly_patterns)
		var/list/recipe = GLOB.smithing_assembly_patterns[pattern]
		var/list/parts = recipe["parts"]
		var/list/materials = list()
		for(var/part_kind in parts)
			materials += list(list("name" = part_kind, "amount" = parts[part_kind]))
		if(recipe["wood"])
			materials += list(list("name" = "Wood planks", "amount" = recipe["wood"]))
		recipes += list(list("name" = pattern, "materials" = materials, "strikes" = recipe["strikes"]))
	return list("recipes" = recipes)

/obj/structure/smithing_station/bench/ui_data(mob/user)
	var/list/loaded = list("Wood planks" = 0)
	for(var/obj/item/smithing_blank/part in contents)
		if(part.quenched)
			loaded[part.part_kind]++
	for(var/obj/item/stack/sheet/mineral/wood/planks in contents)
		loaded["Wood planks"] += planks.get_amount()
	return list(
		"loaded" = loaded,
		"selected_pattern" = selected_pattern,
		"assembly_strikes" = assembly_strikes,
		"finished_item" = assembled_item?.loc == src ? assembled_item.name : null,
	)

/obj/structure/smithing_station/bench/attack_hand_secondary(mob/user, list/modifiers)
	if(busy || !user.can_perform_action(src))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	for(var/obj/item/item as anything in contents)
		item.forceMove(drop_location())
	assembled_item = null
	selected_pattern = null
	assembly_strikes = 0
	SStgui.update_uis(src)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/structure/smithing_station/bench/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(busy || assembled_item?.loc == src)
		user.balloon_alert(user, busy ? "workbench in use!" : "collect the finished item!")
		return ITEM_INTERACT_BLOCKING
	if(istype(tool, /obj/item/carpenter_hammer/smithing))
		INVOKE_ASYNC(src, PROC_REF(assemble), user, tool)
		return ITEM_INTERACT_SUCCESS
	var/obj/item/ingredient = tool
	var/using_tongs = istype(tool, /obj/item/smithing_tongs)
	if(using_tongs)
		ingredient = locate(/obj/item/smithing_blank) in tool.contents
		if(!ingredient)
			user.balloon_alert(user, "hold a quenched part in the tongs!")
			return ITEM_INTERACT_BLOCKING
	var/obj/item/smithing_blank/part = ingredient
	if(istype(part) && !part.quenched)
		user.balloon_alert(user, "quench this part first!")
		return ITEM_INTERACT_BLOCKING
	if(!istype(part) && !istype(ingredient, /obj/item/stack/sheet/mineral/wood))
		return ..()
	if(using_tongs)
		ingredient.forceMove(src)
	else if(!user.transferItemToLoc(ingredient, src))
		return ITEM_INTERACT_BLOCKING
	user.balloon_alert(user, "part loaded")
	SStgui.update_uis(src)
	return ITEM_INTERACT_SUCCESS

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
	user.balloon_alert(user, "assembling [lowertext(pattern)]")
	SStgui.update_uis(src)
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
	SStgui.update_uis(src)

/// Recheck the loaded ingredients when assembly completes, then consume them once.
/obj/structure/smithing_station/bench/proc/finish_pattern(pattern)
	var/list/recipe = GLOB.smithing_assembly_patterns[pattern]
	if(!recipe || assembled_item?.loc == src)
		return FALSE
	var/list/plan = get_plan(recipe)
	if(!plan)
		return FALSE
	var/list/materials = list()
	var/list/untracked_stock = list()
	for(var/obj/item/smithing_blank/part in plan)
		for(var/datum/material/material as anything in part.custom_materials)
			materials[material] += part.custom_materials[material]
		if(part.untracked_stock)
			untracked_stock[part.untracked_stock]++
	for(var/obj/item/ingredient as anything in plan)
		if(istype(ingredient, /obj/item/stack))
			var/obj/item/stack/stack = ingredient
			stack.use(plan[ingredient])
		else
			qdel(ingredient)
	var/output_type = recipe["output"]
	assembled_item = new output_type(src)
	apply_smithing_materials(assembled_item, materials, untracked_stock)
	apply_smithing_tint(assembled_item, materials, untracked_stock)
	apply_smithing_bonuses(assembled_item, materials, untracked_stock)
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

/// Keep the composition for all stock. New materials get controlled smithing perks
/// instead of unrelated native effects such as curses or gas release.
/obj/structure/smithing_station/bench/proc/apply_smithing_materials(obj/item/gear, list/materials, list/untracked_stock)
	var/native_effects = !length(untracked_stock)
	for(var/datum/material/material as anything in materials)
		if(!is_type_in_typecache(material, GLOB.smithing_native_effects))
			native_effects = FALSE
			break
	if(native_effects)
		gear.material_flags |= MATERIAL_ADD_PREFIX | MATERIAL_EFFECTS
		gear.set_custom_materials(materials)
		return

	gear.material_flags &= ~MATERIAL_EFFECTS
	gear.set_custom_materials(materials)
	var/list/material_names = list()
	for(var/obj/item/stack/stock_type as anything in untracked_stock)
		material_names |= initial(stock_type.name)
	for(var/datum/material/material as anything in materials)
		material_names |= material.name
	gear.name = "[material_names.Join("-")] [gear.name]"

/// Weight bonuses by the material in the actual blanks. Handle wood never enters this calculation.
/obj/structure/smithing_station/bench/proc/apply_smithing_bonuses(obj/item/gear, list/materials, list/untracked_stock)
	var/list/composition = materials.Copy()
	for(var/stock_type in untracked_stock)
		composition[stock_type] = untracked_stock[stock_type] * SHEET_MATERIAL_AMOUNT
	var/total_amount = 0
	var/list/bonuses = list()
	for(var/stock in composition)
		var/amount = composition[stock]
		total_amount += amount
		var/datum/material/material = stock
		var/perk_type = istype(material) ? material.type : stock
		var/list/perks = GLOB.smithing_material_perks[perk_type]
		if(istype(material))
			// Use the catalogue value per sheet as the rarity proxy, capped at +9.
			var/sheet_value = material.value_per_unit * SHEET_MATERIAL_AMOUNT
			bonuses["damage"] += min(9, sqrt(max(0, sheet_value - 25)) / 3.5) * amount
		if(!perks)
			bonuses["durability"] += 0.05 * amount
		for(var/perk in perks)
			bonuses[perk] += perks[perk] * amount
	if(!total_amount)
		return
	for(var/perk in bonuses)
		bonuses[perk] /= total_amount
	if(istype(gear, /obj/item/seed_sieve))
		var/obj/item/seed_sieve/sieve = gear
		sieve.seed_yield = clamp(2 + round(bonuses["damage"] * 4 / 9 + 0.5), 2, 6)
		return

	var/edge = round(bonuses["edge"] + 0.5)
	var/guard = round(bonuses["guard"] + 0.5)
	var/throw_bonus = round(bonuses["throw"] + 0.5)
	var/fire_bonus = round(bonuses["fire"] + 0.5)
	if(gear.uses_integrity && bonuses["durability"])
		gear.modify_max_integrity(round(gear.max_integrity * (1 + bonuses["durability"])))
	var/is_armor = isclothing(gear)
	var/is_shield = istype(gear, /obj/item/shield)
	if(!is_armor)
		gear.force += round(bonuses["damage"] + 0.5)
	if(is_armor || is_shield)
		var/speed_bonus = bonuses["speed"] || 0
		var/datum/armor/armor = gear.get_armor()
		gear.set_armor(armor.generate_new_with_specific(list(
			"melee" = min(100, armor.get_rating("melee") + edge + guard),
			"bullet" = min(100, armor.get_rating("bullet") + throw_bonus),
			"laser" = min(100, armor.get_rating("laser") + round(speed_bonus * 50 + 0.5)),
			"fire" = min(100, armor.get_rating("fire") + fire_bonus),
		)))
		if(is_shield)
			gear.block_chance += guard
		return

	gear.armour_penetration += edge
	gear.block_chance += guard
	gear.throwforce += throw_bonus
	gear.attack_speed *= 1 - (bonuses["speed"] || 0)
	if(fire_bonus)
		gear.set_armor_rating("fire", min(100, gear.get_armor_rating("fire") + fire_bonus))

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
