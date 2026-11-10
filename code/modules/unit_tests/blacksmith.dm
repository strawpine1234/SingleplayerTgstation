/// Verify the Nova-style parts workflow and permanent reagent armor.
/datum/unit_test/blacksmith_workshop

/datum/unit_test/blacksmith_workshop/Run()
	var/datum/job/blacksmith/job = SSjob.get_job_type(/datum/job/blacksmith)
	TEST_ASSERT_NOTNULL(job, "Blacksmith must be registered.")
	var/mob/living/carbon/human/smith = allocate(/mob/living/carbon/human/consistent)
	smith.equipOutfit(job.outfit)
	var/obj/item/storage/box/smithing_kit/kit = locate() in smith.back?.contents
	TEST_ASSERT_NOTNULL(kit, "The Blacksmith outfit must supply a workshop kit.")
	TEST_ASSERT(locate(/obj/item/smithing_frame/bench) in kit.contents, "The kit must include the separate workbench.")
	var/obj/item/smithing_tongs/tongs = locate() in kit.contents
	var/obj/item/smithing_bellows/bellows = locate() in kit.contents
	var/obj/item/carpenter_hammer/smithing/hammer = locate() in kit.contents
	TEST_ASSERT_NOTNULL(tongs, "The kit must supply tongs.")
	TEST_ASSERT_NOTNULL(bellows, "The kit must supply bellows.")
	TEST_ASSERT_NOTNULL(hammer, "The kit must supply a hammer.")
	var/obj/structure/smithing_station/forge/forge = allocate(/obj/structure/smithing_station/forge)
	var/obj/structure/smithing_station/anvil/anvil = allocate(/obj/structure/smithing_station/anvil)
	var/obj/structure/smithing_station/basin/basin = allocate(/obj/structure/smithing_station/basin)
	var/obj/structure/smithing_station/bench/bench = allocate(/obj/structure/smithing_station/bench)
	var/obj/item/stack/sheet/mineral/wood/fuel = allocate(/obj/item/stack/sheet/mineral/wood, run_loc_floor_bottom_left, 12)
	TEST_ASSERT_EQUAL(forge.item_interaction(smith, fuel), ITEM_INTERACT_SUCCESS, "The forge must accept wood as fuel.")
	forge.process(10)
	TEST_ASSERT_EQUAL(forge.temperature, 50, "Unstoked wood must stop at 50.")
	smith.put_in_active_hand(tongs)
	var/obj/item/stack/rods/rods = allocate(/obj/item/stack/rods, run_loc_floor_bottom_left, 2)
	TEST_ASSERT_EQUAL(tongs.interact_with_atom(rods, smith), ITEM_INTERACT_SUCCESS, "Tongs must lift a rod from a stack.")
	TEST_ASSERT_EQUAL(rods.amount, 1, "Tongs must lift exactly one unit.")
	var/obj/item/stack/rod = locate() in tongs.contents
	TEST_ASSERT(!forge.cast_part(tongs, rod, "Plate"), "A wood fire needs bellows before metal can be worked.")
	TEST_ASSERT_EQUAL(forge.item_interaction(smith, bellows), ITEM_INTERACT_SUCCESS, "Bellows must stoke the fire.")
	TEST_ASSERT(forge.cast_part(tongs, rod, "Plate"), "A hot forge must form a blank from the rod.")
	var/obj/item/smithing_blank/blank = locate() in tongs.contents
	TEST_ASSERT_EQUAL(basin.item_interaction(smith, tongs), ITEM_INTERACT_SUCCESS, "Early quenching must cool the blank.")
	TEST_ASSERT(!blank.quenched && blank.hot_until == 0, "An unfinished part must stay unfinished.")
	blank.hot_until = world.time + 1 MINUTES
	blank.strikes = blank.required_strikes - 1
	TEST_ASSERT_EQUAL(anvil.item_interaction(smith, tongs), ITEM_INTERACT_SUCCESS, "Tongs must place the hot blank on the anvil.")
	smith.dropItemToGround(tongs)
	smith.put_in_active_hand(hammer)
	anvil.hammer_blank(smith, hammer, blank)
	TEST_ASSERT_EQUAL(blank.strikes, blank.required_strikes, "Anvil hammering must finish shaping the blank.")
	TEST_ASSERT_EQUAL(anvil.item_interaction(smith, tongs), ITEM_INTERACT_SUCCESS, "Tongs must retrieve the shaped blank.")
	TEST_ASSERT_EQUAL(basin.item_interaction(smith, tongs), ITEM_INTERACT_SUCCESS, "The basin must quench shaped metal.")
	TEST_ASSERT(blank.quenched, "Quenching must produce an assembly part.")
	qdel(blank)

	var/list/static_data = bench.ui_static_data(smith)
	var/list/ui_recipes = static_data["recipes"]
	TEST_ASSERT_EQUAL(length(ui_recipes), length(GLOB.smithing_assembly_patterns), "The recipe list must show every pattern on an empty bench.")
	var/list/ui_recipes_by_name = list()
	for(var/list/ui_recipe as anything in ui_recipes)
		ui_recipes_by_name[ui_recipe["name"]] = ui_recipe

	for(var/pattern in GLOB.smithing_assembly_patterns)
		var/list/recipe = GLOB.smithing_assembly_patterns[pattern]
		TEST_ASSERT(!bench.finish_pattern(pattern), "Assembly must require the recipe's parts.")
		var/list/parts = recipe["parts"]
		var/list/ui_recipe = ui_recipes_by_name[pattern]
		TEST_ASSERT_NOTNULL(ui_recipe, "The workbench UI must list [pattern].")
		TEST_ASSERT_EQUAL(ui_recipe["strikes"], recipe["strikes"], "The workbench UI must show the correct strike count for [pattern].")
		var/list/ui_materials = list()
		for(var/list/material as anything in ui_recipe["materials"])
			ui_materials[material["name"]] = material["amount"]
		for(var/part_kind in parts)
			TEST_ASSERT_EQUAL(ui_materials[part_kind], parts[part_kind], "The workbench UI must show the correct amount of [part_kind] for [pattern].")
			for(var/index in 1 to parts[part_kind])
				var/obj/item/smithing_blank/part = new(bench, part_kind, list(/datum/material/iron = HALF_SHEET_MATERIAL_AMOUNT))
				part.quenched = TRUE
		if(recipe["wood"])
			new /obj/item/stack/sheet/mineral/wood(bench, recipe["wood"])
		TEST_ASSERT_EQUAL(ui_materials["Wood planks"], recipe["wood"], "The workbench UI must show the correct wood requirement for [pattern].")
		var/list/ui_data = bench.ui_data(smith)
		var/list/loaded = ui_data["loaded"]
		for(var/material in ui_materials)
			TEST_ASSERT_EQUAL(loaded[material], ui_materials[material], "The workbench UI must count the loaded [material].")
		TEST_ASSERT(bench.finish_pattern(pattern), "The bench must assemble [pattern].")
		TEST_ASSERT(istype(bench.assembled_item, recipe["output"]), "Assembly must produce the correct item.")
		TEST_ASSERT(!bench.finish_pattern(pattern), "The same components must not yield a second item.")
		if(pattern == "Chestplate")
			verify_infusion(bench.assembled_item)
		qdel(bench.assembled_item)
		bench.assembled_item = null

