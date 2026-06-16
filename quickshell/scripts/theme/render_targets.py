#!/usr/bin/env python3

from __future__ import annotations

import json
import os
import re
import shutil
import errno
import colorsys
import sys
from configparser import ConfigParser
from pathlib import Path


HOME = Path.home()
CONFIG_HOME = Path(os.environ.get("XDG_CONFIG_HOME", HOME / ".config"))
CACHE_HOME = Path(os.environ.get("XDG_CACHE_HOME", HOME / ".cache"))
STATE_HOME = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state"))
DATA_HOME = Path(os.environ.get("XDG_DATA_HOME", HOME / ".local/share"))
THEME_NAME = "AjisaiShell"
ICON_THEME_NAME = "AjisaiPapirus"


def hex_to_rgb_triplet(value: str) -> str:
    value = value.lstrip("#")
    return ",".join(str(int(value[i : i + 2], 16)) for i in (0, 2, 4))


def hex_to_rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))


def rgb_to_hex(value: tuple[int, int, int]) -> str:
    return "#{:02x}{:02x}{:02x}".format(*value)


def mix_hex(a: str, b: str, ratio: float) -> str:
    a_rgb = hex_to_rgb(a)
    b_rgb = hex_to_rgb(b)
    mixed = tuple(
        max(0, min(255, round((1 - ratio) * left + ratio * right)))
        for left, right in zip(a_rgb, b_rgb, strict=True)
    )
    return rgb_to_hex(mixed)


def terminal_palette(palette: dict[str, str]) -> dict[str, str]:
    terminal_background = mix_hex(palette["mantle"], palette["base"], 0.18)
    terminal_foreground = mix_hex(palette["text"], palette["accent"], 0.03)
    terminal_black = mix_hex(palette["mantle"], terminal_background, 0.10)
    terminal_bright_black = mix_hex(palette["surface"], palette["accent"], 0.04)

    # Build all ANSI accents from the extracted palette so they fully track wallpaper changes.
    # We mix with text color slightly to ensure they are visible on dark backgrounds.
    terminal_red = mix_hex(palette["accent"], palette["accent2"], 0.42)
    terminal_green = mix_hex(palette["accent2"], palette["text"], 0.35)
    terminal_yellow = mix_hex(palette["accent"], palette["text"], 0.35)
    terminal_blue = mix_hex(palette["accent"], palette["text"], 0.45)
    terminal_magenta = mix_hex(palette["accent2"], palette["accent"], 0.22)
    terminal_cyan = mix_hex(palette["accent2"], palette["text"], 0.55)
    terminal_selection_background = mix_hex(terminal_background, palette["accent"], 0.25)

    return {
        "foreground": terminal_foreground,
        "background": terminal_background,
        "regular0": terminal_black,
        "regular1": terminal_red,
        "regular2": terminal_green,
        "regular3": terminal_yellow,
        "regular4": terminal_blue,
        "regular5": terminal_magenta,
        "regular6": terminal_cyan,
        "regular7": terminal_foreground,
        "bright0": terminal_bright_black,
        "bright1": mix_hex(terminal_red, palette["text"], 0.35),
        "bright2": mix_hex(terminal_green, palette["text"], 0.35),
        "bright3": mix_hex(terminal_yellow, palette["text"], 0.35),
        "bright4": mix_hex(terminal_blue, palette["text"], 0.45),
        "bright5": mix_hex(terminal_magenta, palette["text"], 0.45),
        "bright6": mix_hex(terminal_cyan, palette["text"], 0.45),
        "bright7": palette["text"],
        "selection_foreground": terminal_foreground,
        "selection_background": terminal_selection_background,
        "cursor": terminal_foreground,
    }


