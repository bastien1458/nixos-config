"""
SVG sources of the Cyberdeck cursor theme, on a 32 unit grid.
Each shape: (svg body, hotspot x, hotspot y). Colours are placeholders that
the Nix build fills with the active palette:
  @BG@ body, @P@ neon outline, @A@ accent, @D@ danger.
`wait` and `progress` are animated: @ROT@ is replaced per frame.
"""

ARROW = "M5 3.5 L5 25 L10.4 20.1 L14 28 L17.6 26.3 L14.1 18.6 L21.6 18.6 Z"
ARROW_SMALL = "M3 2.5 L3 17.5 L6.8 14 L9.3 19.5 L11.8 18.3 L9.4 13 L14.6 13 Z"
OUTLINE = 'fill="@BG@" stroke="@P@" stroke-width="1.6" stroke-linejoin="miter" stroke-miterlimit="8"'


def ring(cx, cy, r, color, width=2.2, segments=8, gap=14):
    out = []
    import math
    step = 360 / segments
    for i in range(segments):
        a0 = math.radians(i * step + gap / 2)
        a1 = math.radians((i + 1) * step - gap / 2)
        x0, y0 = cx + r * math.cos(a0), cy + r * math.sin(a0)
        x1, y1 = cx + r * math.cos(a1), cy + r * math.sin(a1)
        opacity = 0.25 + 0.75 * (i / (segments - 1))
        out.append(f'<path d="M{x0:.2f} {y0:.2f} A{r} {r} 0 0 1 {x1:.2f} {y1:.2f}" fill="none" stroke="{color}" stroke-width="{width}" opacity="{opacity:.2f}"/>')
    return "\n".join(out)


def arrows(d):
    # double headed resize arrow along the x axis, rotated by the caller
    return (f'<g transform="rotate({d} 16 16)">'
            '<path d="M3 16 L9 10 L9 13.5 L23 13.5 L23 10 L29 16 L23 22 L23 18.5 L9 18.5 L9 22 Z" ' + OUTLINE + '/>'
            '<path d="M12 16 L20 16" stroke="@A@" stroke-width="1.4"/></g>')