/datum/unit_test/blacksmith_workshop/proc/verify_infusion(obj/item/chestplate)
	var/datum/component/smithing_infusion/infusion = chestplate.GetComponent(/datum/component/smithing_infusion)
	TEST_ASSERT_NOTNULL(infusion, "Forged armor must accept reagent imbuing.")
	chestplate.reagents.add_reagent(/datum/reagent/medicine/salbutamol, 99)
	TEST_ASSERT(!infusion.seal_infusion(), "The forge must require the full reagent amount.")
	chestplate.reagents.add_reagent(/datum/reagent/medicine/salbutamol, 1)
	TEST_ASSERT(infusion.seal_infusion(), "A full reagent load must imbue the armor.")
	TEST_ASSERT_EQUAL(chestplate.reagents.total_volume, 0, "Imbuing must consume the loading reservoir.")
	TEST_ASSERT(!infusion.seal_infusion(), "A finished infusion cannot be replaced.")
	var/mob/living/carbon/human/wearer = allocate(/mob/living/carbon/human/consistent)
	wearer.equip_to_slot(chestplate, ITEM_SLOT_OCLOTHING)
	infusion.process(1)
	infusion.next_dose = 0
	infusion.process(1)
	TEST_ASSERT_EQUAL(wearer.reagents.get_reagent_amount(/datum/reagent/medicine/salbutamol), 1, "Worn armor must regenerate its half-unit doses.")

