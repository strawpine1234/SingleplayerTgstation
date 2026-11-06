// A stationary, atmospherics-gated source of mineral sheets for solo stations.
/obj/machinery/bluespace_miner
	name = "bluespace resource miner"
	desc = "A bluespace extractor that produces mineral sheets when immersed in cold, pure plasma."
	icon = 'icons/obj/machines/mining_machines.dmi'
	icon_state = "console"
	density = TRUE
	anchored = TRUE
	circuit = /obj/item/circuitboard/machine/bluespace_miner
	idle_power_usage = BASE_MACHINE_IDLE_CONSUMPTION
	active_power_usage = BASE_MACHINE_ACTIVE_CONSUMPTION * 2
	/// Seconds of uninterrupted operation toward the next sheet.
	var/production_progress = 0
	var/selected_resource = null
	var/auto_deposit = TRUE
	var/status_message = "Idle"
	/// Time required to produce a sheet, in seconds.
	var/production_interval = 5
	/// Effective tier of installed machine parts; defaults to tier one.
	var/parts_tier = 1
	/// Lowest acceptable surrounding pressure, in kPa.
	var/minimum_pressure = 100
	/// Maximum acceptable surrounding temperature, in kelvin (exclusive).
	var/maximum_temperature = 120
	/// Maximum non-plasma fraction of the surrounding atmosphere.
	var/max_impurity_fraction = 0.001
	/// One sheet per production cycle. Weights are represented by repeated entries.
	var/static/list/resource_types = list(
		/obj/item/stack/sheet/iron,
		/obj/item/stack/sheet/iron,
		/obj/item/stack/sheet/iron,
		/obj/item/stack/sheet/glass,
		/obj/item/stack/sheet/glass,
		/obj/item/stack/sheet/mineral/plasma,
		/obj/item/stack/sheet/mineral/silver,
		/obj/item/stack/sheet/mineral/gold,
		/obj/item/stack/sheet/mineral/uranium,
		/obj/item/stack/sheet/mineral/titanium,
		/obj/item/stack/sheet/mineral/diamond,
	)

/// Recalculate the output interval from the installed machine part tier.
/obj/machinery/bluespace_miner/proc/set_parts_tier(new_tier)
	parts_tier = clamp(round(new_tier), 1, 4)
	switch(parts_tier)
		if(1)
			production_interval = 5
		if(2)
			production_interval = 4
		if(3)
			production_interval = 3
		if(4)
			production_interval = 1
	production_progress = min(production_progress, production_interval)

/obj/machinery/bluespace_miner/RefreshParts()
	. = ..()
	var/total_rating = 0
	var/number_of_bins = 0
	for(var/datum/stock_part/matter_bin/bin in component_parts)
		total_rating += bin.tier
		number_of_bins++
	if(number_of_bins)
		set_parts_tier(round(total_rating / number_of_bins))

/obj/machinery/bluespace_miner/proc/atmosphere_is_valid()
	var/turf/open/miner_turf = get_turf(src)
	if(!isopenturf(miner_turf))
		return FALSE

	var/datum/gas_mixture/air = miner_turf.return_air()
	if(!air || air.temperature >= maximum_temperature || air.return_pressure() < minimum_pressure)
		return FALSE

	var/total_moles = air.total_moles()
	if(total_moles <= 0)
		return FALSE

	var/plasma_moles = air.moles[/datum/gas/plasma]
	if(plasma_moles <= 0)
		return FALSE

	return ((total_moles - plasma_moles) / total_moles) <= max_impurity_fraction

/obj/machinery/bluespace_miner/process(seconds_per_tick)
	if(machine_stat & (BROKEN | NOPOWER) || !powered() || !atmosphere_is_valid())
		production_progress = 0
		return

	production_progress += seconds_per_tick
	if(production_progress < production_interval)
		return

	production_progress -= production_interval
	use_energy(active_power_usage * production_interval)
	var/resource_type = selected_resource || pick(resource_types)
	var/obj/item/stack/sheet/produced = new resource_type(drop_location())
	if(auto_deposit && GLOB.ore_silo_default && GLOB.ore_silo_default.materials)
		GLOB.ore_silo_default.materials.insert_item(produced)

/obj/machinery/bluespace_miner/examine(mob/user)
	. = ..()
	. += span_notice("Requires at least [minimum_pressure] kPa of almost pure plasma below [maximum_temperature] K, plus electrical power.")
	. += span_notice("Produces one mineral sheet every [production_interval] seconds while operating.")

// A simple interactive control panel; a full TGUI frontend can replace this later.
/obj/machinery/bluespace_miner/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	var/list/options = list("Select resource", "Toggle silo deposit", "Check status")
	var/choice = tgui_input_list(user, "Bluespace miner controls", name, options)
	if(!choice || !Adjacent(user))
		return
	switch(choice)
		if("Select resource")
			var/list/choices = list("Random" = "Random")
			for(var/resource_type in resource_types)
				choices[initial(resource_type:name)] = resource_type
			var/selection = tgui_input_list(user, "Choose output", name, choices)
			if(!selection || !Adjacent(user))
				return
			selected_resource = choices[selection] == "Random" ? null : choices[selection]
			to_chat(user, span_notice("Miner output: [selection]."))
		if("Toggle silo deposit")
			auto_deposit = !auto_deposit
			to_chat(user, span_notice("Silo deposit [auto_deposit ? "enabled" : "disabled"]."))
		if("Check status")
			to_chat(user, span_notice("Power: [powered() ? "available" : "unavailable"]. Atmosphere: [atmosphere_is_valid() ? "valid" : "invalid"]. Progress: [round(production_progress, 0.1)]/[production_interval] seconds."))
