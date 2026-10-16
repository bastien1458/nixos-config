{
  config,
  lib,
  pkgs,
  ...
}:

{

  ## managing fonts

  fonts.packages = with pkgs; [
    jetbrains-mono
    # Rajdhani, the closest open font to the Cyberpunk 2077 UI, used by the Quickshell launcher
    (runCommand "rajdhani" { } (
      lib.concatStringsSep "\n" (
        lib.mapAttrsToList (weight: hash: ''
          install -Dm444 ${
            fetchurl {
              url = "https://raw.githubusercontent.com/google/fonts/5174b3333331c966c38f4355d50b03ca1c1df2f9/ofl/rajdhani/Rajdhani-${weight}.ttf";
              inherit hash;
            }
          } $out/share/fonts/truetype/Rajdhani-${weight}.ttf
        '') {
          Medium = "sha256-Ev99z+TCBuOHWsU7F2LqtX3movp/WobCa5e4jWWR6sI=";
          SemiBold = "sha256-lLvSWhjKZlmZ/rBaU33p/SuGDc+3i76coAJwglvyNdo=";
          Bold = "sha256-aRRw3TKGoU6Wd5QNC/dXlheYQbpSFcvaGiyJEKMiav0=";
        }
      )
    ))
  ];
  fonts.fontconfig.enable = true;
  fonts.fontconfig.defaultFonts = {
    monospace = [ "JetBrains Mono" ];
  };

  ## handle nvidia gpu

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };


  ## use yazi as a file chooser

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-termfilechooser
    ];
    config.common = {
      "org.freedesktop.impl.portal.FileChooser" = [ "termfilechooser" ];
    };
  };

  environment.sessionVariables = {
    GTK_USE_PORTAL = "1";
    QT_QPA_PLATFORMTHEME = "xdgdesktopportal";
  };

  ## general nix settings

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;
  networking.hostName = "hello";
  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "fr";
  };
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;
  users.users.hello = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    packages = with pkgs; [
      tree
    ];
  };
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
  ];

  programs.niri = {
    enable = true;
  };

  system.stateVersion = "26.05";
  imports = [
    ./hardware-configuration.nix
  ];
}
