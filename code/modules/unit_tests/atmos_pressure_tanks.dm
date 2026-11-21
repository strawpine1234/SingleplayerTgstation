/datum/unit_test/atmos_pressure_tanks
	abstract_type = /datum/unit_test/atmos_pressure_tanks

/// Returns the test room turf offset from the bottom left corner
/datum/unit_test/atmos_pressure_tanks/proc/room_turf(dx, dy)
	return locate(run_loc_floor_bottom_left.x + dx, run_loc_floor_bottom_left.y + dy, run_loc_floor_bottom_left.z)

/// Total moles of gas on the floor of the test room
/datum/unit_test/atmos_pressure_tanks/proc/room_moles()
	var/total_moles = 0
	for(var/turf/open/floor in block(run_loc_floor_bottom_left, run_loc_floor_top_right))
		total_moles += floor.return_air().total_moles()
	return total_moles

/// Total moles of gas held by pressure tanks in the test room, counting shared mixes once
/datum/unit_test/atmos_pressure_tanks/proc/tank_moles()
	var/list/mixes = list()
	for(var/turf/floor in block(run_loc_floor_bottom_left, run_loc_floor_top_right))
		for(var/obj/machinery/atmospherics/components/tank/tank in floor)
			mixes |= tank.return_analyzable_air()
	var/total_moles = 0
	for(var/datum/gas_mixture/mix as anything in mixes)
		total_moles += mix.total_moles()
	return total_moles

/// Cutting open one tank of a merged group should release only that tank's share, not create gas
/datum/unit_test/atmos_pressure_tanks/tank_deconstruct_conserves_gas

/datum/unit_test/atmos_pressure_tanks/tank_deconstruct_conserves_gas/Run()
	var/list/tanks = list()
	for(var/i in 0 to 2)
		tanks += allocate(/obj/machinery/atmospherics/components/tank/oxygen, room_turf(i, 0))

	var/moles_before = room_moles() + tank_moles()
	var/obj/machinery/atmospherics/components/tank/cut_tank = tanks[3]
	cut_tank.deconstruct(TRUE)
	var/moles_after = room_moles() + tank_moles()

	TEST_ASSERT(abs(moles_after - moles_before) < 1, "Cutting open one of three merged tanks changed the total gas from [moles_before] to [moles_after] moles")

/// Bridging two tank groups with a new empty tank should not create gas
/datum/unit_test/atmos_pressure_tanks/tank_bridge_conserves_gas

/datum/unit_test/atmos_pressure_tanks/tank_bridge_conserves_gas/Run()
	allocate(/obj/machinery/atmospherics/components/tank/oxygen, room_turf(0, 0))
	allocate(/obj/machinery/atmospherics/components/tank/oxygen, room_turf(1, 0))
	allocate(/obj/machinery/atmospherics/components/tank/oxygen, room_turf(3, 0))
	allocate(/obj/machinery/atmospherics/components/tank/oxygen, room_turf(4, 0))

	var/moles_before = tank_moles()
	allocate(/obj/machinery/atmospherics/components/tank, room_turf(2, 0))
	var/moles_after = tank_moles()

	TEST_ASSERT(abs(moles_after - moles_before) < 1, "Joining two tank groups with an empty tank changed the total gas from [moles_before] to [moles_after] moles")

/// Changing storage volume must conserve gas and follow the advertised part tiers.
/datum/unit_test/expanded_canister
	normal_floor_required = TRUE

/datum/unit_test/expanded_canister/Run()
	var/obj/machinery/portable_atmospherics/canister/expanded/canister = allocate(/obj/machinery/portable_atmospherics/canister/expanded)
	TEST_ASSERT_EQUAL(canister.volume, 4000, "A new T1 canister must have twice the normal volume.")
	TEST_ASSERT_EQUAL(length(canister.component_parts), 5, "Construction requires a board, one bin, two servos and one scanner.")
	var/datum/gas_mixture/mix = canister.return_air()
	mix.set_gas(/datum/gas/oxygen, 100)
	var/original_moles = mix.total_moles()
	var/original_pressure = mix.return_pressure()
	var/list/volumes = list(4000, 8000, 12000, 20000)
	for(var/tier in 1 to 4)
		canister.component_parts = list(canister.circuit)
		for(var/datum/stock_part/part as anything in GLOB.stock_part_datums)
			var/datum/stock_part/instance = GLOB.stock_part_datums[part]
			if(instance.tier != tier)
				continue
			if(istype(instance, /datum/stock_part/matter_bin) || istype(instance, /datum/stock_part/scanning_module))
				canister.component_parts += instance
			if(istype(instance, /datum/stock_part/servo))
				canister.component_parts += instance
				canister.component_parts += instance
		canister.RefreshParts()
		TEST_ASSERT_EQUAL(mix.volume, volumes[tier], "The gas mixture must match the advertised tier capacity.")
		TEST_ASSERT_EQUAL(mix.total_moles(), original_moles, "Upgrades must not create or destroy gas.")
		TEST_ASSERT(abs(mix.return_pressure() - original_pressure * 4000 / volumes[tier]) < 0.01, "Pressure must decrease in proportion to the expanded volume.")
	canister.component_parts += GLOB.stock_part_datums[/datum/stock_part/servo]
	canister.RefreshParts()
	TEST_ASSERT_EQUAL(mix.volume, 4000, "A lower-tier part must limit mixed-tier capacity.")
	canister.deconstruct(TRUE)
	TEST_ASSERT(QDELETED(canister), "The expanded canister must support normal machine disassembly.")
	TEST_ASSERT(locate(/obj/item/circuitboard/machine/expanded_canister) in run_loc_floor_bottom_left, "Disassembly must return its circuit board.")
