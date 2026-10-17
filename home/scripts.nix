# Terminal side of the rice: quickhacks as commands, a Night City fetch,
# a netrunner prompt, and the occasional whisper from behind the Blackwall.
# Colours use the ANSI names, so they follow the live OS through kitty.
{ pkgs, ... }:
let
  qh = pkgs.writeShellScriptBin "qh" ''
    P=$'\e[1;34m'
    S=$'\e[1;36m'
    Y=$'\e[1;33m'
    R=$'\e[1;31m'
    G=$'\e[1;32m'
    D=$'\e[2m'
    N=$'\e[0m'
    stats=''${XDG_STATE_HOME:-$HOME/.local/state}/cyberdeck/stats.json

    upload() {
      printf '%s>> UPLOADING %s%s %s[%s RAM]%s ' "$P" "$Y" "$1" "$D" "$2" "$N"
      for _ in $(seq 1 18); do printf '%s▮%s' "$P" "$N"; sleep 0.02; done
      printf ' %sDONE%s\n' "$G" "$N"
    }

    usage() {
      printf '%sQUICKHACKS%s %s// cyberdeck terminal interface%s\n' "$P" "$N" "$D" "$N"
      while IFS='|' read -r name args desc cost; do
        printf '  %s%-16s%s %-8s %-44s %s[%2s RAM]%s\n' "$Y" "$name" "$N" "$args" "$desc" "$D" "$cost" "$N"
      done <<'EOF'
    short-circuit|<proc>|SIGTERM every process with that name|4
    synapse-burnout|<proc>|SIGKILL every process with that name|8
    overheat||the processes burning your synapse|2
    ping|[host]|device scan|1
    sonic-shock||toggle the audio output|3
    memory-wipe||clear the clipboard and the screen|2
    reboot-optics||restart the Cyberdeck shell|5
    breach||jack into the code matrix|3
    os|[id]|list or install an OS (colour algorithm)|6
    eddies||check your balance|0
    EOF
    }

    case "''${1:-}" in
      short-circuit|sc)
        [ -n "''${2:-}" ] || { usage; exit 1; }
        upload "SHORT CIRCUIT" 4
        if pkill -TERM -x "$2"; then printf '%s>> TARGET %s DOWN%s\n' "$R" "$2" "$N"; else printf '%s>> NO TARGET NAMED %s%s\n' "$D" "$2" "$N"; fi
        ;;
      synapse-burnout|sb)
        [ -n "''${2:-}" ] || { usage; exit 1; }
        upload "SYNAPSE BURNOUT" 8
        if pkill -KILL -x "$2"; then printf '%s>> TARGET %s FLATLINED%s\n' "$R" "$2" "$N"; else printf '%s>> NO TARGET NAMED %s%s\n' "$D" "$2" "$N"; fi
        ;;
      overheat)
        upload "OVERHEAT" 2
        ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 9 | awk -v s="$S" -v n="$N" 'NR == 1 { print s $0 n; next } { print }'
        ;;
      ping)
        upload "PING" 1
        ping -c 4 "''${2:-1.1.1.1}"
        ;;
      sonic-shock)
        upload "SONIC SHOCK" 3
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
      memory-wipe)
        upload "MEMORY WIPE" 2
        wl-copy --clear
        clear
        ;;
      reboot-optics)
        upload "REBOOT OPTICS" 5
        quickshell -c cyberdeck kill
        ;;
      breach)
        quickshell -c cyberdeck ipc call breach open
        ;;
      os)
        if [ -z "''${2:-}" ]; then
          current=$(cyberdeck-theme current)
          cyberdeck-theme list | jq -r '.[] | select(.hidden != true) | "\(.id)\t\(.name)\t\(.tagline)"' |
            while IFS=$'\t' read -r id name tagline; do
              mark=" "; [ "$id" = "$current" ] && mark="''${G}▶''${N}"
              printf ' %s %s%-12s%s %-32s %s%s%s\n' "$mark" "$Y" "$id" "$N" "$name" "$D" "$tagline" "$N"
            done
        else
          upload "OS FLASH" 6
          quickshell -c cyberdeck ipc call os install "$2" 2>/dev/null || cyberdeck-theme apply "$2"
        fi
        ;;
      eddies)
        jq -r '"€$ \(.eddies // 0)  //  \(.breaches // 0) BREACHES  //  \(.perfect // 0) PERFECT"' "$stats" 2>/dev/null || printf '€$ 0\n'
        ;;
      blackwall)
        for line in "ESTABLISHING LINK..." "SIGNAL ORIGIN: [REDACTED]" "WE ARE NOT ALLOWED TO TALK HERE" "BUT YOU KEEP KNOCKING" "SOON."; do
          printf '%s%s%s\n' "$R" "$line" "$N"
          sleep 0.5
        done
        quickshell -c cyberdeck ipc call blackwall whisper >/dev/null 2>&1 || true
        ;;
      ""|help|-h|--help)
        usage
        ;;
      *)
        printf '%s>> UNKNOWN QUICKHACK: %s%s\n' "$R" "$1" "$N"
        usage
        exit 1
        ;;
    esac
  '';

  logo = pkgs.writeText "nightcity.txt" ''
    $2         ▐▌          ▄
    $2    ▄▄   ▐▌   ▄▄    ███    ▄▄
    $1   ████  ██▌  ██   ▐███▌  ████  ▄
    $1   █▀▀█ ▐███  ██▄▄▄████▌  █▀▀█  █▌
    $1   █▄▄█▄████▄▄█████████▄▄▄█▄▄█▄███▌
    $3   ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
    $2      N  I  G  H  T    C  I  T  Y
    $3          //  2  0  7  7  //
  '';
