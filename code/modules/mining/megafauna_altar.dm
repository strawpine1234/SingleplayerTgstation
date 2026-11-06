// A player-built, reusable summoning altar for solo boss encounters.
// Summons use the normal mob types, preserving their attacks and loot.
/obj/structure/megafauna_altar
	name = "megafauna summoning altar"
	desc = "A bluespace-powered altar capable of calling forth a terrifying opponent. Select a creature and sacrifice your peace."
	icon = 'icons/obj/antags/cult/structures.dmi'
	icon_state = "talismanaltar"
	density = TRUE
	anchored = TRUE
	max_integrity = 300
	/// Chosen boss name, local to each altar.
	var/selected_boss = "Ash Drake"
	/// The available encounters and their exact mob types.
	var/static/list/summonable_bosses = list(
		"Ash Drake" = /mob/living/simple_animal/hostile/megafauna/dragon,
		"Colossus" = /mob/living/simple_animal/hostile/megafauna/colossus,
		"Bubblegum" = /mob/living/simple_animal/hostile/megafauna/bubblegum,
		"Blood-Drunk Miner" = /mob/living/basic/boss/blood_drunk_miner,
		"Hierophant" = /mob/living/simple_animal/hostile/megafauna/hierophant,
		"Clockwork Defender" = /mob/living/simple_animal/hostile/megafauna/clockwork_defender,
		"Wendigo" = /mob/living/simple_animal/hostile/megafauna/wendigo,
		"Demonic Frost Miner" = /mob/living/simple_animal/hostile/megafauna/demonic_frost_miner,
		"The Thing" = /mob/living/basic/boss/thing,
	)

/obj/structure/megafauna_altar/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	ui_interact(user)
	return TRUE

/obj/structure/megafauna_altar/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MegafaunaAltar", name)
		ui.open()

/obj/structure/megafauna_altar/ui_data(mob/user)
	var/list/data = list()
	data["selected_boss"] = selected_boss
	data["bosses"] = list()
	for(var/boss_name in summonable_bosses)
		data["bosses"] += boss_name
	return data

/obj/structure/megafauna_altar/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(!Adjacent(usr))
		return FALSE
	switch(action)
		if("select_boss")
			var/choice = params["boss"]
			if(!istext(choice) || !(choice in summonable_bosses))
				return FALSE
			selected_boss = choice
			return TRUE
		if("sacrifice")
			var/boss_type = summonable_bosses[selected_boss]
			if(!ispath(boss_type, /mob/living))
				return FALSE

			// Never place a boss inside the altar, a wall, or an occupied tile.
			var/list/possible_turfs = list()
			for(var/turf/open/candidate in orange(2, src))
				if(candidate.density)
					continue
				var/blocked = FALSE
				for(var/atom/movable/occupant in candidate)
					if(occupant.density)
						blocked = TRUE
						break
				if(!blocked)
					possible_turfs += candidate

			if(!length(possible_turfs))
				to_chat(usr, span_warning("The altar needs an unoccupied open space within two tiles to complete the sacrifice."))
				return FALSE

			var/turf/spawn_turf = pick(possible_turfs)
			var/mob/living/summoned = new boss_type(spawn_turf)
			visible_message(span_danger("[src] erupts in bluespace energy as [summoned] materializes nearby!"))
			playsound(src, 'sound/effects/magic/repulse.ogg', 65, TRUE)
			return TRUE
	return FALSE
