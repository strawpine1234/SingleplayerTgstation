// Adapted from Nova Sector's AGPL-3.0 reagent_forging module. See the Blacksmith guide for provenance.
#define SMITHING_MIN_HEAT 51
#define SMITHING_MAX_HEAT 100

/// Nova's small parts take ten strikes. Weapon heads take thirty.
GLOBAL_LIST_INIT(smithing_parts, list(
	"Chain" = list("sprite" = "chain", "strikes" = 10),
	"Plate" = list("sprite" = "plate", "strikes" = 10),
	"Katana blade" = list("sprite" = "katanablade", "strikes" = 30),
	"Claymore blade" = list("sprite" = "blade", "strikes" = 30),
	"Broadsword blade" = list("sprite" = "blade", "strikes" = 30),
	"Dagger blade" = list("sprite" = "daggerblade", "strikes" = 30),
	"Shortsword blade" = list("sprite" = "blade", "strikes" = 30),
	"Warhammer head" = list("sprite" = "hammerhead", "strikes" = 30),
))

/// Legacy forging metals retain their existing native material effects on finished gear.
GLOBAL_LIST_INIT(smithing_native_effects, typecacheof(list(
	/datum/material/iron,
	/datum/material/silver,
	/datum/material/gold,
	/datum/material/titanium,
	/datum/material/alloy/plasteel,
	/datum/material/alloy/plastitanium,
)))

/obj/item/storage/box/smithing_kit
	name = "blacksmith workshop kit"
	desc = "Four separately placeable smithing stations, forging tools, metal, and fuel."

/obj/item/storage/box/smithing_kit/Initialize(mapload)
	. = ..()
	atom_storage.max_slots = 10

/obj/item/storage/box/smithing_kit/PopulateContents()
	new /obj/item/smithing_frame/forge(src)
	new /obj/item/smithing_frame/anvil(src)
	new /obj/item/smithing_frame/basin(src)
	new /obj/item/smithing_frame/bench(src)
	new /obj/item/smithing_tongs(src)
	new /obj/item/carpenter_hammer/smithing(src)
	new /obj/item/smithing_bellows(src)
	new /obj/item/stack/sheet/iron/ten(src)
	new /obj/item/stack/sheet/mineral/wood(src, 12)
	new /obj/item/stack/sheet/mineral/coal(src, 2)

/datum/supply_pack/misc/blacksmith_kit
	name = "Blacksmith Workshop Kit"
	desc = "A forge, anvil, water basin, and workbench with tongs, a hammer, bellows, iron, wood, and coal."
	cost = CARGO_CRATE_VALUE * 4
	contains = list(/obj/item/storage/box/smithing_kit)
	crate_name = "blacksmith workshop crate"

/obj/item/smithing_frame
	name = "folded smithing frame"
	desc = "Use this frame on a clear floor tile to assemble its station."
	icon = 'icons/obj/devices/circuitry_n_data.dmi'
	icon_state = "mainboard"
	w_class = WEIGHT_CLASS_SMALL
	abstract_type = /obj/item/smithing_frame
	var/station_type

/obj/item/smithing_frame/forge
	name = "folded forge frame"
	station_type = /obj/structure/smithing_station/forge

/obj/item/smithing_frame/anvil
	name = "folded anvil frame"
	station_type = /obj/structure/smithing_station/anvil

/obj/item/smithing_frame/basin
	name = "folded water basin frame"
	station_type = /obj/structure/smithing_station/basin

/obj/item/smithing_frame/bench
	name = "folded smithing workbench frame"
	station_type = /obj/structure/smithing_station/bench

