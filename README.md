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
- **Neovim cyberdeck** as the default editor (`home/apps/nvim`): live OS
  palette (recoloured with the rest of the deck), netrunner statusline, a
  quickhack start screen (`Space s`), mini.nvim pickers (`Space f`,
  `Space /`), tree-sitter and nixd / lua_ls / qmlls; `Space` shows every key
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
  - wallpaper bank (`Mod+W`, or the image button in the bar): every image
    of `home/assets/wallpapers`, previewed with the palette the active OS
    pulls out of it; picking one recolours the whole deck live
  - **Shell Settings** app (listed in the quickhack launcher, or
    `quickshell -c cyberdeck ipc call settings open`): rebuild folder, bar
    height and position (top / bottom), frosted glass, shadows, panel
    opacity, dim behind menus, weather location, clock seconds, sounds.
    Saved live in `~/.local/state/cyberdeck/settings.json`
  - frosted panels: niri blurs the wallpaper behind the control center and
    the menus (ext-background-effect), with a drop shadow and a backing
  - notifications, volume OSD, lockscreen with PAM
  - a CRT style power-on sequence on the login screen and on the first
    login of a boot
  - sounds: UI blips, city ambience, breach OST (see [Sounds](#sounds))
  - hints of the **Blackwall** everywhere: whispers in the bar, the
    lockscreen, the launcher, the terminal, and a hidden daemon in the
    code matrix that unlocks a seventh OS
- **Colour engine** (`theme/cyberdeck_theme.py`): every "OS" is a colour
  picking algorithm run on the wallpaper. Stylix uses it at build time,
  the bar uses it live
- **Cyberdeck cursor theme**, generated from SVG and tinted with the palette
- **Greeter**: Quickshell login screen on greetd (tuigreet fallback)
- Terminal goodies: **zsh** (ghost suggestions, neon syntax highlighting,
  shared history, HUD completion menu, `rebuild` from the Shell Settings
  folder), fzf, zoxide (`z`), eza with icons, bat; kitty on frosted glass
  with a neon cursor trail, slanted numbered tabs and a red glitch bell, `qh` quickhacks, Night City fastfetch, a two-line
  netrunner starship HUD, btop and cava themed by Stylix

## Repository Layout

```text
.
├── flake.nix                         # Flake inputs and the hello host
├── theme/
│   ├── os                            # OS (colour algorithm) baked into Stylix
│   ├── wallpaper                     # wallpaper baked into Stylix and the greeter
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
    │   └── assets/sounds/            # placeholder sounds, replace them freely
    ├── assets/wallpapers/            # the wallpaper bank
    ├── niri.nix, niri/               # Niri settings, layout, keybindings
    └── apps/                         # VS Code, Firefox, Neovim (+ nvim/ Lua), Yazi
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
pick it up on their next launch. Switching wallpaper (`Mod+W`) works the
same way, the palettes of every wallpaper of the flake being computed at
build time. **Engrave into system firmware** (in the OS menu, or
`cyberdeck-engrave`) rebuilds the system so Stylix themes every other app
(VS Code, Firefox, btop, the TTY...) with the same OS and wallpaper.

Engraving rebuilds **the clone at `dotfiles` in `flake.nix`**
(`/home/hello/.dotfiles` by default) and writes `theme/os` and
`theme/wallpaper` back into it. If the repo lives somewhere else, change
`dotfiles` there (or export `CYBERDECK_REPO`), otherwise engraving rebuilds an
old copy of the config. The engraving terminal prints the path and the commit
it builds from.

## Wallpapers

Drop images (`.jpg`, `.png`, `.webp`) into `home/assets/wallpapers`. They
show up in the wallpaper bank right away (marked NEW, palette computed on the
fly); after `git add` and a rebuild they are part of the flake with
precomputed palettes. Engraving adds them to git for you.

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
| `Mod+W` | Wallpaper bank |
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

The Cyberdeck bindings (`Mod+D`, `Mod+A`, `Mod+B`, `Mod+O`, `Mod+W`, `Mod+N`,
`Mod+Alt+L`, `Mod+Shift+R`) are declared in `home/shell.nix`, next to the
scripts they call; the others are in `home/niri/shortcuts.nix`.

## Sounds

Every sound is a file of `home/quickshell/assets/sounds`, played with
`pw-play`. The ones in the repo are synth placeholders: replace a file
keeping its name and rebuild. The SOUND tile of the control center cycles
between everything, effects only and muted.

| File | Played when |
| --- | --- |
| `hover.mp3` | the pointer lands on something clickable, or the quickhack selection moves |
| `click.mp3` | something is clicked, a quickhack is uploaded, a matrix cell is picked |
| `ambient.mp3` | always, in a loop (general ambience) |
| `breach.mp3` | in a loop while the breach protocol is open (replaces the ambience) |
| `matrix-hover.mp3` | a cell of the code matrix gets hovered |
| `breach-success.mp3` | a breach ends with at least one daemon installed |
| `breach-fail.mp3` | a breach ends with nothing installed |
| `notification.mp3` | a notification arrives (not in do not disturb) |
| `deck-switch.mp3` | the OS (netdriver, canto...) is switched |
| `boot.mp3` | the power-on sequence of the first login |
