#!/usr/bin/env python3

from __future__ import annotations

import json
import math
import re
import subprocess
import sys
from pathlib import Path


def hex_to_rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def rgb_to_hex(rgb: tuple[int, int, int]) -> str:
    return "#{:02x}{:02x}{:02x}".format(*rgb)


def luminance(rgb: tuple[int, int, int]) -> float:
    r, g, b = [channel / 255.0 for channel in rgb]
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def saturation(rgb: tuple[int, int, int]) -> float:
    r, g, b = [channel / 255.0 for channel in rgb]
    highest = max(r, g, b)
    lowest = min(r, g, b)
    if highest == 0:
        return 0.0
    return (highest - lowest) / highest


def mix(a: tuple[int, int, int], b: tuple[int, int, int], ratio: float) -> tuple[int, int, int]:
    return tuple(
        max(0, min(255, round((1 - ratio) * x + ratio * y)))
        for x, y in zip(a, b, strict=True)
    )


def lighten(rgb: tuple[int, int, int], ratio: float) -> tuple[int, int, int]:
    return mix(rgb, (255, 255, 255), ratio)


def darken(rgb: tuple[int, int, int], ratio: float) -> tuple[int, int, int]:
    return mix(rgb, (0, 0, 0), ratio)


def clamp_accent(rgb: tuple[int, int, int]) -> tuple[int, int, int]:
    value = rgb
    if luminance(value) < 0.20:
        value = lighten(value, 0.22)
    if saturation(value) < 0.16:
        value = mix(value, (130, 120, 170), 0.24)
    return value


def parse_histogram(image_path: str) -> list[tuple[int, tuple[int, int, int]]]:
    cmd = [
        "magick",
        image_path,
        "-resize",
        "96x96^",
        "-gravity",
        "center",
        "-extent",
        "96x96",
        "-colors",
        "12",
        "-format",
        "%c",
        "histogram:info:-",
    ]
    result = subprocess.run(cmd, check=True, text=True, capture_output=True)
    colors: list[tuple[int, tuple[int, int, int]]] = []
    pattern = re.compile(r"\s*(\d+):\s*\(([0-9.]+),([0-9.]+),([0-9.]+)")

    for line in result.stdout.splitlines():
        match = pattern.match(line)
        if not match:
            continue
        count = int(match.group(1))
        rgb = (
            round(float(match.group(2))),
            round(float(match.group(3))),
            round(float(match.group(4))),
        )
        colors.append((count, rgb))

    if not colors:
        raise RuntimeError("No colors extracted from image")

    colors.sort(key=lambda item: item[0], reverse=True)
    return colors


def visible_swatch(rgb: tuple[int, int, int]) -> tuple[int, int, int]:
    value = rgb
    if luminance(value) < 0.14:
        value = lighten(value, 0.28)
    if luminance(value) > 0.88:
        value = darken(value, 0.10)
    return value


def build_dark_palette(accent: tuple[int, int, int], accent2: tuple[int, int, int], lightest: tuple[int, int, int], swatches: list[str]) -> dict[str, object]:
    base_anchor = (24, 22, 34)
    mantle_anchor = (16, 15, 24)
    surface_anchor = (34, 31, 45)
    surface2_anchor = (48, 44, 62)
    text_anchor = (214, 214, 228)
    subtext_anchor = (156, 157, 179)

    # Keep shell surfaces consistently dark and only lightly tinted.
    base = mix(base_anchor, accent, 0.06)
    mantle = mix(mantle_anchor, accent, 0.04)
    surface = mix(surface_anchor, accent, 0.08)
    surface2 = mix(surface2_anchor, accent, 0.10)
    text = mix(text_anchor, lightest, 0.14)
    subtext = mix(subtext_anchor, text, 0.12)
    border = mix(surface2, accent, 0.10)

    return {
        "base": rgb_to_hex(base),
        "mantle": rgb_to_hex(mantle),
        "surface": rgb_to_hex(surface),
        "surface2": rgb_to_hex(surface2),
        "text": rgb_to_hex(text),
        "subtext": rgb_to_hex(subtext),
        "accent": rgb_to_hex(accent),
        "accent2": rgb_to_hex(accent2),
        "border": rgb_to_hex(border),
        "colors": swatches,
    }


