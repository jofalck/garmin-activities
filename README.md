# garmin-activities

Connect IQ watch apps for the Forerunner 245 / 245 Music. Each records a FIT activity with the
right sport type, so Garmin Connect and Intervals.icu show it correctly without editing:

| App (eng / nob) | FIT sport / sub-sport | Garmin Connect type |
|---|---|---|
| Football / Fotball | soccer / generic | Soccer/Football |
| XC Classic / Klassisk | cross_country_skiing / generic | Cross Country Classic Skiing |
| XC Skate / Skøyting | cross_country_skiing / skate_skiing | Cross Country Skate Skiing |
| Randonee | alpine_skiing / backcountry | Backcountry Skiing |
| Roller Ski / Rulleski | inline_skating / generic | Inline Skating (no roller-ski type exists in FIT) |

## On the watch

- **START**: start. While recording, START stops and opens *Resume / Save / Discard*. Discard asks again before deleting.
- **BACK**: lap. While stopped, BACK reopens the menu. Before you start, BACK exits the app.
- **UP / DOWN**: switch data screens.
- Header colour: yellow = waiting for GPS / auto-pause, green = recording, red = stopped, blue = lap summary (5 s).
- Text is Norwegian when the watch language is Norsk, otherwise English.

## Install on a Forerunner 245 Music from a Windows PC

1. On the Windows PC, open https://github.com/jofalck/garmin-activities, sign in, open the `dist/` folder.
   For each `.prg` file (`football`, `xc-classic`, `xc-skate`, `randonee`, `roller-ski`): click it and use the
   *Download raw file* button (down arrow, top right of the file view).
2. Connect the watch to the PC with the Garmin charging cable. Wait until the watch shows the
   USB/connected screen.
3. Open File Explorer, then go to **This PC → Forerunner 245 Music → Internal Storage → GARMIN → APPS**.
   - The Music model connects as a media device (MTP), not as a drive letter. That's normal.
   - If the watch doesn't appear, close Garmin Express if it's running, then unplug and replug the watch.
4. Copy the five `.prg` files into `APPS`. To update later, copy the new files over the old ones with
   the same names.
5. Unplug the watch. It installs the apps when it disconnects.
6. On the watch, press START to open the activity list. The apps should be at the bottom of the list.
   If they're missing: START → scroll to **Add** (or hold UP → Settings → Activities & Apps → Add)
   and add them.
7. Test with a 2-minute recording: wait for the green header, record, save, sync. Then check the
   activity type in Garmin Connect and Intervals.icu.

To remove an app, delete its `.prg` from `GARMIN/APPS`.

## Change settings

Each app's settings are in `<app>/source/Config.mc`:
- sport type
- auto-lap distance (`AUTO_LAP_M`, XC = 2500)
- auto-pause speed and delay (`AUTO_PAUSE_KMH`, `AUTO_PAUSE_SEC`)
- the data screens (`PAGES`)
- the lap summary fields (`LAP_FIELDS`)

Shared code is in `common/`. Text is in `common/resources*/strings/ui.xml`. App names are in
`<app>/resources*/strings/strings.xml`. Icons are in `<app>/resources/drawables/launcher_icon.svg`
(40×40, 64-colour palette).

## Build

Requires the Connect IQ SDK (via the SDK Manager), the fr245/fr245m device files, and Java
(`brew install openjdk@21`).

```sh
./build.sh   # builds all apps into bin/ and copies the 245 Music builds to dist/
```

The signing key `developer_key` is not in git. Keep a backup of it (for example in a password
manager), because updates to installed apps must be signed with the same key.
