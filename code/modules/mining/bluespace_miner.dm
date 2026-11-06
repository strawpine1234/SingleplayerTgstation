// A stationary, atmospherics-gated source of mineral sheets for solo stations.
/obj/machinery/bluespace_miner
	name = "bluespace resource miner"
	desc = "A bluespace extractor that produces mineral sheets when immersed in cold, pure plasma."
	icon = 'icons/obj/machines/mining_machines.dmi'
	icon_state = "console"
	density = TRUE
	anchored = TRUE
	idle_power_usage = BASE_MACHINE_IDLE_CONSUMPTION
	active_power_usage = BASE_MACHINE_ACTIVE_CONSUMPTION * 2
	/// Seconds of uninterrupted operation toward the next sheet.
	var/production_progress = 0
	/// Time required to produce a sheet, in seconds.
	var/production_interval = 5
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
	var/resource_type = pick(resource_types)
	new resource_type(drop_location())

/obj/machinery/bluespace_miner/examine(mob/user)
	. = ..()
	. += span_notice("Requires at least [minimum_pressure] kPa of almost pure plasma below [maximum_temperature] K, plus electrical power.")
	. += span_notice("Produces one random mineral sheet every [production_interval] seconds while operating.")