def build_light_palette(accent: tuple[int, int, int], accent2: tuple[int, int, int], swatches: list[str]) -> dict[str, object]:
    base_anchor = (238, 241, 247)
    mantle_anchor = (230, 234, 242)
    surface_anchor = (208, 214, 226)
    surface2_anchor = (190, 198, 214)
    text_anchor = (64, 69, 88)
    subtext_anchor = (91, 98, 120)

    light_accent = accent
    if luminance(light_accent) > 0.58:
        light_accent = darken(light_accent, 0.24)
    if luminance(light_accent) < 0.26:
        light_accent = lighten(light_accent, 0.12)

    light_accent2 = accent2
    if luminance(light_accent2) > 0.62:
        light_accent2 = darken(light_accent2, 0.22)

    base = mix(base_anchor, light_accent, 0.05)
    mantle = mix(mantle_anchor, light_accent, 0.04)
    surface = mix(surface_anchor, light_accent, 0.07)
    surface2 = mix(surface2_anchor, light_accent, 0.09)
    text = mix(text_anchor, light_accent, 0.06)
    subtext = mix(subtext_anchor, text, 0.10)
    border = mix(surface2, light_accent, 0.12)

    return {
        "base": rgb_to_hex(base),
        "mantle": rgb_to_hex(mantle),
        "surface": rgb_to_hex(surface),
        "surface2": rgb_to_hex(surface2),
        "text": rgb_to_hex(text),
        "subtext": rgb_to_hex(subtext),
        "accent": rgb_to_hex(light_accent),
        "accent2": rgb_to_hex(light_accent2),
        "border": rgb_to_hex(border),
        "colors": swatches,
    }


def pick_palette(colors: list[tuple[int, tuple[int, int, int]]]) -> dict[str, object]:
    ranked = [rgb for _, rgb in colors]
    lightest = max(ranked[:8], key=luminance)
    weighted = colors[:6]
    swatches = [rgb_to_hex(visible_swatch(rgb)) for rgb in ranked[:8]]

    # Avoid picking tiny saturated outliers from noisy wallpapers.
    accent_candidates = sorted(
        weighted,
        key=lambda item: (
            saturation(item[1]) * 1.8
            - abs(luminance(item[1]) - 0.50)
            + min(item[0] / weighted[0][0], 1.0) * 0.35
        ),
        reverse=True,
    )
    accent = clamp_accent(accent_candidates[0][1])

    accent2 = None
    for _, candidate in accent_candidates[1:]:
        if abs(luminance(candidate) - luminance(accent)) > 0.08:
            accent2 = clamp_accent(candidate)
            break
    if accent2 is None:
        accent2 = darken(accent, 0.22) if luminance(accent) > 0.45 else lighten(accent, 0.18)

    dark = build_dark_palette(accent, accent2, lightest, swatches)
    light = build_light_palette(accent, accent2, swatches)

    return {
        **dark,
        "dark": dark,
        "light": light,
    }


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: extract_palette.py IMAGE_PATH [OUTPUT_JSON]", file=sys.stderr)
        return 1

    image_path = sys.argv[1]
    output_path = Path(sys.argv[2]) if len(sys.argv) > 2 else None

    fallback = {
        "base": "#24273a",
        "mantle": "#1e2030",
        "surface": "#363a4f",
        "surface2": "#494d64",
        "text": "#cad3f5",
        "subtext": "#939ab7",
        "accent": "#8aadf4",
        "accent2": "#c6a0f6",
        "border": "#494d64",
        "colors": ["#8aadf4", "#c6a0f6", "#cad3f5", "#939ab7", "#494d64", "#363a4f", "#24273a", "#1e2030"],
    }
    fallback["dark"] = dict(fallback)
    fallback["light"] = {
        "base": "#eff1f5",
        "mantle": "#e6e9ef",
        "surface": "#ccd0da",
        "surface2": "#bcc0cc",
        "text": "#4c4f69",
        "subtext": "#6c6f85",
        "accent": "#1e66f5",
        "accent2": "#8839ef",
        "border": "#bcc0cc",
        "colors": fallback["colors"],
    }

    try:
        palette = pick_palette(parse_histogram(image_path))
    except Exception:
        palette = fallback

    payload = json.dumps(palette, ensure_ascii=True)
    if output_path is not None:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(payload, encoding="utf-8")

    print(payload)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
