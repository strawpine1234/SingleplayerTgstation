# Solo expeditions

Print an **Expedition Mission Console Board** at a Cargo or Engineering circuit
imprinter. It is available from the starter **Material Processing** node. Build
it using the normal computer frame construction process. For admin testing,
spawn `/obj/machinery/computer/expedition`.

Every board has three offers in random order: one boarding-pod siege and two
different wilderness missions drawn from survey, salvage, and hunt.
Titles, difficulty, field-work duration, encounter composition,
and reward tiers vary. All consoles share one active expedition and progress
for the round, including across console reconstruction.

1. Accept an offer. A clear natural site is selected on a mining z-level, in
   Lavaland's unexplored surface or the ice moon's unexplored underground.
   Deployment fails without consuming the offer if no suitable site is found.
2. Bring a GPS, mining protection, combat equipment, and a way home. Travel with
   the existing mining shuttle or your usual transport. The console provides
   the `EXP-...` GPS signal and X/Y/Z coordinates. No new shuttle is required.
3. At the beacon, interact with it and remain nearby for the stated field-work
   duration. Survey work completes there. Salvage produces a unique recorder
   that must be used on a console. Hunts require killing the specific tagged
   fauna before verifying the beacon. Native fauna do not count.
4. Return to a powered console and choose **one** of the three advertised rare
   rewards. Rewards appear beside the console and three fresh offers are generated.

Each of the four tiers has a separate pool of six artifacts. Every offer draws three distinct
choices from its pool, without replacement. Those choices are locked when the
offer is generated; reopening the console or rebuilding it does not reroll them.
Choose one of the three on completion. Unoffered items cannot be claimed.

| Difficulty | Reward pool (three drawn per offer) |
| --- | --- |
| 1 | Linked warp cubes; Immortality Talisman; Rapid Repeater design disk; wisp lantern; Book of Babel; linked paradox bags |
| 2 | Resurrection crystal; Eye of God; Hierophant club; cleaving saw; Rod of Asclepius; flight potion |
| 3 | High-frequency blade; godslayer armour; admin-only omnitool; divine vocal cords; berserker armour; staff of storms |
| 4 (siege only) | Worldsplitter; Aegis of the Undying; Architect's Hand; Tempest Sovereign; Sovereign's Sceptre; Beastbane |

Each artifact retains its normal abilities, restrictions, and drawbacks. The red
warp cube automatically creates its linked blue partner. The resurrection crystal
must be activated and cannot save a completely destroyed body. The Eye of God
binds when equipped. The omnitool switches between tool modes when used in hand.

## Boarding pod siege

Sieges take place on the station, at an unoccupied clear floor selected on
acceptance. The pod uses a GPS signal and the console lists its coordinates.
It docks without an explosion or hull breach, preserving the station layout.
Bring armour, a weapon, and healing supplies before accepting.

You have 45 seconds before the first two raiders deploy. Another two arrive
40 seconds later, then three more after another 40 seconds. Each wave has one
gunner and the remaining enemies use melee attacks. There are at most seven
enemies; normal AI lets them move away from the pod and fight on the station.

After the first wave, interact with the pod for an uninterrupted twelve seconds
to disable reinforcements, or destroy its 300-integrity hull. Killing the pod
before the first wave fails the mission. Once deployment has stopped (including
automatically after wave three), defeat every spawned boarder to complete the
mission. Deleted live enemies fail the mission rather than counting as kills.
Six failed exit checks, five seconds apart, fail a blocked deployment. Abandonment
and reward collection clean up the mission-owned pod, enemies, and timers.

Mythical rewards retain existing item abilities and add these stronger stats:

- **Worldsplitter:** 40 blade force and 60% block chance.
- **Aegis of the Undying:** 1,000 emergency healing, one-minute recharge.
- **Architect's Hand:** omnitool with a 0.02 tool-time multiplier.
- **Tempest Sovereign:** twelve lightning charges, five-second charging.
- **Sovereign's Sceptre:** 60 melee force with Hierophant blast/teleport abilities.
- **Beastbane:** 35 closed/50 open saw force, plus 60 against mining fauna/bosses.

Abandoning an expedition removes its beacon, recorder, and assigned fauna and
imposes a one-minute departure cooldown. Loss of an uncompleted objective or a
live hunt target marks the mission failed; abandon it to continue. Spawned sites
are also cleaned up when rewards are claimed. Existing terrain and native fauna
are preserved. Sites use the current mining maps rather than separate away-map
instances; weather and the normal wilderness remain dangerous.

## Validation

The `expedition_console` DM unit test covers offer variety, invalid/stale IDs,
premature and duplicate claims, reward validation, and abandonment cooldown.
Run the normal BYOND build and unit-test workflow before relying on this in a
long-running round. Interface lint and include checks do not replace an in-game
test of GPS discovery, fauna, field work interruption, and return/reward flow.
