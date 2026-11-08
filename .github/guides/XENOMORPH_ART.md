# Expedition xenomorph artwork

Mission-only assets in `icons/mob/expedition/`:

- `burrow.dmi`: one static 64x64 frame, steady green light, no emergence particles or animation.
- `xenomorphs.dmi`: dark stock hunter, custom squat bronze-armored drone, and a slender reference-inspired sentinel with a narrow pale ivory crown, dark segmented chitin, skeletal rib highlights and a thin curled tail. Four living directions and corpse states. The sentinel corpse matches its pale crown and slender dark skeletal body in a prone pose.
- `queen.dmi`: custom reference-inspired 64x64 living queen with a swept-back spiked fan crown, purple-black and burgundy chitin, long dorsal blades, ivory-tipped claws and a curled spear-tipped tail. The matching static corpse retains the spiked crown, purple-red chitin, ivory claws and curled tail in a collapsed pose. Horizontal registration remains -16px.

The built-in image generation tool produced the burrow and drone artwork and adapted the user-provided queen and TGMC sentinel references into four-view sprite strips. Artwork was extracted and resized with nearest-neighbor sampling into transparent BYOND DMI states. Hunter artwork and the hunter/drone corpse states reuse existing repository sprites. Queen and sentinel corpses were generated from the current living sprite references using the built-in image generation tool. All packaged states use one frame. Ordinary non-mission aliens are unchanged.

Final prompt specifications:

- Burrow: one static SS13 pixel-art tunnel mouth, jagged charcoal-indigo resin rim, torn steel decking, subtle green veins, opaque black opening and transparent exterior; no creatures, eggs, labels, scene or animation frames.
- Sentinel: closely follow the supplied TGMC sentinel reference: tall slender skeletal silhouette, narrow pale tan/ivory elongated crown, dark charcoal-blue segmented chitin, fine gray/beige rib and limb highlights, thin curled tail and delicate claws. Subtle purple shadows, no bright green or broad armor. Four square directional cells, South/North/East/West, transparent pixel-art production strip for 32x32 sprites.
- Queen: closely follow the supplied queen reference: massive swept-back spiked fan crown, angular purple-black chitin with muted burgundy-red ridges, recessed black ribs, long dorsal blades, large ivory-tipped claws, powerful digitigrade legs and a long curled segmented tail with a red spear tip. Four square directional cells, South/North/East/West, transparent pixel-art production strip for 64x64 sprites.
- Drone: four-direction SS13 strip with a shorter broader hunched silhouette, thick excavating forearms, shovel-shaped armored skull, rust-bronze carapace ridges and dark segmented tail; no green markings.

Validation: parsed DMI metadata; verified four unique nonempty static views for both living reference-inspired castes, 64x64 queen versus 32x32 sentinel, and unchanged pixel data for all other caste and corpse states. Existing DM tests cover sprite references, queen size and burrow visibility. In-game appearance remains unverified in this environment.

Corpse prompt specifications: queen and sentinel each collapsed lifeless on their side, limbs slack, head resting down and tail curled beside the body. Preserve the current caste silhouette, crown, chitin colors and claws. One static transparent pixel-art cell each, 64x64 queen and 32x32 sentinel; no animation, scene, text or additional creatures.

Corpse validation: both dead states remain one nonempty frame and one direction; all living sprites and unrelated corpse pixel data are unchanged. In-game death rendering remains unverified in this environment.
