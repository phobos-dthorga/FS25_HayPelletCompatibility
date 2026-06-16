# Testing Notes

Recommended in-game smoke tests:

1. Load a save with a mod that provides `HAY_PELLETS`.
2. Put a hay pellet pallet into a normal trailer or forage trailer that accepts hay.
3. Confirm the receiving vehicle stores `DRYGRASS_WINDROW` and gains four times the pellet liters accepted.
4. Put a hay pellet pallet into a mixer wagon.
5. Confirm the mixer treats it as hay, not as pellets or another fill type.
6. Put hay pellets into an animal feeding trough that accepts hay.
7. Confirm the animals receive normal hay at the 1:4 ratio.
8. Put hay pellets into a pellet-specific storage or production input.
9. Confirm the pellets remain `HAY_PELLETS`.

Regression checks:

- The game log should not contain Lua call-stack errors from `FS25_HayPelletCompatibility`.
- A save without `HAY_PELLETS` loaded should not produce missing-fill-type warnings from this mod.
