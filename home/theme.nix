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
      # a neon block that leaves a trail when it jumps, and never stops pulsing
      cursor_shape = "block";
      cursor_blink_interval = "0.5 ease-in-out";
      cursor_stop_blinking_after = 0;
      cursor_trail = 3;
      cursor_trail_decay = "0.08 0.3";
      cursor_trail_start_threshold = 3;

      # sharp frame, thin neon edge between splits, no client decorations
      window_padding_width = "10 14";
      window_border_width = "1px";
      draw_minimal_borders = "yes";
      hide_window_decorations = "yes";
      confirm_os_window_close = 0;

      # tabs cut at an angle, numbered like the workspaces of the bar
      tab_bar_edge = "top";
      tab_bar_style = "slant";
      tab_bar_margin_height = "0 6";
      tab_title_template = "{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}{index:02d} // {title}";
      active_tab_title_template = "▶ {index:02d} // {title}";
      active_tab_font_style = "bold";
      inactive_tab_font_style = "normal";
      bell_on_tab = "⚠ ";

      # the bell is a red glitch on the window, not a sound
      enable_audio_bell = "no";
      visual_bell_duration = "0.12";

      # ctrl+shift+a then m / l: more or less glass
      dynamic_background_opacity = "yes";
      shell = "${pkgs.zsh}/bin/zsh";

      url_style = "straight";
      scrollback_lines = 10000;
    };
    keybindings = {
      "ctrl+shift+t" = "new_tab_with_cwd";
      "ctrl+shift+enter" = "new_window_with_cwd";
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