/datum/unit_test/blacksmith_seed_sieve

/datum/unit_test/blacksmith_seed_sieve/Run()
	var/mob/living/carbon/human/smith = allocate(/mob/living/carbon/human/consistent)
	var/obj/item/seed_sieve/sieve = allocate(/obj/item/seed_sieve)
	var/obj/item/food/grown/tomato/produce = allocate(/obj/item/food/grown/tomato)
	var/obj/item/seeds/parent_seed = produce.get_plant_seed()
	TEST_ASSERT_NOTNULL(parent_seed, "The test crop must have a seed.")
	parent_seed.potency = 47
	smith.put_in_active_hand(sieve)
	TEST_ASSERT_EQUAL(sieve.interact_with_atom(produce, smith), ITEM_INTERACT_SUCCESS, "The sieve must process harvested produce.")
	TEST_ASSERT(QDELETED(produce), "Sifting must consume the produce.")
	var/seeds_found = 0
	for(var/obj/item/seeds/tomato/seed in run_loc_floor_bottom_left)
		seeds_found++
		TEST_ASSERT_EQUAL(seed.potency, 47, "The sieve must copy the crop's seed traits.")
		TEST_ASSERT_EQUAL(sieve.interact_with_atom(seed, smith), NONE, "The sieve must not duplicate existing seed packets.")
	TEST_ASSERT_EQUAL(seeds_found, 2, "The standard sieve must produce two seed packets.")

