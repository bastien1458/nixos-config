# The Cyberdeck Quickshell shell: bar, control center, quickhack launcher,
# breach protocol, OS selector, notifications, lockscreen and idle handling.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  theme = import ../theme { inherit pkgs lib; };
  repo = "${config.home.homeDirectory}/.dotfiles";
  qs = "${pkgs.quickshell}/bin/quickshell";

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

  # bakes the live OS into Stylix: every app gets the palette after this
  engrave = pkgs.writeShellScriptBin "cyberdeck-engrave" ''
    set -u
    os=$(${theme.tool}/bin/cyberdeck-theme current)
    printf '\e[1;35m'
    cat <<'EOF'
    ╔══════════════════════════════════════════════╗
    ║   CYBERDECK // FIRMWARE ENGRAVING PROTOCOL   ║
    ╚══════════════════════════════════════════════╝
    EOF
    printf '\e[0m\n\e[1;33m>> ENGRAVING %s INTO SYSTEM FIRMWARE\e[0m\n\n' "''${os^^}"
    if [ -f ${repo}/theme/os ]; then
      printf '%s\n' "$os" > ${repo}/theme/os
    fi
    if sudo nixos-rebuild switch --flake ${repo}#hello; then
      printf '\n\e[1;32m>> FIRMWARE ENGRAVED. EVERY APP NOW RUNS %s.\e[0m\n' "''${os^^}"
    else
      printf '\n\e[1;31m>> ENGRAVING FAILED. ICE HELD.\e[0m\n'
    fi
    read -r -n 1 -p "PRESS ANY KEY TO DISCONNECT"
  '';
in
{
  xdg.configFile."quickshell/cyberdeck".source = ./quickshell;

  xdg.configFile."cyberdeck/config.json".text = builtins.toJSON {
    wallpaper = "${theme.wallpaper}";
    defaultOs = theme.os;
    osFile = "${repo}/theme/os";
    # empty: located from the IP by wttr.in, or e.g. "Paris"
    weatherLocation = "";
  };

  home.packages = [
    pkgs.quickshell
    shell
    lock
    engrave
  ];

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
