/// Shared earnings ledger. Fractional gas-sale credits accumulate until withdrawal.
/datum/seller_account
	var/balance = 0
	var/total_earned = 0
	var/status = "Ready to trade."

/datum/seller_account/proc/credit(amount)
	if(!isnum(amount) || isnan(amount) || amount <= 0)
		return FALSE
	balance += amount
	total_earned += amount
	return TRUE

/datum/seller_account/proc/get_data()
	return list("balance" = balance, "earned" = total_earned, "status" = status)

/datum/seller_account/proc/withdraw(atom/source, mob/living/user, all = FALSE)
	var/amount = all ? balance : FLOOR(balance, 1)
	if(amount <= 0)
		return null
	balance -= amount
	var/obj/item/holochip/payment = new(source.drop_location(), amount)
	if(user)
		user.put_in_hands(payment)
	return payment

/// Sells individual, empty items at the same prices used by the cargo export system.
/obj/machinery/item_seller
	name = "item seller"
	desc = "An export terminal that accepts items for sale at current cargo export prices. Insert items, review their values, and sell them through its interface."
	icon = 'icons/obj/machines/recycling.dmi'
	icon_state = "grinder-o0"
	density = TRUE
	circuit = /obj/item/circuitboard/machine/item_seller
	var/datum/seller_account/sales
	var/list/stock = list()
	var/capacity = 20

/obj/machinery/item_seller/Initialize(mapload)
	sales = new
	return ..()

/obj/machinery/item_seller/Destroy()
	QDEL_NULL(sales)
	stock.Cut()
	return ..()

/obj/machinery/item_seller/Exited(atom/movable/gone, direction)
	stock -= gone
	return ..()

/obj/machinery/item_seller/on_deconstruction(disassembled = TRUE)
	sales.withdraw(src, all = TRUE)
	return ..()

/obj/machinery/item_seller/screwdriver_act(mob/living/user, obj/item/tool)
	return default_deconstruction_screwdriver(user, tool)

/obj/machinery/item_seller/crowbar_act(mob/living/user, obj/item/tool)
	return default_deconstruction_crowbar(user, tool)

/obj/machinery/item_seller/proc/get_sale_value(obj/item/item)
	var/datum/export_report/report = export_single_item(item, dry_run = TRUE, delete_unsold = FALSE)
	var/value = 0
	for(var/datum/export/export as anything in report.total_value)
		value += report.total_value[export]
	qdel(report)
	return max(0, value)

/obj/machinery/item_seller/item_interaction(mob/living/user, obj/item/item, list/modifiers)
	. = ..()
	if(.)
		return
	if(!is_operational || panel_open)
		return ITEM_INTERACT_BLOCKING
	if(length(stock) >= capacity)
		balloon_alert(user, "seller full!")
		return ITEM_INTERACT_BLOCKING
	if(length(item.contents))
		balloon_alert(user, "empty the item first!")
		return ITEM_INTERACT_BLOCKING
	if(get_sale_value(item) <= 0)
		balloon_alert(user, "no export value!")
		return ITEM_INTERACT_BLOCKING
	if(!user.transferItemToLoc(item, src))
		return ITEM_INTERACT_BLOCKING
	stock += item
	sales.status = "[item.name] accepted for appraisal."
	return ITEM_INTERACT_SUCCESS

/obj/machinery/item_seller/proc/sell_stock()
	if(!is_operational || panel_open)
		return 0
	var/earned = 0
	for(var/obj/item/item as anything in stock.Copy())
		if(QDELETED(item) || item.loc != src || length(item.contents))
			continue
		var/datum/export_report/report = export_single_item(item, delete_unsold = FALSE)
		for(var/datum/export/export as anything in report.total_value)
			earned += report.total_value[export]
		qdel(report)
	sales.credit(earned)
	sales.status = earned > 0 ? "Sale complete: [earned] credits earned." : "No items could be sold at current prices."
	return earned

/obj/machinery/item_seller/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TradeSeller", name)
		ui.open()

/obj/machinery/item_seller/ui_data(mob/user)
	var/list/data = sales.get_data()
	data["mode"] = "items"
	data["capacity"] = capacity
	var/list/items = list()
	for(var/obj/item/item as anything in stock)
		items += list(list("id" = REF(item), "name" = item.name, "value" = get_sale_value(item)))
	data["items"] = items
	return data

/obj/machinery/item_seller/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(!is_operational || panel_open || !isliving(usr) || !usr.can_perform_action(src))
		return FALSE
	switch(action)
		if("sell")
			sell_stock()
			return TRUE
		if("withdraw")
			sales.withdraw(src, usr)
			return TRUE
		if("eject")
			var/obj/item/item = locate(params["id"]) in stock
			if(item)
				item.forceMove(drop_location())
			return TRUE
	return FALSE

