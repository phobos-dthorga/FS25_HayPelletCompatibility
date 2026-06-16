# FS25 Hay Pellet Compatibility

Small Farming Simulator 25 compatibility mod that lets hay pellets behave like normal hay wherever a target already accepts hay but does not explicitly support hay pellets.

## Behavior

- Converts `HAY_PELLETS` into `DRYGRASS_WINDROW`.
- Uses a 1:4 pellet-to-hay ratio: `250 L HAY_PELLETS -> 1000 L DRYGRASS_WINDROW`.
- Works with normal vehicle fill units, mixer wagons, unload triggers, and animal feeding troughs.
- Leaves pellet-specific places alone. If a vehicle, production, silo, or other target explicitly accepts `HAY_PELLETS`, this mod does not override that behavior.
- Quietly does nothing when `HAY_PELLETS` is not present in the current mod set.

## Installation

Copy `FS25_HayPelletCompatibility.zip` into your Farming Simulator 25 `mods` folder and activate it for the save.

## Compatibility Notes

This mod is intended to be a gentle bridge for Straw Harvest-style hay pellets in FS25. It does not edit map files, vehicle XML, production XML, or third-party mods.

The conversion is applied only when the receiving target already supports normal hay and does not explicitly support hay pellets. That keeps dedicated pellet storage, pellet processors, and pellet-burning production chains intact.

## Current Scope

Covered:

- Trailers and other normal fill units
- Mixer wagons
- Placeable unload triggers
- Husbandry feeding troughs
- Direct husbandry food additions
- Native FS25 fill-type converter registration under `HAY_PELLETS_TO_HAY`

Not covered:

- Straw pellets
- Custom scripts that bypass FS25 fill units and unload triggers entirely
- Any target that intentionally defines its own `HAY_PELLETS` behavior
