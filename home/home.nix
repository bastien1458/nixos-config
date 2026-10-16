{
  pkgs,
  lib,
  inputs,
  config,
  ...
}:
{
  home.stateVersion = "26.05";

  # GTK colours, fonts and cursor come from Stylix (see theme.nix)
  gtk.enable = true;

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = lib.mkDefault "prefer-dark";
    };
  };

  imports = [
    ./apps/code.nix
    ./apps/firefox.nix
    ./apps/vim.nix
    ./apps/yazi.nix
    ./niri.nix
    ./niri/layout.nix
    ./packages.nix
    ./theme.nix
    ./shell.nix
    ./scripts.nix
  ];
}
