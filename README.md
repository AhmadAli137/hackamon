# Hackamon

A Pokemon-style game for the Hack the North 2026 hacker badge. Scan NFC stickers to
meet wild Pokemon, battle them Game Boy style, and build your team.

One file, `hackamon.lua`, installed through the
[badge IDE](https://badge.hackthenorth.com/ide/).

## Pokemon

| Code | Pokemon | HP | Type | Attack | Effect move |
| --- | --- | --- | --- | --- | --- |
| `PKM01` | Charmander | 39 | Fire | Scratch | Ember: damage plus a burn that hurts each turn |
| `PKM02` | Squirtle | 44 | Water | Tackle | Withdraw: halves incoming damage for two turns |
| `PKM03` | Bulbasaur | 45 | Grass | Tackle | Leech Seed: drains the enemy and heals you each turn |

Fire beats Grass, Grass beats Water, Water beats Fire. Super effective hits do 1.5x.

## Playing

- First launch: pick a starter.
- Home: **SCAN** turns on the NFC reader. **SWITCH** cycles through the Pokemon you own.
- Hold a sticker to the back of the badge. A wild Pokemon appears.
- Battle: UP/DOWN pick a move, A uses it, B runs. A advances the dialogue.
- Beat a wild Pokemon to catch it. Your team is saved on the badge.

## Screen layout

Enemy sprite top-right with its name and HP bar top-left. Your Pokemon bottom-left,
mirrored to face the enemy, with its name, HP bar and numbers bottom-right. Dialogue box
along the bottom: messages on the left, move menu on the right.

## Stickers

Write the code as an NDEF **Text** record onto an NTAG215 sticker with the NFC Tools
phone app. Uppercase, no spaces.

## Installing

1. Open the badge IDE in Chrome or Edge.
2. **Import app**, paste the whole of `hackamon.lua` including the header, **Replace editor files**.
3. Remove `icon.bin` from the workspace.
4. Badge off, USB data cable in, badge on. **Connect**, choose **USB JTAG/serial debug unit**.
5. **Push**, then open Hackamon from the launcher.
