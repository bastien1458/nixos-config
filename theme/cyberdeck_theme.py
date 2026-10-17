#!/usr/bin/env python3
"""
cyberdeck-theme: wallpaper driven colour engine for the Cyberdeck desktop.

Every "OS" is a colour picking algorithm named after cyberware from the game.
The same code runs at build time (Stylix scheme, cursor colours, greeter) and
at runtime (the OS switcher in the bar), so both always agree.

  cyberdeck-theme palette --image WALL --out DIR    build time: one json per OS
  cyberdeck-theme apply [OS] [--wallpaper W]        runtime: switch OS / wallpaper, write app themes
  cyberdeck-theme init                              runtime: (re)generate state if missing/stale
  cyberdeck-theme current                           print the active OS id
  cyberdeck-theme list                              print the catalog as json
  cyberdeck-theme wallpaper [show|set W]            print, display (swaybg) or switch the wallpaper
  cyberdeck-theme wallpapers                        print every known wallpaper as json
"""

import argparse
import colorsys
import hashlib
import json
import math
import os
import signal
import subprocess
import sys
import tempfile
import time

from PIL import Image

# --------------------------------------------------------------------------- catalog

CATALOG = [
    {
        "id": "netwatch",
        "name": "NETWATCH NETDRIVER MK.5",
        "short": "NETDRIVER",
        "maker": "NETWATCH",
        "logo": "netwatch",
        "class": "CYBERDECK",
        "tier": "LEGENDARY",
        "tagline": "FAITHFUL SCAN",
        "desc": "Samples the strongest neon signatures of the wallpaper and keeps them untouched.",
    },
    {
        "id": "canto",
        "name": "MILITECH CANTO MK.6",
        "short": "CANTO MK.6",
        "maker": "MILITECH",
        "logo": "militech",
        "class": "CYBERDECK",
        "tier": "LEGENDARY",
        "tagline": "TARGET LOCK",
        "desc": "Locks onto the dominant neon and builds a disciplined analogous palette around it.",
    },
    {
        "id": "arasaka",
        "name": "ARASAKA MK.4",
        "short": "ARASAKA MK.4",
        "maker": "ARASAKA",
        "logo": "arasaka",
        "class": "CYBERDECK",
        "tier": "EPIC",
        "tagline": "CORPORATE PROTOCOL",
        "desc": "Strips the city down to brushed steel and keeps a single blood-red signature.",
    },
    {
        "id": "sandevistan",
        "name": "MILITECH \"APOGEE\" SANDEVISTAN",
        "short": "APOGEE",
        "maker": "MILITECH",
        "logo": "militech",
        "class": "SANDEVISTAN",
        "tier": "LEGENDARY",
        "tagline": "CHROMATIC DILATION",
        "desc": "Overclocks every hue to full neon and splits the light into a triadic afterimage.",
    },
    {
        "id": "berserk",
        "name": "ZETATECH BERSERK MK.5",
        "short": "BERSERK",
        "maker": "ZETATECH",
        "logo": "zetatech",
        "class": "BERSERK",
        "tier": "LEGENDARY",
        "tagline": "OVERHEAT",
        "desc": "Floods the palette with heat: scorched background, molten accents, no cool-down.",
    },
    {
        "id": "rippler",
        "name": "TETRATRONIC RIPPLER MK.4",
        "short": "RIPPLER",
        "maker": "TETRATRONIC",
        "logo": "tetratronic",
        "class": "CYBERDECK",
        "tier": "EPIC",
        "tagline": "PHASE INVERSION",
        "desc": "Phase-shifts the wallpaper's hues by 180 degrees for complementary contrast.",
    },
    {
        "id": "blackwall",
        "name": "BLACKWALL",
        "short": "BLACKWALL",
        "maker": "UNKNOWN",
        "logo": "",
        "class": "█████",
        "tier": "ICONIC",
        "tagline": "IT SEES YOU",
        "desc": "Not a product. Not a protocol. Something on the other side of the wall wants in.",
        "hidden": True,
    },
]
CATALOG_BY_ID = {entry["id"]: entry for entry in CATALOG}
DEFAULT_OS = "netwatch"

# --------------------------------------------------------------------------- colour maths (OKLab)


def _to_linear(c):
    c /= 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _to_srgb(c):
    c = 12.92 * c if c <= 0.0031308 else 1.055 * (c ** (1 / 2.4)) - 0.055
    return c


_LINEAR = [_to_linear(i) for i in range(256)]


