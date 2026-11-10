/// The forge offers the same patterns in iron and masterwork titanium.
GLOBAL_LIST_INIT(smithing_patterns, list(
	"Katana" = list("output" = /obj/item/katana/forged, "sheets" = 5, "strikes" = 6),
	"Claymore" = list("output" = /obj/item/claymore/forged, "sheets" = 6, "strikes" = 7),
	"Broadsword" = list("output" = /obj/item/claymore/forged_broadsword, "sheets" = 5, "strikes" = 6),
	"Dagger" = list("output" = /obj/item/knife/combat/forged_dagger, "sheets" = 2, "strikes" = 3),
	"Shortsword" = list("output" = /obj/item/claymore/shortsword/forged, "sheets" = 3, "strikes" = 4),
	"Shield" = list("output" = /obj/item/shield/roman/forged, "sheets" = 5, "strikes" = 5),
	"Chestplate" = list("output" = /obj/item/clothing/suit/armor/vest/cuirass/forged, "sheets" = 6, "strikes" = 7),
	"Helmet" = list("output" = /obj/item/clothing/head/helmet/knight/forged, "sheets" = 4, "strikes" = 5),
	"Warhammer" = list("output" = /obj/item/carpenter_hammer/forged_warhammer, "sheets" = 6, "strikes" = 7),
	"Seed Sieve" = list("output" = /obj/item/seed_sieve, "sheets" = 2, "strikes" = 3),
))

/obj/item/storage/box/smithing_kit
	name = "blacksmith workshop kit"
	desc = "A portable forge, anvil, and quench basin with smithing tools and starter supplies. Unpack the frames and use each on a clear floor tile."

/obj/item/storage/box/smithing_kit/PopulateContents()
	new /obj/item/smithing_frame/forge(src)
	new /obj/item/smithing_frame/anvil(src)
	new /obj/item/smithing_frame/basin(src)
	new /obj/item/smithing_tongs(src)
	new /obj/item/carpenter_hammer/smithing(src)
	new /obj/item/stack/sheet/iron/ten(src)
	new /obj/item/stack/sheet/mineral/wood(src, 6)

/datum/supply_pack/misc/blacksmith_kit
	name = "Blacksmith Workshop Kit"
	desc = "A portable smithing workshop with tongs, a hammer, and enough fuel and iron for the first few patterns."
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
	/// The station assembled by using this frame.
	var/station_type

/obj/item/smithing_frame/forge
	name = "folded forge frame"
	station_type = /obj/structure/smithing_station/forge

/obj/item/smithing_frame/anvil
	name = "folded anvil frame"
	station_type = /obj/structure/smithing_station/anvil

/obj/item/smithing_frame/basin
	name = "folded quench basin frame"
	station_type = /obj/structure/smithing_station/basin

/obj/item/smithing_frame/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!isturf(interacting_with) || SHOULD_SKIP_INTERACTION(interacting_with, src, user))
		return NONE
	var/turf/open/floor/site = interacting_with
	if(!istype(site) || site.is_blocked_turf())
		user.balloon_alert(user, "clear floor needed!")
		return ITEM_INTERACT_BLOCKING
	if(!do_after(user, 2 SECONDS, site))
		return ITEM_INTERACT_BLOCKING
	if(QDELETED(src) || !user.is_holding(src) || !user.can_perform_action(site) || site.is_blocked_turf())
		return ITEM_INTERACT_BLOCKING
	new station_type(site)
	qdel(src)
	return ITEM_INTERACT_SUCCESS

/obj/item/carpenter_hammer/smithing
	name = "smithing hammer"
	desc = "A small hammer for shaping hot metal on an anvil. Pause between blows and listen for the change in tone."
	force = 8
	w_class = WEIGHT_CLASS_SMALL

/obj/item/smithing_tongs
	name = "smithing tongs"
	desc = "Use empty tongs on the forge to cast a blank. Carry the hot blank to an anvil and then to a quench basin."
	icon = 'icons/obj/medical/surgery_tools.dmi'
	icon_state = "hemostat"
	inhand_icon_state = "hemostat"
	lefthand_file = 'icons/mob/inhands/equipment/medical_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/medical_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL

/obj/item/smithing_tongs/examine(mob/user)
	. = ..()
	var/obj/item/smithing_blank/blank = locate() in contents
	if(blank)
		. += blank.examine(user)

/obj/item/smithing_tongs/attack_self(mob/user, modifiers)
	var/obj/item/smithing_blank/blank = locate() in contents
	if(blank)
		blank.forceMove(drop_location())
		user.balloon_alert(user, "blank released")
		return
	return ..()

/obj/item/smithing_tongs/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	var/obj/item/smithing_blank/blank = interacting_with
	if(!istype(blank) || SHOULD_SKIP_INTERACTION(interacting_with, src, user))
		return NONE
	if(length(contents))
		user.balloon_alert(user, "tongs already loaded!")
		return ITEM_INTERACT_BLOCKING
	if(blank.loc == user)
		if(!user.temporarilyRemoveItemFromInventory(blank, newloc = src))
			return ITEM_INTERACT_BLOCKING
	else if(isturf(blank.loc))
		blank.forceMove(src)
	else
		return ITEM_INTERACT_BLOCKING
	return ITEM_INTERACT_SUCCESS

/obj/item/smithing_tongs/Destroy(force)
	var/obj/item/smithing_blank/blank = locate() in contents
	blank?.forceMove(drop_location())
	return ..()

/obj/item/smithing_blank
	name = "cast blank"
	desc = "A cast metal blank awaiting the hammer and quench."
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-metal"
	w_class = WEIGHT_CLASS_SMALL
	abstract_type = /obj/item/smithing_blank
	/// The final item path selected from the pattern list when this blank was cast.
	var/output_type
	var/masterwork = FALSE
	var/hot_until = 0
	var/strikes = 0
	var/required_strikes = 0
	var/next_strike = 0

/obj/item/smithing_blank/Initialize(mapload, pattern_name, list/pattern, make_masterwork)
	. = ..()
	if(!pattern)
		return
	name = "[lowertext(pattern_name)] blank"
	output_type = pattern["output"]
	masterwork = make_masterwork
	required_strikes = pattern["strikes"] + (masterwork ? 3 : 0)
	hot_until = world.time + 45 SECONDS

/obj/item/smithing_blank/examine(mob/user)
	. = ..()
	. += span_notice("[masterwork ? "Masterwork titanium" : "Standard iron"] • [strikes]/[required_strikes] strikes • [world.time < hot_until ? "hot" : "cold"].")

/obj/item/smithing_blank/attack_hand(mob/living/user, list/modifiers)
	if(world.time < hot_until)
		user.balloon_alert(user, "too hot to handle!")
		return TRUE
	return ..()

/obj/structure/smithing_station
	abstract_type = /obj/structure/smithing_station
	anchored = TRUE
	density = TRUE
	max_integrity = 200

/obj/structure/smithing_station/forge
	name = "smithing forge"
	desc = "Load iron or titanium sheets for casting and wood or coal for heat. Use empty tongs to choose a pattern or loaded tongs to reheat a blank."
	icon = 'icons/obj/machines/kitchen.dmi'
	icon_state = "grill_open"
	var/iron = 0
	var/titanium = 0
	/// One heat charge per cast or reheat. Wood provides one and coal provides three.
	var/fuel = 0

/obj/structure/smithing_station/forge/examine(mob/user)
	. = ..()
	. += span_notice("[iron] iron sheets, [titanium] titanium sheets, and [fuel] heat charges loaded.")

