# Hackamon

A Pokemon-style game for the Hack the North 2026 hacker badge. Scan NFC stickers to
meet wild Pokemon, battle them Game Boy style, and build your team.

One file, `hackamon.lua`, installed through the
[badge IDE](https://badge.hackthenorth.com/ide/).

## Pokemon

You start with Pikachu. The other three live on NFC stickers.

| Code | Pokemon | HP | Type | Attack | Effect move |
| --- | --- | --- | --- | --- | --- |
| starter | Pikachu | 35 | Electric | Quick Attack | Thunder Wave: paralyzes, enemy may lose its turn for 3 turns |
| `PKM01` | Charmander | 39 | Fire | Scratch | Ember: damage plus a burn that hurts each turn |
| `PKM02` | Squirtle | 44 | Water | Tackle | Withdraw: halves incoming damage for two turns |
| `PKM03` | Bulbasaur | 45 | Grass | Tackle | Leech Seed: drains the enemy and heals you each turn |

Fire beats Grass, Grass beats Water, Water beats Fire, Electric beats Water, Grass resists
Electric. Super effective hits do 1.5x, resisted hits 0.5x.

## Playing

- Launch: a title screen where the four Pokemon parade across a night sky, each posing
  centre stage with its element's effects and LED colour. A wipes to the home screen.
- HOME returns to the home screen from anywhere. **EXIT** on the home menu leaves the
  game. Leaving fragments the badge's memory until the next reboot, so play stays inside
  the app rather than bouncing through the launcher.
- Home: **SCAN** turns on the NFC reader. **SWITCH LEAD** picks which Pokemon goes first.
  **HACKADEX** lists all four Pokemon: caught ones are starred, seen ones show their sprite
  and stats, unseen ones show as ???.
- Hold a sticker to the back of the badge. A wild Pokemon appears.
- Battle: UP/DOWN pick a move, A uses it, B runs. A advances the dialogue, and HP bars
  drop in step with the text. The attacker lunges, the target shakes and darkens, and
  the LEDs play in the move's colour. Attack moves are quick: a triple flash and an instant
  hit. Special moves are long: three laps around the LED ring, then all six hold for the
  impact. The struck Pokemon blinks and flames, bubbles, leaves or sparks burst over it.
- **SWITCH** appears in the battle menu once you own more than one Pokemon. Switching
  uses your turn.
- Every battle starts with your whole team at full HP.
- Beat a wild Pokemon you don't own and it joins your team. Beat one you already own and
  nothing changes, no duplicates.
- If any of your Pokemon faints, you lose the whole team and start over with Pikachu.

## Screen layout

Enemy sprite top-right with its name and HP bar top-left. Your Pokemon bottom-left,
mirrored to face the enemy, with its name, HP bar and numbers bottom-right. Dialogue box
along the bottom: messages on the left, move menu on the right.

## Stickers

Write the code as an NDEF **Text** record onto an NTAG215 sticker with the NFC Tools
phone app. Uppercase, no spaces.

## Installing

The game is seven small files, because the badge only has RAM for the code a screen
needs. `hackamon.lua` (manifest header plus game code), `data.lua` (stats) and `fx.lua`
(battle lights and motion) stay loaded. `ui.lua` (widget builder), `title.lua` (title
parade and wipe), `gen.lua` and `sprites.lua` (first-launch sprite renderer) are loaded
once, used, and dropped.

1. Open the badge IDE in Chrome or Edge.
2. **Import app**, paste the whole of `hackamon.lua` including the header, **Replace editor files**.
3. Click **+** and add each of `data.lua`, `fx.lua`, `ui.lua`, `title.lua`, `gen.lua` and
   `sprites.lua`, named exactly, pasting the repo file into each.
4. Remove `icon.bin` from the workspace, or keep it if you want the custom icon.
5. Badge off, USB data cable in, badge on. **Connect**, choose **USB JTAG/serial debug unit**.
6. **Push**. The console should list `slug=hackamon` with all seven files.
7. Click **Reboot** the first time, since the manifest sets a 96 KB Lua quota.
8. Open Hackamon from the launcher.

If the console says `cannot open .../data.lua`, the second file is missing or misnamed.
If it says `main.lua is not a regular file`, the code file in the workspace is not named
`main.lua`.

On first launch the game renders each sprite into a 44x44 image file in its private appdata folder, which keeps the app folder at about 28 KB so it fits the 48 KiB Share limit and, with the images, the 64 KiB storage quota
(`s1.bin` to `s4.bin` for the enemy view, `m1.bin` to `m4.bin` for the mirrored player
view, about 31 KB total). The screen says "First launch: preparing sprites"
for a few seconds while that happens, then every later launch is instant. If you
change a sprite in `data.lua`, delete the matching `.bin` files in the IDE console, for
example `rm /littlefs/appdata/hackamon/s2.bin`, so they get rebuilt.