def rgb_to_oklab(r, g, b):
    r, g, b = _LINEAR[r], _LINEAR[g], _LINEAR[b]
    l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
    s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b
    l, m, s = l ** (1 / 3), m ** (1 / 3), s ** (1 / 3)
    return (
        0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
        1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
        0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
    )


def oklab_to_linear(L, a, b):
    l = (L + 0.3963377774 * a + 0.2158037573 * b) ** 3
    m = (L - 0.1055613458 * a - 0.0638541728 * b) ** 3
    s = (L - 0.0894841775 * a - 1.2914855480 * b) ** 3
    return (
        4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
        -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
        -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
    )


def lch_to_lab(L, C, h):
    rad = math.radians(h)
    return L, C * math.cos(rad), C * math.sin(rad)


def lab_to_lch(L, a, b):
    return L, math.hypot(a, b), math.degrees(math.atan2(b, a)) % 360


def in_gamut(L, C, h):
    return all(-1e-4 <= v <= 1 + 1e-4 for v in oklab_to_linear(*lch_to_lab(L, C, h)))


class Color:
    """An OKLCH colour that is always mapped into sRGB when rendered."""

    __slots__ = ("L", "C", "h", "share")

    def __init__(self, L, C, h):
        self.L = min(1.0, max(0.0, L))
        self.C = max(0.0, C)
        self.h = h % 360

    @classmethod
    def from_rgb(cls, r, g, b):
        return cls(*lab_to_lch(*rgb_to_oklab(r, g, b)))

    def with_(self, L=None, C=None, h=None):
        return Color(self.L if L is None else L, self.C if C is None else C, self.h if h is None else h)

    def rgb(self):
        # keep hue and lightness, reduce chroma until the colour fits in sRGB
        C = self.C
        if not in_gamut(self.L, C, self.h):
            lo, hi = 0.0, C
            for _ in range(20):
                mid = (lo + hi) / 2
                if in_gamut(self.L, mid, self.h):
                    lo = mid
                else:
                    hi = mid
            C = lo
        lin = oklab_to_linear(*lch_to_lab(self.L, C, self.h))
        return tuple(int(round(min(1, max(0, _to_srgb(max(0.0, v)))) * 255)) for v in lin)

    def hex(self):
        return "#%02x%02x%02x" % self.rgb()

    def mix(self, other, t):
        a = lch_to_lab(self.L, self.C, self.h)
        b = lch_to_lab(other.L, other.C, other.h)
        return Color(*lab_to_lch(*(x + (y - x) * t for x, y in zip(a, b))))


def hue_dist(a, b):
    d = abs(a - b) % 360
    return min(d, 360 - d)


def hue_lerp(a, b, t):
    d = ((b - a + 540) % 360) - 180
    return (a + d * t) % 360


# canonical OKLCH hues of the terminal colours
HUES = {"red": 27, "orange": 55, "yellow": 100, "green": 145, "cyan": 200, "blue": 255, "magenta": 330}

# --------------------------------------------------------------------------- analysis