/obj/structure/smithing_station/forge/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(istype(tool, /obj/item/smithing_tongs))
		var/obj/item/smithing_tongs/tongs = tool
		var/obj/item/smithing_blank/blank = locate() in tongs.contents
		if(!blank)
			INVOKE_ASYNC(src, PROC_REF(select_pattern), user, tongs)
			return ITEM_INTERACT_SUCCESS
		if(world.time < blank.hot_until)
			user.balloon_alert(user, "blank is already hot!")
			return ITEM_INTERACT_BLOCKING
		if(!fuel)
			user.balloon_alert(user, "load wood or coal!")
			return ITEM_INTERACT_BLOCKING
		fuel--
		blank.hot_until = world.time + 45 SECONDS
		user.balloon_alert(user, "blank reheated")
		playsound(src, 'sound/machines/grill/grillsizzle.ogg', 35, TRUE)
		return ITEM_INTERACT_SUCCESS
	var/obj/item/stack/material = tool
	if(!istype(material))
		return ..()
	var/amount = material.get_amount()
	if(amount <= 0)
		return ITEM_INTERACT_BLOCKING
	if(istype(material, /obj/item/stack/sheet/iron))
		if(!material.use(amount))
			return ITEM_INTERACT_BLOCKING
		iron += amount
	else if(istype(material, /obj/item/stack/sheet/mineral/titanium))
		if(!material.use(amount))
			return ITEM_INTERACT_BLOCKING
		titanium += amount
	else if(istype(material, /obj/item/stack/sheet/mineral/wood) || istype(material, /obj/item/stack/sheet/mineral/coal))
		var/heat_per_piece = istype(material, /obj/item/stack/sheet/mineral/coal) ? 3 : 1
		if(!material.use(amount))
			return ITEM_INTERACT_BLOCKING
		fuel += amount * heat_per_piece
	else
		return ..()
	user.balloon_alert(user, "forge loaded")
	return ITEM_INTERACT_SUCCESS

/obj/structure/smithing_station/forge/proc/select_pattern(mob/living/user, obj/item/smithing_tongs/tongs)
	var/list/choices = list()
	for(var/pattern_name in GLOB.smithing_patterns)
		var/list/pattern = GLOB.smithing_patterns[pattern_name]
		choices["[pattern_name] ([pattern["sheets"]] iron / [pattern["sheets"] + 2] titanium)"] = pattern_name
	var/choice = tgui_input_list(user, "Choose a pattern for your blank.", "Smithing Forge", choices)
	var/pattern_name = choices[choice]
	if(!pattern_name || QDELETED(src) || QDELETED(tongs) || !user.is_holding(tongs) || !user.can_perform_action(src))
		return
	var/quality = tgui_input_list(user, "Choose iron for standard work or titanium for masterwork.", "Casting Material", list("Standard Iron", "Masterwork Titanium"))
	if(!quality || QDELETED(src) || QDELETED(tongs) || !user.is_holding(tongs) || !user.can_perform_action(src))
		return
	if(!cast_blank(tongs, pattern_name, quality == "Masterwork Titanium"))
		user.balloon_alert(user, "need empty tongs, metal, and fuel!")
		return
	user.balloon_alert(user, "hot blank cast")
	playsound(src, 'sound/machines/grill/grillsizzle.ogg', 35, TRUE)

/// Recheck the current inventory after the selection menus close. Commit metal and heat together.
/obj/structure/smithing_station/forge/proc/cast_blank(obj/item/smithing_tongs/tongs, pattern_name, masterwork = FALSE)
	var/list/pattern = GLOB.smithing_patterns[pattern_name]
	if(!pattern || QDELETED(tongs) || length(tongs.contents) || fuel <= 0)
		return FALSE
	var/cost = pattern["sheets"]
	if(masterwork)
		cost += 2
		if(titanium < cost)
			return FALSE
		titanium -= cost
	else
		if(iron < cost)
			return FALSE
		iron -= cost
	fuel--
	new /obj/item/smithing_blank(tongs, pattern_name, pattern, masterwork)
	return TRUE

/obj/structure/smithing_station/anvil
	name = "smithing anvil"
	desc = "Set down a hot blank with the tongs. Strike it with a smithing hammer, letting the ring fade between blows."
	icon = 'icons/obj/smooth_structures/table.dmi'
	icon_state = "table-0"

/obj/structure/smithing_station/anvil/examine(mob/user)
	. = ..()
	var/obj/item/smithing_blank/blank = locate() in contents
	if(blank)
		. += blank.examine(user)

