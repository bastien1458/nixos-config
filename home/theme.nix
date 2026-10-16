# User side of the theme: Stylix targets plus the live layer written by
# cyberdeck-theme, so switching OS from the bar recolours running apps.
{
  config,
  options,
  pkgs,
  lib,
  ...
}:
let
  theme = import ../theme { inherit pkgs lib; };
  state = "${config.xdg.stateHome}/cyberdeck";
in
{
  # niri gets its colours from the live include (see niri.nix), not from Stylix;
  # the target only exists when niri-flake ships its Stylix module
  stylix.targets = lib.optionalAttrs (options.stylix.targets ? niri) { niri.enable = false; } // {
    firefox.profileNames = [ "default" ];
    # Qt keeps the portal platform theme set in configuration.nix
    qt.enable = false;

    # GTK windows in the same DNA as the shell: sharp corners, neon edges
    gtk.extraCss = ''
      /* Cyberdeck: every GTK window speaks the same language as the shell */
      * {
        border-radius: 0;
      }

      window.background,
      .background {
        background-color: @window_bg_color;
      }

      headerbar,
      .titlebar {
        border-bottom: 1px solid alpha(@accent_color, 0.65);
        box-shadow: inset 3px 0 0 @accent_color;
      }

      headerbar .title,
      .title {
        font-weight: 700;
        letter-spacing: 1px;
      }

      button:hover {
        box-shadow: inset 0 0 0 1px alpha(@accent_color, 0.8);
      }

      button:checked,
      button.suggested-action {
        background-color: @accent_bg_color;
        color: @accent_fg_color;
      }

      button.destructive-action {
        background-color: @destructive_bg_color;
        color: @destructive_fg_color;
      }

      entry:focus-within,
      spinbutton:focus-within {
        box-shadow: inset 0 0 0 1px @accent_color;
      }

      *:focus-visible {
        outline: 1px solid @accent_color;
        outline-offset: -1px;
      }

      selection,
      *:selected,
      row:selected {
        background-color: alpha(@accent_color, 0.3);
        color: @window_fg_color;
      }

      row:selected {
        box-shadow: inset 3px 0 0 @accent_color;
      }

      scrollbar slider {
        background-color: alpha(@accent_color, 0.45);
        min-width: 4px;
        min-height: 4px;
      }

      scrollbar slider:hover {
        background-color: @accent_color;
      }

      tooltip,
      tooltip.background {
        background-color: @window_bg_color;
        border: 1px solid @accent_color;
      }

      popover > contents,
      popover.background > contents,
      menu,
      .menu,
      .context-menu {
        border: 1px solid alpha(@accent_color, 0.6);
      }

      progressbar progress,
      scale highlight,
      levelbar block.filled {
        background-color: @accent_color;
      }

      switch:checked {
        background-color: @accent_bg_color;
      }

      /* live colours of the active OS, written by cyberdeck-theme */
      @import url("file://${state}/gtk.css");
    '';
  };

  programs.kitty = {
    enable = true;
    settings = {
      cursor_shape = "block";
      cursor_blink_interval = "0.5";
      window_padding_width = 12;
      window_border_width = "1px";
      confirm_os_window_close = 0;
      enable_audio_bell = "no";
      tab_bar_edge = "top";
      tab_bar_style = "powerline";
    };
    # loaded last: overrides the Stylix colours with the live OS palette,
    # and kitty re-reads it on SIGUSR1 when the OS changes
    extraConfig = lib.mkAfter ''
      include ${state}/kitty.conf
    '';
  };

  # the live palette exists before anything reads it
  home.activation.cyberdeckTheme = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${theme.tool}/bin/cyberdeck-theme init || true
  '';

  home.packages = [ theme.tool ];
}