class Scan:
    """Everything the algorithms need to know about a wallpaper."""

    def __init__(self, path):
        img = Image.open(path).convert("RGB")
        w, h = img.size

        # shadows and global luminance on a tiny copy, averaging is what we want here
        tiny = img.resize((max(1, int(w * 160 / max(w, h))), max(1, int(h * 160 / max(w, h)))), Image.Resampling.BOX)
        data = tiny.tobytes()
        lum = []
        dark_lab = [0.0, 0.0, 0.0]
        dark_w = 0.0
        for i in range(0, len(data), 3):
            L, A, B = rgb_to_oklab(data[i], data[i + 1], data[i + 2])
            lum.append(L)
            if L < 0.42:
                weight = 0.42 - L
                dark_lab[0] += L * weight
                dark_lab[1] += A * weight
                dark_lab[2] += B * weight
                dark_w += weight
        lum.sort()
        self.luma_median = lum[len(lum) // 2]
        self.dark = Color(*lab_to_lch(*(v / dark_w for v in dark_lab))) if dark_w else Color(0.18, 0.02, 250)

        # neon signs are thin: look for them on a larger copy, prefiltered in C through HSV
        scale = 720 / max(w, h)
        mid = img.resize((max(1, int(w * scale)), max(1, int(h * scale))), Image.Resampling.BOX)
        rgb = mid.tobytes()
        hsv = mid.convert("HSV").tobytes()
        hist = [0.0] * 360
        neon = []
        for i in range(0, len(rgb), 3):
            if hsv[i + 1] < 46 or hsv[i + 2] < 70:
                continue
            L, A, B = rgb_to_oklab(rgb[i], rgb[i + 1], rgb[i + 2])
            C = math.hypot(A, B)
            if C < 0.045 or L < 0.36:
                continue
            hue = math.degrees(math.atan2(B, A)) % 360
            weight = C * C * (0.4 + L)
            hist[int(hue) % 360] += weight
            neon.append((L, C, hue, weight))

        self.peaks = self._cluster(hist, neon)
        if not self.peaks:
            # grayscale wallpaper: invent a signature from the shadows
            fallback = Color(0.78, 0.14, self.dark.h if self.dark.C > 0.01 else 200)
            fallback.share = 1.0
            self.peaks = [fallback]

    @staticmethod
    def _cluster(hist, neon, k=5):
        """Weighted circular k-means on the hue histogram."""
        total = sum(hist)
        if total <= 0:
            return []
        smooth = [sum(hist[(i + d) % 360] for d in range(-6, 7)) for i in range(360)]
        order = sorted(range(360), key=lambda i: -smooth[i])
        centres = []
        for i in order:
            if smooth[i] <= 0 or len(centres) == k:
                break
            if all(hue_dist(i, c) >= 22 for c in centres):
                centres.append(float(i))

        for _ in range(16):
            sums = [[0.0, 0.0, 0.0] for _ in centres]
            for hue in range(360):
                weight = hist[hue]
                if weight <= 0:
                    continue
                j = min(range(len(centres)), key=lambda c: hue_dist(hue, centres[c]))
                sums[j][0] += math.cos(math.radians(hue)) * weight
                sums[j][1] += math.sin(math.radians(hue)) * weight
                sums[j][2] += weight
            centres = [math.degrees(math.atan2(s[1], s[0])) % 360 if s[2] else c for s, c in zip(sums, centres)]

        peaks = []
        for centre in centres:
            members = [n for n in neon if min(range(len(centres)), key=lambda c: hue_dist(n[2], centres[c])) == centres.index(centre)]
            weight = sum(n[3] for n in members)
            if not members or weight / total < 0.03:
                continue
            members.sort(key=lambda n: n[1])
            # the neon "core" of a sign is its most saturated part, not its average
            core = members[int(len(members) * 0.8):] or members
            core_w = sum(n[3] for n in core)
            peak = Color(sum(n[0] * n[3] for n in core) / core_w, sum(n[1] * n[3] for n in core) / core_w, centre)
            peak.share = weight / total
            peaks.append(peak)
        peaks.sort(key=lambda p: -p.share)
        return peaks

    def accents(self, count=3):
        """Strongest signature first, then the ones that are both strong and far from the others."""
        picked = [self.peaks[0]]
        rest = list(self.peaks[1:])
        while rest and len(picked) < count:
            best = max(rest, key=lambda p: p.share * min(1.0, min(hue_dist(p.h, q.h) for q in picked) / 80.0) ** 1.5)
            picked.append(best)
            rest.remove(best)
        return picked

    def nearest(self, hue, window=60):
        best = min(self.peaks, key=lambda p: hue_dist(p.h, hue))
        return best if hue_dist(best.h, hue) <= window else None


def neon(color, L, C):
    return color.with_(L=L, C=C)


def pulled(scan, hue, strength, window=40):
    """Canonical hue pulled toward the closest wallpaper signature."""
    near = scan.nearest(hue, window)
    if near is None:
        return hue
    return hue_lerp(hue, near.h, strength * (1 - hue_dist(near.h, hue) / (window * 1.6)))


# --------------------------------------------------------------------------- algorithms
#
# Each algorithm returns: bg (Color), fg tint hue/chroma, three accents and the
# parameters for the semantic colours. `finish` turns that into base16 + roles.


def algo_netwatch(scan):
    found = scan.accents(3)
    p1 = found[0]
    p2 = found[1] if len(found) > 1 else p1.with_(h=p1.h + 150)
    p3 = found[2] if len(found) > 2 else p1.with_(h=hue_lerp(p1.h, p2.h, 0.5))
    lift = lambda p, drop=0.0: neon(p, min(0.84, max(0.75, p.L)) - drop, min(0.2, max(0.13, p.C * 1.15)))
    return dict(
        bg=Color(0.165, min(0.032, scan.dark.C * 1.4), scan.dark.h),
        fg_hue=p2.h, fg_c=0.018,
        primary=lift(p1),
        secondary=lift(p2),
        tertiary=lift(p3, 0.03),
        sem=dict(pull=0.55, L=0.74, C=0.15),
    )


def algo_canto(scan):
    lock = scan.peaks[0]
    H = lock.h
    return dict(
        bg=Color(0.16, 0.03, H),
        fg_hue=H, fg_c=0.025,
        primary=Color(0.82, 0.17, H),
        secondary=Color(0.72, 0.13, H + 32),
        tertiary=Color(0.66, 0.11, H - 34),
        sem=dict(pull=0.35, L=0.73, C=0.13, tint=H, tint_strength=0.18),
    )


def algo_arasaka(scan):
    red = scan.nearest(20, window=55)
    hue = hue_lerp(25, red.h, 0.25) if red else 25
    return dict(
        bg=Color(0.135, 0.006, scan.dark.h),
        fg_hue=scan.dark.h, fg_c=0.006,
        primary=Color(0.63, 0.22, hue),
        secondary=Color(0.90, 0.008, scan.dark.h),
        tertiary=Color(0.70, 0.03, scan.dark.h),
        sem=dict(pull=0.2, L=0.70, C=0.075, keep_red=Color(0.63, 0.22, hue)),
    )


def algo_sandevistan(scan):
    base = scan.peaks[0]
    trail = []
    for offset in (120, 240):
        target = base.h + offset
        near = scan.nearest(target, window=30)
        trail.append(hue_lerp(target, near.h, 0.6) if near else target)
    return dict(
        bg=Color(0.15, 0.045, base.h),
        fg_hue=base.h, fg_c=0.03,
        primary=Color(0.78, 0.25, base.h),
        secondary=Color(0.76, 0.25, trail[0]),
        tertiary=Color(0.80, 0.25, trail[1]),
        sem=dict(pull=0.3, L=0.78, C=0.2),
    )


def algo_berserk(scan):
    warm = scan.nearest(30, window=70)
    hot = hue_lerp(28, warm.h, 0.35) if warm else 28
    pink = scan.nearest(345, window=40)
    return dict(
        bg=Color(0.145, 0.04, 28),
        fg_hue=40, fg_c=0.03,
        primary=Color(0.66, 0.23, hot),
        secondary=Color(0.82, 0.17, 68),
        tertiary=Color(0.70, 0.21, hue_lerp(350, pink.h, 0.5) if pink else 350),
        sem=dict(pull=0.25, L=0.74, C=0.17, tint=35, tint_strength=0.22),
    )


def algo_rippler(scan):
    found = scan.accents(2)
    p1 = found[0]
    p2 = found[1] if len(found) > 1 else p1.with_(h=p1.h + 60)
    return dict(
        bg=Color(0.16, min(0.03, scan.dark.C * 1.3), scan.dark.h),
        fg_hue=p1.h + 180, fg_c=0.02,
        primary=Color(0.84, 0.16, p1.h + 180),
        secondary=Color(0.78, 0.15, p2.h + 180),
        tertiary=Color(0.76, 0.15, p1.h),
        sem=dict(pull=0.4, L=0.75, C=0.15),
    )


def algo_blackwall(scan):
    ghost = scan.nearest(200, window=70)
    return dict(
        bg=Color(0.11, 0.035, 22),
        fg_hue=22, fg_c=0.04,
        primary=Color(0.60, 0.235, 24),
        secondary=Color(0.56, 0.19, 18),
        tertiary=Color(0.84, 0.12, ghost.h if ghost else 200),
        sem=dict(pull=0.15, L=0.68, C=0.15, tint=24, tint_strength=0.35),
    )


ALGORITHMS = {
    "netwatch": algo_netwatch,
    "canto": algo_canto,
    "arasaka": algo_arasaka,
    "sandevistan": algo_sandevistan,
    "berserk": algo_berserk,
    "rippler": algo_rippler,
    "blackwall": algo_blackwall,
}


def finish(scan, spec):
    bg = spec["bg"]
    fh, fc = spec["fg_hue"], spec["fg_c"]
    sem = spec["sem"]

    def semantic(name):
        hue = pulled(scan, HUES[name], sem["pull"])
        if "tint" in sem:
            hue = hue_lerp(hue, sem["tint"], sem["tint_strength"])
        return Color(sem["L"], sem["C"], hue)

    danger = sem.get("keep_red") or semantic("red").with_(C=max(sem["C"], 0.16), L=max(0.64, sem["L"] - 0.06))
    roles = {
        "bg": bg,
        "surface": bg.with_(L=bg.L + 0.04, C=bg.C * 1.1),
        "overlay": bg.with_(L=bg.L + 0.095, C=bg.C * 1.25),
        "muted": Color(0.50, max(0.012, min(0.04, bg.C * 1.2)), bg.h),
        "subtle": Color(0.70, fc * 1.1, fh),
        "fg": Color(0.91, fc, fh),
        "bright": Color(0.955, fc * 0.6, fh),
        "white": Color(0.985, fc * 0.3, fh),
        "primary": spec["primary"],
        "secondary": spec["secondary"],
        "tertiary": spec["tertiary"],
        "danger": danger,
        "alt": semantic("orange"),
        "warn": semantic("yellow").with_(L=max(sem["L"], 0.8)),
        "ok": semantic("green"),
    }
    roles["deep"] = spec["primary"].mix(bg, 0.55)

    base16 = {
        "base00": roles["bg"],
        "base01": roles["surface"],
        "base02": roles["overlay"],
        "base03": roles["muted"],
        "base04": roles["subtle"],
        "base05": roles["fg"],
        "base06": roles["bright"],
        "base07": roles["white"],
        "base08": roles["danger"],
        "base09": roles["alt"],
        "base0A": roles["warn"],
        "base0B": roles["ok"],
        "base0C": roles["secondary"],
        "base0D": roles["primary"],
        "base0E": roles["tertiary"],
        "base0F": roles["deep"],
    }
    return {
        "base16": {k: v.hex() for k, v in base16.items()},
        "roles": {k: v.hex() for k, v in roles.items()},
    }


def build_all(image):
    scan = Scan(image)
    out = {}
    for entry in CATALOG:
        palette = finish(scan, ALGORITHMS[entry["id"]](scan))
        out[entry["id"]] = dict(entry, **palette)
    return out


# --------------------------------------------------------------------------- app themes


def kitty_conf(roles, b16):
    lines = [
        "# generated by cyberdeck-theme, overrides the Stylix colours at runtime",
        f"foreground {roles['fg']}",
        f"background {roles['bg']}",
        f"selection_foreground {roles['bg']}",
        f"selection_background {roles['primary']}",
        f"cursor {roles['warn']}",
        f"cursor_text_color {roles['bg']}",
        f"url_color {roles['secondary']}",
        f"active_border_color {roles['primary']}",
        f"inactive_border_color {roles['overlay']}",
        f"bell_border_color {roles['danger']}",
        f"visual_bell_color {roles['danger']}",
        f"active_tab_foreground {roles['bg']}",
        f"active_tab_background {roles['primary']}",
        f"inactive_tab_foreground {roles['subtle']}",
        f"inactive_tab_background {roles['surface']}",
        f"tab_bar_background {roles['bg']}",
        f"tab_bar_margin_color {roles['bg']}",
        f"mark1_background {roles['primary']}",
        f"mark2_background {roles['secondary']}",
        f"mark3_background {roles['tertiary']}",
    ]
    ansi = ["base00", "base08", "base0B", "base0A", "base0D", "base0E", "base0C", "base05",
            "base03", "base08", "base0B", "base0A", "base0D", "base0E", "base0C", "base07"]
    for i, key in enumerate(ansi):
        lines.append(f"color{i} {b16[key]}")
    return "\n".join(lines) + "\n"


def gtk_css(roles):
    r = roles
    pairs = {
        "accent_color": r["primary"],
        "accent_bg_color": r["primary"],
        "accent_fg_color": r["bg"],
        "destructive_color": r["danger"],
        "destructive_bg_color": r["danger"],
        "destructive_fg_color": r["bg"],
        "success_color": r["ok"],
        "success_bg_color": r["ok"],
        "success_fg_color": r["bg"],
        "warning_color": r["warn"],
        "warning_bg_color": r["warn"],
        "warning_fg_color": r["bg"],
        "error_color": r["danger"],
        "error_bg_color": r["danger"],
        "error_fg_color": r["bg"],
        "window_bg_color": r["bg"],
        "window_fg_color": r["fg"],
        "view_bg_color": r["bg"],
        "view_fg_color": r["fg"],
        "headerbar_bg_color": r["surface"],
        "headerbar_fg_color": r["fg"],
        "headerbar_border_color": r["primary"],
        "headerbar_backdrop_color": r["bg"],
        "headerbar_shade_color": r["bg"],
        "sidebar_bg_color": r["surface"],
        "sidebar_fg_color": r["fg"],
        "sidebar_backdrop_color": r["bg"],
        "sidebar_shade_color": r["bg"],
        "secondary_sidebar_bg_color": r["surface"],
        "secondary_sidebar_fg_color": r["fg"],
        "card_bg_color": r["surface"],
        "card_fg_color": r["fg"],
        "card_shade_color": r["bg"],
        "dialog_bg_color": r["surface"],
        "dialog_fg_color": r["fg"],
        "popover_bg_color": r["surface"],
        "popover_fg_color": r["fg"],
        "thumbnail_bg_color": r["surface"],
        "thumbnail_fg_color": r["fg"],
        "theme_bg_color": r["bg"],
        "theme_fg_color": r["fg"],
        "theme_base_color": r["bg"],
        "theme_text_color": r["fg"],
        "theme_selected_bg_color": r["primary"],
        "theme_selected_fg_color": r["bg"],
        "insensitive_fg_color": r["muted"],
        "borders": r["overlay"],
        "cyber_secondary": r["secondary"],
        "cyber_tertiary": r["tertiary"],
        "cyber_overlay": r["overlay"],
        "cyber_muted": r["muted"],
    }
    body = "\n".join(f"@define-color {k} {v};" for k, v in pairs.items())
    return "/* generated by cyberdeck-theme, loaded after the Stylix colours */\n" + body + "\n"


def niri_kdl(roles):
    return f"""// generated by cyberdeck-theme, included by the niri config and live reloaded
layout {{
    focus-ring {{
        active-color "{roles['primary']}"
        inactive-color "{roles['overlay']}"
    }}
    border {{
        active-color "{roles['secondary']}"
        inactive-color "{roles['surface']}"
    }}
    insert-hint {{
        color "{roles['primary']}80"
    }}
}}
overview {{
    backdrop-color "{roles['bg']}"
}}
"""


# --------------------------------------------------------------------------- runtime state

# bump when an algorithm changes, so palettes cached at runtime are recomputed
ENGINE = 3
IMAGE_EXTENSIONS = (".jpg", ".jpeg", ".png", ".webp")


def state_dir():
    base = os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state")
    return os.path.join(base, "cyberdeck")


def cache_dir():
    base = os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache")
    return os.path.join(base, "cyberdeck")


def config_file():
    base = os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config")
    return os.path.join(base, "cyberdeck", "config.json")


def load_config():
    try:
        with open(config_file()) as fh:
            return json.load(fh)
    except (OSError, ValueError):
        return {}


def write_atomic(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), prefix=".tmp-")
    with os.fdopen(fd, "w") as fh:
        fh.write(text)
    os.replace(tmp, path)


