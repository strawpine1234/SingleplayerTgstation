# Solo expeditions

Print an **Expedition Mission Console Board** at a Cargo or Engineering circuit
imprinter. It is available from the starter **Material Processing** node. Build
it using the normal computer frame construction process. For admin testing,
spawn `/obj/machinery/computer/expedition`.

The console has five tabs: **T1 Expedition**, **T2 Expedition**, **T3 Expedition**,
**Syndicate Signal**, and **Lavaland Anomalies**. Each expedition tier has one
randomized survey, salvage, or hunt offer. Syndicate Signal contains the tier-four
Syndicate Breach Raid; Lavaland Anomalies contains the tier-four Necropolis Breach.
All five offers refresh together after a reward is claimed or an assignment is
withdrawn. Browsing a tab does not reroll its mission or rewards. While an
assignment is active, other tabs remain readable and a **View Active Assignment**
button returns to its progress and reward controls. Only one assignment can be
active at a time.
Central Command's Special Assignments Office issues every mission. Each brief
explains the assignment and provides field orders, tracking details, and an
authorized requisition reserve. Read the orders and prepare before accepting;
station-defense deployments begin immediately, with a 45-second warning.
Titles, difficulty, field-work duration, encounter composition,
and reward tiers vary. All consoles share one active expedition and progress
for the round, including across console reconstruction.

For wilderness assignments:

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
   rewards. Rewards appear beside the console and all five offers are refreshed.

Each of the four tiers has a separate pool of six artifacts. Every offer draws three distinct
choices from its pool, without replacement. Those choices are locked when the
offer is generated; reopening the console or rebuilding it does not reroll them.
Choose one of the three on completion. Unoffered items cannot be claimed.

| Difficulty | Reward pool (three drawn per offer) |
| --- | --- |
| 1 | Linked warp cubes; Immortality Talisman; Rapid Repeater design disk; wisp lantern; Book of Babel; linked paradox bags |
| 2 | Resurrection crystal; Eye of God; Hierophant club; cleaving saw; Rod of Asclepius; flight potion |
| 3 | High-frequency blade; godslayer armour; omnitool; divine vocal cords; berserker armour; staff of storms |
| 4 (general mythical pool) | Worldsplitter; Aegis of the Undying; Vox of the Necropolis; Tempest Sovereign; Sovereign's Sceptre; Beastbane |

Tier-four missions can select their own exclusive reward pool. The existing
boarding-pod siege is now titled **Syndicate Breach Raid** and draws three of
these six new items, with one claim on completion:

| Syndicate mythical reward | Abilities |
| --- | --- |
| Red Verdict | An unmarked hilt concealing a crimson energy blade; activate it before entering combat. |
| Crimson Bulwark | A layered hardlight shield that can turn aside incoming fire and reflect eligible energy shots. Overwhelming attacks bypass it. |
| Blackstar Carbine | A restricted laser carbine whose internal power system replenishes its charge between engagements. |
| Ghost Legion assault set | Flexible black assault plates with a matching helmet, built for protected movement through confined decks. Not space-rated. |
| Skeleton Protocol | Unlimited ranged emag supporting normal doors and machines. Hacking is destructive and still uses each target's normal emag handling. |
| Phantom Relay | Chameleon projector with immediate reuse after disruption. Contact and attacks still break the disguise. |

The original six general mythical items are the Necropolis Breach reward pool
and remain the fallback for other T4 mission types. Lower-tier pools are unchanged. Raid reward cards show
the Syndicate pool label, and the three choices are locked when the offer is
generated. Claim requests cannot select unoffered items or a different pool.

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

The pod has a large Syndicate drop-pod hull, insignia and closed hatch before
deployment. The hatch opens after wave one. Red emissive status lights turn blue
when deployment is disabled or exhausted.

