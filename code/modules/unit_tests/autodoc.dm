/// Autodocs retain their identity and supplies when disassembled, and servo speed does not compound.
/datum/unit_test/autodoc_parts

/datum/unit_test/autodoc_parts/Run()
	var/obj/machinery/sleeper/autodoc/machine = allocate(/obj/machinery/sleeper/autodoc)
	var/obj/item/circuitboard/machine/board = machine.circuit
	TEST_ASSERT_EQUAL(board.build_path, /obj/machinery/sleeper/autodoc, "Autodoc board must rebuild an Autodoc.")
	TEST_ASSERT_EQUAL(machine.procedure_duration, 10 SECONDS, "Basic parts should take ten seconds.")
	TEST_ASSERT_EQUAL(machine.get_procedure_duration(heal_damage = TRUE), 20 SECONDS, "Basic healing should take twice as long.")
	var/datum/stock_part/servo/old_servo = locate() in machine.component_parts
	TEST_ASSERT_NOTNULL(old_servo, "Autodoc must contain an upgradeable servo.")
	machine.component_parts -= old_servo
	var/datum/stock_part/servo/tier4/new_servo = GLOB.stock_part_datums[/datum/stock_part/servo/tier4]
	machine.component_parts += new_servo
	machine.RefreshParts()
	TEST_ASSERT_EQUAL(machine.procedure_duration, 2.5 SECONDS, "Tier four servo should take 2.5 seconds.")
	TEST_ASSERT_EQUAL(machine.get_procedure_duration(heal_damage = TRUE), 5 SECONDS, "Upgraded healing should also take twice as long.")
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

/// Damage treatment heals in place and does not consume a loaded supply or remove implants.
/datum/unit_test/autodoc_healing

/datum/unit_test/autodoc_healing/Run()
	var/obj/machinery/sleeper/autodoc/machine = allocate(/obj/machinery/sleeper/autodoc)
	var/mob/living/carbon/human/patient = allocate(/mob/living/carbon/human/consistent)
	var/obj/item/implant/implant = allocate(/obj/item/implant)
	implant.implant(patient, patient)
	var/obj/item/implantcase/payload = allocate(/obj/item/implantcase, machine)
	machine.surgical_payload = payload
	machine.close_machine(patient)
	machine.set_is_operational(TRUE)
	patient.adjust_brute_loss(20)
	patient.adjust_fire_loss(20)
	patient.adjust_tox_loss(10)
	patient.adjust_oxy_loss(10)
	var/obj/item/organ/brain = patient.get_organ_slot(ORGAN_SLOT_BRAIN)
	var/obj/item/organ/liver = patient.get_organ_slot(ORGAN_SLOT_LIVER)
	brain.set_organ_damage(10)
	liver.set_organ_damage(20)
	machine.finish_procedure(patient, payload, heal_damage = TRUE)
	TEST_ASSERT_EQUAL(patient.get_brute_loss(), 0, "Healing must clear brute damage.")
	TEST_ASSERT_EQUAL(patient.get_fire_loss(), 0, "Healing must clear burn damage.")
	TEST_ASSERT_EQUAL(patient.get_tox_loss(), 0, "Healing must clear toxin damage.")
	TEST_ASSERT_EQUAL(patient.get_oxy_loss(), 0, "Healing must clear oxygen damage.")
	TEST_ASSERT_EQUAL(brain.damage, 0, "Healing must clear brain damage.")
	TEST_ASSERT_EQUAL(liver.damage, 0, "Healing must clear internal organ damage.")
	TEST_ASSERT_EQUAL(patient.get_organ_slot(ORGAN_SLOT_BRAIN), brain, "Healing must preserve installed organs.")
	TEST_ASSERT_EQUAL(implant.imp_in, patient, "Healing must preserve implants.")
	TEST_ASSERT_EQUAL(machine.surgical_payload, payload, "Healing must preserve the loaded supply.")
	TEST_ASSERT(!machine.operating, "Healing completion must stop operation.")
	TEST_ASSERT_NULL(machine.operating_sound.sound_token_instance, "Healing completion must stop audio.")

	patient.adjust_brute_loss(20)
	machine.set_is_operational(FALSE)
	machine.finish_procedure(patient, payload, heal_damage = TRUE)
	TEST_ASSERT_EQUAL(patient.get_brute_loss(), 20, "Unavailable power must prevent healing.")