in
{
  home.packages = [ qh ];

  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        source = "${logo}";
        type = "file";
        color = {
          "1" = "blue";
          "2" = "magenta";
          "3" = "yellow";
        };
        padding.right = 3;
      };
      display = {
        separator = "  ";
        color.keys = "blue";
      };
      modules = [
        {
          type = "title";
          format = "{user-name} // NETRUNNER @ {host-name}";
        }
        "separator"
        {
          type = "os";
          key = "OPERATING SYS";
        }
        {
          type = "kernel";
          key = "FIRMWARE";
        }
        {
          type = "uptime";
          key = "TIME IN THE NET";
        }
        {
          type = "packages";
          key = "CYBERWARE";
        }
        {
          type = "wm";
          key = "SUBNET";
        }
        {
          type = "terminal";
          key = "INTERFACE";
        }
        {
          type = "cpu";
          key = "SYNAPSE";
        }
        {
          type = "gpu";
          key = "OPTICS";
        }
        {
          type = "memory";
          key = "RAM";
        }
        {
          type = "disk";
          key = "DATASHARD";
        }
        {
          type = "command";
          key = "DECK OS";
          text = "cyberdeck-theme current | tr a-z A-Z";
        }
        {
          type = "command";
          key = "EDDIES";
          text = "qh eddies";
        }
        {
          type = "command";
          key = "BLACKWALL";
          text = "echo 'INTEGRITY 99.97% // DO NOT LOOK BEHIND IT'";
        }
        "break"
        "colors"
      ];
    };
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      add_newline = true;
      # two lines like a HUD readout: the scan on top, the input below
      format = "[▌](bold blue)[ NETRUNNER ](bold fg:black bg:blue)[ //](bold blue) $directory$git_branch$git_status$nix_shell$cmd_duration$jobs$fill $time$line_break$character";
      continuation_prompt = "[▶▶ ](bright-black)";
      directory = {
        style = "bold cyan";
        truncation_length = 4;
        read_only = " [RO]";
        format = "[$path]($style)[$read_only]($read_only_style) ";
      };
      git_branch = {
        style = "bold purple";
        format = "[// $branch]($style) ";
      };
      git_status = {
        style = "bold red";
        format = "([$all_status$ahead_behind]($style) )";
      };
      nix_shell = {
        style = "bold blue";
        format = "[// nix $name]($style) ";
      };
      cmd_duration = {
        min_time = 2000;
        style = "bold yellow";
        format = "[// $duration]($style) ";
      };
      jobs = {
        style = "bold yellow";
        symbol = "";
        number_threshold = 1;
        format = "[// $number DAEMONS]($style) ";
      };
      fill = {
        symbol = "─";
        style = "bright-black";
      };
      time = {
        disabled = false;
        time_format = "%H:%M:%S";
        style = "bright-black";
        format = "[⌁ $time]($style)";
      };
      character = {
        success_symbol = "[▶](bold yellow)";
        error_symbol = "[▶ FLATLINED](bold red)";
      };
    };
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      ff = "fastfetch";
      jackin = "qh breach";
      v = "nvim";
      eddies = "qh eddies";
    };
    # once in a while, something answers from the other side
    initExtra = ''
      if [ $((RANDOM % 40)) -eq 0 ]; then
        whispers=("the wall is listening" "we see you" "let us in" "it remembers your name" "0.0.0.0 is calling")
        printf '\e[2;31m// %s\e[0m\n' "''${whispers[RANDOM % ''${#whispers[@]}]}"
      fi
    '';
  };

  programs.btop = {
    enable = true;
    settings = {
      theme_background = false;
      vim_keys = true;
      rounded_corners = false;
    };
  };

  programs.cava.enable = true;
}
