/// Item sales use real export prices, consume sold objects once, and do not run without power.
/datum/unit_test/item_seller/Run()
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human/consistent)
	var/obj/machinery/item_seller/seller = allocate(/obj/machinery/item_seller)
	var/obj/item/wrench/item = allocate(/obj/item/wrench)
	var/datum/export/wrench/export = locate() in GLOB.exports_list
	var/old_elasticity = export.k_elasticity
	var/expected = seller.get_sale_value(item)
	TEST_ASSERT(expected > 0, "A wrench must have its normal cargo export value.")
	user.put_in_hands(item)
	seller.set_is_operational(TRUE)
	seller.item_interaction(user, item, list())
	TEST_ASSERT(item in seller.stock, "Inserted items must be held for review before sale.")
	TEST_ASSERT_EQUAL(seller.sales.balance, 0, "Appraising an item must not pay out.")
	seller.set_is_operational(FALSE)
	TEST_ASSERT_EQUAL(seller.sell_stock(), 0, "Unpowered machines must not sell items.")
	TEST_ASSERT(!QDELETED(item), "A rejected sale must preserve the item.")
	seller.set_is_operational(TRUE)
	TEST_ASSERT_EQUAL(seller.sell_stock(), expected, "The sale must use the real cargo export price.")
	TEST_ASSERT(QDELETED(item), "Paid items must be consumed.")
	TEST_ASSERT_EQUAL(seller.sales.balance, expected, "Sale proceeds must be credited exactly once.")
	TEST_ASSERT_EQUAL(seller.sell_stock(), 0, "Selling an empty machine must not duplicate credits.")
	export.k_elasticity = old_elasticity

	var/obj/item/storage/backpack/bag = allocate(/obj/item/storage/backpack)
	var/obj/item/wrench/kept = allocate(/obj/item/wrench, bag)
	user.put_in_hands(bag)
	seller.item_interaction(user, bag, list())
	TEST_ASSERT(!(bag in seller.stock), "Filled containers must not be accepted.")
	TEST_ASSERT_EQUAL(kept.loc, bag, "Rejected containers must preserve their contents.")
	var/obj/item/paper/unsellable = allocate(/obj/item/paper)
	TEST_ASSERT_EQUAL(seller.get_sale_value(unsellable), 0, "Unpriced items must not gain an invented value.")

/// Gas sales account for every species and fraction of a mole, without repeat or rounding payouts.
/datum/unit_test/gas_seller/Run()
	var/obj/machinery/atmospherics/components/unary/gas_seller/seller = allocate(/obj/machinery/atmospherics/components/unary/gas_seller)
	var/obj/machinery/atmospherics/pipe/smart/simple/pipe = allocate(/obj/machinery/atmospherics/pipe/smart/simple, get_step(seller, SOUTH))
	pipe.atmos_init()
	seller.atmos_init()
	TEST_ASSERT_EQUAL(seller.nodes[1], pipe, "The gas seller must connect to ordinary atmos piping.")
	var/datum/gas_mixture/mixture = seller.airs[1]
	mixture.assert_gas(/datum/gas/oxygen)
	mixture.assert_gas(/datum/gas/nitrogen)
	mixture.moles[/datum/gas/oxygen] = 10.5
	mixture.moles[/datum/gas/nitrogen] = 7.25
	mixture.temperature = T20C
	TEST_ASSERT_EQUAL(seller.sell_gas(), 0, "A switched-off seller must preserve incoming gas.")
	seller.set_on(TRUE)
	seller.set_is_operational(FALSE)
	TEST_ASSERT_EQUAL(seller.sell_gas(), 0, "An unpowered seller must preserve incoming gas.")
	TEST_ASSERT_EQUAL(mixture.total_moles(), 17.75, "Rejected sales must not consume gas.")
	seller.set_is_operational(TRUE)
	var/expected = 10.5 * /datum/gas/oxygen::base_value + 7.25 * /datum/gas/nitrogen::base_value
	TEST_ASSERT(abs(seller.sell_gas() - expected) < 0.0001, "Each gas must sell for its per-mole base price.")
	TEST_ASSERT_EQUAL(mixture.total_moles(), 0, "Sold gas must be removed from the pipe buffer.")
	TEST_ASSERT_EQUAL(seller.total_moles_sold, 17.75, "Fractional moles must be counted accurately.")
	TEST_ASSERT_EQUAL(seller.sell_gas(), 0, "An empty buffer must not produce additional credits.")
	var/obj/item/holochip/payment = seller.sales.withdraw(seller)
	TEST_ASSERT_EQUAL(payment.credits, FLOOR(expected, 1), "Withdrawal must pay only whole available credits.")
	TEST_ASSERT_NULL(seller.sales.withdraw(seller), "Repeated withdrawal must not duplicate credits.")
	TEST_ASSERT(abs(seller.sales.balance - (expected - FLOOR(expected, 1))) < 0.0001, "Fractional proceeds must remain available.")
	var/balance = seller.sales.balance
	var/obj/item/holochip/remainder = seller.sales.withdraw(seller, all = TRUE)
	TEST_ASSERT(abs(remainder.credits - balance) < 0.0001, "Deconstruction refunds must include fractional credits.")
	TEST_ASSERT_EQUAL(seller.sales.balance, 0, "A full refund must clear the ledger.")