def read_text(path, default=""):
    try:
        with open(path) as fh:
            return fh.read().strip()
    except OSError:
        return default


def stats():
    try:
        with open(os.path.join(state_dir(), "stats.json")) as fh:
            return json.load(fh)
    except (OSError, ValueError):
        return {}


def current_os(cfg):
    os_id = read_text(os.path.join(state_dir(), "os")) or cfg.get("defaultOs") or DEFAULT_OS
    return os_id if os_id in ALGORITHMS else DEFAULT_OS


def remember(path, value):
    # write the choice back into the flake, so the next rebuild bakes it into Stylix
    if path and os.path.isfile(path) and read_text(path) != value:
        try:
            with open(path, "w") as fh:
                fh.write(value + "\n")
        except OSError:
            pass


def reload_kitty():
    # SIGUSR1 makes every kitty instance re-read kitty.conf (and its includes)
    try:
        out = subprocess.run(["pgrep", "-x", "kitty|\\.kitty-wrapped"], capture_output=True, text=True).stdout
    except OSError:
        return
    for pid in out.split():
        try:
            os.kill(int(pid), signal.SIGUSR1)
        except (OSError, ValueError):
            pass


# --------------------------------------------------------------------------- wallpapers


def is_image(name):
    return name.lower().endswith(IMAGE_EXTENSIONS)