/obj/item/smithing_frame/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!isturf(interacting_with) || SHOULD_SKIP_INTERACTION(interacting_with, src, user))
		return NONE
	var/turf/open/site = interacting_with
	if(!istype(site) || !(site.turf_flags & IS_SOLID) || isgroundlessturf(site) || islava(site) || site.is_blocked_turf())
		user.balloon_alert(user, "clear solid ground needed!")
		return ITEM_INTERACT_BLOCKING
	if(!do_after(user, 2 SECONDS, site))
		return ITEM_INTERACT_BLOCKING
	if(QDELETED(src) || QDELETED(site) || !user.is_holding(src) || !user.can_perform_action(site) || site.is_blocked_turf())
		return ITEM_INTERACT_BLOCKING
	new station_type(site)
	qdel(src)
	return ITEM_INTERACT_SUCCESS

/datum/crafting_recipe/smithing_forge
	name = "Forge frame"
	result = /obj/item/smithing_frame/forge
	reqs = list(/obj/item/stack/sheet/iron = 10)
	category = CAT_STRUCTURE
	time = 5 SECONDS

/datum/crafting_recipe/smithing_anvil
	name = "Anvil frame"
	result = /obj/item/smithing_frame/anvil
	reqs = list(/obj/item/stack/sheet/iron = 10)
	category = CAT_STRUCTURE
	time = 5 SECONDS

/datum/crafting_recipe/smithing_basin
	name = "Water basin frame"
	result = /obj/item/smithing_frame/basin
	reqs = list(/obj/item/stack/sheet/mineral/wood = 5)
	category = CAT_STRUCTURE
	time = 5 SECONDS

/datum/crafting_recipe/smithing_bench
	name = "Smithing workbench frame"
	result = /obj/item/smithing_frame/bench
	reqs = list(/obj/item/stack/sheet/mineral/wood = 5, /obj/item/stack/sheet/iron = 2)
	category = CAT_STRUCTURE
	time = 5 SECONDS

/datum/crafting_recipe/smithing_bellows
	name = "Forging bellows"
	result = /obj/item/smithing_bellows
	reqs = list(/obj/item/stack/sheet/mineral/wood = 5)
	category = CAT_TOOLS

/datum/crafting_recipe/smithing_tongs
	name = "Forging tongs"
	result = /obj/item/smithing_tongs
	reqs = list(/obj/item/stack/sheet/iron = 5)
	category = CAT_TOOLS

/datum/crafting_recipe/smithing_hammer
	name = "Forging hammer"
	result = /obj/item/carpenter_hammer/smithing
	reqs = list(/obj/item/stack/sheet/iron = 5)
	category = CAT_TOOLS

/obj/item/smithing_bellows
	name = "forging bellows"
	desc = "Stokes a fueled forge hot enough to work metal."
	icon = 'icons/obj/smithing/forge_items.dmi'
	icon_state = "billow"
	w_class = WEIGHT_CLASS_SMALL

/obj/item/carpenter_hammer/smithing
	name = "forging hammer"
	desc = "A mallet for shaping hot metal and assembling quenched parts."
	icon = 'icons/obj/smithing/forge_items.dmi'
	icon_state = "hammer"
	inhand_icon_state = "hammer"
	lefthand_file = 'icons/mob/smithing/forge_weapon_l.dmi'
	righthand_file = 'icons/mob/smithing/forge_weapon_r.dmi'
	force = 8
	w_class = WEIGHT_CLASS_SMALL

/obj/item/smithing_tongs
	name = "forging tongs"
	desc = "Pick up one rod or a unit from any material sheet stack with these tongs. Use them at a hot forge to shape a blank, or to carry a blank between stations."
	icon = 'icons/obj/smithing/forge_items.dmi'
	icon_state = "tong_empty"
	inhand_icon_state = "hemostat"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL

/obj/item/smithing_tongs/update_icon_state()
	icon_state = length(contents) ? "tong_full" : "tong_empty"
	return ..()

