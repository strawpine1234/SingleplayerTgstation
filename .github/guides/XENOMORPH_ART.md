# Expedition xenomorph artwork

Mission-only assets in `icons/mob/expedition/`:

- `burrow.dmi`: one static 64x64 frame, steady green light, no emergence particles or animation.
- `xenomorphs.dmi`: dark stock hunter, custom squat bronze-armored drone, custom muted greenish-purple sentinel; four living directions and corpse states.
- `queen.dmi`: existing large royal queen artwork, 64x64 with a broad crown and long tail, registered with a -16px horizontal offset.

Burrow, drone and sentinel artwork was generated/edited with the built-in image generation tool, then extracted and resized with nearest-neighbor sampling into transparent BYOND DMI states. Hunter and queen artwork reuses the existing repository sprites. All packaged states use one frame. Ordinary non-mission alien appearances are unchanged.

Final prompt specifications:

- Burrow: one static SS13 pixel-art tunnel mouth, jagged charcoal-indigo resin rim, torn steel decking, subtle green veins, opaque black opening, transparent exterior; no creatures, eggs, labels, scene or animation frames.
- Sentinel: recolor the four-direction sprite with dusky plum and eggplant shadows, muted sage-teal undertones and soft gray-lavender highlights. Replace neon lime bands with restrained organic greenish-purple skin; preserve silhouettes, poses, tails, mouth details, transparent background and hard pixel edges. No bright or fluorescent markings.
- Drone: four-direction SS13 strip with a shorter broader hunched silhouette, thick excavating forearms, shovel-shaped armored skull, rust-bronze carapace ridges and dark segmented tail; no green markings.

Validation: parsed all DMI metadata; checked every frame is static and nonempty, every living caste has four views, every sentinel view uses muted colors without bright green bands, queen art is larger than regular castes, and mission icon references exist. DM unit tests added for sprite state references, queen size, and burrow visibility. BYOND compilation and in-game appearance remain unverified in this environment.