SHAPES = {
    "default": (f'<path d="{ARROW}" {OUTLINE}/><path d="M7.4 9 L7.4 19.4" stroke="@P@" stroke-width="1" opacity="0.55"/><path d="M17.6 21.6 L21 21.6" stroke="@A@" stroke-width="1.6"/>', 5, 3.5),
    "pointer": (f'<path d="{ARROW}" fill="@P@" stroke="@BG@" stroke-width="1.2" stroke-linejoin="miter"/><path d="M7.4 9 L7.4 19.4" stroke="@BG@" stroke-width="1.2"/><rect x="19" y="23" width="4" height="4" fill="@A@"/><rect x="24.5" y="23" width="4" height="4" fill="@A@" opacity="0.6"/>', 5, 3.5),
    "text": ('<path d="M11 4 H21 M11 28 H21 M16 4 V28" stroke="@BG@" stroke-width="4.2"/><path d="M11 4 H21 M11 28 H21 M16 4 V28" stroke="@P@" stroke-width="1.8"/><path d="M13.5 16 H18.5" stroke="@A@" stroke-width="1.6"/>', 16, 16),
    "crosshair": ('<circle cx="16" cy="16" r="9" fill="none" stroke="@BG@" stroke-width="4"/>'
                  '<path d="M16 2 V10 M16 22 V30 M2 16 H10 M22 16 H30" stroke="@BG@" stroke-width="4"/>'
                  '<path d="M9.6 9.6 A9 9 0 0 1 22.4 9.6 M22.4 22.4 A9 9 0 0 1 9.6 22.4" fill="none" stroke="@P@" stroke-width="1.8"/>'
                  '<path d="M16 2 V10 M16 22 V30 M2 16 H10 M22 16 H30" stroke="@P@" stroke-width="1.8"/>'
                  '<rect x="14.8" y="14.8" width="2.4" height="2.4" fill="@A@"/>', 16, 16),
    "move": ('<path d="M16 2 L21 8 H18 V14 H24 V11 L30 16 L24 21 V18 H18 V24 H21 L16 30 L11 24 H14 V18 H8 V21 L2 16 L8 11 V14 H14 V8 H11 Z" ' + OUTLINE + '/>'
             '<rect x="14.6" y="14.6" width="2.8" height="2.8" fill="@A@"/>', 16, 16),
    "grab": ('<path d="M8 13 V8 H11 V12 M11 12 V5.5 H14 V12 M14 12 V5 H17 V12 M17 12 V6 H20 V13 M20 13 V9.5 H23 V19 L19.5 25 H11 L6 18.5 V13 Z" ' + OUTLINE + '/>', 15, 13),
    "grabbing": ('<path d="M9 12 H23 V20 L19.5 25 H11.5 L7.5 19.5 V14 Z M9 12 V10 M13 12 V9.5 M17 12 V9.5 M21 12 V10.5" ' + OUTLINE + '/>'
                 '<path d="M11 17 H21" stroke="@A@" stroke-width="1.4"/>', 15, 14),
    "not-allowed": ('<circle cx="16" cy="16" r="10.5" fill="@BG@" stroke="@D@" stroke-width="2.6"/><path d="M8.6 8.6 L23.4 23.4" stroke="@D@" stroke-width="2.6"/>', 16, 16),
    "ew-resize": (arrows(0), 16, 16),
    "ns-resize": (arrows(90), 16, 16),
    "nwse-resize": (arrows(45), 16, 16),
    "nesw-resize": (arrows(-45), 16, 16),
    "help": (f'<path d="{ARROW_SMALL}" {OUTLINE}/><rect x="16" y="15" width="13" height="14" fill="@BG@" stroke="@A@" stroke-width="1.4"/>'
             '<path d="M19.6 19.4 Q19.6 17.4 22.5 17.4 Q25.4 17.4 25.4 19.6 Q25.4 21.4 22.5 22 V23.6" fill="none" stroke="@A@" stroke-width="1.6"/><rect x="21.7" y="25" width="1.7" height="1.7" fill="@A@"/>', 3, 2.5),
    "copy": (f'<path d="{ARROW_SMALL}" {OUTLINE}/><rect x="16" y="16" width="13" height="13" fill="@BG@" stroke="@A@" stroke-width="1.4"/><path d="M22.5 18.5 V26.5 M18.5 22.5 H26.5" stroke="@A@" stroke-width="1.8"/>', 3, 2.5),
    "alias": (f'<path d="{ARROW_SMALL}" {OUTLINE}/><rect x="16" y="16" width="13" height="13" fill="@BG@" stroke="@A@" stroke-width="1.4"/><path d="M19 26 L26 19 M21.5 19 H26 V23.5" fill="none" stroke="@A@" stroke-width="1.6"/>', 3, 2.5),
    "context-menu": (f'<path d="{ARROW_SMALL}" {OUTLINE}/><rect x="16" y="15" width="13" height="14" fill="@BG@" stroke="@P@" stroke-width="1.4"/><path d="M18.5 19 H26.5 M18.5 22 H26.5 M18.5 25 H24" stroke="@A@" stroke-width="1.4"/>', 3, 2.5),
    "cell": ('<path d="M13 4 H19 V13 H28 V19 H19 V28 H13 V19 H4 V13 H13 Z" ' + OUTLINE + '/><rect x="14.8" y="14.8" width="2.4" height="2.4" fill="@A@"/>', 16, 16),
    "zoom-in": ('<circle cx="13" cy="13" r="8" fill="@BG@" stroke="@P@" stroke-width="2"/><path d="M19 19 L28 28" stroke="@P@" stroke-width="3"/><path d="M13 9 V17 M9 13 H17" stroke="@A@" stroke-width="1.8"/>', 13, 13),
    "zoom-out": ('<circle cx="13" cy="13" r="8" fill="@BG@" stroke="@P@" stroke-width="2"/><path d="M19 19 L28 28" stroke="@P@" stroke-width="3"/><path d="M9 13 H17" stroke="@A@" stroke-width="1.8"/>', 13, 13),
    "vertical-text": ('<path d="M4 11 V21 M28 11 V21 M4 16 H28" stroke="@BG@" stroke-width="4.2"/><path d="M4 11 V21 M28 11 V21 M4 16 H28" stroke="@P@" stroke-width="1.8"/>', 16, 16),
    "wait": ('<g transform="rotate(@ROT@ 16 16)">' + ring(16, 16, 11, "@P@", 3.2) + '</g><rect x="14" y="14" width="4" height="4" fill="@A@"/>', 16, 16),
    "progress": (f'<path d="{ARROW_SMALL}" {OUTLINE}/><g transform="rotate(@ROT@ 23 23)">' + ring(23, 23, 6.5, "@P@", 2.4) + '</g>', 3, 2.5),
}