/obj/structure/smithing_station/anvil/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	var/obj/item/smithing_blank/blank = locate() in contents
	if(istype(tool, /obj/item/smithing_tongs))
		var/obj/item/smithing_blank/held_blank = locate() in tool.contents
		if(blank && !held_blank)
			blank.forceMove(tool)
			return ITEM_INTERACT_SUCCESS
		if(!blank && held_blank)
			held_blank.forceMove(src)
			return ITEM_INTERACT_SUCCESS
		user.balloon_alert(user, blank ? "anvil occupied!" : "load a blank first!")
		return ITEM_INTERACT_BLOCKING
	if(!istype(tool, /obj/item/carpenter_hammer/smithing))
		return ..()
	if(!blank)
		user.balloon_alert(user, "place a blank first!")
		return ITEM_INTERACT_BLOCKING
	if(blank.strikes >= blank.required_strikes)
		user.balloon_alert(user, "ready to quench!")
		return ITEM_INTERACT_BLOCKING
	if(world.time >= blank.hot_until)
		user.balloon_alert(user, "reheat the blank!")
		return ITEM_INTERACT_BLOCKING
	if(world.time < blank.next_strike)
		user.balloon_alert(user, "let the ring fade!")
		return ITEM_INTERACT_BLOCKING
	blank.strikes++
	blank.next_strike = world.time + 1 SECONDS
	playsound(src, 'sound/effects/clang.ogg', 45, TRUE)
	user.balloon_alert(user, blank.strikes == blank.required_strikes ? "ready to quench!" : "[blank.strikes]/[blank.required_strikes] strikes")
	return ITEM_INTERACT_SUCCESS

/obj/structure/smithing_station/anvil/Destroy(force)
	var/obj/item/smithing_blank/blank = locate() in contents
	blank?.forceMove(drop_location())
	return ..()

/obj/structure/smithing_station/basin
	name = "quench basin"
	desc = "Quench a shaped, hot blank in 10 units of water using tongs. Add at least 20 units of one other reagent to infuse a weapon or piece of armor. Alt-click to drain the bath."
	icon = 'icons/obj/watercloset.dmi'
	icon_state = "sink"

/obj/structure/smithing_station/basin/Initialize(mapload)
	. = ..()
	create_reagents(100, OPENCONTAINER)
	reagents.add_reagent(/datum/reagent/water, 50)

/obj/structure/smithing_station/basin/click_alt(mob/living/user)
	if(!user.can_perform_action(src))
		return NONE
	reagents.clear_reagents()
	user.balloon_alert(user, "bath drained")
	return CLICK_ACTION_SUCCESS

/obj/structure/smithing_station/basin/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(!istype(tool, /obj/item/smithing_tongs))
		return ..()
	var/obj/item/smithing_blank/blank = locate() in tool.contents
	if(!blank?.output_type || blank.strikes < blank.required_strikes)
		user.balloon_alert(user, "shape a blank first!")
		return ITEM_INTERACT_BLOCKING
	if(world.time >= blank.hot_until)
		user.balloon_alert(user, "reheat the blank!")
		return ITEM_INTERACT_BLOCKING
	if(reagents.get_reagent_amount(/datum/reagent/water) < 10)
		user.balloon_alert(user, "need 10 units of water!")
		return ITEM_INTERACT_BLOCKING
	var/datum/reagent/additive
	for(var/datum/reagent/chemical as anything in reagents.reagent_list)
		if(chemical.type == /datum/reagent/water)
			continue
		if(additive || chemical.volume < 20)
			user.balloon_alert(user, "use 20 units of one additive!")
			return ITEM_INTERACT_BLOCKING
		additive = chemical
	if(additive && ispath(blank.output_type, /obj/item/seed_sieve))
		user.balloon_alert(user, "this pattern needs plain water!")
		return ITEM_INTERACT_BLOCKING
	var/obj/item/finished = new blank.output_type(drop_location())
	blank.finish_item(finished)
	if(additive)
		finished.create_reagents(20, NO_REACT)
		reagents.trans_to(finished, 20, target_id = additive.type, no_react = TRUE)
		var/armor_slot = NONE
		if(istype(finished, /obj/item/clothing/head))
			armor_slot = ITEM_SLOT_HEAD
		else if(istype(finished, /obj/item/clothing/suit))
			armor_slot = ITEM_SLOT_OCLOTHING
		finished.AddComponent(/datum/component/smithing_infusion, armor_slot)
	reagents.remove_reagent(/datum/reagent/water, 10)
	qdel(blank)
	playsound(src, 'sound/effects/wounds/sizzle1.ogg', 40, TRUE)
	to_chat(user, span_notice("You quench the blank and finish [finished]."))
	return ITEM_INTERACT_SUCCESS