def wallpapers(cfg):
    """Every wallpaper of the deck: the ones built into the flake first, then any
    image dropped in the repo folder since the last rebuild."""
    out, seen = [], set()
    for entry in cfg.get("wallpapers") or []:
        if entry.get("path") and os.path.isfile(entry["path"]):
            out.append({"name": entry["name"], "path": entry["path"], "palettes": entry.get("palettes"), "engraved": True})
            seen.add(entry["name"])
    folder = cfg.get("wallpaperDir")
    if folder and os.path.isdir(folder):
        for name in sorted(os.listdir(folder)):
            path = os.path.join(folder, name)
            if name not in seen and is_image(name) and os.path.isfile(path):
                out.append({"name": name, "path": path, "palettes": None, "engraved": False})
                seen.add(name)
    default = cfg.get("wallpaper")
    if default and os.path.isfile(default) and all(w["path"] != default for w in out):
        out.insert(0, {"name": os.path.basename(default), "path": default, "palettes": None, "engraved": True})
    return out


def resolve_wallpaper(cfg, wanted):
    """A wallpaper given either as a path or as a file name of the wallpaper folder."""
    for w in wallpapers(cfg):
        if wanted in (w["name"], w["path"]):
            return w["path"]
    if os.path.isfile(wanted) and is_image(wanted):
        return os.path.abspath(wanted)
    sys.exit("cyberdeck-theme: unknown wallpaper '%s'" % wanted)


