# Expedition xenomorph artwork

Mission-only assets in `icons/mob/expedition/`:

- `burrow.dmi`: one static 64x64 frame, steady green light, no emergence particles or animation.
- `xenomorphs.dmi`: dark stock hunter, custom squat bronze-armored drone, custom green-marked sentinel; four living directions and corpse states.
- `queen.dmi`: existing large royal queen artwork, 64x64 with a broad crown and long tail, registered with a -16px horizontal offset.

Burrow, drone and sentinel artwork was generated/edited with the built-in image generation tool, then extracted and resized with nearest-neighbor sampling into transparent BYOND DMI states. Hunter and queen artwork reuses the existing repository sprites. All packaged states use one frame. Ordinary non-mission alien appearances are unchanged.

Final prompt specifications:

- Burrow: one static SS13 pixel-art tunnel mouth, jagged charcoal-indigo resin rim, torn steel decking, subtle green veins, opaque black opening, transparent exterior; no creatures, eggs, labels, scene or animation frames.
- Sentinel: edit the original four-direction sentinel strip, preserve black-indigo chitin and registration, add bright acid-green bands on crown ridges, shoulders, dorsal spines and tail in all four directions; retain transparent pixel-art style.
- Drone: four-direction SS13 strip with a shorter broader hunched silhouette, thick excavating forearms, shovel-shaped armored skull, rust-bronze carapace ridges and dark segmented tail; no green markings.

Validation: parsed all DMI metadata; checked every frame is static and nonempty, every living caste has four views, every sentinel view contains prominent green pixels, queen art is larger than regular castes, and mission icon references exist. DM unit tests added for sprite state references, queen size, and burrow visibility. BYOND compilation and in-game appearance remain unverified in this environment.
