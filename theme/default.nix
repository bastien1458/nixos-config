# Everything colour related that both the system and home-manager need:
# the colour engine, the palettes it computes from the wallpaper at build
# time, the cursor theme and the fonts.
{ pkgs, lib }:
let
  # the OS (colour algorithm) baked into Stylix; the bar rewrites this file
  # when you switch OS, so the next rebuild picks the same one
  os = builtins.head (lib.splitString "\n" (builtins.readFile ./os));

  wallpaper = ../home/assets/wallpaper.jpg;

  python = pkgs.python3.withPackages (ps: [ ps.pillow ]);

  tool =
    pkgs.runCommand "cyberdeck-theme"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
        meta.mainProgram = "cyberdeck-theme";
      }
      ''
        install -Dm644 ${./cyberdeck_theme.py} $out/share/cyberdeck/cyberdeck_theme.py
        makeWrapper ${python}/bin/python3 $out/bin/cyberdeck-theme \
          --add-flags $out/share/cyberdeck/cyberdeck_theme.py \
          --prefix PATH : ${lib.makeBinPath [ pkgs.procps ]}
      '';

  # one json per OS, computed from the wallpaper (read back at eval time)
  palettes = pkgs.runCommand "cyberdeck-palettes" { } ''
    ${tool}/bin/cyberdeck-theme palette --image ${wallpaper} --out $out
  '';

  palette = builtins.fromJSON (builtins.readFile "${palettes}/${os}.json");

  scheme = {
    scheme = "Cyberdeck ${palette.name}";
    author = "cyberdeck-theme";
  }
  // lib.mapAttrs (_: lib.removePrefix "#") palette.base16;

  cursors = pkgs.callPackage ./cursors {
    xcursorgen = pkgs.xcursorgen or pkgs.xorg.xcursorgen;
    colors = {
      bg = palette.roles.bg;
      primary = palette.roles.primary;
      accent = palette.roles.warn;
      danger = palette.roles.danger;
    };
  };

  # Rajdhani, the closest open font to the Cyberpunk 2077 UI
  rajdhani = pkgs.runCommand "rajdhani" { } (
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList
        (weight: hash: ''
          install -Dm444 ${
            pkgs.fetchurl {
              url = "https://raw.githubusercontent.com/google/fonts/5174b3333331c966c38f4355d50b03ca1c1df2f9/ofl/rajdhani/Rajdhani-${weight}.ttf";
              inherit hash;
            }
          } $out/share/fonts/truetype/Rajdhani-${weight}.ttf
        '')
        {
          Medium = "sha256-Ev99z+TCBuOHWsU7F2LqtX3movp/WobCa5e4jWWR6sI=";
          SemiBold = "sha256-lLvSWhjKZlmZ/rBaU33p/SuGDc+3i76coAJwglvyNdo=";
          Bold = "sha256-aRRw3TKGoU6Wd5QNC/dXlheYQbpSFcvaGiyJEKMiav0=";
        }
    )
  );
in
{
  inherit
    os
    wallpaper
    tool
    palettes
    palette
    scheme
    cursors
    rajdhani
    ;
  cursorName = "Cyberdeck";
  cursorSize = 28;
}
