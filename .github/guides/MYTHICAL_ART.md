# Mythical expedition artwork

The mythical reward subtypes use dedicated transparent DMI resources. Ordinary
items retain their original sprites. Each reward has a four-frame inventory and
ground animation; equipped weapons have matching directional held artwork, and
the armour sets have matching worn sprites. The Aegis includes its own antlered
hood, and Ghost Legion includes its matching helmet.

| Mythical item | Original inspiration | Visual treatment and idle animation |
| --- | --- | --- |
| Worldsplitter | High-frequency blade | Obsidian steel, ivory edge and travelling pale resonance when wielded |
| Aegis of the Undying | Godslayer armour and helm | Frost-dark plates, ivory antlers and pulsing amber life runes |
| Vox of the Necropolis | Divine vocal cords | Ash-grey tissue, obsidian filaments and breathing amber throat rings |
| Tempest Sovereign | Staff of storms | Dark mineral shaft, ivory crown and flickering captive cyan lightning |
| Sovereign's Sceptre | Hierophant club | Violet geometric facets, pale-gold inlay and shifting rune light |
| Beastbane | Cleaving saw | Blackened teeth, fossil-bone grip and ember seams |
| Red Verdict | Red energy sword | Black/silver hilt, crimson crystal and pulsing red energy blade |
| Crimson Bulwark | Combat energy shield | Compact emitter and scanning crimson hex-panel hardlight |
| Blackstar Carbine | Type 5 laser gun | Black receiver, silver barrel and cycling crimson charge indicators |
| Ghost Legion assault set | Armour vest and helmet | Charcoal plates, crimson chevrons, status diodes and scanning visor |
| Skeleton Protocol | Cryptographic sequencer | Ivory skull, exposed pale circuitry and cascading intrusion indicators |
| Phantom Relay | Chameleon projector | Dark casing, crimson emitter and shifting cyan holographic interference |

## Resources

- `icons/obj/mining_zones/mythical_items.dmi`: 32x32 item states and retained charge/readiness overlays.
- `icons/mob/clothing/mythical_items.dmi`: directional armour and helmet sprites.
- `icons/mob/inhands/mythical_lefthand.dmi` and `mythical_righthand.dmi`: 32x32 held sprites.
- `icons/mob/inhands/mythical_64x64_lefthand.dmi` and `mythical_64x64_righthand.dmi`: 64x64 held club and saw sprites.

Existing state names are preserved for wielding, opening, activation, energy
sword colour modes, Hierophant readiness and laser charge overlays. The new hood
uses `godslayer_hood` to avoid colliding with the armour's inventory state.
Directional frames remain in BYOND's south/north/east/west order. Inventory loops
have four frames at two deciseconds per frame. Worn and held poses are separate
from these inventory loops.

The artwork was generated using the built-in imagegen tool with the original
item and directional sprites as references, then sliced and encoded at native
32x32/64x64 dimensions with nearest-neighbour sampling. The DMI files are the
editable game assets; they do not require image generation tools at build time.
Source sprite families include the existing sword, transforming-energy, shield,
mining-artifact, storm-staff, organ, energy-gun, armour, helmet, card and Syndicate
gadget files, with their corresponding held and worn sprites.

No item statistics, cooldowns, reward selection or mission mechanics change.
The old red tints are removed from the newly coloured Syndicate sprites so their
silver, charcoal and holographic details display correctly.

The `expedition_mythical_art` unit test checks every reward's initial icon and
normal transformation cycle, both activated hand sprites, and matching helmets.