/// A single-port gas sink. Only positively priced gases are consumed; other gases remain in the pipe buffer.
/obj/machinery/atmospherics/components/unary/gas_seller
	name = "gas seller"
	desc = "A piped export terminal that sells gas at its listed credit value per mole. Earnings can be withdrawn as holochips."
	icon_state = "inje_off"
	circuit = /obj/item/circuitboard/machine/gas_seller
	idle_power_usage = BASE_MACHINE_IDLE_CONSUMPTION
	active_power_usage = BASE_MACHINE_ACTIVE_CONSUMPTION
	on = FALSE
	interaction_flags_atom = INTERACT_ATOM_ATTACK_HAND | INTERACT_ATOM_UI_INTERACT
	var/datum/seller_account/sales
	var/total_moles_sold = 0

/obj/machinery/atmospherics/components/unary/gas_seller/Initialize(mapload)
	sales = new
	return ..()

/obj/machinery/atmospherics/components/unary/gas_seller/Destroy()
	QDEL_NULL(sales)
	return ..()

/obj/machinery/atmospherics/components/unary/gas_seller/on_deconstruction(disassembled = TRUE)
	sales.withdraw(src, all = TRUE)
	return ..()

/obj/machinery/atmospherics/components/unary/gas_seller/update_icon_nopipes()
	icon_state = on && is_operational ? "inje_on" : "inje_off"

/obj/machinery/atmospherics/components/unary/gas_seller/process_atmos()
	if(!on || !is_operational || panel_open)
		return
	sell_gas()

/obj/machinery/atmospherics/components/unary/gas_seller/proc/sell_gas()
	if(!on || !is_operational || panel_open)
		return 0
	var/datum/gas_mixture/mixture = airs[1]
	var/earned = 0
	var/sold_moles = 0
	for(var/datum/gas/gas as anything in mixture.moles.Copy())
		var/moles = mixture.moles[gas]
		var/price = initial(gas.base_value)
		if(moles <= 0 || price <= 0)
			continue
		earned += moles * price
		sold_moles += moles
		mixture.moles[gas] = 0
	if(sold_moles > 0)
		mixture.garbage_collect()
		update_parents()
		total_moles_sold += sold_moles
		sales.credit(earned)
		sales.status = "Sold [round(sold_moles, 0.01)] mol for [round(earned, 0.01)] credits."
	return earned

/obj/machinery/atmospherics/components/unary/gas_seller/screwdriver_act(mob/living/user, obj/item/tool)
	if(on)
		balloon_alert(user, "turn off first!")
		return ITEM_INTERACT_BLOCKING
	return default_deconstruction_screwdriver(user, tool)

/obj/machinery/atmospherics/components/unary/gas_seller/crowbar_act(mob/living/user, obj/item/tool)
	if(on)
		return ITEM_INTERACT_BLOCKING
	return crowbar_deconstruction_act(user, tool)

/obj/machinery/atmospherics/components/unary/gas_seller/wrench_act(mob/living/user, obj/item/tool)
	if(on)
		return ITEM_INTERACT_BLOCKING
	return default_change_direction_wrench(user, tool)

/obj/machinery/atmospherics/components/unary/gas_seller/multitool_act(mob/living/user, obj/item/tool)
	if(on || !panel_open)
		balloon_alert(user, "turn off and open panel!")
		return ITEM_INTERACT_BLOCKING
	set_piping_layer(piping_layer >= PIPING_LAYER_MAX ? PIPING_LAYER_MIN : piping_layer + 1)
	reconnect_nodes()
	balloon_alert(user, "pipe layer [piping_layer]")
	return ITEM_INTERACT_SUCCESS

/obj/machinery/atmospherics/components/unary/gas_seller/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TradeSeller", name)
		ui.open()

/obj/machinery/atmospherics/components/unary/gas_seller/ui_data(mob/user)
	var/list/data = sales.get_data()
	data["mode"] = "gas"
	data["enabled"] = on
	data["connected"] = !!nodes[1]
	data["moles_sold"] = total_moles_sold
	var/list/gases = list()
	var/datum/gas_mixture/mixture = airs[1]
	for(var/datum/gas/gas as anything in GLOB.meta_gas_info[META_GAS_ID])
		if(initial(gas.base_value) <= 0 && mixture.moles[gas] <= 0)
			continue
		gases += list(list("name" = initial(gas.name), "price" = initial(gas.base_value), "moles" = mixture.moles[gas] || 0))
	data["gases"] = gases
	return data

/obj/machinery/atmospherics/components/unary/gas_seller/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(!is_operational || panel_open || !isliving(usr) || !usr.can_perform_action(src))
		return FALSE
	switch(action)
		if("toggle")
			set_on(!on)
			update_use_power(on ? ACTIVE_POWER_USE : IDLE_POWER_USE)
			update_appearance()
			return TRUE
		if("withdraw")
			sales.withdraw(src, usr)
			return TRUE
	return FALSE
