/// Autodocs retain their identity and supplies when disassembled, and servo speed does not compound.
/datum/unit_test/autodoc_parts

/datum/unit_test/autodoc_parts/Run()
	var/obj/machinery/sleeper/autodoc/machine = allocate(/obj/machinery/sleeper/autodoc)
	var/obj/item/circuitboard/machine/board = machine.circuit
	TEST_ASSERT_EQUAL(board.build_path, /obj/machinery/sleeper/autodoc, "Autodoc board must rebuild an Autodoc.")
	TEST_ASSERT_EQUAL(machine.procedure_duration, 10 SECONDS, "Basic parts should take ten seconds.")
	var/datum/stock_part/servo/old_servo = locate() in machine.component_parts
	TEST_ASSERT_NOTNULL(old_servo, "Autodoc must contain an upgradeable servo.")
	machine.component_parts -= old_servo
	var/datum/stock_part/servo/tier4/new_servo = GLOB.stock_part_datums[/datum/stock_part/servo/tier4]
	machine.component_parts += new_servo
	machine.RefreshParts()
	TEST_ASSERT_EQUAL(machine.procedure_duration, 2.5 SECONDS, "Tier four servo should take 2.5 seconds.")
	machine.RefreshParts()
	TEST_ASSERT_EQUAL(machine.procedure_duration, 2.5 SECONDS, "Repeated refresh must not compound upgrades.")
	machine.component_parts -= new_servo
	machine.component_parts += old_servo
	machine.RefreshParts()
	TEST_ASSERT_EQUAL(machine.procedure_duration, 10 SECONDS, "Basic parts should restore the original duration.")

	var/obj/item/implantcase/payload = allocate(/obj/item/implantcase, machine)
	machine.surgical_payload = payload
	var/turf/machine_turf = get_turf(machine)
	machine.deconstruct(TRUE)
	TEST_ASSERT(!QDELETED(board), "Disassembly must preserve the Autodoc board.")
	TEST_ASSERT_EQUAL(board.loc, machine_turf, "Disassembly must drop the board.")
	TEST_ASSERT(!QDELETED(payload), "Disassembly must preserve the loaded payload.")
	TEST_ASSERT_EQUAL(payload.loc, machine_turf, "Disassembly must drop the payload.")
