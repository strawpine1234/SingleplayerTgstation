/// A receiving pad for cargo purchases, linked using a multitool.
/obj/machinery/bsc_pad
	name = "BSC pad"
	desc = "A Bluespace Cargo receiving pad. Use a multitool on this pad, then on a Bluespace cargo console to link them."
	icon = 'icons/obj/machines/telepad.dmi'
	icon_state = "lpad-idle"
	circuit = /obj/item/circuitboard/machine/bsc_pad
	var/delivery_busy = FALSE

/obj/machinery/bsc_pad/multitool_act(mob/living/user, obj/item/multitool/tool)
	tool.set_buffer(src)
	balloon_alert(user, "pad saved to buffer")
	return ITEM_INTERACT_SUCCESS

/obj/machinery/bsc_pad/screwdriver_act(mob/living/user, obj/item/tool)
	if(delivery_busy)
		return ITEM_INTERACT_BLOCKING
	return default_deconstruction_screwdriver(user, tool)

/obj/machinery/bsc_pad/crowbar_act(mob/living/user, obj/item/tool)
	if(delivery_busy)
		return ITEM_INTERACT_BLOCKING
	return default_deconstruction_crowbar(user, tool)

/obj/machinery/bsc_pad/proc/can_receive()
	return is_operational && anchored && !panel_open && !delivery_busy && is_station_level(z)

/// Reserve separate clear floor tiles so a cart never arrives inside a person or another crate.
/obj/machinery/bsc_pad/proc/delivery_turfs()
	var/list/available = list()
	var/turf/center = get_turf(src)
	if(istype(center, /turf/open/floor) && !center.is_blocked_turf())
		available += center
	for(var/turf/open/floor/candidate in range(2, center))
		if(candidate != center && !candidate.is_blocked_turf())
			available += candidate
	return available

/// Uses the standard cargo catalogue and pack generation, with its own cart and no shuttle dependency.
/obj/machinery/computer/cargo/bluespace
	name = "Bluespace cargo console"
	desc = "A cargo ordering terminal that teleports purchased orders to a linked BSC pad at checkout. Link a pad using a multitool."
	circuit = /obj/item/circuitboard/computer/cargo/bluespace
	interface_type = "BluespaceCargo"
	can_send = FALSE
	can_approve_requests = FALSE
	stationcargo = FALSE
	var/datum/weakref/linked_pad
	var/list/bsc_cart = list()
	var/checkout_busy = FALSE
	var/last_status = "Link a BSC pad with a multitool to enable delivery."
	var/cart_capacity = 20

/obj/machinery/computer/cargo/bluespace/Destroy()
	QDEL_LIST(bsc_cart)
	linked_pad = null
	return ..()

/obj/machinery/computer/cargo/bluespace/multitool_act(mob/living/user, obj/item/multitool/tool)
	var/obj/machinery/bsc_pad/pad = tool.buffer
	if(!istype(pad) || QDELETED(pad))
		balloon_alert(user, "save a BSC pad first!")
		return ITEM_INTERACT_BLOCKING
	linked_pad = WEAKREF(pad)
	tool.set_buffer(null)
	last_status = "Linked to [pad.name] in [get_area_name(pad)]."
	balloon_alert(user, "pad linked")
	return ITEM_INTERACT_SUCCESS

/obj/machinery/computer/cargo/bluespace/proc/pack_available(datum/supply_pack/pack)
	if(!pack || SSshuttle.supply_packs[pack.type] != pack)
		return FALSE
	if(pack.order_flags & (ORDER_INVISIBLE | ORDER_POD_ONLY))
		return FALSE
	if((pack.order_flags & ORDER_EMAG_ONLY) && !(obj_flags & EMAGGED))
		return FALSE
	if((pack.order_flags & ORDER_CONTRABAND) && !contraband)
		return FALSE
	if((pack.order_flags & ORDER_SPECIAL) && !(pack.order_flags & ORDER_SPECIAL_ENABLED))
		return FALSE
	return TRUE

/obj/machinery/computer/cargo/bluespace/add_item(mob/user, id, amount = 1)
	if(checkout_busy || !isliving(user) || !isnum(amount) || amount != round(amount) || amount < 1 || amount > CARGO_MAX_ORDER)
		return FALSE
	var/datum/supply_pack/pack = SSshuttle.supply_packs[text2path(id) || id]
	if(!pack_available(pack))
		return FALSE
	var/count = 0
	for(var/datum/supply_order/order as anything in bsc_cart)
		if(order.pack == pack)
			count++
	if(count + amount > CARGO_MAX_ORDER || length(bsc_cart) + amount > cart_capacity)
		last_status = "Cart limit reached. Check out or remove some orders first."
		return FALSE
	var/mob/living/buyer = user
	var/obj/item/card/id/id_card = buyer.get_idcard(TRUE)
	var/datum/bank_account/account
	if(self_paid)
		account = id_card?.registered_account
		if(!account || IS_DEPARTMENTAL_CARD(id_card))
			last_status = "Private purchases require a personal ID with a bank account."
			return FALSE
		if(pack.access_view && !(pack.access_view in id_card.GetAccess()) && !istype(id_card, /obj/item/card/id/advanced/chameleon))
			last_status = "Your ID lacks access to this supply pack."
			return FALSE
	else if(pack.order_flags & ORDER_GOODY)
		last_status = "Small personal orders must be purchased privately."
		return FALSE
	var/rank = "Silicon"
	if(ishuman(user))
		var/mob/living/carbon/human/human_buyer = user
		rank = human_buyer.get_assignment(hand_first = TRUE)
	for(var/index in 1 to amount)
		bsc_cart += new /datum/supply_order(pack, user.real_name, rank, user.ckey, paying_account = account)
	last_status = "[pack.name] added to the cart. Payment is taken at checkout."
	return TRUE

