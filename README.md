<div align="center">
  <img src="https://raw.githubusercontent.com/phobos-dthorga/FS25_HayPelletCompatibility/asset-source/modhub-icon-v0.1.1/assets/source/modIcon/hay-pellet-compatibility-ai-source.png" alt="Hay pellet pallet converting into loose hay" width="420">
  <h1>FS25 Hay Pellet Compatibility</h1>
  <p><strong>Hay pellets behave like regular hay wherever hay is already accepted.</strong></p>
</div>

A small Farming Simulator 25 compatibility mod for Straw Harvest-style hay pellets. It converts `HAY_PELLETS` into `DRYGRASS_WINDROW` only when the receiving target accepts normal hay but does not explicitly support hay pellets.

## Download

Download the latest zip from [Releases](https://github.com/phobos-dthorga/FS25_HayPelletCompatibility/releases/latest), then copy `FS25_HayPelletCompatibility.zip` into your Farming Simulator 25 `mods` folder and activate it for the save.

## What It Does

- Converts `HAY_PELLETS` into `DRYGRASS_WINDROW`.
- Uses the expected 1:4 ratio: `250 L HAY_PELLETS -> 1000 L DRYGRASS_WINDROW`.
- Covers normal fill units, mixer wagons, unload triggers, and animal feeding troughs.
- Leaves pellet-specific storage, productions, and vehicles alone.
- Does nothing quietly when `HAY_PELLETS` is not loaded.

## Compatibility Notes

This mod does not edit map files, vehicle XML, production XML, or third-party mods. The conversion happens at runtime and only bridges targets that already know how to receive hay.

That keeps dedicated pellet yards, pellet processors, and pellet-burning production chains intact.

## Notes For Modders

- Native converter name: `HAY_PELLETS_TO_HAY`
- Runtime icon: `icon_hayPelletCompatibility.dds`
- Icon/source details: [docs/assets.md](docs/assets.md)
- Smoke-test checklist: [docs/testing.md](docs/testing.md)

## Current Scope

Covered now:

- Trailers and other normal fill units
- Mixer wagons
- Placeable unload triggers
- Husbandry feeding troughs
- Direct husbandry food additions
- Native FS25 fill-type converter registration under `HAY_PELLETS_TO_HAY`

Not covered by design:

- Straw pellets
- Custom scripts that bypass FS25 fill units and unload triggers entirely
- Any target that intentionally defines its own `HAY_PELLETS` behavior