def write_file(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    try:
        path.write_text(content, encoding="utf-8")
    except OSError as error:
        if error.errno != errno.EROFS or not path.is_symlink():
            raise
        path.unlink()
        path.write_text(content, encoding="utf-8")


def update_ini(path: Path, section: str, values: dict[str, str]) -> None:
    config = ConfigParser()
    config.optionxform = str
    if path.exists():
        config.read(path, encoding="utf-8")
    if not config.has_section(section):
        config.add_section(section)
    for key, value in values.items():
        config.set(section, key, value)
    path.parent.mkdir(parents=True, exist_ok=True)
    try:
        with path.open("w", encoding="utf-8") as file:
            config.write(file, space_around_delimiters=False)
    except OSError as error:
        if error.errno != errno.EROFS or not path.is_symlink():
            raise
        path.unlink()
        with path.open("w", encoding="utf-8") as file:
            config.write(file, space_around_delimiters=False)


def remove_ini_section(path: Path, section: str) -> None:
    if not path.exists():
        return

    config = ConfigParser()
    config.optionxform = str
    config.read(path, encoding="utf-8")
    if not config.remove_section(section):
        return

    try:
        with path.open("w", encoding="utf-8") as file:
            config.write(file, space_around_delimiters=False)
    except OSError as error:
        if error.errno != errno.EROFS or not path.is_symlink():
            raise
        path.unlink()
        with path.open("w", encoding="utf-8") as file:
            config.write(file, space_around_delimiters=False)


def prepend_desktop_association(value: str, desktop_id: str) -> str:
    items = [item for item in value.split(";") if item]
    items = [item for item in items if item != desktop_id]
    return ";".join([desktop_id, *items]) + ";"


def update_mimeapps(path: Path) -> None:
    defaults = {
        "inode/directory": "org.kde.dolphin.desktop",
        "image/bmp": "qimgv.desktop",
        "image/gif": "qimgv.desktop",
        "image/jpeg": "qimgv.desktop",
        "image/jpg": "qimgv.desktop",
        "image/png": "qimgv.desktop",
        "image/svg+xml": "qimgv.desktop",
        "image/webp": "qimgv.desktop",
        "video/mp4": "org.kde.haruna.desktop",
        "video/mpeg": "org.kde.haruna.desktop",
        "video/ogg": "org.kde.haruna.desktop",
        "video/quicktime": "org.kde.haruna.desktop",
        "video/webm": "org.kde.haruna.desktop",
        "video/x-matroska": "org.kde.haruna.desktop",
        "video/x-ms-wmv": "org.kde.haruna.desktop",
    }

    config = ConfigParser()
    config.optionxform = str
    if path.exists():
        config.read(path, encoding="utf-8")
    for section in ("Default Applications", "Added Associations"):
        if not config.has_section(section):
            config.add_section(section)

    for mime, desktop_id in defaults.items():
        config.set("Default Applications", mime, desktop_id)
        current = config.get("Added Associations", mime, fallback="")
        config.set("Added Associations", mime, prepend_desktop_association(current, desktop_id))

    path.parent.mkdir(parents=True, exist_ok=True)
    try:
        with path.open("w", encoding="utf-8") as file:
            config.write(file, space_around_delimiters=False)
    except OSError as error:
        if error.errno != errno.EROFS or not path.is_symlink():
            raise
        path.unlink()
        with path.open("w", encoding="utf-8") as file:
            config.write(file, space_around_delimiters=False)


def update_ini_from_text(path: Path, content: str) -> None:
    source = ConfigParser()
    source.optionxform = str
    source.read_string(content)

    config = ConfigParser()
    config.optionxform = str
    if path.exists():
        config.read(path, encoding="utf-8")

    for section in source.sections():
        if not config.has_section(section):
            config.add_section(section)
        for key, value in source.items(section):
            config.set(section, key, value)

    path.parent.mkdir(parents=True, exist_ok=True)
    try:
        with path.open("w", encoding="utf-8") as file:
            config.write(file, space_around_delimiters=False)
    except OSError as error:
        if error.errno != errno.EROFS or not path.is_symlink():
            raise
        path.unlink()
        with path.open("w", encoding="utf-8") as file:
            config.write(file, space_around_delimiters=False)


def current_wallpaper_path() -> str:
    wallpaper_file = STATE_HOME / "quickshell/theme/current-wallpaper"
    if not wallpaper_file.exists():
        return ""
    return wallpaper_file.read_text(encoding="utf-8").strip()


def current_mode() -> str:
    mode_file = STATE_HOME / "quickshell/theme/mode"
    if not mode_file.exists():
        return "dark"

    mode = mode_file.read_text(encoding="utf-8").strip().lower()
    return mode if mode in {"dark", "light"} else "dark"


def active_palette(payload: dict[str, object], mode: str) -> dict[str, str]:
    selected = payload.get(mode)
    if isinstance(selected, dict):
        return selected
    return payload


def render_gtk_colors(palette: dict[str, str]) -> str:
    return f"""@define-color theme_bg_color {palette["base"]};
@define-color theme_fg_color {palette["text"]};
@define-color theme_base_color {palette["mantle"]};
@define-color theme_selected_bg_color {palette["accent"]};
@define-color theme_selected_fg_color {palette["text"]};
@define-color theme_unfocused_fg_color {palette["subtext"]};
@define-color theme_unfocused_bg_color {palette["surface"]};
@define-color borders {palette["border"]};
@define-color window_bg_color {palette["base"]};
@define-color window_fg_color {palette["text"]};
@define-color view_bg_color {palette["mantle"]};
@define-color view_fg_color {palette["text"]};
@define-color headerbar_bg_color {palette["surface"]};
@define-color headerbar_fg_color {palette["text"]};
@define-color accent_color {palette["accent"]};
@define-color accent_bg_color {palette["accent"]};
@define-color accent_fg_color {palette["text"]};
@define-color card_bg_color {palette["surface"]};
@define-color card_fg_color {palette["text"]};
@define-color popover_bg_color {palette["surface"]};
@define-color popover_fg_color {palette["text"]};
"""


def render_gtk_settings(mode: str) -> str:
    prefer_dark = "1" if mode == "dark" else "0"
    theme = "Adwaita-dark" if mode == "dark" else "Adwaita"
    return f"""[Settings]
gtk-application-prefer-dark-theme={prefer_dark}
gtk-theme-name={theme}
gtk-icon-theme-name={ICON_THEME_NAME}
gtk-font-name=Sawarabi Gothic 13
"""


def render_kde_colors(palette: dict[str, str]) -> str:
    base = hex_to_rgb_triplet(palette["base"])
    mantle = hex_to_rgb_triplet(palette["mantle"])
    surface = hex_to_rgb_triplet(palette["surface"])
    border = hex_to_rgb_triplet(palette["border"])
    text = hex_to_rgb_triplet(palette["text"])
    subtext = hex_to_rgb_triplet(palette["subtext"])
    accent = hex_to_rgb_triplet(palette["accent"])
    accent2 = hex_to_rgb_triplet(palette["accent2"])

    term = terminal_palette(palette)
    red = hex_to_rgb_triplet(term["regular1"])
    yellow = hex_to_rgb_triplet(term["regular3"])
    green = hex_to_rgb_triplet(term["regular2"])

    return f"""[General]
ColorScheme={THEME_NAME}
Name={THEME_NAME}
fixed=Mononoki Nerd Font Mono,13,-1,5,50,0,0,0,0,0,Regular
font=Sawarabi Gothic,13,-1,5,50,0,0,0,0,0,Regular
menuFont=Sawarabi Gothic,13,-1,5,50,0,0,0,0,0,Regular
shadeSortColumn=true
smallestReadableFont=Sawarabi Gothic,11,-1,5,50,0,0,0,0,0,Regular
toolBarFont=Sawarabi Gothic,13,-1,5,50,0,0,0,0,0,Regular

[Icons]
Theme={ICON_THEME_NAME}

[Colors:Button]
BackgroundAlternate={surface}
BackgroundNormal={surface}
DecorationFocus={accent}
DecorationHover={accent2}
ForegroundActive={accent}
ForegroundInactive={subtext}
ForegroundLink={accent2}
ForegroundNegative={red}
ForegroundNeutral={yellow}
ForegroundNormal={text}
ForegroundPositive={green}
ForegroundVisited={accent2}

[Colors:Complementary]
BackgroundAlternate={surface}
BackgroundNormal={base}
DecorationFocus={accent}
DecorationHover={accent2}
ForegroundActive={accent}
ForegroundInactive={subtext}
ForegroundLink={accent2}
ForegroundNegative={red}
ForegroundNeutral={yellow}
ForegroundNormal={text}
ForegroundPositive={green}
ForegroundVisited={accent2}

[Colors:Header]
BackgroundAlternate={surface}
BackgroundNormal={base}
DecorationFocus={accent}
DecorationHover={accent2}
ForegroundActive={accent}
ForegroundInactive={subtext}
ForegroundLink={accent2}
ForegroundNegative={red}
ForegroundNeutral={yellow}
ForegroundNormal={text}
ForegroundPositive={green}
ForegroundVisited={accent2}

[Colors:Header][Inactive]
BackgroundAlternate={surface}
BackgroundNormal={base}
DecorationFocus={accent}
DecorationHover={accent2}
ForegroundActive={accent}
ForegroundInactive={subtext}
ForegroundLink={accent2}
ForegroundNegative={red}
ForegroundNeutral={yellow}
ForegroundNormal={subtext}
ForegroundPositive={green}
ForegroundVisited={accent2}

[Colors:Selection]
BackgroundAlternate={accent}
BackgroundNormal={accent}
DecorationFocus={accent}
DecorationHover={accent2}
ForegroundActive={text}
ForegroundInactive={text}
ForegroundLink={text}
ForegroundNegative={text}
ForegroundNeutral={text}
ForegroundNormal={text}
ForegroundPositive={text}
ForegroundVisited={text}

[Colors:Tooltip]
BackgroundAlternate={surface}
BackgroundNormal={surface}
DecorationFocus={accent}
DecorationHover={accent2}
ForegroundActive={accent}
ForegroundInactive={subtext}
ForegroundLink={accent2}
ForegroundNegative={red}
ForegroundNeutral={yellow}
ForegroundNormal={text}
ForegroundPositive={green}
ForegroundVisited={accent2}

[Colors:View]
BackgroundAlternate={surface}
BackgroundNormal={mantle}
DecorationFocus={accent}
DecorationHover={accent2}
ForegroundActive={accent}
ForegroundInactive={subtext}
ForegroundLink={accent2}
ForegroundNegative={red}
ForegroundNeutral={yellow}
ForegroundNormal={text}
ForegroundPositive={green}
ForegroundVisited={accent2}

[Colors:Window]
BackgroundAlternate={surface}
BackgroundNormal={base}
DecorationFocus={accent}
DecorationHover={accent2}
ForegroundActive={accent}
ForegroundInactive={subtext}
ForegroundLink={accent2}
ForegroundNegative={red}
ForegroundNeutral={yellow}
ForegroundNormal={text}
ForegroundPositive={green}
ForegroundVisited={accent2}

[ColorEffects:Disabled]
Color={border}
ColorAmount=0
ColorEffect=0
ContrastAmount=0.65
ContrastEffect=1
IntensityAmount=0.1
IntensityEffect=2

[ColorEffects:Inactive]
Color={border}
ColorAmount=0
ColorEffect=0
ContrastAmount=0
ContrastEffect=0
IntensityAmount=0
IntensityEffect=0

[WM]
activeBackground={surface}
activeForeground={text}
inactiveBackground={base}
inactiveForeground={subtext}
"""


def icon_data_roots() -> list[Path]:
    roots = [Path(path) for path in os.environ.get("XDG_DATA_DIRS", "").split(":") if path]
    roots.extend([
        HOME / ".nix-profile/share",
        HOME / ".local/state/nix/profile/share",
        Path(f"/etc/profiles/per-user/{os.environ.get('USER', '')}/share"),
        Path("/run/current-system/sw/share"),
    ])

    seen = set()
    result = []
    for root in roots:
        if root in seen:
            continue
        seen.add(root)
        result.append(root)
    return result


def papirus_theme_name(mode: str) -> str:
    return "Papirus-Light" if mode == "light" else "Papirus-Dark"


def papirus_theme_dir(mode: str) -> Path | None:
    theme_name = papirus_theme_name(mode)
    for root in icon_data_roots():
        candidate = root / "icons" / theme_name
        if (candidate / "index.theme").exists():
            return candidate
    return None


def render_icon_theme_index(directories: list[str], mode: str) -> str:
    directory_text = ",".join(directories)
    lines = [
        "[Icon Theme]",
        f"Name={ICON_THEME_NAME}",
        "Comment=Generated AjisaiShell Papirus folder colors",
        f"Inherits={papirus_theme_name(mode)},Papirus,hicolor",
        "Example=folder",
        "FollowsColorScheme=true",
        "DesktopDefault=48",
        "ToolbarDefault=22",
        "MainToolbarDefault=22",
        "SmallDefault=16",
        "PanelDefault=48",
        "DialogDefault=48",
        f"Directories={directory_text}",
    ]
    scaled = [directory for directory in directories if "@" in directory]
    if scaled:
        lines.append(f"ScaledDirectories={','.join(scaled)}")
    lines.append("")

    for directory in directories:
        size_match = re.match(r"(\d+)x\d+(?:@(\d+)x)?/(places|mimetypes)", directory)
        if not size_match:
            continue
        size = size_match.group(1)
        scale = size_match.group(2)
        context = "MimeTypes" if directory.endswith("/mimetypes") else "Places"
        lines.extend([
            f"[{directory}]",
            f"Context={context}",
            f"Size={size}",
            "Type=Fixed",
        ])
        if scale:
            lines.append(f"Scale={scale}")
        lines.append("")

    return "\n".join(lines)


def render_folder_icon_svg(svg: str, palette: dict[str, str], mode: str) -> str:
    main = mix_hex(palette["accent"], palette["accent2"], 0.16)
    dark = mix_hex(main, palette["mantle"], 0.42)
    tab = mix_hex(main, palette["text"], 0.70 if mode == "dark" else 0.56)
    shadow = mix_hex(dark, "#000000", 0.35)

    def replace_fill(match: re.Match[str]) -> str:
        color = match.group(1)
        r, g, b = hex_to_rgb(color)
        h, lightness, saturation = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)

        if saturation < 0.10 and lightness < 0.18:
            target = color
        elif saturation < 0.10 and lightness > 0.74:
            target = tab
        elif lightness < 0.42:
            target = dark
        elif lightness > 0.72:
            target = tab
        else:
            target = main

        return f"fill:{target}"

    svg = re.sub(r"fill:(#[0-9a-fA-F]{6})", replace_fill, svg)

    return svg.replace("opacity:0.2", f"opacity:0.22;fill:{shadow}", 1)


