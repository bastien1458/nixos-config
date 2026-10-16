{ ... }:
{
  programs.niri.settings = {
    layout = {
      gaps = 12;
      # the bar reserves its own space, struts only add breathing room
      struts = {
        left = 8;
        right = 8;
        top = 4;
        bottom = 8;
      };
      # colours come from the live OS palette (see the include in niri.nix)
      focus-ring = {
        width = 2;
      };
      border = {
        enable = false;
        width = 1;
      };
      shadow = {
        enable = true;
        softness = 24;
        spread = 4;
        offset = {
          x = 0;
          y = 8;
        };
        color = "#00000080";
      };
    };

    animations = {
      workspace-switch.kind = {
        spring = {
          damping-ratio = 0.85;
          stiffness = 720;
          epsilon = 0.0001;
        };
      };
      window-movement.kind = {
        spring = {
          damping-ratio = 0.9;
          stiffness = 680;
          epsilon = 0.0001;
        };
      };
    };

    window-rules = [
      {
        geometry-corner-radius = {
          top-left = 0.0;
          top-right = 0.0;
          bottom-left = 0.0;
          bottom-right = 0.0;
        };
        clip-to-geometry = true;
      }
      {
        matches = [
          { app-id = "file_chooser"; }
          { app-id = "kitty"; }
          { app-id = "cyberdeck-float"; }
        ];
        open-floating = true;
      }
    ];

    prefer-no-csd = true;
  };
}
