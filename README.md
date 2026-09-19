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

- Home: **SCAN** turns on the NFC reader. **SWITCH LEAD** picks which Pokemon goes first.
- Hold a sticker to the back of the badge. A wild Pokemon appears.
- Battle: UP/DOWN pick a move, A uses it, B runs. A advances the dialogue, and HP bars
  drop in step with the text. A hit darkens the target for a moment.
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

The game is two files: `hackamon.lua` (manifest header plus game code) and `data.lua`
(Pokemon stats and sprites). Splitting them keeps the Lua compiler's memory peak under
the badge's limit.

1. Open the badge IDE in Chrome or Edge.
2. **Import app**, paste the whole of `hackamon.lua` including the header, **Replace editor files**.
3. Click **+**, name the new file exactly `data.lua`, and paste the contents of `data.lua` into it.
4. Remove `icon.bin` from the workspace, or keep it if you want the custom icon.
5. Badge off, USB data cable in, badge on. **Connect**, choose **USB JTAG/serial debug unit**.
6. **Push**. The console should list `slug=hackamon` with `main.lua`, `data.lua` and `manifest.cfg`.
7. Click **Reboot** the first time, since the manifest sets a 96 KB Lua quota.
8. Open Hackamon from the launcher.

If the console says `cannot open .../data.lua`, the second file is missing or misnamed.
