{
  config,
  pkgs,
  lib,
  ...
}:
let
  theme = import ../theme { inherit pkgs lib; };
in
{
  programs.niri.settings = {
    outputs.DP-2.mode = {
      height = 1080;
      width = 1920;
      refresh = 179.982;
    };

    outputs.DP-1.mode = {
      height = 1080;
      width = 1920;
      refresh = 180.00;
    };

    input.keyboard.xkb.layout = "fr";
    # digits on the keypad work right away (passwords!)
    input.keyboard.numlock = true;

    input.focus-follows-mouse.enable = true;

    # focus ring, borders and overview colours of the live OS, rewritten by
    # cyberdeck-theme on every switch and hot reloaded by niri
    includes = [
      {
        path = "${config.xdg.stateHome}/cyberdeck/niri.kdl";
        optional = true;
      }
    ];

    cursor = {
      theme = theme.cursorName;
      size = theme.cursorSize;
      hide-when-typing = true;
    };

    hotkey-overlay.skip-at-startup = true;

    # the shell and the wallpaper are started from shell.nix

    # the wallpaper keeps showing behind workspaces in the overview
    layer-rules = [
      {
        matches = [ { namespace = "^wallpaper$"; } ];
        place-within-backdrop = true;
      }
    ];

    binds = import ./niri/shortcuts.nix { inherit config; };
  };

  xdg.configFile."xdg-desktop-portal-termfilechooser/config" = {
    enable = true;
    text = ''
      [filechooser]
      cmd=${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
      default_dir=$HOME/Downloads
      env=TERMCMD='kitty --class=file_chooser'
      create_help_file=0
      open_mode=default
      save_mode=default
    '';
  };
}
