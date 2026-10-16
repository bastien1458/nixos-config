"""Writes the SVG frames + xcursorgen configs of the Cyberdeck cursor theme."""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from shapes import ALIASES, ANIMATED, SHAPES  # noqa: E402

colors = json.loads(sys.argv[1])
out = sys.argv[2]
sizes = [int(s) for s in sys.argv[3].split(",")]
frames = 12

os.makedirs(out, exist_ok=True)
for name, (body, hx, hy) in SHAPES.items():
    svg = body.replace("@BG@", colors["bg"]).replace("@P@", colors["primary"]).replace("@A@", colors["accent"]).replace("@D@", colors["danger"])
    steps = range(frames) if name in ANIMATED else [None]
    cfg = []
    for step in steps:
        frame = svg.replace("@ROT@", str((step or 0) * 360 / frames))
        stem = name if step is None else f"{name}-{step:02d}"
        with open(os.path.join(out, stem + ".svg"), "w") as fh:
            fh.write('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" width="32" height="32">' + frame + "</svg>")
        for size in sizes:
            k = size / 32
            delay = " 60" if step is not None else ""
            cfg.append(f"{size} {round(hx * k)} {round(hy * k)} {stem}-{size}.png{delay}")
    with open(os.path.join(out, name + ".cfg"), "w") as fh:
        fh.write("\n".join(cfg) + "\n")

with open(os.path.join(out, "aliases"), "w") as fh:
    for name, names in ALIASES.items():
        for alias in names:
            if alias != name:
                fh.write(f"{name} {alias}\n")