/// Exercise actual sheet pickup, casting, and the finished weapon stats for different materials.
/datum/unit_test/blacksmith_materials/Run()
	var/mob/living/carbon/human/smith = allocate(/mob/living/carbon/human/consistent)
	var/obj/item/smithing_tongs/tongs = allocate(/obj/item/smithing_tongs)
	var/obj/structure/smithing_station/forge/forge = allocate(/obj/structure/smithing_station/forge)
	var/obj/structure/smithing_station/bench/bench = allocate(/obj/structure/smithing_station/bench)
	smith.put_in_active_hand(tongs)
	forge.temperature = 80

	var/list/sheet_types = list(
		/obj/item/stack/sheet/iron,
		/obj/item/stack/sheet/rglass,
		/obj/item/stack/sheet/cloth,
		/obj/item/stack/sheet/bluespace_crystal,
		/obj/item/stack/sheet/mineral/diamond,
		/obj/item/stack/sheet/mineral/mythril,
		/obj/item/stack/sheet/animalhide/ashdrake,
	)
	var/list/weapons = list()
	for(var/sheet_type in sheet_types)
		var/obj/item/stack/sheet/stock = allocate(sheet_type, run_loc_floor_bottom_left, 2, FALSE)
		TEST_ASSERT_EQUAL(tongs.interact_with_atom(stock, smith), ITEM_INTERACT_SUCCESS, "Tongs must accept [sheet_type].")
		TEST_ASSERT_EQUAL(stock.get_amount(), 1, "Tongs must take exactly one sheet.")
		var/obj/item/stack/sheet/piece = locate() in tongs.contents
		TEST_ASSERT(forge.cast_part(tongs, piece, "Katana blade"), "The forge must cast [sheet_type].")
		var/obj/item/smithing_blank/part = locate() in tongs.contents
		TEST_ASSERT_NOTNULL(part, "Casting must produce a blank.")
		part.quenched = TRUE
		part.forceMove(bench)
		new /obj/item/stack/sheet/mineral/wood(bench, 2)
		TEST_ASSERT(bench.finish_pattern("Katana"), "A [sheet_type] blade must assemble.")
		weapons[sheet_type] = bench.assembled_item
		bench.assembled_item.forceMove(run_loc_floor_bottom_left)
		bench.assembled_item = null

	var/obj/item/katana/forged/iron = weapons[/obj/item/stack/sheet/iron]
	var/obj/item/katana/forged/glass = weapons[/obj/item/stack/sheet/rglass]
	var/obj/item/katana/forged/cloth = weapons[/obj/item/stack/sheet/cloth]
	var/obj/item/katana/forged/bluespace = weapons[/obj/item/stack/sheet/bluespace_crystal]
	var/obj/item/katana/forged/diamond = weapons[/obj/item/stack/sheet/mineral/diamond]
	var/obj/item/katana/forged/mythril = weapons[/obj/item/stack/sheet/mineral/mythril]
	var/obj/item/katana/forged/drake = weapons[/obj/item/stack/sheet/animalhide/ashdrake]
	TEST_ASSERT_EQUAL(iron.force, initial(iron.force), "Common iron must keep the baseline melee damage.")
	TEST_ASSERT_EQUAL(cloth.force, iron.force, "Sheets without registered materials must have common-tier damage.")
	TEST_ASSERT(findtext(cloth.name, "cloth"), "Untracked materials must retain their names.")
	TEST_ASSERT_EQUAL(length(glass.custom_materials), 2, "Reinforced glass must retain both constituent materials.")
	TEST_ASSERT(glass.armour_penetration > iron.armour_penetration && glass.armour_penetration < diamond.armour_penetration, "Mixed stock must receive proportionate bonuses.")
	TEST_ASSERT(bluespace.attack_speed < iron.attack_speed, "Bluespace weapons must swing faster.")
	TEST_ASSERT(diamond.force > bluespace.force && bluespace.force > iron.force, "Rare stock must increase damage in value order.")
	TEST_ASSERT_EQUAL(mythril.force, iron.force + 9, "The rarest stock must reach the damage cap.")
	TEST_ASSERT_EQUAL(drake.force, iron.force + 8, "Rare sheets without material datums must still get a rarity bonus.")
	TEST_ASSERT(!mythril.GetComponent(/datum/component/fantasy), "Mythril smithing must apply controlled bonuses.")

	for(var/index in 1 to 4)
		var/material = index <= 2 ? /datum/material/diamond : /datum/material/iron
		var/list/materials = list()
		materials[material] = SHEET_MATERIAL_AMOUNT
		var/obj/item/smithing_blank/plate = new(bench, "Plate", materials)
		plate.quenched = TRUE
	TEST_ASSERT(bench.finish_pattern("Helmet"), "The bench must accept plates of mixed materials.")
	var/obj/item/clothing/head/helmet/knight/forged/helmet = bench.assembled_item
	var/datum/armor/base_armor = get_armor_by_type(initial(helmet.armor_type))
	TEST_ASSERT_EQUAL(helmet.get_armor_rating("melee"), base_armor.get_rating("melee") + 4, "Two diamond plates out of four must grant half the full melee protection bonus.")
	TEST_ASSERT_EQUAL(helmet.get_armor_rating("wound"), base_armor.get_rating("wound"), "Forging bonuses must preserve other armor ratings.")
	for(var/sheet_type in weapons)
		qdel(weapons[sheet_type])