def write_icon_theme(theme_dir: Path, palette: dict[str, str], mode: str) -> bool:
    source = papirus_theme_dir(mode)
    if source is None:
        return False

    old_shadow = DATA_HOME / "icons" / "Papirus-Dark"
    old_index = old_shadow / "index.theme"
    if old_index.exists() and "Generated AjisaiShell" in old_index.read_text(encoding="utf-8", errors="ignore"):
        shutil.rmtree(old_shadow)

    if theme_dir.exists():
        shutil.rmtree(theme_dir)

    directories = set()
    for pattern in ("*/places/folder*.svg", "*/places/stock_folder.svg"):
        for icon in source.glob(pattern):
            if not icon.is_file():
                continue
            target = theme_dir / icon.relative_to(source)
            svg = icon.read_text(encoding="utf-8")
            write_file(target, render_folder_icon_svg(svg, palette, mode))
            directories.add(str(icon.parent.relative_to(source)))

    folder_aliases = {
        "folder.svg": [
            "inode-directory.svg",
            "user-home.svg",
            "user-trash.svg",
            "folder-home.svg",
        ],
        "folder-desktop.svg": ["user-desktop.svg"],
        "folder-documents.svg": ["user-documents.svg"],
        "folder-download.svg": ["user-download.svg", "user-downloads.svg"],
        "folder-music.svg": ["user-music.svg"],
        "folder-pictures.svg": ["user-pictures.svg"],
        "folder-publicshare.svg": ["user-publicshare.svg"],
        "folder-templates.svg": ["user-templates.svg"],
        "folder-videos.svg": ["user-videos.svg"],
        "folder-remote.svg": ["network-server.svg"],
        "folder-network.svg": ["network-workgroup.svg"],
    }

    for places_dir in sorted(d for d in directories if d.endswith("/places")):
        target_places_dir = theme_dir / places_dir
        mimetypes_dir = Path(places_dir).parent / "mimetypes"
        for source_name, aliases in folder_aliases.items():
            source_icon = target_places_dir / source_name
            if not source_icon.exists():
                source_icon = target_places_dir / "folder.svg"
            if not source_icon.exists():
                continue

            svg = source_icon.read_text(encoding="utf-8")
            for alias in aliases:
                alias_context = mimetypes_dir if alias == "inode-directory.svg" else Path(places_dir)
                write_file(theme_dir / alias_context / alias, svg)
                directories.add(str(alias_context))

    write_file(theme_dir / "index.theme", render_icon_theme_index(sorted(directories), mode))

    return True


