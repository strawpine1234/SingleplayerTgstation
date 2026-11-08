# Expedition xenomorph artwork

Mission-only assets in `icons/mob/expedition/`:

- `burrow.dmi`: one static 64x64 frame, steady green light, no emergence particles or animation.
- `xenomorphs.dmi`: dark stock hunter, squat bronze-armored drone and robust sentinel. The sentinel has broad chest armor, thick shoulders and limbs, strong thighs and a heavier tail, with a pale elongated crown and dark purple/slate chitin. Four standing directions and a matching collapsed corpse.
- `queen.dmi`: reference-inspired 64x64 queen with a swept-back spiked fan crown, purple-black and burgundy chitin, dorsal blades, ivory claws and a curled spear-tipped tail. The matching corpse retains these features in a collapsed pose. Horizontal registration remains -16px.

The built-in image generation tool produced the custom living and corpse artwork from the supplied appearance references. Sprites were extracted and resized with nearest-neighbor sampling into transparent BYOND DMI states. Hunter artwork and hunter/drone corpse states reuse existing repository sprites. All packaged states use one frame. Ordinary non-mission aliens are unchanged.

## Sentinel scale

Opaque artwork bounds, rather than faint almost-transparent atlas export noise, determine cropping. The four standing views share a scale and aligned feet. Every standing view occupies 30 pixels vertically within its 32x32 cell, with 349–385 opaque pixels per direction. This removes the padding that previously made sentinels look tiny. The dead state is fitted to the same 32x32 cell size and matches the broader build.

Final sentinel prompt specification: five square cells containing South/North/East/West standing views and one matching collapsed corpse; robust athletic alien body, broad chest armor, thick shoulders and 2–3-pixel limbs, powerful thighs and thick segmented tail, elongated pale ivory crown, dark charcoal-purple/slate chitin and restrained beige rib accents. No neon green. Transparent, hard-edged SS13 pixel art, with standing artwork filling about 90% of cell height.

Other prompt specifications:

- Burrow: static dark resin tunnel mouth with torn decking, subtle green veins, a black opening and transparent exterior.
- Queen: follow the supplied queen reference with a large swept-back spiked crown, purple-red chitin, large claws, dorsal blades and curled spear-tipped tail; four directional views and a matching lifeless prone corpse, 64x64 cells.
- Drone: short broad hunched body, excavating forearms, shovel-shaped skull, rust-bronze armor and dark tail.

Validation: inspected the sprites at game scale; parsed DMI metadata; checked nonempty static directional and dead states, standing sentinel height and opaque pixel counts, and identical pixel data for every non-sentinel state. Queen, hunter, drone and burrow artwork are unchanged by the sentinel build revision. In-game appearance remains unverified in this environment.

## Final caste assignment

The living and dead drone/sentinel artwork has been swapped at the user's request. The mission's former drone is now named **alien bruiser**, uses the broad armored build and matching corpse, and has 150 starting and maximum health (up from the inherited 125). It retains its existing drone AI and attacks. Mission sentinels now use the squat bronze-armored artwork formerly assigned to drones and retain their ranged sentinel behavior and health. The resource state names remain drone/drone_dead and sentinel/sentinel_dead for compatibility; the pixel data is swapped. Ordinary non-mission drones remain unchanged.

Verified exact living/dead pixel swaps, static frame metadata, unchanged hunter artwork, and matching 150 starting/maximum health on the mission bruiser. No rewards were added.
