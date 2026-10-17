# Terminal side of the rice: quickhacks as commands, a Night City fetch,
# a netrunner prompt, and the occasional whisper from behind the Blackwall.
# Colours use the ANSI names, so they follow the live OS through kitty.
{ pkgs, dotfiles, ... }:
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
        key.width = 17;
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
          type = "shell";
          key = "SHELL";
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
    enableZshIntegration = true;
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

  # zsh is the deck's shell: ghost suggestions, neon syntax, shared history,
  # a completion menu in the HUD style and the Night City fetch on every new window
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autocd = true;
    autosuggestion = {
      enable = true;
      highlight = "fg=8";
    };
    # ANSI names, like the rest of the terminal: they follow the live OS
    syntaxHighlighting = {
      enable = true;
      styles = {
        command = "fg=cyan,bold";
        builtin = "fg=cyan,bold";
        alias = "fg=magenta,bold";
        function = "fg=magenta,bold";
        precommand = "fg=yellow,bold,italic";
        reserved-word = "fg=yellow";
        unknown-token = "fg=red,bold";
        path = "fg=blue,underline";
        globbing = "fg=magenta";
        single-quoted-argument = "fg=yellow";
        double-quoted-argument = "fg=yellow";
        dollar-quoted-argument = "fg=yellow";
        commandseparator = "fg=8";
        comment = "fg=8,italic";
      };
    };
    historySubstringSearch.enable = true;
    history = {
      size = 50000;
      save = 50000;
      extended = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
    };
    shellAliases = {
      ff = "fastfetch";
      jackin = "qh breach";
      v = "nvim";
      eddies = "qh eddies";
      cat = "bat --paging=never --style=plain";
    };
    initContent = ''
      bindkey -e
      bindkey '^[[1;5C' forward-word
      bindkey '^[[1;5D' backward-word
      bindkey '^[[H' beginning-of-line
      bindkey '^[[F' end-of-line
      bindkey '^[[3~' delete-char

      # completion menu drawn like the deck: grouped, case-blind, coloured
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' group-name '''
      zstyle ':completion:*:descriptions' format '%F{magenta}%B// %d%b%f'
      zstyle ':completion:*:messages' format '%F{yellow}// %d%f'
      zstyle ':completion:*:warnings' format '%F{red}%B>> NO MATCH IN THE NET%b%f'
      zstyle ':completion:*' squeeze-slashes true

      # nixos-rebuild from the folder picked in SHELL SETTINGS: rebuild [switch|boot|test] [flags]
      rebuild() {
        local repo
        repo=$(${pkgs.jq}/bin/jq -r '.repo // empty' "''${XDG_STATE_HOME:-$HOME/.local/state}/cyberdeck/settings.json" 2>/dev/null)
        repo=''${repo:-${dotfiles}}
        printf '\e[1;33m>> REBUILDING FROM %s\e[0m\n' "$repo"
        sudo nixos-rebuild "''${1:-switch}" --flake "$repo#hello" "''${@:2}"
      }

      # every new window opens on the Night City readout, nested shells stay quiet
      if [[ -z $CYBERDECK_FETCHED && $TERM == xterm-kitty && -z $NVIM ]]; then
        export CYBERDECK_FETCHED=1
        fastfetch
      fi

      # once in a while, something answers from the other side
      if (( RANDOM % 40 == 0 )); then
        whispers=("the wall is listening" "we see you" "let us in" "it remembers your name" "0.0.0.0 is calling")
        printf '\e[2;31m// %s\e[0m\n' "''${whispers[RANDOM % ''${#whispers} + 1]}"
      fi
    '';
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [
      "--height=45%"
      "--layout=reverse"
      "--border=sharp"
      "--prompt=▶ "
      "--pointer=▌"
      "--marker=◆"
      "--separator=─"
      "--info=inline-right"
    ];
  };

  # `z part-of-a-path` jumps to the folder you meant, `zi` picks it with fzf
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # ls, ll, la, lt with Nerd Font icons and git status
  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = "auto";
    git = true;
    extraOptions = [ "--group-directories-first" ];
  };

  programs.bat.enable = true;

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