/// Validate the whole cart before charging; never touch the cargo shuttle's shared shopping list.
/obj/machinery/computer/cargo/bluespace/proc/checkout(mob/user)
	if(checkout_busy || !is_operational || panel_open || !length(bsc_cart))
		return FALSE
	var/obj/machinery/bsc_pad/pad = linked_pad?.resolve()
	if(!pad || !pad.can_receive() || SSshuttle.supply_blocked)
		last_status = "Delivery unavailable. Check the linked pad's power, maintenance hatch, and station location."
		return FALSE
	var/list/destinations = pad.delivery_turfs()
	if(length(destinations) < length(bsc_cart))
		last_status = "Clear more floor space around the BSC pad before checkout."
		return FALSE
	var/datum/bank_account/cargo_budget = SSeconomy.get_dep_account(cargo_account)
	var/list/totals = list()
	var/list/prices = list()
	for(var/datum/supply_order/order as anything in bsc_cart)
		if(!pack_available(order.pack))
			last_status = "An order is no longer available. Remove it before checkout."
			return FALSE
		var/datum/bank_account/account = order.paying_account || cargo_budget
		var/price = order.get_final_cost()
		if(QDELETED(account) || !isnum(price) || isnan(price) || price < 0)
			last_status = "An order has no valid payment account or price."
			return FALSE
		totals[account] += price
		prices[order] = price
	for(var/datum/bank_account/account as anything in totals)
		if(!account.has_money(totals[account]))
			last_status = "Insufficient funds in [account.account_holder]. No orders were charged."
			return FALSE
	checkout_busy = TRUE
	pad.delivery_busy = TRUE
	var/list/charged = list()
	for(var/datum/bank_account/account as anything in totals)
		if(totals[account] > 0 && !account.adjust_money(-totals[account], "Bluespace cargo checkout"))
			for(var/datum/bank_account/refund_account as anything in charged)
				refund_account.adjust_money(totals[refund_account], "Bluespace cargo checkout refund")
			checkout_busy = FALSE
			pad.delivery_busy = FALSE
			last_status = "Payment failed. Charged accounts were refunded."
			return FALSE
		charged += account
	var/delivered_count = 0
	for(var/datum/supply_order/order as anything in bsc_cart.Copy())
		var/turf/destination = pick_n_take(destinations)
		var/atom/movable/delivery = order.generate(destination)
		var/datum/bank_account/account = order.paying_account || cargo_budget
		if(QDELETED(delivery))
			account.adjust_money(prices[order], "Bluespace cargo delivery refund")
			continue
		new /obj/effect/temp_visual/bluespace_fissure(destination)
		if(order.paying_account)
			cargo_budget?.adjust_money(max(0, prices[order] - order.pack.get_cost()), "Bluespace cargo handling fee")
			SSeconomy.add_audit_entry(account, prices[order], order.pack.name)
		log_game("[key_name(user)] received bluespace cargo order #[order.id] ([order.pack.name]) at [AREACOORD(pad)] for [prices[order]] credits.")
		bsc_cart -= order
		qdel(order)
		delivered_count++
	playsound(pad, 'sound/items/weapons/flash.ogg', 50, TRUE)
	pad.use_energy(pad.active_power_usage)
	pad.delivery_busy = FALSE
	checkout_busy = FALSE
	last_status = "[delivered_count] order(s) delivered to [pad.name]."
	return delivered_count > 0

/obj/machinery/computer/cargo/bluespace/ui_data(mob/user)
	var/list/data = list()
	var/datum/bank_account/budget = SSeconomy.get_dep_account(cargo_account)
	var/obj/machinery/bsc_pad/pad = linked_pad?.resolve()
	data["points"] = budget?.account_balance || 0
	data["self_paid"] = self_paid
	data["status"] = last_status
	data["pad"] = pad ? "[pad.name] - [get_area_name(pad)]" : "No pad linked"
	data["pad_ready"] = pad && pad.can_receive() && !SSshuttle.supply_blocked
	var/list/orders = list()
	var/total = 0
	for(var/datum/supply_order/order as anything in bsc_cart)
		var/price = order.get_final_cost()
		total += price
		orders += list(list("id" = "[order.id]", "name" = order.pack.name, "cost" = price, "payer" = order.paying_account?.account_holder || "Cargo budget"))
	data["orders"] = orders
	data["total"] = total
	return data

/// The parent handler operates on the shuttle's shared cart, so this console handles its actions locally.
/obj/machinery/computer/cargo/bluespace/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	var/mob/user = ui.user
	if(!is_operational || panel_open || !isliving(user) || !user.can_perform_action(src) || checkout_busy)
		return FALSE
	switch(action)
		if("add")
			return add_item(user, params["id"])
		if("toggleprivate")
			self_paid = !self_paid
			return TRUE
		if("checkout")
			return checkout(user)
		if("remove")
			for(var/datum/supply_order/order as anything in bsc_cart)
				if("[order.id]" == params["id"])
					bsc_cart -= order
					qdel(order)
					return TRUE
	return FALSE