def kvantum_template_dir(mode: str) -> Path | None:
    manager = shutil.which("kvantummanager")
    if not manager:
        return None

    share = Path(manager).resolve().parents[1] / "share/Kvantum"
    template = "KvFlatLight" if mode == "light" else "KvFlat"
    path = share / template
    return path if path.exists() else None


def render_kvantum_config(palette: dict[str, str], mode: str) -> str:
    template_dir = kvantum_template_dir(mode)
    template_name = "KvFlatLight" if mode == "light" else "KvFlat"
    if template_dir:
        template_file = template_dir / f"{template_name}.kvconfig"
        if template_file.exists():
            content = template_file.read_text(encoding="utf-8")
        else:
            content = ""
    else:
        content = ""

    if not content:
        content = """[%General]
author=AjisaiShell
comment=Generated AjisaiShell Kvantum theme
composite=true
menu_shadow_depth=4
tooltip_shadow_depth=4
scroll_width=10
scroll_arrows=false
toolbar_icon_size=16
animate_states=true
transient_scrollbar=true

[GeneralColors]
window.color=#202020
base.color=#181818
alt.base.color=#242424
button.color=#303030
light.color=#383838
mid.light.color=#303030
dark.color=#101010
mid.color=#282828
highlight.color=#5e81ac
inactive.highlight.color=#4c566a
text.color=#ffffff
window.text.color=#ffffff
button.text.color=#ffffff
disabled.text.color=#808080
tooltip.text.color=#ffffff
highlight.text.color=#ffffff
link.color=#88c0d0
link.visited.color=#b48ead

[Hacks]
transparent_ktitle_label=true
transparent_dolphin_view=false
respect_darkness=true
""";

    replacements = {
        "window.color": palette["base"],
        "base.color": palette["mantle"],
        "alt.base.color": palette["surface"],
        "button.color": mix_hex(palette["surface"], palette["surface2"], 0.35),
        "light.color": palette["surface2"],
        "mid.light.color": palette["surface"],
        "dark.color": mix_hex(palette["mantle"], "#000000", 0.35),
        "mid.color": palette["border"],
        "highlight.color": palette["accent"],
        "inactive.highlight.color": mix_hex(palette["accent"], palette["surface"], 0.55),
        "text.color": palette["text"],
        "window.text.color": palette["text"],
        "button.text.color": palette["text"],
        "disabled.text.color": palette["subtext"],
        "tooltip.text.color": palette["text"],
        "highlight.text.color": palette["text"],
        "link.color": palette["accent2"],
        "link.visited.color": mix_hex(palette["accent2"], palette["accent"], 0.35),
        "progress.indicator.text.color": palette["text"],
    }

    lines = []
    seen = set()
    for line in content.splitlines():
        key = line.split("=", 1)[0].strip()
        if key in replacements:
            lines.append(f"{key}={replacements[key]}")
            seen.add(key)
        elif key in {"text.normal.color", "text.press.color", "text.toggle.color"}:
            lines.append(f"{key}={palette['text']}")
        elif key == "text.focus.color":
            lines.append(f"{key}={palette['accent']}")
        elif key == "text.shadow.color":
            lines.append(f"{key}={palette['mantle']}")
        elif key == "text.shadow.alpha":
            lines.append("text.shadow.alpha=120")
        elif key == "author":
            lines.append("author=AjisaiShell")
        elif key == "comment":
            lines.append("comment=Generated from the active AjisaiShell wallpaper palette")
        elif key == "menu_shadow_depth":
            lines.append("menu_shadow_depth=4")
        elif key == "tooltip_shadow_depth":
            lines.append("tooltip_shadow_depth=4")
        elif key == "translucent_windows":
            lines.append("translucent_windows=false")
        elif key == "popup_blurring":
            lines.append("popup_blurring=false")
        elif key == "blurring":
            lines.append("blurring=false")
        elif key == "respect_darkness":
            lines.append(f"respect_darkness={'true' if mode == 'dark' else 'false'}")
        else:
            lines.append(line)

    missing = [f"{key}={value}" for key, value in replacements.items() if key not in seen]
    if missing:
        try:
            insert_at = lines.index("[Hacks]")
        except ValueError:
            insert_at = len(lines)
        lines[insert_at:insert_at] = missing + [""]

    return "\n".join(lines).rstrip() + "\n"


