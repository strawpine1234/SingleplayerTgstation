# Solo expeditions

Print an **Expedition Mission Console Board** at a Cargo or Engineering circuit
imprinter. It is available from the starter **Material Processing** node. Build
it using the normal computer frame construction process. For admin testing,
spawn `/obj/machinery/computer/expedition`.

Every board has three offers in random order: one survey, one salvage recovery,
and one hunt. Titles, difficulty, field-work duration, encounter composition,
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

Each tier has a separate pool of six artifacts. Every offer draws three distinct
choices from its pool, without replacement. Those choices are locked when the
offer is generated; reopening the console or rebuilding it does not reroll them.
Choose one of the three on completion. Unoffered items cannot be claimed.

| Difficulty | Reward pool (three drawn per offer) |
| --- | --- |
| 1 | Linked warp cubes; Immortality Talisman; Rapid Repeater design disk; wisp lantern; Book of Babel; linked paradox bags |
| 2 | Resurrection crystal; Eye of God; Hierophant club; cleaving saw; Rod of Asclepius; flight potion |
| 3 | High-frequency blade; godslayer armour; admin-only omnitool; divine vocal cords; berserker armour; staff of storms |

Each artifact retains its normal abilities, restrictions, and drawbacks. The red
warp cube automatically creates its linked blue partner. The resurrection crystal
must be activated and cannot save a completely destroyed body. The Eye of God
binds when equipped. The omnitool switches between tool modes when used in hand.

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
