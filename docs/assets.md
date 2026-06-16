# Assets

Runtime FS25 assets on the working branch should be game-facing files only.

## Mod Icon

- Runtime file: `icon_hayPelletCompatibility.dds`
- Source branch: `asset-source/modhub-icon-v0.1.1`
- Source file on that branch: `assets/source/modIcon/hay-pellet-compatibility-ai-source.png`

The source branch preserves the original generated PNG and prompt. The working branch keeps only the final DDS icon so source artwork is not mistaken for a runtime FS25 asset.

## DDS Contract

The root mod icon follows the current FS25 ModHub convention observed in installed FS25 mods and the GIANTS guideline:

- filename starts with `icon_`
- 512x512 pixels
- compressed BC1 / DXT1 DDS
- one image level, no mip chain

This keeps the public-facing icon aligned with ModHub while preserving the BgaExtensions lesson that game-facing textures must be compressed DDS assets, not raw PNG or uncompressed DDS files.
