# The Cyberdeck Quickshell shell: bar, control center, quickhack launcher,
# breach protocol, OS and wallpaper selectors, notifications, sounds,
# lockscreen and idle handling, plus the niri bindings that drive them.
{
  config,
  pkgs,
  lib,
  dotfiles,
  ...
}:
let
  theme = import ../theme { inherit pkgs lib; };
  qs = "${pkgs.quickshell}/bin/quickshell";
  themeBin = "${theme.tool}/bin/cyberdeck-theme";

  # keeps the shell alive, but stops retrying if the config is broken
  shell = pkgs.writeShellScriptBin "cyberdeck-shell" ''
    crashes=0
    while true; do
      started=$(date +%s)
      ${qs} -c cyberdeck && exit 0
      if [ $(( $(date +%s) - started )) -lt 15 ]; then
        crashes=$((crashes + 1))
      else
        crashes=0
      fi
      if [ "$crashes" -ge 5 ]; then
        ${pkgs.libnotify}/bin/notify-send -u critical "CYBERDECK" "Shell flatlined 5 times in a row, giving up. Check: quickshell -c cyberdeck log" || true
        exit 1
      fi
      sleep 1
    done
  '';

  # lock through the shell, swaylock if the shell is down
  lock = pkgs.writeShellScriptBin "cyberdeck-lock" ''
    ${qs} -c cyberdeck ipc call lock lock 2>/dev/null || ${pkgs.swaylock}/bin/swaylock -f -c 000000
  '';

  # the real Cyberpunk 2077 UI sounds, from a zip that stays out of the repo
  sounds = pkgs.writeShellApplication {
    name = "cyberdeck-sounds";
    runtimeInputs = [
      pkgs.unzip
      pkgs.ffmpeg-headless
      pkgs.quickshell
    ];
    text = builtins.readFile ./cyberdeck-sounds.sh;
  };

  # bakes the live OS and wallpaper into Stylix: every app gets the palette after this
  engrave = pkgs.writeShellScriptBin "cyberdeck-engrave" ''
    set -u
    export PATH=/run/wrappers/bin:/run/current-system/sw/bin:${lib.makeBinPath [ pkgs.git ]}:$PATH
    repo=''${CYBERDECK_REPO:-${dotfiles}}
    os=$(${themeBin} current)
    name=$(basename "$(${themeBin} wallpaper)")
    printf '\e[1;35m'
    cat <<'EOF'
    ╔══════════════════════════════════════════════╗
    ║   CYBERDECK // FIRMWARE ENGRAVING PROTOCOL   ║
    ╚══════════════════════════════════════════════╝
    EOF
    printf '\e[0m\n'
    if [ ! -f "$repo/flake.nix" ]; then
      printf '\e[1;31m>> NO FIRMWARE SOURCE AT %s\e[0m\n' "$repo"
      printf 'Clone the repo there, or set `dotfiles` in flake.nix (or $CYBERDECK_REPO) to your clone.\n\n'
      read -r -n 1 -p "PRESS ANY KEY TO DISCONNECT"
      exit 1
    fi
    printf '\e[1;33m>> ENGRAVING %s INTO SYSTEM FIRMWARE\e[0m\n' "''${os^^}"
    printf '\e[2m   source     %s\e[0m\n' "$repo"
    if git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then
      printf '\e[2m   commit     %s\e[0m\n' "$(git -C "$repo" log -1 --format='%h %s (%cr)')"
      printf '\e[2m   branch     %s\e[0m\n' "$(git -C "$repo" status -sb | head -n 1)"
    fi
    printf '\e[2m   wallpaper  %s\e[0m\n\n' "$name"
    printf '%s\n' "$os" > "$repo/theme/os"
    if [ -f "$repo/home/assets/wallpapers/$name" ]; then
      printf '%s\n' "$name" > "$repo/theme/wallpaper"
    else
      printf '\e[1;33m>> %s IS NOT IN home/assets/wallpapers, KEEPING THE ENGRAVED ONE\e[0m\n' "$name"
    fi
    # flakes only see what git tracks: new wallpapers have to be added first
    git -C "$repo" add -- theme/os theme/wallpaper home/assets/wallpapers 2>/dev/null || true
    if sudo nixos-rebuild switch --flake "$repo#hello"; then
      printf '\n\e[1;32m>> FIRMWARE ENGRAVED. EVERY APP NOW RUNS %s.\e[0m\n' "''${os^^}"
    else
      printf '\n\e[1;31m>> ENGRAVING FAILED. ICE HELD.\e[0m\n'
    fi
    read -r -n 1 -p "PRESS ANY KEY TO DISCONNECT"
  '';

  # niri and the shell call everything by absolute path: nothing depends on the session PATH
  ipc = call: [ qs "-c" "cyberdeck" "ipc" "call" ] ++ call;
