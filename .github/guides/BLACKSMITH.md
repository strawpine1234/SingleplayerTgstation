# Blacksmith

Choose **Blacksmith** under Cargo. The **Blacksmith Workshop Kit** in your
backpack contains four placeable frames, tongs, a hammer, bellows, iron, and
fuel. Cargo also sells the kit under Miscellaneous Supplies.

You can make each frame separately in **Crafting → Structures**, and the three
tools in **Crafting → Tools**. Use the frames on clear solid ground to arrange
the workshop. Right-click a forge, anvil, or basin with an empty hand to
unsecure it for moving. Use a wrench to pack an empty station. Move a fueled,
hot, or upgraded forge by unsecuring it so it retains its state.

| Station frame | Construction materials |
| --- | --- |
| Forge | 10 iron sheets |
| Anvil | 10 iron sheets |
| Water basin | 5 wood planks |
| Workbench | 5 wood planks and 2 iron sheets |

1. Add wood or coal to the forge. Wood reaches 50 heat on its own. Stoke it
   with bellows to get past the working threshold of 51. Coal can reach 100.
   The forge can smelt compatible ore into sheets.
2. Use the tongs on any material sheet stack or rods to pick up one unit.
   Use the loaded tongs on the hot forge and choose a part. The stock used
   for the part carries through to the finished item. Parts and finished
   gear take on the stock's color. Mixed parts blend their colors.
3. Place the hot blank on the anvil with tongs. Use the hammer once to begin
   repeated blows. Moving away or putting the hammer down stops the work.
   Plate and chain take 10 blows, and weapon heads take 30. Smithing skill
   speeds the work. Reheat cold blanks by using loaded tongs on the forge.
4. Retrieve the shaped blank with tongs and use it on the basin. A shaped
   blank becomes a quenched part. A premature quench cools the unfinished blank.
5. Click the workbench with an empty hand to browse every pattern and check
   how many of each part are loaded and required. Load the quenched parts and
   any required wood, then use the hammer to assemble. Click with an empty hand
   to collect the result. Right-click the bench to unload its contents.

| Finished item | Workbench parts |
| --- | --- |
| Katana, claymore, broadsword, dagger, or shortsword | The matching blade and 2 wood planks |
| Warhammer | Warhammer head and 2 wood planks |
| Shield | 5 plates |
| Chestplate | 6 plates |
| Helmet | 4 plates |
| Seed sieve | 1 plate and 2 chains |

More valuable stock adds up to 9 melee damage to weapons and shield bashes.
Diamond cuts through armor, bluespace swings faster, silver improves parries,
and plasteel makes gear tougher. On armor, materials improve protection or
durability. Mixed parts blend their bonuses by material amount. Wood used for
a handle does not affect the blade's bonuses. Cloth swings a little faster
and deals common-tier damage. Rare sheets such as ash drake hide get their
own damage and protection bonuses.

Use the seed sieve on a sand pile to recover random seed packets, including
Strange Seed Packs and mutant varieties.
Each use consumes one pile. The sieve's forged material determines its yield,
from 2 for iron to 6 for mythril. Examine the sieve to see its yield.

To imbue finished gear, fit the forge with three regenerative cores or use
a legendary smith's expertise. Load the gear with 100 units of each eligible
reagent, then use it on the hot reagent forge. It can bind up to two reagents.
Infused weapons deliver a unit of each reagent on an unblocked hit and take
wear. Infused chestplates and helmets deliver half-unit doses while worn.
The infusion regenerates once sealed.

The smithing workflow, skill, sprites, and sounds come from Nova Sector's
Reagent Forging module. The station interactions use this fork's tool APIs
and the bench recipes cover the requested local weapons and armor. [Nova Sector guide](https://wiki.novasector13.com/wiki/Guide_to_Smithing_and_Reagent_Forging) · [Pinned upstream module](https://github.com/NovaSector/NovaSector/tree/5ce2bd2215c0355ba9c54ff56d52ae20c90d36da/modular_nova/modules/reagent_forging)

Upstream credits the module to Jake Park. The adapted code is AGPL-3.0, and
the imported sprites and sounds retain their upstream CC BY-SA 3.0 license.
See Nova Sector's licensing notes. [Upstream README](https://github.com/NovaSector/NovaSector/blob/5ce2bd2215c0355ba9c54ff56d52ae20c90d36da/README.md#license)