/obj/item/smithing_tongs/Entered(atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	. = ..()
	update_appearance(UPDATE_ICON_STATE)

/obj/item/smithing_tongs/Exited(atom/movable/gone, direction)
	. = ..()
	update_appearance(UPDATE_ICON_STATE)

/obj/item/smithing_tongs/examine(mob/user)
	. = ..()
	for(var/obj/item/item as anything in contents)
		. += span_notice("Holding [item].")
		. += item.examine(user)

/obj/item/smithing_tongs/attack_self(mob/user, modifiers)
	for(var/obj/item/item as anything in contents)
		item.forceMove(drop_location())
	return ..()

/obj/item/smithing_tongs/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(SHOULD_SKIP_INTERACTION(interacting_with, src, user))
		return NONE
	if(!istype(interacting_with, /obj/item/smithing_blank) && !istype(interacting_with, /obj/item/stack))
		return NONE
	if(length(contents))
		user.balloon_alert(user, "tongs are full!")
		return ITEM_INTERACT_BLOCKING
	var/obj/item/item = interacting_with
	if(!isturf(item.loc) && item.loc != user)
		return ITEM_INTERACT_BLOCKING
	if(istype(item, /obj/item/stack))
		var/obj/item/stack/stock = item
		if(!istype(stock, /obj/item/stack/rods) && !istype(stock, /obj/item/stack/sheet))
			return NONE
		var/obj/item/stack/piece = stock.split_stack(1)
		if(!piece)
			return ITEM_INTERACT_BLOCKING
		piece.forceMove(src)
	else if(item.loc == user)
		if(!user.temporarilyRemoveItemFromInventory(item, newloc = src))
			return ITEM_INTERACT_BLOCKING
	else
		item.forceMove(src)
	return ITEM_INTERACT_SUCCESS

/obj/item/smithing_tongs/Destroy(force)
	for(var/obj/item/item as anything in contents)
		item.forceMove(drop_location())
	return ..()

/obj/item/smithing_blank
	name = "smithing blank"
	desc = "A piece of material shaped on an anvil."
	icon = 'icons/obj/smithing/forge_items.dmi'
	icon_state = "hot_plate"
	w_class = WEIGHT_CLASS_SMALL
	abstract_type = /obj/item/smithing_blank
	material_flags = MATERIAL_COLOR | MATERIAL_ADD_PREFIX
	var/part_kind
	/// Source stack type for sheets such as cloth that have no registered material composition.
	var/obj/item/stack/untracked_stock
	var/hot_until = 0
	var/strikes = 0
	var/required_strikes = 0
	var/strike_delay
	var/quenched = FALSE

/obj/item/smithing_blank/Initialize(mapload, pattern_name, list/materials, untracked_stock)
	. = ..()
	var/list/pattern = GLOB.smithing_parts[pattern_name]
	if(!pattern)
		return INITIALIZE_HINT_QDEL
	part_kind = pattern_name
	name = "[lowertext(pattern_name)] blank"
	icon_state = "hot_[pattern["sprite"]]"
	required_strikes = pattern["strikes"]
	strike_delay = required_strikes == 10 ? 0.5 SECONDS : 1 SECONDS
	hot_until = world.time + 1 MINUTES
	src.untracked_stock = untracked_stock
	set_custom_materials(materials)

/obj/item/smithing_blank/examine(mob/user)
	. = ..()
	var/material_name = untracked_stock ? initial(untracked_stock.name) : get_material_english_list(custom_materials)
	if(material_name)
		. += span_notice("Forged from [material_name].")
	if(quenched)
		. += span_notice("Ready to assemble on a smithing workbench.")
	else
		. += span_notice("[strikes]/[required_strikes] strikes. The blank is [world.time < hot_until ? "hot" : "cold"].")

/obj/item/smithing_blank/attack_hand(mob/living/user, list/modifiers)
	if(!quenched && world.time < hot_until)
		user.balloon_alert(user, "too hot to handle!")
		return TRUE
	return ..()

/obj/structure/smithing_station
	abstract_type = /obj/structure/smithing_station
	icon = 'icons/obj/smithing/forge_structures.dmi'
	anchored = TRUE
	density = TRUE
	max_integrity = 200
	var/frame_type
	var/busy = FALSE

/obj/structure/smithing_station/wrench_act(mob/living/user, obj/item/tool)
	if(busy || length(contents))
		user.balloon_alert(user, "empty the station first!")
		return TRUE
	if(!tool.use_tool(src, user, 2 SECONDS, volume = 50) || QDELETED(src) || busy || length(contents))
		return TRUE
	new frame_type(drop_location())
	qdel(src)
	return TRUE

/obj/structure/smithing_station/attack_hand_secondary(mob/user, list/modifiers)
	if(!busy && user.can_perform_action(src))
		set_anchored(!anchored)
		user.balloon_alert(user, anchored ? "secured" : "unsecured")
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/structure/smithing_station/Destroy(force)
	for(var/obj/item/item as anything in contents)
		item.forceMove(drop_location())
	return ..()

/obj/structure/smithing_station/forge
	name = "smithing forge"
	desc = "Fuel it with wood or coal. Wood needs bellows to reach working heat. Use a sheet or rod in tongs to form a blank or loaded tongs to reheat one."
	icon_state = "forge_inactive"
	frame_type = /obj/item/smithing_frame/forge
	var/temperature = 0
	var/wood_seconds = 0
	var/coal_seconds = 0
	var/stoked_until = 0
	var/insulation = 0
	var/reagent_cores = 0

/obj/structure/smithing_station/forge/examine(mob/user)
	. = ..()
	. += span_notice("Heat [round(temperature)]/100. Working heat starts at 51. Wood lasts [round(wood_seconds)] seconds and coal lasts [round(coal_seconds)] seconds.")
	. += span_notice(reagent_cores >= 3 ? "This forge can imbue finished gear." : "Fit three regenerative cores to enable reagent imbuing. Installed [reagent_cores]/3.")

/obj/structure/smithing_station/forge/Destroy(force)
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/structure/smithing_station/forge/wrench_act(mob/living/user, obj/item/tool)
	if(temperature || wood_seconds || coal_seconds || insulation || reagent_cores)
		user.balloon_alert(user, "right-click to unsecure the forge!")
		return TRUE
	return ..()

/obj/structure/smithing_station/forge/update_icon_state()
	icon_state = temperature > 0 ? "forge_active" : "forge_inactive"
	return ..()

// Adapted from Nova's weak/strong fuel and target-temperature loop.
/obj/structure/smithing_station/forge/process(seconds_per_tick)
	var/target_heat = 0
	if(coal_seconds > 0)
		coal_seconds = max(0, coal_seconds - seconds_per_tick)
		target_heat = SMITHING_MAX_HEAT
	else if(wood_seconds > 0)
		wood_seconds = max(0, wood_seconds - seconds_per_tick)
		target_heat = world.time < stoked_until ? 90 : 50
	if(temperature < target_heat)
		temperature = min(target_heat, temperature + 5 * seconds_per_tick)
	else if(temperature > target_heat)
		temperature = max(target_heat, temperature - (5 - insulation) * seconds_per_tick)
	update_appearance(UPDATE_ICON_STATE)
	if(!temperature && !wood_seconds && !coal_seconds)
		return PROCESS_KILL

/obj/structure/smithing_station/forge/attack_hand(mob/living/user, list/modifiers)
	if(..())
		return TRUE
	var/skill_level = user.mind?.get_skill_level(/datum/skill/smithing)
	if(skill_level > insulation)
		insulation = min(4, skill_level)
		user.balloon_alert(user, "forge insulated")
	if(skill_level >= SKILL_LEVEL_LEGENDARY && reagent_cores < 3)
		reagent_cores = 3
		user.balloon_alert(user, "reagent forge unlocked")
	return TRUE

/obj/structure/smithing_station/forge/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(busy)
		user.balloon_alert(user, "forge busy!")
		return ITEM_INTERACT_BLOCKING
	if(istype(tool, /obj/item/smithing_tongs))
		INVOKE_ASYNC(src, PROC_REF(work_with_tongs), user, tool)
		return ITEM_INTERACT_SUCCESS
	if(istype(tool, /obj/item/smithing_bellows))
		if(!wood_seconds && !coal_seconds)
			user.balloon_alert(user, "fuel the forge first!")
			return ITEM_INTERACT_BLOCKING
		if(temperature >= 90 && world.time < stoked_until)
			user.balloon_alert(user, "forge already stoked!")
			return ITEM_INTERACT_BLOCKING
		stoked_until = world.time + 30 SECONDS
		temperature = min(SMITHING_MAX_HEAT, temperature + 20)
		update_appearance(UPDATE_ICON_STATE)
		user.mind?.adjust_experience(/datum/skill/smithing, 5)
		user.balloon_alert(user, "heat [round(temperature)]/100")
		return ITEM_INTERACT_SUCCESS
	if(istype(tool, /obj/item/organ/monster_core/regenerative_core) && reagent_cores < 3)
		if(!user.temporarilyRemoveItemFromInventory(tool))
			return ITEM_INTERACT_BLOCKING
		reagent_cores++
		qdel(tool)
		user.balloon_alert(user, "reagent cores [reagent_cores]/3")
		return ITEM_INTERACT_SUCCESS
	var/obj/item/stack/fuel = tool
	if(istype(fuel, /obj/item/stack/sheet/mineral/wood) || istype(fuel, /obj/item/stack/sheet/mineral/coal))
		return refuel(user, fuel)
	if(istype(tool, /obj/item/stack/ore))
		INVOKE_ASYNC(src, PROC_REF(smelt_ore), user, tool)
		return ITEM_INTERACT_SUCCESS
	var/datum/component/smithing_infusion/infusion = tool.GetComponent(/datum/component/smithing_infusion)
	if(infusion)
		INVOKE_ASYNC(src, PROC_REF(imbue_gear), user, tool, infusion)
		return ITEM_INTERACT_SUCCESS
	return ..()

/obj/structure/smithing_station/forge/proc/refuel(mob/living/user, obj/item/stack/fuel)
	var/strong_fuel = istype(fuel, /obj/item/stack/sheet/mineral/coal)
	if((strong_fuel ? coal_seconds : wood_seconds) >= 300)
		user.balloon_alert(user, "forge full of that fuel!")
		return ITEM_INTERACT_BLOCKING
	if(!fuel.use(1))
		return ITEM_INTERACT_BLOCKING
	if(strong_fuel)
		coal_seconds = min(600, coal_seconds + 300)
	else
		wood_seconds = min(600, wood_seconds + 300)
		if(prob(45))
			addtimer(CALLBACK(src, PROC_REF(spawn_charcoal)), 1 MINUTES)
	START_PROCESSING(SSobj, src)
	user.mind?.adjust_experience(/datum/skill/smithing, strong_fuel ? 10 : 5)
	user.balloon_alert(user, "forge fueled")
	return ITEM_INTERACT_SUCCESS

/obj/structure/smithing_station/forge/proc/spawn_charcoal()
	if(!wood_seconds)
		return
	var/obj/item/stack/sheet/mineral/coal/charcoal = new(drop_location(), 1, FALSE)
	charcoal.name = "charcoal"

/obj/structure/smithing_station/forge/proc/work_with_tongs(mob/living/user, obj/item/smithing_tongs/tongs)
	if(busy || temperature < SMITHING_MIN_HEAT || QDELETED(tongs) || !user.is_holding(tongs))
		user.balloon_alert(user, "forge busy or too cool!")
		return
	var/obj/item/smithing_blank/blank = locate() in tongs.contents
	var/obj/item/stack/metal = locate() in tongs.contents
	if(!blank && !metal)
		user.balloon_alert(user, "load a sheet or rod into the tongs!")
		return
	if(blank && (blank.quenched || world.time < blank.hot_until))
		user.balloon_alert(user, "blank does not need heating!")
		return
	busy = TRUE
	var/pattern
	if(metal)
		pattern = tgui_input_list(user, "Choose the part to forge.", "Smithing Forge", GLOB.smithing_parts)
		if(!pattern || QDELETED(src) || QDELETED(metal) || metal.loc != tongs || QDELETED(user) || !user.is_holding(tongs) || !user.can_perform_action(src))
			busy = FALSE
			return
	if(do_after(user, 2 SECONDS, src) && !QDELETED(src) && !QDELETED(tongs) && user.is_holding(tongs) && temperature >= SMITHING_MIN_HEAT)
		if(blank && !QDELETED(blank) && blank.loc == tongs)
			blank.hot_until = world.time + 1 MINUTES
			user.balloon_alert(user, "blank reheated")
		else if(metal && !QDELETED(metal) && metal.loc == tongs)
			if(!cast_part(tongs, metal, pattern))
				busy = FALSE
				return
			user.balloon_alert(user, "hot blank ready")
		user.mind?.adjust_experience(/datum/skill/smithing, 5)
	busy = FALSE

/obj/structure/smithing_station/forge/proc/cast_part(obj/item/smithing_tongs/tongs, obj/item/stack/metal, pattern)
	if(temperature < SMITHING_MIN_HEAT || !GLOB.smithing_parts[pattern] || QDELETED(metal) || metal.loc != tongs)
		return FALSE
	var/list/materials = metal.mats_per_unit?.Copy()
	var/untracked_stock = length(materials) ? null : metal.merge_type
	if(!metal.use(1))
		return FALSE
	new /obj/item/smithing_blank(tongs, pattern, materials, untracked_stock)
	return TRUE

/obj/structure/smithing_station/forge/proc/smelt_ore(mob/living/user, obj/item/stack/ore/ore)
	if(busy || temperature < SMITHING_MIN_HEAT || QDELETED(ore) || !ore.refined_type)
		user.balloon_alert(user, "need heat and refinable ore!")
		return
	busy = TRUE
	if(do_after(user, 3 SECONDS, src) && !QDELETED(src) && !QDELETED(ore) && user.is_holding(ore) && temperature >= SMITHING_MIN_HEAT)
		var/refined_type = ore.refined_type
		if(ore.use(1))
			new refined_type(drop_location())
			user.mind?.adjust_experience(/datum/skill/smithing, 5)
			user.balloon_alert(user, "ore smelted")
	busy = FALSE

/obj/structure/smithing_station/forge/proc/imbue_gear(mob/living/user, obj/item/gear, datum/component/smithing_infusion/infusion)
	if(busy || reagent_cores < 3 || temperature < SMITHING_MIN_HEAT || QDELETED(infusion) || length(infusion.imbued_reagents))
		user.balloon_alert(user, "need a hot reagent forge and unimbued gear!")
		return
	busy = TRUE
	if(do_after(user, 10 SECONDS, src) && !QDELETED(src) && !QDELETED(gear) && !QDELETED(infusion) && user.is_holding(gear) && temperature >= SMITHING_MIN_HEAT)
		if(infusion.seal_infusion())
			user.balloon_alert(user, "gear imbued")
			user.mind?.adjust_experience(/datum/skill/smithing, 60)
		else
			user.balloon_alert(user, "need 100 units of an eligible reagent!")
	busy = FALSE

/obj/structure/smithing_station/anvil
	name = "smithing anvil"
	desc = "Set a hot blank on the anvil with tongs. Use a forging hammer to work it until the metal sounds ready."
	icon_state = "anvil_empty"
	frame_type = /obj/item/smithing_frame/anvil

/obj/structure/smithing_station/anvil/update_overlays()
	. = ..()
	var/obj/item/smithing_blank/blank = locate() in contents
	if(blank)
		var/mutable_appearance/part_overlay = mutable_appearance(blank.icon, blank.icon_state)
		part_overlay.color = blank.color
		. += part_overlay

/obj/structure/smithing_station/anvil/examine(mob/user)
	. = ..()
	var/obj/item/smithing_blank/blank = locate() in contents
	if(blank)
		. += blank.examine(user)

/obj/structure/smithing_station/anvil/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	var/obj/item/smithing_blank/blank = locate() in contents
	if(busy)
		user.balloon_alert(user, "anvil in use!")
		return ITEM_INTERACT_BLOCKING
	if(istype(tool, /obj/item/smithing_tongs))
		var/obj/item/smithing_blank/held_blank = locate() in tool.contents
		if(blank && !length(tool.contents))
			blank.forceMove(tool)
		else if(!blank && held_blank && !held_blank.quenched)
			held_blank.forceMove(src)
		else
			return ITEM_INTERACT_BLOCKING
		update_appearance(UPDATE_OVERLAYS)
		return ITEM_INTERACT_SUCCESS
	if(!istype(tool, /obj/item/carpenter_hammer/smithing))
		return ..()
	if(!blank || blank.strikes >= blank.required_strikes || world.time >= blank.hot_until)
		user.balloon_alert(user, !blank ? "place a blank first!" : (blank.strikes >= blank.required_strikes ? "ready to quench!" : "reheat the blank!"))
		return ITEM_INTERACT_BLOCKING
	INVOKE_ASYNC(src, PROC_REF(hammer_blank), user, tool, blank)
	return ITEM_INTERACT_SUCCESS

// Adapted from Nova's interruptible, skill-scaled anvil hammering.
/obj/structure/smithing_station/anvil/proc/hammer_blank(mob/living/user, obj/item/tool, obj/item/smithing_blank/blank)
	if(busy || QDELETED(blank) || blank.loc != src)
		return
	busy = TRUE
	var/skill_modifier = user.mind?.get_skill_modifier(/datum/skill/smithing, SKILL_SPEED_MODIFIER) || 1
	while(blank.strikes < blank.required_strikes)
		if(!do_after(user, skill_modifier * blank.strike_delay * tool.toolspeed, src))
			break
		if(QDELETED(src) || QDELETED(blank) || blank.loc != src || !user.is_holding(tool))
			break
		if(world.time >= blank.hot_until)
			blank.strikes = max(0, blank.strikes - 3)
			user.balloon_alert(user, "metal too cool!")
			break
		playsound(src, 'sound/items/smithing/forge.ogg', 45, TRUE)
		blank.strikes++
		user.mind?.adjust_experience(/datum/skill/smithing, 1)
	if(!QDELETED(blank) && blank.strikes >= blank.required_strikes)
		user.balloon_alert(user, "workpiece sounds ready")
	busy = FALSE

/obj/structure/smithing_station/basin
	name = "quench basin"
	desc = "A water basin for cooling shaped metal. Quenched parts are ready for assembly at a workbench."
	icon_state = "water_basin"
	frame_type = /obj/item/smithing_frame/basin

/obj/structure/smithing_station/basin/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(!istype(tool, /obj/item/smithing_tongs))
		return ..()
	var/obj/item/smithing_blank/blank = locate() in tool.contents
	if(!blank || blank.quenched)
		return ITEM_INTERACT_BLOCKING
	playsound(src, 'sound/items/smithing/hot_hiss.ogg', 45, TRUE)
	blank.hot_until = 0
	if(blank.strikes < blank.required_strikes)
		user.balloon_alert(user, "blank cooled before it was ready!")
		return ITEM_INTERACT_SUCCESS
	var/list/pattern = GLOB.smithing_parts[blank.part_kind]
	blank.quenched = TRUE
	blank.name = lowertext(blank.part_kind)
	blank.icon_state = pattern["sprite"]
	blank.forceMove(drop_location())
	user.mind?.adjust_experience(/datum/skill/smithing, 10)
	user.balloon_alert(user, "part ready for assembly")
	return ITEM_INTERACT_SUCCESS

#undef SMITHING_MIN_HEAT
#undef SMITHING_MAX_HEAT
