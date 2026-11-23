/datum/unit_test/second_chance
	normal_floor_required = TRUE

/datum/unit_test/second_chance/Run()
	var/obj/machinery/second_chance/pod = allocate(/obj/machinery/second_chance, get_step(run_loc_floor_bottom_left, EAST))
	pod.set_is_operational(TRUE)
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human)
	user.mind_initialize()
	var/datum/mind/original_mind = user.mind
	var/datum/bank_account/bank = allocate(/datum/bank_account, "Reconstruction Test", null, 1, FALSE)
	bank.account_balance = 0
	var/obj/item/card/id/advanced/card = allocate(/obj/item/card/id/advanced)
	card.registered_name = user.real_name
	card.assignment = "Engineer"
	card.access = list(ACCESS_ENGINEERING)
	card.set_account(bank)
	user.put_in_hands(card)
	TEST_ASSERT_EQUAL(pod.item_interaction(user, card), ITEM_INTERACT_SUCCESS, "The user's own ID must start enrollment.")
	TEST_ASSERT(!pod.enroll(user), "Enrollment must require a DNA sample.")
	var/datum/tgui/ui = new(user, pod, "SecondChance")
	TEST_ASSERT(pod.ui_act("sample", list(), ui), "The enrollment interface must collect the user's DNA.")
	TEST_ASSERT(pod.ui_act("register", list(), ui), "ID and DNA must allow enrollment.")
	user.death()
	TEST_ASSERT(pod.death_pending, "Death must trigger the registered reconstruction.")
	pod.process()
	TEST_ASSERT(!pod.printing, "Insufficient funds must not print a body.")
	bank.account_balance = 100
	pod.process()
	TEST_ASSERT(pod.printing, "A funded dead subject must start printing.")
	TEST_ASSERT_EQUAL(pod.finish_at, world.time + 5 SECONDS, "Printing must take five seconds.")
	TEST_ASSERT_EQUAL(bank.account_balance, 50, "Printing must charge exactly 50 credits.")
	pod.set_is_operational(FALSE)
	pod.process()
	TEST_ASSERT_EQUAL(bank.account_balance, 100, "Interrupted printing must refund its charge.")
	pod.set_is_operational(TRUE)
	pod.process()
	pod.finish_at = world.time
	pod.finish_print()
	var/mob/living/carbon/human/body = original_mind.current
	TEST_ASSERT(body != user && ishuman(body) && body.stat != DEAD, "Reconstruction must restore the original mind into a living human body.")
	TEST_ASSERT_EQUAL(body.real_name, user.real_name, "The reconstructed character must retain their name.")
	TEST_ASSERT(istype(body.w_uniform, /obj/item/clothing/under/color/grey), "The new body must wear a normal grey jumpsuit.")
	var/obj/item/card/id/advanced/reprinted = body.get_idcard()
	TEST_ASSERT(reprinted && reprinted.registered_account == bank, "The reprinted ID must use the original bank account.")
	TEST_ASSERT(ACCESS_ENGINEERING in reprinted.GetAccess(), "The reprinted ID must retain the saved access.")
	TEST_ASSERT_EQUAL(bank.account_balance, 50, "Only one successful reconstruction must be charged.")
	TEST_ASSERT(!pod.registered && !pod.printing, "A successful print must consume the enrollment.")
	pod.finish_print()
	TEST_ASSERT_EQUAL(original_mind.current, body, "Repeated completion must not duplicate a body.")
	qdel(body)
	qdel(ui)
