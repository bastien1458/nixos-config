{
  description = "hello :)";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri = {
      url = "github:epireyn/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      niri,
      nixpkgs,
      home-manager,
      stylix,
      ...
    }@inputs:
    {
      nixosConfigurations.hello = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./config/configuration.nix
          niri.nixosModules.niri
          {
            nixpkgs.overlays = [ niri.overlays.niri ];
            programs.niri.package = niri.packages.x86_64-linux.niri-unstable;
          }
          stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # files that already exist (~/.bashrc, gtk.css...) are moved aside instead of failing
            home-manager.backupFileExtension = "hm-bak";

            home-manager.extraSpecialArgs = { inherit inputs; };

            home-manager.users.hello = import ./home/home.nix;
          }
        ];
      };
    };
}
