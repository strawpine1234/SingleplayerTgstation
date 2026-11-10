/datum/job/blacksmith
	title = JOB_BLACKSMITH
	description = "Cast and shape weapons, armor, and seed sieves. Set up your portable workshop in Cargo."
	faction = FACTION_STATION
	total_positions = 1
	spawn_positions = 1
	supervisors = SUPERVISOR_QM
	exp_granted_type = EXP_TYPE_CREW
	config_tag = "BLACKSMITH"
	outfit = /datum/outfit/job/cargo_tech/blacksmith
	plasmaman_outfit = /datum/outfit/plasmaman/cargo
	paycheck = PAYCHECK_CREW
	paycheck_department = ACCOUNT_CAR
	display_order = JOB_DISPLAY_ORDER_BLACKSMITH
	bounty_types = CIV_JOB_RANDOM
	departments_list = list(/datum/job_department/cargo)
	job_flags = STATION_JOB_FLAGS
	rpg_title = "Armorer"
	tgui_icon = FA_ICON_HAMMER

/datum/job/blacksmith/get_default_roundstart_spawn_point()
	for(var/obj/effect/landmark/start/spawn_point as anything in GLOB.start_landmarks_list)
		if(spawn_point.name == title)
			return ..()
	// Existing station maps already have Cargo spawn points.
	var/datum/job/cargo_job = SSjob.get_job_type(/datum/job/cargo_technician)
	return cargo_job.get_default_roundstart_spawn_point()

/datum/id_trim/job/cargo_technician/blacksmith
	assignment = JOB_BLACKSMITH
	job = /datum/job/blacksmith
	honorifics = list("Smith")

/datum/outfit/job/cargo_tech/blacksmith
	name = JOB_BLACKSMITH
	jobtype = /datum/job/blacksmith
	id_trim = /datum/id_trim/job/cargo_technician/blacksmith
	suit = /obj/item/clothing/suit/apron
	l_hand = null
	backpack_contents = list(/obj/item/storage/box/smithing_kit = 1)
