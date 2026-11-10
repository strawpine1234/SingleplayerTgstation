/// Verify that casting, hammering, and quenching consume a blank only after it is ready.
/datum/unit_test/blacksmith_workshop

/datum/unit_test/blacksmith_workshop/Run()
	var/datum/job/blacksmith/job = SSjob.get_job_type(/datum/job/blacksmith)
	TEST_ASSERT_NOTNULL(job, "Blacksmith must be registered as a station job.")
	var/mob/living/carbon/human/smith = allocate(/mob/living/carbon/human/consistent)
	smith.equipOutfit(job.outfit)
	var/obj/item/storage/box/smithing_kit/kit = locate() in smith.back?.contents
	TEST_ASSERT_NOTNULL(kit, "The Blacksmith outfit must supply a workshop kit.")
	TEST_ASSERT(locate(/obj/item/smithing_frame/forge) in kit.contents, "The kit must include a forge frame.")
	TEST_ASSERT(locate(/obj/item/smithing_frame/anvil) in kit.contents, "The kit must include an anvil frame.")
	TEST_ASSERT(locate(/obj/item/smithing_frame/basin) in kit.contents, "The kit must include a basin frame.")
	var/obj/item/smithing_tongs/tongs = locate() in kit.contents
	var/obj/item/carpenter_hammer/smithing/hammer = locate() in kit.contents
	TEST_ASSERT_NOTNULL(tongs, "The kit must supply tongs.")
	TEST_ASSERT_NOTNULL(hammer, "The kit must supply a smithing hammer.")
	var/obj/structure/smithing_station/forge/forge = allocate(/obj/structure/smithing_station/forge)
	var/obj/structure/smithing_station/anvil/anvil = allocate(/obj/structure/smithing_station/anvil)
	var/obj/structure/smithing_station/basin/basin = allocate(/obj/structure/smithing_station/basin)
	forge.iron = 50
	forge.fuel = 12
	TEST_ASSERT(!forge.cast_blank(tongs, "Katana", TRUE), "A masterwork must require titanium.")
	TEST_ASSERT_EQUAL(forge.fuel, 12, "An unaffordable cast must leave the fuel alone.")
	for(var/pattern_name in GLOB.smithing_patterns)
		var/list/pattern = GLOB.smithing_patterns[pattern_name]
		var/starting_iron = forge.iron
		TEST_ASSERT(forge.cast_blank(tongs, pattern_name), "The forge must cast [pattern_name].")
		TEST_ASSERT_EQUAL(forge.iron, starting_iron - pattern["sheets"], "The cast must consume the advertised metal.")
		TEST_ASSERT(!forge.cast_blank(tongs, pattern_name), "Loaded tongs cannot receive a second blank.")
		var/obj/item/smithing_blank/blank = locate() in tongs.contents
		TEST_ASSERT_EQUAL(basin.item_interaction(smith, tongs), ITEM_INTERACT_BLOCKING, "A raw blank cannot be quenched.")
		TEST_ASSERT_EQUAL(anvil.item_interaction(smith, tongs), ITEM_INTERACT_SUCCESS, "Tongs must place the blank on the anvil.")
		for(var/strike in 1 to blank.required_strikes)
			blank.next_strike = 0
			TEST_ASSERT_EQUAL(anvil.item_interaction(smith, hammer), ITEM_INTERACT_SUCCESS, "The hammer must shape a hot blank.")
		TEST_ASSERT_EQUAL(anvil.item_interaction(smith, tongs), ITEM_INTERACT_SUCCESS, "Tongs must retrieve the shaped blank.")
		basin.reagents.add_reagent(/datum/reagent/water, 10)
		TEST_ASSERT_EQUAL(basin.item_interaction(smith, tongs), ITEM_INTERACT_SUCCESS, "Quenching must finish [pattern_name].")
		TEST_ASSERT(QDELETED(blank), "Quenching must consume the blank.")
		var/obj/item/finished = locate(pattern["output"]) in basin.loc
		TEST_ASSERT_NOTNULL(finished, "Quenching must produce the correct item.")
		qdel(finished)

	// Finish a titanium chestplate with a finite infusion and check delivery while worn.
	forge.titanium = 8
	TEST_ASSERT(forge.cast_blank(tongs, "Chestplate", TRUE), "Titanium must support the masterwork option.")
	TEST_ASSERT_EQUAL(forge.titanium, 0, "A masterwork chestplate must use eight titanium sheets.")
	var/obj/item/smithing_blank/armor_blank = locate() in tongs.contents
	armor_blank.strikes = armor_blank.required_strikes
	armor_blank.hot_until = 0
	TEST_ASSERT_EQUAL(basin.item_interaction(smith, tongs), ITEM_INTERACT_BLOCKING, "A cold blank must be reheated.")
	TEST_ASSERT_EQUAL(forge.item_interaction(smith, tongs), ITEM_INTERACT_SUCCESS, "Loaded tongs must reheat the blank.")
	basin.reagents.add_reagent(/datum/reagent/medicine/salbutamol, 20)
	TEST_ASSERT_EQUAL(basin.item_interaction(smith, tongs), ITEM_INTERACT_SUCCESS, "A valid reagent bath must quench the armor.")
	var/obj/item/clothing/suit/armor/vest/cuirass/forged/chestplate = locate() in basin.loc
	TEST_ASSERT_NOTNULL(chestplate, "The masterwork chestplate must be produced.")
	TEST_ASSERT_EQUAL(chestplate.reagents.total_volume, 20, "The armor must hold only its finite bath infusion.")
	TEST_ASSERT_EQUAL(basin.reagents.get_reagent_amount(/datum/reagent/medicine/salbutamol), 0, "The bath must pay for the infusion.")
	var/datum/component/smithing_infusion/infusion = chestplate.GetComponent(/datum/component/smithing_infusion)
	TEST_ASSERT_NOTNULL(infusion, "The infused armor must have its dosing component.")
	infusion.process(1)
	TEST_ASSERT_EQUAL(chestplate.reagents.total_volume, 20, "Unworn armor must not dispense reagent.")
	var/mob/living/carbon/human/wearer = allocate(/mob/living/carbon/human/consistent)
	wearer.equip_to_slot(chestplate, ITEM_SLOT_OCLOTHING)
	infusion.process(1)
	TEST_ASSERT_EQUAL(wearer.reagents.get_reagent_amount(/datum/reagent/medicine/salbutamol), 0.5, "Equipped armor must dose the wearer.")
	TEST_ASSERT_EQUAL(chestplate.reagents.total_volume, 19.5, "Each dose must consume part of the infusion.")

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
