// A stationary, atmospherics-gated source of mineral sheets for solo stations.
/obj/machinery/bluespace_miner
	name = "bluespace resource miner"
	desc = "A bluespace extractor that produces mineral sheets when immersed in cold, pure plasma."
	icon = 'icons/obj/machines/bluespace_miner.dmi'
	icon_state = "bluespace_miner"
	density = TRUE
	anchored = TRUE
	circuit = /obj/item/circuitboard/machine/bluespace_miner
	idle_power_usage = BASE_MACHINE_IDLE_CONSUMPTION
	active_power_usage = BASE_MACHINE_ACTIVE_CONSUMPTION * 2
	/// Seconds of uninterrupted operation toward the next sheet.
	var/production_progress = 0
	var/selected_resource = null
	var/auto_deposit = TRUE
	var/mining_enabled = TRUE
	var/total_produced = 0
	var/list/production_counts = list()
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
	if(!mining_enabled || machine_stat & (BROKEN | NOPOWER) || !powered() || !atmosphere_is_valid())
		production_progress = 0
		return

	production_progress += seconds_per_tick
	if(production_progress < production_interval)
		return

	production_progress -= production_interval
	use_energy(active_power_usage * production_interval)
	var/resource_type = selected_resource || pick(resource_types)
	var/obj/item/stack/sheet/produced = new resource_type(drop_location())
	total_produced++
	var/resource_name = initial(resource_type:name)
	production_counts[resource_name] = (production_counts[resource_name] || 0) + 1
	if(auto_deposit && GLOB.ore_silo_default && GLOB.ore_silo_default.materials)
		GLOB.ore_silo_default.materials.insert_item(produced)

/obj/machinery/bluespace_miner/examine(mob/user)
	. = ..()
	. += span_notice("Requires at least [minimum_pressure] kPa of almost pure plasma below [maximum_temperature] K, plus electrical power.")
	. += span_notice("Produces one mineral sheet every [production_interval] seconds while operating.")

// Live machine interface.
/obj/machinery/bluespace_miner/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BluespaceMiner", name)
		ui.open()

/obj/machinery/bluespace_miner/ui_data(mob/user)
	var/list/data = list()
	var/turf/open/miner_turf = get_turf(src)
	var/datum/gas_mixture/air
	if(isopenturf(miner_turf))
		air = miner_turf.return_air()
	var/total_moles = air ? air.total_moles() : 0
	var/plasma_moles = air ? air.moles[/datum/gas/plasma] : 0
	data["enabled"] = mining_enabled
	data["powered"] = powered() && !(machine_stat & (BROKEN | NOPOWER))
	data["atmosphere_valid"] = atmosphere_is_valid()
	data["temperature"] = air ? air.temperature : 0
	data["pressure"] = air ? air.return_pressure() : 0
	data["purity"] = total_moles > 0 ? 100 * plasma_moles / total_moles : 0
	data["progress"] = production_progress
	data["interval"] = production_interval
	data["resource"] = selected_resource ? initial(selected_resource:name) : "Random"
	data["resources"] = list()
	var/list/seen_types = list()
	for(var/resource_type in resource_types)
		if(resource_type in seen_types)
			continue
		seen_types += resource_type
		data["resources"] += list(list("name" = initial(resource_type:name), "path" = "[resource_type]"))
	data["auto_deposit"] = auto_deposit
	data["silo_connected"] = !!GLOB.ore_silo_default
	data["total_produced"] = total_produced
	data["power_usage"] = active_power_usage
	data["production"] = production_counts
	return data

/obj/machinery/bluespace_miner/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("toggle_power")
			mining_enabled = !mining_enabled
			if(!mining_enabled)
				production_progress = 0
			return TRUE
		if("toggle_silo")
			auto_deposit = !auto_deposit
			return TRUE
		if("select_resource")
			var/path = params["path"]
			if(path == "Random")
				selected_resource = null
				return TRUE
			var/resource_type = text2path(path)
			if(!(resource_type in resource_types))
				return FALSE
			selected_resource = resource_type
			return TRUE
	return FALSE


// Lavaland regeneration controller. The destructive backend is intentionally locked
// until the map generator can safely regenerate a live mining z-level.
/obj/machinery/lavaland_regenerator
	name = "bluespace terraforming array"
	desc = "A bluespace control array intended to rebuild the Lavaland expedition zone."
	icon = 'icons/obj/machines/mining_machines.dmi'
	icon_state = "console"
	density = TRUE
	anchored = TRUE
	idle_power_usage = BASE_MACHINE_IDLE_CONSUMPTION
	active_power_usage = BASE_MACHINE_ACTIVE_CONSUMPTION
	var/reset_in_progress = FALSE
	var/reset_count = 0
	var/last_request = "No regeneration requests have been made."
	var/last_requester = "None"
	var/last_request_time = 0
	var/static/list/reset_safety_requirements = list(
		"No living players or observers in the regeneration zone",
		"No occupied shuttles, mining bases, or protected landmarks",
		"Clean removal of old ruins, mobs, objects, and map references",
		"Fresh terrain, ore, fauna, ruin, and boss generation",
		"Safe reconnection of mining destinations and z-level metadata",
	)

/obj/machinery/lavaland_regenerator/examine(mob/user)
	. = ..()
	. += span_warning("The full-reset backend is not yet certified. Regeneration is locked to prevent world corruption.")

/obj/machinery/lavaland_regenerator/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "LavalandRegenerator", name)
		ui.open()

/obj/machinery/lavaland_regenerator/ui_data(mob/user)
	var/list/data = list()
	data["powered"] = powered() && !(machine_stat & (BROKEN | NOPOWER))
	data["busy"] = reset_in_progress
	data["backend_ready"] = FALSE
	data["reset_count"] = reset_count
	data["last_request"] = last_request
	data["last_requester"] = last_requester
	data["last_request_time"] = last_request_time
	data["requirements"] = reset_safety_requirements
	return data

/obj/machinery/lavaland_regenerator/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(action == "request_reset")
		if(reset_in_progress)
			return FALSE
		last_requester = "[usr]"
		last_request_time = world.time
		last_request = "Denied: the live Lavaland regeneration backend is not implemented."
		to_chat(usr, span_warning("Safety interlock: Lavaland cannot be regenerated until the live map reset backend is implemented and verified."))
		return TRUE
	return FALSE
