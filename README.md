# NixOS Configuration

My personal NixOS configuration, managed with flakes and
Home Manager. This is built around the Niri compositor and is
configured for NVIDIA graphics, and two 1920x1080
180 Hz DisplayPort monitors.

The whole desktop is a Cyberpunk 2077 "cyberdeck": a Quickshell shell, a
wallpaper driven colour scheme applied by Stylix, a matching cursor,
lockscreen and login screen.

## What I've added for now

- NixOS unstable with flakes enabled
- Niri compositor
- Home Manager integrated into the system configuration
- NVIDIA drivers
- PipeWire audio
- Yazi as the XDG portal file chooser
- Neovim as the default editor
- Firefox with uBlock Origin and tracking protection enabled
- Visual Studio Code with Nix IDE and Material Icon Theme
- Unfree packages enabled
- **Cyberdeck shell** (Quickshell, replaces Waybar and Mako)
  - top bar per monitor: quickhack button, niri workspaces, focused window,
    clock and weather, eddies, breach protocol, OS selector, tray with
    themed menus, volume, network, notifications, control center
  - control center: media (MPRIS), output/input/app volumes, weather,
    calendar, deck status (CPU / RAM / uptime), notification log, toggles
  - quickhack launcher (applications + system menu), RAM rolled between
    max - 10 and max on every opening, hacks that cost more than the free RAM
    turn red and **OVERCLOCK**
  - breach protocol mini game (the code matrix from the game) with
    eurodollar rewards
  - notifications, volume OSD, lockscreen with PAM
  - hints of the **Blackwall** everywhere: whispers in the bar, the
    lockscreen, the launcher, the terminal, and a hidden daemon in the
    code matrix that unlocks a seventh OS
- **Colour engine** (`theme/cyberdeck_theme.py`): every "OS" is a colour
  picking algorithm run on the wallpaper. Stylix uses it at build time,
  the bar uses it live
- **Cyberdeck cursor theme**, generated from SVG and tinted with the palette
- **Greeter**: Quickshell login screen on greetd (tuigreet fallback)
- Terminal goodies: `qh` quickhacks, Night City fastfetch, netrunner
  starship prompt, btop and cava themed by Stylix

## Repository Layout

```text
.
├── flake.nix                         # Flake inputs and the hello host
├── theme/
│   ├── os                            # OS (colour algorithm) baked into Stylix
│   ├── cyberdeck_theme.py            # colour engine (build time + runtime)
│   ├── default.nix                   # palettes, fonts, cursor package
│   └── cursors/                      # Cyberdeck xcursor theme (SVG sources)
├── config/
│   ├── configuration.nix             # System-wide NixOS settings
│   ├── stylix.nix                    # Stylix fed with the computed palette
│   ├── greeter.nix                   # greetd + Quickshell greeter on niri
│   ├── greeter/                      # greeter QML
│   └── hardware-configuration.nix    # Machine-generated hardware settings
└── home/
    ├── home.nix                      # Home Manager entry point
    ├── theme.nix                     # Stylix targets, kitty, GTK styling
    ├── shell.nix                     # Quickshell deployment, idle, engrave
    ├── scripts.nix                   # qh, fastfetch, starship, bash
    ├── quickshell/                   # the Cyberdeck shell (QML)
    ├── niri.nix, niri/               # Niri settings, layout, keybindings
    └── apps/                         # VS Code, Firefox, Neovim, Yazi
```

## Operating systems (colour algorithms)

| OS | Algorithm |
| --- | --- |
| NetWatch Netdriver Mk.5 | faithful scan: the strongest neon signatures of the wallpaper |
| Militech Canto Mk.6 | target lock: analogous palette around the dominant neon |
| Arasaka Mk.4 | corporate: brushed steel and a single blood-red accent |
| Militech "Apogee" Sandevistan | chromatic dilation: neon triad |
| Zetatech Berserk Mk.5 | overheat: everything pushed into the red |
| Tetratronic Rippler Mk.4 | phase inversion: complementary hues |
| ████████ | win a breach through the wall |

Switching OS from the bar (or `Mod+O`, or `qh os <id>`) is live: the shell
morphs, kitty and the niri focus ring are recoloured instantly, GTK apps
pick it up on their next launch. **Engrave into system firmware** (in the OS
menu, or `cyberdeck-engrave`) rebuilds the system so Stylix themes every
other app (VS Code, Firefox, btop, the TTY...) with the same OS.

The corporation logos are the official ones from the game (CD Projekt RED
trademarks), used for this personal rice only.

## First build

New files have to be tracked by git before a flake can see them, and the
`stylix` input gets added to `flake.lock` on the first build:

```bash
git add -A && sudo nixos-rebuild switch --flake ~/.dotfiles#hello
```

The palettes are computed from the wallpaper during evaluation (import from
derivation), so the very first evaluation builds the colour engine.

If the graphical greeter fails to start, a tuigreet in the same colours takes
over automatically; `style = "tuigreet"` in `config/greeter.nix` makes it the
default. Other TTYs (`Ctrl+Alt+F2`) keep a plain login as a last resort.

## Niri Keybindings

| Binding | Action |
| --- | --- |
| `Mod+T` | Open Kitty |
| `Mod+D` | Open the Quickhack launcher |
| `Mod+A` | Toggle the control center |
| `Mod+B` | Breach protocol |
| `Mod+O` | OS selector |
| `Mod+N` | Toggle do not disturb |
| `Mod+Alt+L` | Lock the session |
| `Mod+Shift+R` | Restart the shell |
| `Mod+Q` | Close the focused window |
| `Mod+H/J/K/L` | Focus left/down/up/right |
| `Mod+Shift+H/J/K/L` | Focus the monitor left/down/up/right |
| `Mod+1` ... `Mod+9` | Focus workspace 1 through 9 |
| `Mod+Ctrl+1` ... `Mod+Ctrl+9` | Move the column to a workspace |
| `Mod+F` | Maximize the column |
| `Mod+Shift+F` | Toggle fullscreen |
| `Mod+C` | Center the column |
| `Mod+R` | Switch column width preset |
| `Mod+Shift+E` | Quit Niri |
| `Mod+Shift+S` | Screenshot |
| `Ctrl+Print` | Screenshot the screen |
| `Alt+Print` | Screenshot the focused window |

In the bar: scroll on the bar to change workspace, scroll on the volume to
change it, right click on the bell for do not disturb, middle click on a
tray icon for its secondary action.
