# Puts the real Cyberpunk 2077 sounds behind the deck's events, the way the
# game uses them. They belong to CD Projekt RED, so they never enter the repo:
# give this the "UI Sound Effects" zip of The Sounds Resource (or the folder it
# extracts to) and/or V's ringtone with --call, and they land in
# $XDG_DATA_HOME/cyberdeck/sounds, where the shell picks them over its placeholders.
set -euo pipefail

dest=${XDG_DATA_HOME:-$HOME/.local/share}/cyberdeck/sounds

usage() {
  echo "usage: cyberdeck-sounds [UI Sound Effects.zip | extracted folder] [--call ringtone]" >&2
  exit 1
}

pack=""
ringtone=""
while [ $# -gt 0 ]; do
  case $1 in
    --call)
      [ $# -ge 2 ] || usage
      ringtone=$2
      shift 2
      ;;
    *)
      [ -z "$pack" ] || usage
      pack=$1
      shift
      ;;
  esac
done
[ -n "$pack$ringtone" ] || usage
for given in "$pack" "$ringtone"; do
  if [ -n "$given" ] && [ ! -e "$given" ]; then
    echo "no such file: $given" >&2
    exit 1
  fi
done

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

max_volume() {
  ffmpeg -nostats -i "$1" -af volumedetect -f null - 2>&1 | sed -n 's/.*max_volume: \(-\{0,1\}[0-9.]*\) dB.*/\1/p'
}

mean_volume() {
  ffmpeg -nostats -i "$1" -af volumedetect -f null - 2>&1 | sed -n 's/.*mean_volume: \(-\{0,1\}[0-9.]*\) dB.*/\1/p'
}

# the game mixes its UI very low: peaks go to -3 dB, the levels in Sounds.qml do the rest
oneshot() {
  gain=$(awk -v m="$(max_volume "$1")" 'BEGIN { print -3 - m }')
  ffmpeg -v error -y -i "$1" -af "silenceremove=start_periods=1:start_threshold=-60dB,volume=${gain}dB" -ar 48000 -c:a pcm_s16le "$2"
}

# the main menu drone, its tail crossfaded into its head so pw-play can loop it without a seam
loop() {
  length=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$1")
  fade=2
  cut=$(awk -v l="$length" -v f="$fade" 'BEGIN { print l - f }')
  gain=$(awk -v m="$(mean_volume "$1")" 'BEGIN { print -20 - m }')
  ffmpeg -v error -y -i "$1" -filter_complex "
    [0:a]asplit=3[a][b][c];
    [a]atrim=start=$cut,asetpts=PTS-STARTPTS[tail];
    [b]atrim=end=$fade,asetpts=PTS-STARTPTS[head];
    [c]atrim=start=$fade:end=$cut,asetpts=PTS-STARTPTS[body];
    [tail][head]acrossfade=d=$fade:c1=tri:c2=tri[seam];
    [seam][body]concat=n=2:v=0:a=1,volume=${gain}dB,alimiter=limit=0.9[out]" \
    -map "[out]" -ar 48000 -c:a pcm_s16le "$2"
}

# the ringtone without its fade out (what lies 20 dB under its peak at the end),
# repeated four times in one file: the rings keep their beat for as long as a call rings
ring() {
  peak=$(max_volume "$1")
  floor=$(awk -v m="$peak" 'BEGIN { print m - 20 }')
  gain=$(awk -v m="$peak" 'BEGIN { print -3 - m }')
  ffmpeg -v error -y -i "$1" -af "areverse,silenceremove=start_periods=1:start_threshold=${floor}dB,areverse,volume=${gain}dB" -ar 48000 -c:a pcm_s16le "$work/ring.wav"
  ffmpeg -v error -y -stream_loop 3 -i "$work/ring.wav" -c copy "$2"
}

mkdir -p "$dest"

if [ -n "$pack" ]; then
  if [ -d "$pack" ]; then
    root=$pack
  else
    unzip -q "$pack" -d "$work/zip"
    root=$work/zip
  fi
  anchor=$(find "$root" -name ui_menu_hover.wav -print -quit)
  if [ -z "$anchor" ]; then
    echo "no ui_menu_hover.wav in $pack: not the Cyberpunk 2077 UI pack" >&2
    exit 1
  fi
  src=$(dirname "$anchor")

  # deck event | game file
  while IFS='|' read -r event file; do
    if [ ! -f "$src/$file" ]; then
      printf '  %-15s MISSING %s\n' "$event" "$file" >&2
      continue
    fi
    if [ "$event" = ambient ]; then loop "$src/$file" "$dest/$event.wav"; else oneshot "$src/$file" "$dest/$event.wav"; fi
    printf '  %-15s <- %s\n' "$event" "$file"
  done <<'EOF'
hover|ui_menu_hover.wav
click|ui_menu_onpress.wav
tab|ui_main_menu_open_tab.wav
value-up|ui_menu_value_up.wav
value-down|ui_menu_value_down.wav
menu-open|ui_menu_open.wav
menu-close|ui_menu_close.wav
radial-open|ui_radial_menu_open.wav
radial-close|ui_radial_menu_close.wav
notification|ui_popup_lore_open.wav
breach-open|ui_menu_full_screen_perk_espionage_start__01_Play.wav
matrix-hover|ui_menu_hover.wav
breach-success|ui_menu_perk_buy.wav
breach-fail|ui_menu_perk_buy_fail.wav
deck-switch|ui_menu_full_screen_perk_red_loading__01_Play.wav
lock-denied|ui_menu_attributes_fail.wav
lock-granted|ui_menu_enter.wav
boot|ui_main_menu_cc_confirmation_screen_open.wav
ambient|ui_main_menu_loop_start.wav
EOF
fi

if [ -n "$ringtone" ]; then
  ring "$ringtone" "$dest/call.wav"
  printf '  %-15s <- %s\n' call "$(basename "$ringtone")"
fi

echo "installed in $dest"
quickshell -c cyberdeck ipc call sounds rescan >/dev/null 2>&1 || echo "start the shell (or Super+Shift+R) to hear them"
