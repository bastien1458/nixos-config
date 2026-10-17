{
  config,
  lib,
  pkgs,
  ...
}:

{

  ## managing fonts (Rajdhani and JetBrains Mono are installed by Stylix, see stylix.nix)

  fonts.fontconfig.enable = true;

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
    # Discord only cancels its own output: a video playing next to a call went
    # back out through the mic. This source removes everything the default
    # sink plays, whatever the app.
    extraConfig.pipewire."60-echo-cancel"."context.modules" = [
      {
        name = "libpipewire-module-echo-cancel";
        args = {
          "library.name" = "aec/libspa-aec-webrtc";
          "monitor.mode" = true;
          "source.props" = {
            "node.name" = "echo-cancel-source";
            "node.description" = "Micro (sans écho)";
            # above the sound card's mic, so it becomes the default source
            "priority.session" = 2500;
          };
        };
      }
    ];
  };
  security.rtkit.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;
  # zsh is set up by home-manager (home/scripts.nix), this makes it the login shell
  programs.zsh = {
    enable = true;
    # home-manager runs compinit already
    enableGlobalCompInit = false;
  };
  # completions of the system packages
  environment.pathsToLink = [ "/share/zsh" ];

  users.users.hello = {
    isNormalUser = true;
    shell = pkgs.zsh;
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

  # needed by home-manager's dconf settings
  programs.dconf.enable = true;

  # PAM services of the Quickshell lockscreen and of its swaylock fallback
  security.pam.services.cyberlock = { };
  security.pam.services.swaylock = { };

  system.stateVersion = "26.05";
  imports = [
    ./hardware-configuration.nix
    ./stylix.nix
    ./greeter.nix
  ];
}
