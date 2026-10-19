# Fable III on Arch Linux

This launcher runs the Windows version of Fable III with Proton 10.0. It was tested on Arch Linux with an Intel HD 4000 GPU. It uses WineD3D for Direct3D 9 and installs the game's own 32 bit DirectX audio DLLs into a separate Proton prefix so character voices work.

The game and Microsoft DLLs are **not included** in this repository. Obtain game files from a source you are authorized to use. The script works with the file layout shown below.

## Install

1. Install Steam and `cabextract` on Arch Linux:

   ```bash
   sudo pacman -S steam cabextract
   ```

   Steam requires Arch's `multilib` repository. If Steam is already installed, you only need `cabextract`.

2. Open Steam and install **Proton 10.0** from Library → Tools. The launcher looks for a native Steam installation in `~/.local/share/Steam`, `~/.steam/root`, or `~/.steam/steam`.

3. Extract your Fable III game files. Find the folder containing `FableLauncher.exe`. It must also contain these files:

   ```text
   Fable 3/
   ├── FableLauncher.exe
   └── SupportFiles/DirectX/
       ├── Feb2010_XAudio_x86.cab
       └── Feb2010_X3DAudio_x86.cab
   ```

4. Download this repository using GitHub's **Code → Download ZIP** button, then extract the ZIP. Open a terminal in the extracted repository folder.

5. Launch the game, replacing the path with your own game folder:

   ```bash
   chmod +x run-fable3.sh
   ./run-fable3.sh "/home/yourname/Games/Fable 3"
   ```

Use the same command for later launches. Keep the game folder outside this repository. The `.gitignore` also excludes a `Fable 3` folder if you put it here by mistake.

## What the launcher does

- Creates a game-only Proton prefix at `~/.local/share/fable3-proton10`.
- Extracts XAudio, XAPOFX, and X3DAudio DLLs from the DirectX CAB files already supplied with your game. It backs up the original Proton DLLs as `*.fable3-original` inside the prefix.
- Starts the game in windowed mode with low graphics settings. The initial resolution is 800 × 600; adjust it in the game's options after it opens.
- Starts `FableLauncher.exe`, which is the required entry point for this game.

The launcher does not run the game's Windows redistributable installers or install files system-wide.

## Troubleshooting

**“Proton 10.0 was not found.”** Install Proton 10.0 in Steam. If Steam uses a different library, set the full path to its `proton` script:

```bash
PROTON_PATH="/path/to/Proton 10.0/proton" ./run-fable3.sh "/path/to/Fable 3"
```

If the Steam client itself is installed in a different location, also set `STEAM_PATH` to its directory.

**“Missing game file.”** Check that the argument points to the directory containing `FableLauncher.exe`, not the parent download directory. Other game releases may not include the DirectX CAB files required by this audio fix.

**No character voices.** Quit the game and relaunch it with this script. Confirm both CAB files above exist. The script reinstalls the native audio DLLs if Proton replaces them.

**Direct3D failed to initialise.** Keep the game in windowed mode. The script changes `<Fullscreen>` to `False` before each launch and uses Proton's OpenGL renderer for older GPUs.

**Where are saves?** Game data is inside `~/.local/share/fable3-proton10/pfx/drive_c/users/steamuser/`. Back up this prefix before removing it.

## Scope

This setup was verified to reach Fable III's character selection screen on one Arch Linux machine; game builds and hardware can differ. Online features were not tested.

## Publish this guide on GitHub

Create a public repository, then upload only `README.md`, `run-fable3.sh`, and `.gitignore` from this folder. Add a license on GitHub if you want to give others permission to reuse or change your script; MIT is a common permissive choice. Do not upload the `Fable 3` directory or any game archives, executables, or DLLs.