def current_wallpaper(cfg):
    image = read_text(os.path.join(state_dir(), "wallpaper"))
    if image and os.path.isfile(image):
        return image
    return cfg.get("wallpaper") or ""


def palettes_for(image, cfg):
    """Every OS palette for one wallpaper: computed at build time when the
    wallpaper is part of the flake, otherwise computed once and cached."""
    for w in wallpapers(cfg):
        if w["path"] == image and w.get("palettes"):
            try:
                out = {}
                for entry in CATALOG:
                    with open(os.path.join(w["palettes"], entry["id"] + ".json")) as fh:
                        out[entry["id"]] = json.load(fh)
                return out
            except (OSError, ValueError):
                break
    st = os.stat(image)
    key = hashlib.sha1(("%s:%d:%d:%d" % (image, st.st_size, st.st_mtime_ns, ENGINE)).encode()).hexdigest()[:20]
    cache = os.path.join(cache_dir(), "palettes", key + ".json")
    try:
        with open(cache) as fh:
            return json.load(fh)
    except (OSError, ValueError):
        pass
    every = build_all(image)
    try:
        write_atomic(cache, json.dumps(every))
    except OSError:
        pass
    return every


def is_swaybg(pid):
    return read_text("/proc/%d/comm" % pid) == "swaybg"


