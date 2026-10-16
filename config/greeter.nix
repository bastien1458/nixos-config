# Login screen. greetd starts a throwaway niri session for the `greeter` user,
# which runs the Quickshell greeter (config/greeter). If that greeter ever
# crashes, a tuigreet styled the same way takes over so login keeps working.
# Set `style = "tuigreet"` to skip the graphical greeter entirely.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  style = "quickshell";
  user = "hello";

  theme = import ../theme { inherit pkgs lib; };
  niri = config.programs.niri.package;
  roles = theme.palette.roles;
  session = "${niri}/bin/niri-session";
  cache = "/var/cache/cyberdeck-greeter";

  # the greeter shares its components with the user shell
  greeterShell = pkgs.runCommand "cyberdeck-greeter" { } ''
    mkdir -p $out/assets
    cp ${./greeter/shell.qml} $out/shell.qml
    cp ${./greeter/GreeterView.qml} $out/GreeterView.qml
    for component in Theme Plate Icon DecodeText GlitchText Brackets MicroText Logo Chip KeyCap; do
      cp ${../home/quickshell}/$component.qml $out/
    done
    cp ${../home/quickshell/Glyphs.js} $out/Glyphs.js
    cp -r ${../home/quickshell/assets}/logos $out/assets/logos
  '';

  themeJson = pkgs.writeText "cyberdeck-greeter-theme.json" (
    builtins.toJSON {
      version = 1;
      os = theme.os;
      wallpaper = "${theme.wallpaper}";
      stamp = 1;
      palette = theme.palette;
      catalog = [ ];
    }
  );

  greeterJson = pkgs.writeText "cyberdeck-greeter.json" (
    builtins.toJSON {
      inherit user;
      host = config.networking.hostName;
      sessions = [
        {
          name = "NIRI // CYBERDECK";
          command = [ session ];
        }
      ];
    }
  );

  tuigreet = lib.concatStringsSep " " [
    "${pkgs.tuigreet}/bin/tuigreet"
    "--time"
    "--remember"
    "--asterisks"
    "--asterisks-char '#'"
    "--window-padding 2"
    "--container-padding 2"
    "--greeting '>> NIGHT CITY // NET ACCESS TERMINAL <<'"
    "--theme 'border=magenta;text=cyan;prompt=yellow;time=yellow;action=cyan;button=magenta;container=black;input=cyan;title=magenta;greet=yellow'"
    "--cmd ${session}"
  ];

  greeterSession = pkgs.writeShellScript "cyberdeck-greeter-session" ''
    export CYBERDECK_THEME=${themeJson}
    export CYBERDECK_GREETER=${greeterJson}
    export XDG_CACHE_HOME=${cache}
    if ! ${pkgs.quickshell}/bin/quickshell -p ${greeterShell}; then
      ${pkgs.kitty}/bin/kitty --start-as=fullscreen \
        -o background=${roles.bg} -o foreground=${roles.fg} -o font_size=14 \
        -o color6=${roles.primary} -o color5=${roles.secondary} -o color3=${roles.warn} \
        ${tuigreet}
    fi
    ${niri}/bin/niri msg action quit --skip-confirmation
  '';

  niriConfig = pkgs.writeText "cyberdeck-greeter-niri.kdl" ''
    hotkey-overlay {
        skip-at-startup
    }
    input {
        keyboard {
            xkb {
                layout "fr"
            }
        }
    }
    output "DP-1" {
        mode "1920x1080@180.000"
    }
    output "DP-2" {
        mode "1920x1080@179.982"
    }
    cursor {
        xcursor-theme "${theme.cursorName}"
        xcursor-size ${toString theme.cursorSize}
    }
    spawn-at-startup "${greeterSession}"
  '';

  launcher = pkgs.writeShellScript "cyberdeck-greeter" ''
    export XDG_CACHE_HOME=${cache}
    exec ${niri}/bin/niri -c ${niriConfig}
  '';
in
{
  services.greetd = {
    enable = true;
    useTextGreeter = style == "tuigreet";
    settings.default_session = {
      command = if style == "tuigreet" then tuigreet else "${launcher}";
      user = "greeter";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${cache} 0750 greeter greeter - -"
  ];
}