def render_kvantum_svg(mode: str) -> str:
    template_dir = kvantum_template_dir(mode)
    template_name = "KvFlatLight" if mode == "light" else "KvFlat"
    if template_dir:
        template_file = template_dir / f"{template_name}.svg"
        if template_file.exists():
            return template_file.read_text(encoding="utf-8")
    return """<svg width="1" height="1" xmlns="http://www.w3.org/2000/svg">
<rect id="base" x="0" y="0" width="1" height="1" fill="#ffffff"/>
</svg>
"""


def recolor_kvantum_svg(svg: str, palette: dict[str, str]) -> str:
    def replace(match: re.Match[str]) -> str:
        value = match.group(0)
        r, g, b = hex_to_rgb(value)
        _, lightness, saturation = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)

        if saturation < 0.14:
            if lightness < 0.16:
                return mix_hex(palette["mantle"], "#000000", 0.20)
            if lightness < 0.34:
                return palette["mantle"]
            if lightness < 0.52:
                return palette["surface"]
            if lightness < 0.74:
                return palette["surface2"]
            return palette["text"]

        if lightness < 0.34:
            return mix_hex(palette["accent"], palette["mantle"], 0.55)
        if lightness > 0.72:
            return mix_hex(palette["accent"], palette["text"], 0.34)
        return mix_hex(palette["accent"], palette["accent2"], 0.15)

    return re.sub(r"#[0-9A-Fa-f]{6}", replace, svg)


def qt_argb(value: str) -> str:
    return f"#ff{value.lstrip('#').lower()}"


def render_qtct_colors(palette: dict[str, str]) -> str:
    term = terminal_palette(palette)
    base = qt_argb(palette["base"])
    mantle = qt_argb(palette["mantle"])
    surface = qt_argb(palette["surface"])
    surface2 = qt_argb(palette["surface2"])
    border = qt_argb(palette["border"])
    text = qt_argb(palette["text"])
    subtext = qt_argb(palette["subtext"])
    accent = qt_argb(palette["accent"])
    accent2 = qt_argb(palette["accent2"])
    red = qt_argb(term["regular1"])

    active = [
        base, text, mantle, surface, surface2, text, text, surface, text, text,
        surface2, surface, border, border, qt_argb("#000000"), accent, text, accent2, accent2,
        subtext, accent,
    ]
    inactive = [
        base, text, mantle, surface, surface2, text, text, surface, text, text,
        surface2, surface, border, border, qt_argb("#000000"), surface2, text, accent2, accent2,
        subtext, accent,
    ]
    disabled = [
        base, subtext, mantle, surface, surface2, subtext, subtext, surface, subtext, text,
        surface2, surface, border, border, qt_argb("#000000"), surface2, subtext, accent2, red,
        subtext, surface2,
    ]

    return "\n".join([
        "[ColorScheme]",
        f"active_colors={','.join(active)}",
        f"disabled_colors={','.join(disabled)}",
        f"inactive_colors={','.join(inactive)}",
        "",
    ])


