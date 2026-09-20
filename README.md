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
  game after a short reminder to power the badge off and on before the next play.
  Leaving fragments the badge's memory until a reboot, and a launch on a fragmented
  badge fails with a Lua memory error, so play stays inside the app rather than
  bouncing through the launcher.
- Home: **SCAN** turns on the NFC reader. **SWITCH LEAD** picks which Pokemon goes first.
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

The game is five Lua files plus the icon. The badge only has RAM for the code a screen
needs, and a launch on a fragmented heap fails on large allocations, so the files are
kept small. `hackamon.lua` (manifest header, stats, menus, scanning) and `battle.lua`
(moves, effects, encounters) and `fx.lua` (lights and motion) stay loaded. `screens.lua`
builds the widgets and runs the title parade, whose code is dropped after the wipe.
`gen.lua` holds the sprite art and renders the image files on first launch, then is dropped.

1. Open the badge IDE in Chrome or Edge.
2. **Import app**, paste the whole of `hackamon.lua` including the header, **Replace editor files**.
3. Click **+** and add each of `battle.lua`, `fx.lua`, `screens.lua` and `gen.lua`, named
   exactly, pasting the repo file into each.
4. **Choose image** to add the Pokeball icon if you want it.
5. Badge off, USB data cable in, badge on. **Connect**, choose **USB JTAG/serial debug unit**.
6. **Push**. The console should list `slug=hackamon` with all the files.
7. Click **Reboot** the first time, since the manifest sets a 96 KB Lua quota.
8. Open Hackamon from the launcher.

Push never deletes files on the badge. If an older layout left extra files in
`/littlefs/apps/hackamon`, remove them with `rm` in the IDE console; Share allows at
most 16 files and this app uses 15 including its eight sprite images.

## Testing off the badge

`python tools/run_harness.py` runs the whole game under Lua 5.5 with a mock badge API
(needs `pip install lupa`): first-launch render, title, wipe, home, scan, a battle with
a mid-battle switch, and exit. It catches Lua errors and bad widget calls, not visuals.

If the console says `cannot open .../data.lua`, the second file is missing or misnamed.
If it says `main.lua is not a regular file`, the code file in the workspace is not named
`main.lua`.

On first launch the game renders each sprite into a 44x44 four-bit indexed image file with a transparent background in the app folder, about 1.1 KB each, which keeps the whole app near 39 KB so it fits the 48 KiB Share limit with the icon
(`s1.bin` to `s4.bin` for the enemy view, `m1.bin` to `m4.bin` for the mirrored player
view, about 9 KB total). The screen says "First launch: preparing sprites"
for a few seconds while that happens, then every later launch is instant. If you
change a sprite in `data.lua`, delete the matching `.bin` files in the IDE console, for
example `rm /littlefs/apps/hackamon/s2.bin`, so they get rebuilt.