in
{
  xdg.configFile."quickshell/cyberdeck".source = ./quickshell;

  xdg.configFile."cyberdeck/config.json".text = builtins.toJSON {
    # the engraved wallpaper, then every wallpaper of the flake with its prebuilt palettes
    wallpaper = theme.wallpaper;
    wallpapers = theme.catalog;
    # images dropped here show up in the selector before the next rebuild
    wallpaperDir = "${dotfiles}/home/assets/wallpapers";
    wallpaperFile = "${dotfiles}/theme/wallpaper";
    defaultOs = theme.os;
    osFile = "${dotfiles}/theme/os";
    # empty: located from the IP by wttr.in, or e.g. "Paris"
    weatherLocation = "";
    bin = {
      quickshell = qs;
      theme = themeBin;
      engrave = "${engrave}/bin/cyberdeck-engrave";
      lock = "${lock}/bin/cyberdeck-lock";
      kitty = "${config.programs.kitty.package}/bin/kitty";
      niri = "${config.programs.niri.package}/bin/niri";
      pwplay = "${pkgs.pipewire}/bin/pw-play";
      pavucontrol = "${pkgs.pavucontrol}/bin/pavucontrol";
    };
  };

  programs.niri.settings = {
    spawn-at-startup = [
      { command = [ "${shell}/bin/cyberdeck-shell" ]; }
      # swaybg on the remembered wallpaper; the wallpaper selector swaps it live
      {
        command = [
          themeBin
          "wallpaper"
          "show"
        ];
      }
    ];

    binds = {
      "Mod+D".action.spawn = ipc [ "quickhack" "toggle" ];
      "Mod+A".action.spawn = ipc [ "cc" "toggle" ];
      "Mod+B".action.spawn = ipc [ "breach" "open" ];
      "Mod+O".action.spawn = ipc [ "os" "open" ];
      "Mod+W".action.spawn = ipc [ "wallpaper" "open" ];
      "Mod+N".action.spawn = ipc [ "dnd" "toggle" ];
      "Mod+Alt+L".action.spawn = "${lock}/bin/cyberdeck-lock";
      # reboot optics: the supervisor brings the shell back
      "Mod+Shift+R".action.spawn = [
        qs
        "-c"
        "cyberdeck"
        "kill"
      ];
    };
  };

  home.packages = [
    pkgs.quickshell
    shell
    lock
    engrave
    sounds
  ];

  # the launcher that came before the quickhack: an old generation may have left it behind
  home.activation.cyberdeckCleanup = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    for stale in "$HOME/.config/quickshell/quickhack.qml"; do
      if [ -L "$stale" ] && [[ "$(readlink "$stale")" == /nix/store/* ]]; then
        run rm -f "$stale"
      fi
    done
  '';

  # lock after 5 min, screens off after 10, always lock before sleeping
  systemd.user.services.cyberdeck-idle = {
    Unit = {
      Description = "Cyberdeck idle handling";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = lib.concatStringsSep " " [
        "${pkgs.swayidle}/bin/swayidle -w"
        "timeout 300 ${lock}/bin/cyberdeck-lock"
        "timeout 600 '${config.programs.niri.package}/bin/niri msg action power-off-monitors'"
        "before-sleep ${lock}/bin/cyberdeck-lock"
      ];
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
