/// BSC checkout charges the right accounts once and delivers normal cargo crates without touching the shuttle cart.
/datum/unit_test/bluespace_cargo
	normal_floor_required = TRUE
	var/datum/space_level/test_level
	var/old_station_trait
	var/datum/bank_account/budget
	var/old_budget

/datum/unit_test/bluespace_cargo/Destroy()
	if(test_level)
		if(isnull(old_station_trait))
			test_level.traits -= ZTRAIT_STATION
		else
			test_level.traits[ZTRAIT_STATION] = old_station_trait
		GLOB.station_levels_cache[test_level.z_value] = null
	if(budget)
		budget.account_balance = old_budget
	return ..()

/datum/unit_test/bluespace_cargo/Run()
	test_level = SSmapping.z_list[run_loc_floor_bottom_left.z]
	old_station_trait = test_level.traits[ZTRAIT_STATION]
	test_level.traits[ZTRAIT_STATION] = TRUE
	GLOB.station_levels_cache[test_level.z_value] = null
	budget = SSeconomy.get_dep_account(ACCOUNT_CAR)
	old_budget = budget.account_balance
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/consistent)
	var/obj/machinery/computer/cargo/bluespace/console = allocate(/obj/machinery/computer/cargo/bluespace)
	var/obj/machinery/bsc_pad/pad = allocate(/obj/machinery/bsc_pad, get_step(get_step(run_loc_floor_top_right, SOUTHWEST), SOUTHWEST))
	console.set_is_operational(TRUE)
	pad.set_is_operational(TRUE)
	var/datum/supply_pack/pack = SSshuttle.supply_packs[/datum/supply_pack/emergency/bio]
	var/price = round(pack.get_cost())
	budget.account_balance = price * 5
	var/shared_orders = length(SSshuttle.shopping_list)
	TEST_ASSERT(console.add_item(user, "[pack.type]"), "Normal cargo packs must be orderable.")
	TEST_ASSERT_EQUAL(length(SSshuttle.shopping_list), shared_orders, "BSC orders must not enter the shuttle's cart.")
	TEST_ASSERT(!console.checkout(user), "An unlinked console must not charge or deliver.")
	TEST_ASSERT_EQUAL(budget.account_balance, price * 5, "Failed checkout must leave funds untouched.")
	var/obj/item/multitool/tool = allocate(/obj/item/multitool)
	pad.multitool_act(user, tool)
	console.multitool_act(user, tool)
	TEST_ASSERT_EQUAL(console.linked_pad.resolve(), pad, "The multitool must link the receiving pad.")
	pad.set_is_operational(FALSE)
	TEST_ASSERT(!console.checkout(user), "An unpowered pad must prevent checkout.")
	pad.set_is_operational(TRUE)
	pad.delivery_busy = TRUE
	TEST_ASSERT(!console.checkout(user), "A busy pad must prevent concurrent deliveries.")
	pad.delivery_busy = FALSE

	var/datum/bank_account/private = allocate(/datum/bank_account, "BSC Test Buyer", null, 1, FALSE)
	private.account_balance = 0
	var/obj/item/card/id/advanced/card = allocate(/obj/item/card/id/advanced)
	card.registered_account = private
	user.put_in_hands(card)
	console.self_paid = TRUE
	TEST_ASSERT(console.add_item(user, "[pack.type]"), "Personal purchases must use the ID's registered account.")
	TEST_ASSERT(!console.checkout(user), "Insufficient personal funds must reject the entire cart.")
	TEST_ASSERT_EQUAL(budget.account_balance, price * 5, "Rejected mixed-account checkout must not charge the budget.")
	TEST_ASSERT_EQUAL(length(console.bsc_cart), 2, "Rejected checkout must preserve the cart.")
	private.account_balance = price * 5
	TEST_ASSERT(console.checkout(user), "A funded cart with a powered pad must deliver.")
	TEST_ASSERT_EQUAL(budget.account_balance, price * 4, "Only the budget's own order must be charged to cargo.")
	TEST_ASSERT_EQUAL(private.account_balance, price * 4, "Private orders must charge the selected personal account.")
	TEST_ASSERT_EQUAL(length(console.bsc_cart), 0, "Delivered orders must leave the local cart.")
	TEST_ASSERT_EQUAL(length(SSshuttle.shopping_list), shared_orders, "Checkout must leave shuttle orders untouched.")
	var/crates = 0
	for(var/obj/effect/pod_landingzone/zone in range(2, pad))
		for(var/obj/structure/closet/crate/crate in zone.pod)
			crates++
	TEST_ASSERT_EQUAL(crates, 2, "Each paid order must produce one normal cargo crate near the pad.")
	TEST_ASSERT(!console.checkout(user), "Repeated checkout must not duplicate a delivery.")
	TEST_ASSERT_EQUAL(budget.account_balance, price * 4, "Repeated checkout must not charge again.")

	// Runtime-generated canister packs share a type but have distinct catalogue IDs.
	var/datum/supply_pack/canister_pack
	for(var/id in SSshuttle.supply_packs)
		var/datum/supply_pack/candidate = SSshuttle.supply_packs[id]
		if(candidate.type != candidate.id && (/obj/machinery/portable_atmospherics/canister/oxygen in candidate.contains))
			canister_pack = candidate
			break
	TEST_ASSERT(canister_pack, "The catalogue must contain a generated oxygen canister pack.")
	console.self_paid = FALSE
	budget.account_balance = round(canister_pack.get_cost()) * 2
	TEST_ASSERT(console.add_item(user, "[canister_pack.id]"), "Generated canisters must be orderable by catalogue ID.")
	TEST_ASSERT(console.checkout(user), "A canister order must ship in its original container.")
	var/canisters = 0
	for(var/obj/effect/pod_landingzone/zone in range(2, pad))
		for(var/obj/structure/closet/crate/large/crate in zone.pod)
			for(var/obj/machinery/portable_atmospherics/canister/oxygen/canister in crate)
				canisters++
	TEST_ASSERT_EQUAL(canisters, 1, "The cargo pod must contain the full large crate with its oxygen canister inside.")
