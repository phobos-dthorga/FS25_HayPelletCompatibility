# Testing

Recommended in-game smoke tests:

1. Load a save with a mod that provides `HAY_PELLETS`.
2. Confirm the save reaches the world from the loading screen without stalling while vehicles load.
3. Put a hay pellet pallet into a normal trailer or forage trailer that accepts hay.
4. Confirm the receiving vehicle stores `DRYGRASS_WINDROW` and gains four times the pellet liters accepted.
5. Put a hay pellet pallet into a mixer wagon.
6. Confirm the mixer treats it as hay, not as pellets or another fill type.
7. Put hay pellets into an animal feeding trough that accepts hay.
8. Confirm the animals receive normal hay at the 1:4 ratio.
9. Put hay pellets into a pellet-specific storage, production input, or sell point.
10. Confirm the pellets remain `HAY_PELLETS` there so native pellet handling is preserved.

Regression checks:

- The game log should not contain Lua call-stack errors from `FS25_HayPelletCompatibility`.
- Vehicle loading should not pause indefinitely with `FS25_HayPelletCompatibility` enabled.
- A save without `HAY_PELLETS` loaded should not produce missing-fill-type warnings from this mod.
- Pellet-specific yards, productions, silos, and sell points should continue handling `HAY_PELLETS` as pellets.
