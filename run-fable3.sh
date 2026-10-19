#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ! -d "$1" ]]; then
  printf 'Usage: %s "/path/to/Fable 3"\n' "$0" >&2
  exit 2
fi

game_dir="$(cd -- "$1" && pwd)"
for required in FableLauncher.exe SupportFiles/DirectX/Feb2010_XAudio_x86.cab SupportFiles/DirectX/Feb2010_X3DAudio_x86.cab; do
  if [[ ! -f "$game_dir/$required" ]]; then
    printf 'Missing game file: %s\n' "$game_dir/$required" >&2
    exit 1
  fi
done
if ! command -v cabextract >/dev/null 2>&1; then
  printf 'cabextract is required. On Arch: sudo pacman -S cabextract\n' >&2
  exit 1
fi

proton="${PROTON_PATH:-}"
if [[ -z "$proton" ]]; then
  for steam_dir in "$HOME/.local/share/Steam" "$HOME/.steam/root" "$HOME/.steam/steam"; do
    candidate="$steam_dir/steamapps/common/Proton 10.0/proton"
    if [[ -f "$candidate" ]]; then
      proton="$candidate"
      break
    fi
  done
fi
if [[ ! -f "$proton" ]]; then
  printf 'Proton 10.0 was not found. Install it in Steam, or set PROTON_PATH to its proton script.\n' >&2
  exit 1
fi

steam_dir="${STEAM_PATH:-}"
if [[ -z "$steam_dir" ]]; then
  for candidate in "$HOME/.local/share/Steam" "$HOME/.steam/root" "$HOME/.steam/steam"; do
    if [[ -f "$candidate/steam.sh" ]]; then
      steam_dir="$candidate"
      break
    fi
  done
fi
if [[ -z "$steam_dir" ]]; then
  printf 'Steam client directory not found. Set STEAM_PATH to your Steam directory.\n' >&2
  exit 1
fi
export STEAM_COMPAT_DATA_PATH="${FABLE3_PREFIX:-${XDG_DATA_HOME:-$HOME/.local/share}/fable3-proton10}"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="$steam_dir"
export PROTON_USE_WINED3D=1
export WINEDLLOVERRIDES='xaudio2_6=n,b;xapofx1_4=n,b;x3daudio1_7=n,b'

mkdir -p -- "$STEAM_COMPAT_DATA_PATH"
"$proton" run wineboot -u

tmp_dir="$(mktemp -d)"
trap 'rm -rf -- "$tmp_dir"' EXIT
cabextract -q -d "$tmp_dir" \
  "$game_dir/SupportFiles/DirectX/Feb2010_XAudio_x86.cab" \
  "$game_dir/SupportFiles/DirectX/Feb2010_X3DAudio_x86.cab"

system_dll_dir="$STEAM_COMPAT_DATA_PATH/pfx/drive_c/windows/syswow64"
for dll in XAudio2_6.dll XAPOFX1_4.dll X3DAudio1_7.dll; do
  source_dll="$tmp_dir/$dll"
  target_dll="$system_dll_dir/${dll,,}"
  if [[ ! -f "$source_dll" ]]; then
    printf 'Could not extract %s from the game DirectX files.\n' "$dll" >&2
    exit 1
  fi
  if [[ -f "$target_dll" && ! -f "${target_dll}.fable3-original" ]]; then
    cp -a -- "$target_dll" "${target_dll}.fable3-original"
  fi
  if ! cmp -s -- "$source_dll" "$target_dll"; then
    install -m 644 -- "$source_dll" "$target_dll"
  fi
done

video_options="$STEAM_COMPAT_DATA_PATH/pfx/drive_c/users/steamuser/AppData/Roaming/Lionhead Studios/Fable 3/VideoOptions.xml"
if [[ -f "$video_options" ]]; then
  sed -i -E 's#(<Fullscreen type="bool">)[Tt]rue(</Fullscreen>)#\1False\2#' "$video_options"
else
  mkdir -p -- "$(dirname -- "$video_options")"
  cat > "$video_options" <<'XML'
<?xml version="1.0"?>
<VideoOptions>
  <Version type="uint">3</Version>
  <AdapterOrdinal type="uint">0</AdapterOrdinal>
  <ScreenResolutionX type="int">800</ScreenResolutionX>
  <ScreenResolutionY type="int">600</ScreenResolutionY>
  <Fullscreen type="bool">False</Fullscreen>
  <VSync type="bool">True</VSync>
  <TextureDetail type="int">0</TextureDetail>
  <ModelDetail type="int">0</ModelDetail>
  <WaterDetail type="int">0</WaterDetail>
  <ShadowDetail type="int">0</ShadowDetail>
  <EffectsDetail type="int">0</EffectsDetail>
  <EnvironmentDetail type="int">0</EnvironmentDetail>
  <TreeDetail type="int">0</TreeDetail>
  <DrawDistance type="int">0</DrawDistance>
  <Calibrated type="bool">True</Calibrated>
</VideoOptions>
XML
fi

cd -- "$game_dir"
exec "$proton" run ./FableLauncher.exe