Boarders are actual human NPCs, with normal bodyparts, organs, blood, wounds,
armour, pain, oxygen/toxin damage, unconsciousness, critical states and death.
Melee raiders carry survival knives; gunners carry ordinary pistols with finite
ammunition. Their carbon-compatible AI uses normal item attacks and respects
team membership. Unconscious or critically injured targets are not selected for
further attacks. Their armour and weapons can be removed like a crewmember's.
Death leaves a normal corpse, and mission cleanup preserves dead boarders for
looting, surgery, or revival. Living mission-owned boarders are still cleaned up
on abandonment. This replaces the earlier simplified, disappearing troopers.

After the first wave, interact with the pod for an uninterrupted twelve seconds
to disable reinforcements, or destroy its 300-integrity hull. Killing the pod
before the first wave fails the mission. Once deployment has stopped (including
automatically after wave three), defeat every spawned boarder to complete the
mission. Deleted live enemies fail the mission rather than counting as kills.
On completion, a station-wide announcement confirms all boarders are dead and
the mythical reward is ready. The remaining pod dissolves into harmless blue
dust and a bluespace shimmer; the completed offer stays claimable at the console.
Six failed exit checks, five seconds apart, fail a blocked deployment. Abandonment
and reward collection clean up the mission-owned pod, enemies, and timers.

The recovered Necropolis relics retain their familiar handling and abilities:

- **Worldsplitter:** A resonant blade edged with a pale seam of light. Wield it in both hands to command its sweeping cuts.
- **Aegis of the Undying:** Ancient armour that releases restorative warmth when its bearer falters, then rests before intervening again.
- **Vox of the Necropolis:** Ash-encrusted vocal cords carrying an ancient decree. Surgically install them, then use Voice of God to command nearby organic minds. The speaker alone is spared.
- **Tempest Sovereign:** A staff carrying a captive storm. Call lightning or disperse hostile weather, then let its reserves gather again.
- **Sovereign's Sceptre:** A violet geometric relic that commands Hierophant blasts and a linked teleport beacon.
- **Beastbane:** A folding hunter's saw, etched with old quarry marks and made to bite into plated hides.

## Necropolis Breach

Vox of the Necropolis replaces Architect's Hand in the general mythical pool.
It uses the normal divine-vocal-cord commands and cooldowns with a threefold
power multiplier. Resonance reaches living organic targets within eight tiles
and line of effect, including humans, pets, and monsters, regardless of hearing
or holy/mind wards. HALT and knockdown commands also bypass ordinary stun
immunity. Robots, nonorganic entities, corpses, and the speaker are excluded,
even when a name or job is specified. Commands requiring particular anatomy
(such as vomiting) still require that anatomy; fixed actions do not acquire new
effects. Administrator godmode remains respected. Item descriptions use lore
and handling guidance rather than upgrade statistics.

The second Tier 4 station-defense mission uses the **original** six mythical
relics listed above. As usual, three distinct choices are shown before acceptance
and only one can be claimed. Syndicate-only items are excluded from this mission.

A mission-controlled necropolis tendril rises through an unoccupied station floor
in a smoke puff. Its emergence animation, destruction, and completion cleanup
never replace the turf, remove floor tiles, or create a chasm. It uses the real
tendril sprite without the normal tendril's uncontrolled spawner/terrain behaviour.

The station announcement names the room and GPS signal. After 45 seconds, waves
of **3, 4, and 5** randomly selected watchers, goliaths, and basilisks emerge at
40-second intervals: at most twelve assigned creatures. Fauna which create extra
broods are not used. The site requires at least five clear adjacent floor exits;
blocked deployments use the same bounded retry/failure rules as the pod siege.

After the first wave, interact with the tendril for twelve uninterrupted seconds
to seal the breach, or destroy it to prevent further waves. Destroying it before
the first wave fails the mission. Once reinforcements stop, kill every deployed
creature to finish. The station announces that the reward is ready, and any
remaining tendril dissolves into harmless bluespace dust. Room information and
the completed reward offer remain available at the console.

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
