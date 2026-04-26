# Descent Without Dread

A quality-of-life mod for [Idols of Ash](https://store.steampowered.com/app/4450800/Idols_of_Ash/) by Leafy Games.

Adds a waypoint system, arachnophobia mode, precision hook, and a First Kiln intro skip — focused on accessibility and exploration.

> **Compatibility:** Built against Idols of Ash v1.30. If the game has updated since then, the PCK patch may need to be re-applied by running `install.bat` again.

---

## Features

**Waypoints**
Set up to 9 waypoints per level with Ctrl+1-9. Teleport to them with 1-9. Clear all waypoints for the current level with Ctrl+Backspace. Glowing markers show exactly where each waypoint is. Persists between sessions across all maps.

**Arachnophobia Mode**
Toggle in Settings under Misc. Replaces centipede visuals with a cat face billboard and swaps all centipede audio with meows and hisses. Centipede behavior is completely unchanged — they still hunt, chase, and attack. If bioluminescence mode is enabled, the cat gets glowing eyes. Takes effect on next level load.

**First Kiln Intro Skip**
After watching the intro cinematic once, subsequent visits skip directly to the level.

**Precision Hook**
Right click while the hook is in flight to snap it in place. Caps the rope at its current length and kills forward momentum so you can land it exactly where you want. Restores normal rope behavior automatically when the hook attaches or is recalled.

---

## TL;DR

- Built with [GodotModLoader (GML) v7.0.1](https://github.com/GodotModding/godot-mod-loader)
- Requires PCK patching via [GDRE Tools](https://github.com/bruvzg/gdsdecomp) since the game doesn't ship with mod support
- Scripts must be exported as **text** (not compiled) for GML to load them
- Dev environment uses [GodotSteam 4.18.1](https://codeberg.org/godotsteam/godotsteam/releases) (Godot 4.6.2 + Steamworks 1.64)
- End users run `install.bat` — no manual setup required

---

## Project Structure

```
mods-unpacked/ElKameleon-DescentWithoutDread/
  mod_main.gd                   Entry point, registers script extensions
  manifest.json                 GML mod manifest
  Art/
    waypoint_marker.glb         Plumbob waypoint marker mesh
    waypoint_marker.glb.import
    cat.png                     Arachnophobia mode cat texture
    cat_glow.png                Arachnophobia mode glowing eyes (bio-lum variant)
  scenes/
    waypoint_marker.tscn        Waypoint marker scene
  scripts/
    waypoint_manager.gd         Waypoint set/teleport/persist logic
    arachnophobia_manager.gd    Cat replacement for centipede visuals and audio
    settings_ui_ext.gd          Injects Arachnophobia Mode checkbox into Settings UI
    precision_hook.gd           Precision hook mode on right click
  sfx/
    cat_meow.wav                Replaces centipede idle/wander/hunting sounds
    cat_hiss.wav                Replaces centipede attack/chomp sounds
```

---

> **Just here to play?** Everything below this point is for developers and modders. If you just want to install and play, grab the latest release and follow the instructions in `README.txt`.

---

## Dev Environment Setup

### Requirements

- [GodotSteam 4.18.1](https://codeberg.org/godotsteam/godotsteam/releases) (Godot 4.6.2 + Steamworks 1.64)
- A copy of Idols of Ash (Steam)
- [GDRE Tools v2.5-beta](https://github.com/bruvzg/gdsdecomp/releases) for PCK patching

### Getting started

> **Note:** This repo contains only the mod source files. It is not a standalone Godot project. To work on it you need a decompiled copy of Idols of Ash already set up as a Godot project. The mod files live inside that project under `mods-unpacked/`. Decompiling the game is outside the scope of this guide but GDRE Tools can do it.

1. Clone this repo into your Idols of Ash Godot project under `mods-unpacked/`
2. Open the project in GodotSteam
3. Place GML v7.0.1 in `addons/mod_loader/`
4. Place GDRE Tools in `addons/mod_loader/vendor/GDRE/`
5. Set up `override.cfg` in your Idols of Ash game folder (see below)

### override.cfg

Place this file in your Idols of Ash game folder alongside `idols_of_ash.exe`:

```ini
[autoload_prepend]
ModLoader="*res://addons/mod_loader/mod_loader.gd"
ModLoaderStore="*res://addons/mod_loader/mod_loader_store.gd"
```

Note: entries are listed in reverse order — `autoload_prepend` loads the last entry first.

### Why PCK patching is required

Idols of Ash does not ship with GML's autoloads or class registrations in its `project.binary`. GML requires its classes to be registered in the global script class cache before it can run. Since the game's shipped `project.binary` doesn't include these, it needs to be patched.

The dev workflow patches the PCK using GDRE during install. For end users, the release package handles this automatically via `install.bat`.

### Release pipeline

The mod uses an automated release pipeline:

1. **Project → Tools → Bump Version** in GodotSteam — shows current versions, pick Patch / Minor / Major / No Bump. Updates `manifest.json`.
2. **Project → Export → Export PCK/ZIP** — exports to `release/mods/ElKameleon-DescentWithoutDread.zip`.
3. **Run `bump_version.bat`** — reads version from `manifest.json`, updates `install.bat` and `README.txt`, zips the full `release/` folder into `DescentWithoutDread_vX.X.X.zip`.

### Exporting the mod zip

When exporting from GodotSteam:

1. Go to **Project → Export**
2. Under the **Scripts** tab, set export mode to **Text** (not Binary/Compiled)
   - GML looks for `.gd` files — compiled `.gdc` files will not be found
3. Export PCK/ZIP to `release/mods/`
4. The resulting zip contains `project.binary` and `.godot/global_script_class_cache.cfg`
   - These are extracted by `install.bat` and patched into the user's vanilla PCK

---

## Release Package Structure

```
DescentWithoutDread_vX.X.X/
  install.bat
  override.cfg
  README.txt
  addons/
    JSON_Schema_Validator/
    mod_loader/
      vendor/
        GDRE/
  mods/
    ElKameleon-DescentWithoutDread.zip
```

`install.bat` extracts `project.binary` and `global_script_class_cache.cfg` from the mod zip, backs up the vanilla PCK, patches both files in, and cleans up.

---

## Known Limitations

- Arachnophobia mode changes require a level reload to take effect
- If the game updates, the PCK patch needs to be re-applied by running `install.bat` again
- Waypoints are stored in `user://waypoints.cfg` and are not tied to save slots

---

## Dependencies

| Dependency | License |
|---|---|
| [GodotModLoader v7.0.1](https://github.com/GodotModding/godot-mod-loader) | MIT |
| [JSON Schema Validator](https://github.com/GodotModding/JSON-Shema-validator) | MIT |
| [GDRE Tools v2.5-beta](https://github.com/bruvzg/gdsdecomp) | MIT |

---

## License

MIT — see [LICENSE](LICENSE)