ANIMATED = {"wait", "progress"}

# every cursor name toolkits ask for, mapped to the drawn shape
ALIASES = {
    "default": ["left_ptr", "arrow", "top_left_arrow", "left_arrow", "right_ptr", "center_ptr", "draft", "X_cursor", "pirate", "dnd-ask", "dnd-none", "default"],
    "pointer": ["hand1", "hand2", "pointing_hand", "e29285e634086352946a0e7090d73106", "9d800788f1b08800ae810202380a0822"],
    "text": ["xterm", "ibeam"],
    "crosshair": ["cross", "tcross", "cross_reverse", "diamond_cross", "target", "color-picker", "pencil", "dotbox", "icon"],
    "move": ["fleur", "all-scroll", "size_all", "4498f0e0c1937ffe01fd06f973665830", "9081237383d90e509aa00f00170e968f", "dnd-move"],
    "grab": ["openhand", "hand", "5aca4d189052212118709018842178c0"],
    "grabbing": ["closedhand", "fcf21c00b30f7e3f83fe0dfd12e71cff"],
    "not-allowed": ["crossed_circle", "forbidden", "no-drop", "dnd-no-drop", "circle", "03b6e0fcb3499374a867c041f52298f0"],
    "ew-resize": ["sb_h_double_arrow", "h_double_arrow", "col-resize", "split_h", "e-resize", "w-resize", "right_side", "left_side", "size_hor", "14fef782d02440884392942c11205230", "028006030e0e7ebffc7f7070c0600140"],
    "ns-resize": ["sb_v_double_arrow", "v_double_arrow", "row-resize", "split_v", "n-resize", "s-resize", "top_side", "bottom_side", "size_ver", "2870a09082c103050810ffdffffe0204", "00008160000006810000408080010102"],
    "nwse-resize": ["bd_double_arrow", "size_fdiag", "se-resize", "nw-resize", "top_left_corner", "bottom_right_corner", "c7088f0f3e6c8088236ef8e1e3e70000"],
    "nesw-resize": ["fd_double_arrow", "size_bdiag", "ne-resize", "sw-resize", "top_right_corner", "bottom_left_corner", "fcf1c3c7cd4491d801f1e1c78f100000"],
    "help": ["question_arrow", "whats_this", "left_ptr_help", "d9ce0ab605698f320427677b458ad60b", "5c6cd98b3f3ebcb1f9c7f1c204630408"],
    "copy": ["dnd-copy", "1081e37283d90000800003c07f3ef6bf", "6407b0e94181790501fd1e167b474872"],
    "alias": ["link", "dnd-link", "3085a0e285430894940527032f8b26df", "640fb0e74195791501fd1ed57b41487f"],
    "context-menu": [],
    "cell": ["plus"],
    "zoom-in": [],
    "zoom-out": [],
    "vertical-text": [],
    "wait": ["watch", "clock"],
    "progress": ["left_ptr_watch", "half-busy", "08e8e1c95fe2fc01f976f1e063a24ccd", "3ecb610c1bf2410f44200f48c40d3599"],
}