def show_wallpaper(image):
    """Draws the wallpaper with a fresh swaybg. The previous instance only goes
    away once the new one had time to draw, so there is never a bare frame."""
    if not os.environ.get("WAYLAND_DISPLAY") or not os.path.isfile(image):
        return
    pid_file = os.path.join(state_dir(), "swaybg.pid")
    old = read_text(pid_file)
    try:
        proc = subprocess.Popen(
            ["swaybg", "--image", image, "--mode", "fill"],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    except OSError as err:
        print("cyberdeck-theme: cannot start swaybg: %s" % err, file=sys.stderr)
        return
    write_atomic(pid_file, "%d\n" % proc.pid)
    if old.isdigit() and int(old) != proc.pid and is_swaybg(int(old)):
        time.sleep(0.8)
        try:
            os.kill(int(old), signal.SIGTERM)
        except OSError:
            pass


# --------------------------------------------------------------------------- commands


def apply(os_id, cfg, quiet=False, wallpaper=None):
    previous = current_wallpaper(cfg)
    image = wallpaper or previous
    if not image or not os.path.isfile(image):
        sys.exit("cyberdeck-theme: no wallpaper configured in " + config_file())
    if os_id not in ALGORITHMS:
        sys.exit("cyberdeck-theme: unknown OS '%s' (try: %s)" % (os_id, ", ".join(ALGORITHMS)))
    if os_id == "blackwall" and not stats().get("blackwall") and not cfg.get("blackwallUnlocked"):
        sys.exit("cyberdeck-theme: ACCESS DENIED. The wall does not open for you. Yet.")

    every = palettes_for(image, cfg)
    current = every[os_id]
    sd = state_dir()
    write_atomic(os.path.join(sd, "kitty.conf"), kitty_conf(current["roles"], current["base16"]))
    write_atomic(os.path.join(sd, "gtk.css"), gtk_css(current["roles"]))
    write_atomic(os.path.join(sd, "niri.kdl"), niri_kdl(current["roles"]))
    write_atomic(os.path.join(sd, "os"), os_id + "\n")
    write_atomic(os.path.join(sd, "wallpaper"), image + "\n")
    theme = {
        "version": 1,
        "engine": ENGINE,
        "os": os_id,
        "wallpaper": image,
        "stamp": time.time(),
        "palette": current,
        "catalog": [
            dict({k: v for k, v in entry.items() if k not in ("base16",)}, roles=every[entry["id"]]["roles"])
            for entry in CATALOG
        ],
    }
    write_atomic(os.path.join(sd, "theme.json"), json.dumps(theme, indent=1) + "\n")

    remember(cfg.get("osFile"), os_id)
    name = os.path.basename(image)
    if cfg.get("wallpaperDir") and os.path.isfile(os.path.join(cfg["wallpaperDir"], name)):
        remember(cfg.get("wallpaperFile"), name)

    reload_kitty()
    if wallpaper and image != previous:
        show_wallpaper(image)
    if not quiet:
        print(current["name"])


def cmd_apply(args):
    cfg = load_config()
    os_id = args.os or current_os(cfg)
    apply(os_id, cfg, args.quiet, resolve_wallpaper(cfg, args.wallpaper) if args.wallpaper else None)


def init(cfg, force=False):
    try:
        with open(os.path.join(state_dir(), "theme.json")) as fh:
            theme = json.load(fh)
        fresh = theme.get("wallpaper") == current_wallpaper(cfg) and theme.get("engine") == ENGINE
    except (OSError, ValueError):
        fresh = False
    if force or not fresh:
        try:
            apply(current_os(cfg), cfg, quiet=True)
        except SystemExit:
            apply(DEFAULT_OS, cfg, quiet=True)


def cmd_init(args):
    init(load_config(), args.force)


def cmd_current(_args):
    print(current_os(load_config()))


def cmd_list(_args):
    print(json.dumps(CATALOG, indent=1))


def cmd_wallpaper(args):
    cfg = load_config()
    if args.action == "show":
        # session start: make sure the state matches, then put the wallpaper up
        init(cfg)
        show_wallpaper(current_wallpaper(cfg))
    elif args.action == "set":
        if not args.target:
            sys.exit("cyberdeck-theme: wallpaper set needs a file name or a path")
        apply(current_os(cfg), cfg, args.quiet, resolve_wallpaper(cfg, args.target))
    else:
        print(current_wallpaper(cfg))


def cmd_wallpapers(_args):
    cfg = load_config()
    os_id = current_os(cfg)
    current = current_wallpaper(cfg)
    out = []
    for w in wallpapers(cfg):
        try:
            roles = palettes_for(w["path"], cfg)[os_id]["roles"]
        except (OSError, ValueError, KeyError):
            roles = {}
        out.append({"name": w["name"], "path": w["path"], "engraved": w["engraved"], "current": w["path"] == current, "roles": roles})
    print(json.dumps(out))


def cmd_palette(args):
    every = build_all(args.image)
    os.makedirs(args.out, exist_ok=True)
    for os_id, palette in every.items():
        with open(os.path.join(args.out, os_id + ".json"), "w") as fh:
            json.dump(palette, fh, indent=1)
    with open(os.path.join(args.out, "catalog.json"), "w") as fh:
        json.dump(CATALOG, fh, indent=1)


def main():
    parser = argparse.ArgumentParser(prog="cyberdeck-theme", description="Wallpaper driven colour engine")
    sub = parser.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("apply", help="switch the active OS (and wallpaper) and rewrite the runtime themes")
    p.add_argument("os", nargs="?")
    p.add_argument("-w", "--wallpaper", help="file name in the wallpaper folder, or a path")
    p.add_argument("-q", "--quiet", action="store_true")
    p.set_defaults(func=cmd_apply)
    p = sub.add_parser("init", help="generate the runtime state when missing or stale")
    p.add_argument("-f", "--force", action="store_true")
    p.set_defaults(func=cmd_init)
    sub.add_parser("current", help="print the active OS").set_defaults(func=cmd_current)
    sub.add_parser("list", help="print the OS catalog").set_defaults(func=cmd_list)
    p = sub.add_parser("wallpaper", help="print the wallpaper, put it on screen (show) or switch it (set)")
    p.add_argument("action", nargs="?", choices=["show", "set"])
    p.add_argument("target", nargs="?")
    p.add_argument("-q", "--quiet", action="store_true")
    p.set_defaults(func=cmd_wallpaper)
    sub.add_parser("wallpapers", help="print every known wallpaper as json").set_defaults(func=cmd_wallpapers)
    p = sub.add_parser("palette", help="build time: write every palette for an image")
    p.add_argument("--image", required=True)
    p.add_argument("--out", required=True)
    p.set_defaults(func=cmd_palette)
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
