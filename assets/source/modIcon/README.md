# Mod Icon Source

This branch preserves the original AI-generated source artwork and prompt for the v0.1.1 ModHub-facing icon refresh.

The working branch keeps the game-facing `icon.dds` only. The original source PNG stays here so it is not mistaken for a runtime FS25 asset.

## Files

- `hay-pellet-compatibility-ai-source.png` - original generated source artwork, 1254x1254 PNG.
- `source-prompt.md` - prompt used to generate the source artwork.

## Runtime Conversion

The runtime icon should be rebuilt as compressed DXT5 DDS with one image level, matching the BgaExtensions DDS rule that avoided FS25 raw-format texture warnings.
