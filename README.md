# Descent Without Dread
### A Peaceful Mode Mod for Idols of Ash

Removes the centipede from all modes, turning Idols of Ash into a pure exploration experience. Take your time. Nobody is chasing you.

**Compatible with v1.15**

---

## What it does
Adds a Peaceful Mode toggle to the settings menu. When enabled, the centipede will not spawn in any mode. The rest of the game is unchanged.

Note: the centipede is a big part of the game's pacing and atmosphere. This mod changes the experience significantly — consider playing through normally first.

---

## Requirements
- A copy of Idols of Ash (itch.io or Steam)
- [GDRE Tools](https://github.com/bruvzg/gdsdecomp/releases)

---

## Installation
1. Back up your `idols_of_ash.pck` file
   - **itch.io:** found in whatever folder you extracted the game to
   - **Steam:** found in `[Steam install location]\steamapps\common\IdolsOfAsh` — right-click the game in Steam, select **Manage → Browse Local Files** to open the folder directly
2. Open GDRE Tools and select **PCK → Patch PCK archive**
3. Select your `idols_of_ash.pck` as the target
4. Click **Select Files** and add the 4 `.gdc` files from this mod
5. Select all 4 files on the right panel and click **Map selected to Folder**
6. Navigate to and select the `scripts` folder inside your pck file list on the left
7. Click **Patch** — GDRE will prompt you to save the output file. It defaults to `idols_of_ash_patched.pck` on your desktop. Save it wherever you like, then rename it to `idols_of_ash.pck` and place it in your game folder, replacing the original (which you already backed up in step 1)

---

## Caveats
- Requires a restart to take effect after toggling
- If the game updates, the mod will need to be reapplied

---

## Uninstall
Restore your backed up `idols_of_ash.pck` file.