def desktop_entry(name: str, generic_name: str, comment: str, exec_command: str, icon: str, categories: str, mime: str = "") -> str:
    lines = [
        "[Desktop Entry]",
        "Version=1.0",
        f"Name={name}",
        f"GenericName={generic_name}",
        f"Comment={comment}",
        f"Exec=env QT_QPA_PLATFORMTHEME=kde QT_STYLE_OVERRIDE=kvantum KDE_SESSION_VERSION=6 XDG_CURRENT_DESKTOP=KDE:Hyprland {exec_command}",
        f"Icon={icon}",
        "Terminal=false",
        "Type=Application",
        f"Categories={categories}",
    ]
    if mime:
        lines.append(f"MimeType={mime}")
    return "\n".join(lines) + "\n"


def render_foot_ini(palette: dict[str, str]) -> str:
    term = terminal_palette(palette)

    colors = f"""alpha=1.0
foreground={term["foreground"].lstrip("#")}
background={term["background"].lstrip("#")}
regular0={term["regular0"].lstrip("#")}
regular1={term["regular1"].lstrip("#")}
regular2={term["regular2"].lstrip("#")}
regular3={term["regular3"].lstrip("#")}
regular4={term["regular4"].lstrip("#")}
regular5={term["regular5"].lstrip("#")}
regular6={term["regular6"].lstrip("#")}
regular7={term["regular7"].lstrip("#")}
bright0={term["bright0"].lstrip("#")}
bright1={term["bright1"].lstrip("#")}
bright2={term["bright2"].lstrip("#")}
bright3={term["bright3"].lstrip("#")}
bright4={term["bright4"].lstrip("#")}
bright5={term["bright5"].lstrip("#")}
bright6={term["bright6"].lstrip("#")}
bright7={term["bright7"].lstrip("#")}
selection-foreground={term["selection_foreground"].lstrip("#")}
selection-background={term["selection_background"].lstrip("#")}"""

    return f"""[colors-dark]
{colors}
"""


def render_kitty_conf(palette: dict[str, str]) -> str:
    term = terminal_palette(palette)

    return f"""foreground {term["foreground"]}
background {term["background"]}
selection_foreground {term["selection_foreground"]}
selection_background {term["selection_background"]}
cursor {term["cursor"]}
cursor_text_color {term["background"]}
active_border_color {palette["accent"]}
inactive_border_color {palette["border"]}
color0 {term["regular0"]}
color1 {term["regular1"]}
color2 {term["regular2"]}
color3 {term["regular3"]}
color4 {term["regular4"]}
color5 {term["regular5"]}
color6 {term["regular6"]}
color7 {term["regular7"]}
color8 {term["bright0"]}
color9 {term["bright1"]}
color10 {term["bright2"]}
color11 {term["bright3"]}
color12 {term["bright4"]}
color13 {term["bright5"]}
color14 {term["bright6"]}
color15 #ffffff
"""


def render_terminal_sequences(palette: dict[str, str]) -> str:
    term = terminal_palette(palette)
    values = [
        term["regular0"],
        term["regular1"],
        term["regular2"],
        term["regular3"],
        term["regular4"],
        term["regular5"],
        term["regular6"],
        term["regular7"],
        term["bright0"],
        term["bright1"],
        term["bright2"],
        term["bright3"],
        term["bright4"],
        term["bright5"],
        term["bright6"],
        term["bright7"],
    ]

    seq = []
    for index, color in enumerate(values):
        seq.append(f"\033]4;{index};{color}\033\\")
    seq.append(f"\033]10;{term['foreground']}\033\\")
    seq.append(f"\033]11;[100]{term['background']}\033\\")
    seq.append(f"\033]12;{term['cursor']}\033\\")
    seq.append(f"\033]13;{term['cursor']}\033\\")
    seq.append(f"\033]17;{term['foreground']}\033\\")
    seq.append(f"\033]19;{term['background']}\033\\")
    seq.append(f"\033]4;232;{term['background']}\033\\")
    seq.append(f"\033]4;256;{term['foreground']}\033\\")
    seq.append(f"\033]4;257;{term['background']}\033\\")
    seq.append(f"\033]708;[100]{term['background']}\033\\")
    return "".join(seq)


def render_pywal_colors_sh(palette: dict[str, str], wallpaper: str) -> str:
    term = terminal_palette(palette)

    lines = [
        "# Shell variables",
        "# Generated by Quickshell theme runtime",
        f'wallpaper="{wallpaper}"',
        "",
        "# Special",
        f"background='{term['background']}'",
        f"foreground='{term['foreground']}'",
        f"cursor='{term['cursor']}'",
        "",
        "# Colors",
    ]

    values = [
        term["regular0"],
        term["regular1"],
        term["regular2"],
        term["regular3"],
        term["regular4"],
        term["regular5"],
        term["regular6"],
        term["regular7"],
        term["bright0"],
        term["bright1"],
        term["bright2"],
        term["bright3"],
        term["bright4"],
        term["bright5"],
        term["bright6"],
        term["bright7"],
    ]
    for index, color in enumerate(values):
        lines.append(f"color{index}='{color}'")

    lines.extend([
        "",
        "# FZF colors",
        'export FZF_DEFAULT_OPTS="',
        '    $FZF_DEFAULT_OPTS',
        "    --color fg:7,bg:0,hl:1,fg+:232,bg+:1,hl+:255",
        "    --color info:7,prompt:2,spinner:1,pointer:232,marker:1",
        '"',
        "",
        "# Fix LS_COLORS being unreadable.",
        'export LS_COLORS="${LS_COLORS}:su=30;41:ow=30;42:st=30;44:"',
        "",
    ])
    return "\n".join(lines)


