#!/usr/bin/env python3
"""Static validation for FS25_HayPelletCompatibility."""

from __future__ import annotations

import argparse
import struct
import sys
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET


EXPECTED_ICON = "icon_hayPelletCompatibility.dds"
FORBIDDEN_GLOBAL_HOOKS = (
    "UnloadTrigger.loadFillTypes =",
    "UnloadTrigger.setTarget =",
    "UnloadingStation.addFillLevelFromTool =",
)
HAYLOFT_HOOK = "UnloadTrigger.load ="
HAYLOFT_HOOK_GUARDS = (
    "loadUnloadTrigger",
    "return success",
    "configureHayLoftUnloadTrigger",
    "addConversionToUnloadTrigger(unloadTrigger, true)",
    "unloadTrigger.fillTypes[sourceFillType]",
    "HAYLOFT_FILL_TYPE_CATEGORY_NAME",
    'xmlNode .. "#fillTypeCategories"',
)


class Validation:
    def __init__(self) -> None:
        self.errors: list[str] = []

    def error(self, message: str) -> None:
        self.errors.append(message)

    def report(self) -> int:
        for error in self.errors:
            print(f"ERROR: {error}")
        if self.errors:
            print(f"Validation failed with {len(self.errors)} error(s).")
            return 1
        print("Validation passed.")
        return 0


def validate_dds_mod_icon(data: bytes, label: str, validation: Validation) -> None:
    if len(data) < 128 or data[:4] != b"DDS ":
        validation.error(f"Mod icon must be a DDS file: {label}")
        return

    header_size, _flags, height, width, linear_size, _depth, mipmaps = struct.unpack_from("<7I", data, 4)
    pixel_format_size = struct.unpack_from("<I", data, 76)[0]
    pixel_flags = struct.unpack_from("<I", data, 80)[0]
    fourcc = data[84:88]
    rgb_bits = struct.unpack_from("<I", data, 88)[0]
    masks = struct.unpack_from("<4I", data, 92)

    if header_size != 124 or pixel_format_size != 32:
        validation.error(f"Mod icon has an invalid DDS header: {label}")
    if width != 512 or height != 512:
        validation.error(f"Mod icon must be 512x512, found {width}x{height}: {label}")
    if fourcc != b"DXT1" or pixel_flags != 0x4 or rgb_bits != 0:
        validation.error(f"Mod icon must be BC1/DXT1 compressed DDS: {label}")
    if masks != (0, 0, 0, 0):
        validation.error(f"Mod icon must use FourCC color masks: {label}")
    if mipmaps != 1:
        validation.error(f"Mod icon must have one image level/no mip chain, found {mipmaps}: {label}")

    expected_linear_size = ((width + 3) // 4) * ((height + 3) // 4) * 8
    if linear_size != expected_linear_size:
        validation.error(f"Mod icon has unexpected DXT1 linear size: {label}")

    expected_size = 128 + expected_linear_size
    if len(data) != expected_size:
        validation.error(f"Mod icon DDS byte size is unexpected: {label}")


def validate_moddesc(root: Path, validation: Validation) -> None:
    moddesc_path = root / "modDesc.xml"
    try:
        tree = ET.parse(moddesc_path)
    except ET.ParseError as exc:
        validation.error(f"modDesc.xml parse failed: {exc}")
        return

    icon_filename = (tree.getroot().findtext("iconFilename") or "").strip()
    if icon_filename != EXPECTED_ICON:
        validation.error(f"modDesc.xml iconFilename must be {EXPECTED_ICON}, found {icon_filename!r}")

    icon_path = root / icon_filename
    if not icon_path.is_file():
        validation.error(f"modDesc.xml references missing iconFilename: {icon_filename}")
    else:
        validate_dds_mod_icon(icon_path.read_bytes(), icon_filename, validation)

    for source in tree.getroot().findall("./extraSourceFiles/sourceFile"):
        filename = source.get("filename")
        if not filename or not (root / filename).is_file():
            validation.error(f"modDesc.xml references missing sourceFile: {filename}")


def validate_lua_hooks(root: Path, validation: Validation) -> None:
    lua_path = root / "scripts" / "HayPelletCompatibility.lua"
    if not lua_path.is_file():
        validation.error("Missing Lua bridge script")
        return

    source = lua_path.read_text(encoding="utf-8")
    for forbidden in FORBIDDEN_GLOBAL_HOOKS:
        if forbidden in source:
            validation.error(f"Lua bridge must not install broad map unload hook: {forbidden}")
    if HAYLOFT_HOOK in source:
        for guard in HAYLOFT_HOOK_GUARDS:
            if guard not in source:
                validation.error(f"UnloadTrigger.load hook must stay guarded by hayloft detection: missing {guard}")


def validate_package(zip_path: Path, validation: Validation) -> None:
    try:
        with zipfile.ZipFile(zip_path) as archive:
            names = set(archive.namelist())
            if "modDesc.xml" not in names:
                validation.error("Package is missing root modDesc.xml")
                return
            root = ET.fromstring(archive.read("modDesc.xml"))
            icon_filename = (root.findtext("iconFilename") or "").strip()
            if icon_filename != EXPECTED_ICON:
                validation.error(f"Package iconFilename must be {EXPECTED_ICON}, found {icon_filename!r}")
            if icon_filename not in names:
                validation.error(f"Package is missing icon: {icon_filename}")
            else:
                validate_dds_mod_icon(archive.read(icon_filename), icon_filename, validation)
            for source in root.findall("./extraSourceFiles/sourceFile"):
                filename = source.get("filename")
                if filename not in names:
                    validation.error(f"Package is missing sourceFile: {filename}")
    except (zipfile.BadZipFile, ET.ParseError) as exc:
        validation.error(f"Package validation failed: {exc}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", default=".")
    parser.add_argument("--package")
    args = parser.parse_args()

    validation = Validation()
    validate_moddesc(Path(args.repo_root), validation)
    validate_lua_hooks(Path(args.repo_root), validation)
    if args.package:
        validate_package(Path(args.package), validation)
    return validation.report()


if __name__ == "__main__":
    raise SystemExit(main())
