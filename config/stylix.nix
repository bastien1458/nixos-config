# System wide theme: Stylix fed with the palette that cyberdeck-theme
# computes from the wallpaper for the selected OS (see theme/os).
{ pkgs, lib, ... }:
let
  theme = import ../theme { inherit pkgs lib; };
in
{
  stylix = {
    enable = true;
    image = theme.wallpaper;
    polarity = "dark";
    base16Scheme = theme.scheme;

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      sansSerif = {
        package = theme.rajdhani;
        name = "Rajdhani";
      };
      serif = {
        package = theme.rajdhani;
        name = "Rajdhani";
      };
      sizes = {
        applications = 12;
        desktop = 12;
        popups = 12;
        terminal = 12;
      };
    };

    cursor = {
      package = theme.cursors;
      name = theme.cursorName;
      size = theme.cursorSize;
    };

    opacity = {
      terminal = 0.88;
      popups = 0.95;
    };

    # Qt apps keep the xdg-desktop-portal platform theme set in configuration.nix
    targets.qt.enable = false;
  };

  # the greeter runs as its own user: make the cursor theme visible system wide
  environment.systemPackages = [ theme.cursors ];
}