def render_pywal_foot_ini(palette: dict[str, str]) -> str:
    term = terminal_palette(palette)

    return f"""[colors]
background={term["background"].lstrip("#")}
foreground={term["foreground"].lstrip("#")}
regular0={term["regular0"].lstrip("#")}
regular1={term["regular1"].lstrip("#")}
regular2={term["regular2"].lstrip("#")}
regular3={term["regular3"].lstrip("#")}
regular4={term["regular4"].lstrip("#")}
regular5={term["regular5"].lstrip("#")}
regular6={term["regular6"].lstrip("#")}
regular7={term["regular7"].lstrip("#")}
bright0={term["bright0"].lstrip("#")}
bright1={term["bright1"].lstrip("#")}
bright2={term["bright2"].lstrip("#")}
bright3={term["bright3"].lstrip("#")}
bright4={term["bright4"].lstrip("#")}
bright5={term["bright5"].lstrip("#")}
bright6={term["bright6"].lstrip("#")}
bright7={term["bright7"].lstrip("#")}
alpha=1.0
"""


def render_zsh_prompt(palette: dict[str, str]) -> str:
    return """autoload -U colors && colors
autoload -Uz add-zsh-hook

# Runtime prompt generated by Quickshell.
typeset -g AJISAI_PROMPT_FILE="${HOME}/.config/quickshell/generated/shell/prompt.zsh"
typeset -g AJISAI_PROMPT_STAMP="${AJISAI_PROMPT_STAMP:-}"

function _ajisai_reload_prompt() {
    local stamp
    stamp="$(stat -c %Y "$AJISAI_PROMPT_FILE" 2>/dev/null)" || return
    [[ "$stamp" == "$AJISAI_PROMPT_STAMP" ]] && return
    AJISAI_PROMPT_STAMP="$stamp"
    source "$AJISAI_PROMPT_FILE"
}

if [[ -z "${AJISAI_PROMPT_HOOKED:-}" ]]; then
    typeset -g AJISAI_PROMPT_HOOKED=1
    add-zsh-hook precmd _ajisai_reload_prompt
fi

PROMPT='%(?:%F{4}➜%f:%F{1}➜%f) %F{5}%1~%f '
"""


def load_theme_state() -> tuple[str, dict[str, str], str]:
    palette_file = STATE_HOME / "quickshell/theme/palette.json"
    payload = json.loads(palette_file.read_text(encoding="utf-8"))
    mode = current_mode()
    palette = active_palette(payload, mode)
    wallpaper = current_wallpaper_path()
    return mode, palette, wallpaper


def write_terminal_targets(palette: dict[str, str], wallpaper: str) -> dict[str, str]:
    terminal_dir = CONFIG_HOME / "quickshell/generated/terminal"
    foot_dir = CONFIG_HOME / "foot"
    kitty_dir = CONFIG_HOME / "kitty"
    wal_dir = CACHE_HOME / "wal"
    shell_dir = CONFIG_HOME / "quickshell/generated/shell"

    foot_theme = render_foot_ini(palette)
    kitty_theme = render_kitty_conf(palette)
    terminal_sequences = render_terminal_sequences(palette)
    pywal_colors_sh = render_pywal_colors_sh(palette, wallpaper)
    pywal_foot = render_pywal_foot_ini(palette)
    zsh_prompt = render_zsh_prompt(palette)

    write_file(terminal_dir / "foot.ini", foot_theme)
    write_file(terminal_dir / "kitty.conf", kitty_theme)
    write_file(terminal_dir / "sequences.txt", terminal_sequences)
    write_file(foot_dir / "quickshell-theme.ini", foot_theme)
    write_file(kitty_dir / "quickshell-theme.conf", kitty_theme)
    write_file(shell_dir / "prompt.zsh", zsh_prompt)
    write_file(wal_dir / "colors.sh", pywal_colors_sh)
    write_file(wal_dir / "sequences", terminal_sequences)
    write_file(wal_dir / "colors-foot.ini", pywal_foot)
    write_file(wal_dir / "wal", f"{wallpaper}\n")

    return {
        "foot": str(terminal_dir / "foot.ini"),
        "kitty": str(terminal_dir / "kitty.conf"),
        "sequences": str(terminal_dir / "sequences.txt"),
        "foot_include": str(foot_dir / "quickshell-theme.ini"),
        "kitty_include": str(kitty_dir / "quickshell-theme.conf"),
        "zsh_prompt": str(shell_dir / "prompt.zsh"),
        "wal_colors_sh": str(wal_dir / "colors.sh"),
        "wal_sequences": str(wal_dir / "sequences"),
    }


def write_desktop_targets(mode: str, palette: dict[str, str]) -> dict[str, str]:
    gtk3_dir = CONFIG_HOME / "gtk-3.0"
    gtk4_dir = CONFIG_HOME / "gtk-4.0"
    kde_dir = DATA_HOME / "color-schemes"
    kvantum_dir = CONFIG_HOME / "Kvantum"
    kvantum_theme_dir = kvantum_dir / THEME_NAME
    qt5ct_dir = CONFIG_HOME / "qt5ct"
    qt6ct_dir = CONFIG_HOME / "qt6ct"
    icon_theme_dir = DATA_HOME / "icons" / ICON_THEME_NAME
    applications_dir = DATA_HOME / "applications"
    qimgv_config = CONFIG_HOME / "qimgv/qimgv.conf"

    gtk_colors = render_gtk_colors(palette)
    gtk_settings = render_gtk_settings(mode)
    kde_colors = render_kde_colors(palette)
    kvantum_config = render_kvantum_config(palette, mode)
    kvantum_svg = recolor_kvantum_svg(render_kvantum_svg(mode), palette)
    qtct_colors = render_qtct_colors(palette)

    write_file(gtk3_dir / "colors.css", gtk_colors)
    write_file(gtk4_dir / "colors.css", gtk_colors)

    write_file(gtk3_dir / "gtk.css", '@import url("colors.css");\n')
    write_file(gtk4_dir / "gtk.css", '@import url("colors.css");\n')
    write_file(gtk3_dir / "settings.ini", gtk_settings)
    write_file(gtk4_dir / "settings.ini", gtk_settings)

    kde_scheme_path = kde_dir / f"{THEME_NAME}.colors"
    kvantum_config_path = kvantum_theme_dir / f"{THEME_NAME}.kvconfig"
    kvantum_svg_path = kvantum_theme_dir / f"{THEME_NAME}.svg"
    qt5ct_scheme_path = qt5ct_dir / f"colors/{THEME_NAME}.conf"
    qt6ct_scheme_path = qt6ct_dir / f"colors/{THEME_NAME}.conf"

    write_file(kde_scheme_path, kde_colors)
    write_file(kvantum_config_path, kvantum_config)
    write_file(kvantum_svg_path, kvantum_svg)
    write_icon_theme(icon_theme_dir, palette, mode)
    write_file(qt5ct_scheme_path, qtct_colors)
    write_file(qt6ct_scheme_path, qtct_colors)
    write_file(applications_dir / "org.kde.dolphin.desktop", desktop_entry(
        "Dolphin",
        "File Manager",
        "File manager launched with AjisaiShell Qt integration",
        "dolphin %u",
        "org.kde.dolphin",
        "Qt;KDE;System;FileTools;FileManager;",
        "inode/directory;",
    ))
    write_file(applications_dir / "org.kde.haruna.desktop", desktop_entry(
        "Haruna",
        "Media Player",
        "Media player launched with AjisaiShell Qt integration",
        "haruna %u",
        "haruna",
        "Qt;KDE;AudioVideo;Player;Video;TV;",
        "video/mp4;video/x-matroska;video/mpeg;video/ogg;video/quicktime;video/vnd.avi;video/mp2t;video/webm;video/x-ms-wmv;audio/aac;audio/ac3;audio/flac;audio/mp4;audio/mpeg;audio/ogg;audio/vnd.wave;audio/webm;audio/x-matroska;audio/x-mpegurl;",
    ))
    write_file(applications_dir / "qimgv.desktop", desktop_entry(
        "qimgv",
        "Image Viewer",
        "Image viewer launched with AjisaiShell Qt integration",
        "qimgv %f",
        "qimgv",
        "Qt;Graphics;Viewer;",
        "video/webm;image/jpeg;image/gif;image/png;image/bmp;image/webp;",
    ))
    update_ini(kvantum_dir / "kvantum.kvconfig", "General", {"theme": THEME_NAME})
    update_ini_from_text(CONFIG_HOME / "kdeglobals", kde_colors)
    update_ini(CONFIG_HOME / "kdeglobals", "UiSettings", {"ColorScheme": THEME_NAME})
    update_ini(qimgv_config, "General", {
        "mpvBinary": "mpv",
        "useSystemColorScheme": "true",
    })
    remove_ini_section(qimgv_config, "Theme")
    update_mimeapps(CONFIG_HOME / "mimeapps.list")
    update_ini(qt5ct_dir / "qt5ct.conf", "Appearance", {
        "color_scheme_path": str(qt5ct_scheme_path),
        "custom_palette": "true",
    })
    update_ini(qt6ct_dir / "qt6ct.conf", "Appearance", {
        "color_scheme_path": str(qt6ct_scheme_path),
        "custom_palette": "true",
    })

    return {
        "gtk3": str(gtk3_dir / "colors.css"),
        "gtk4": str(gtk4_dir / "colors.css"),
        "kde": str(kde_scheme_path),
        "kdeglobals": str(CONFIG_HOME / "kdeglobals"),
        "kvantum": str(kvantum_config_path),
        "icons": str(icon_theme_dir),
        "qt5ct": str(qt5ct_scheme_path),
        "qt6ct": str(qt6ct_scheme_path),
        "desktop_dolphin": str(applications_dir / "org.kde.dolphin.desktop"),
        "desktop_haruna": str(applications_dir / "org.kde.haruna.desktop"),
        "desktop_qimgv": str(applications_dir / "qimgv.desktop"),
        "qimgv_config": str(qimgv_config),
    }


def main() -> int:
    mode, palette, wallpaper = load_theme_state()
    terminal_only = "--terminal-only" in sys.argv[1:]
    desktop_only = "--desktop-only" in sys.argv[1:]

    result = {"mode": mode}
    if not desktop_only:
        result.update(write_terminal_targets(palette, wallpaper))
    if not terminal_only:
        result.update(write_desktop_targets(mode, palette))

    print(json.dumps(result, ensure_ascii=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
