# Hackamon

A Pokemon-style game for the Hack the North 2026 hacker badge. Scan NFC stickers hidden
around campus to find wild Hackemon, battle them, catch them, and fill your Hackadex.

Everything here is a Lua app for the badge's built-in runtime. No firmware changes, no
extra hardware. Apps are installed from the browser at
[badge.hackthenorth.com/ide](https://badge.hackthenorth.com/ide/).

## The game

`apps/hackemon/hackemon.lua` is the main game.

- **Ten Hackemon** with 8x8 pixel-art sprites, each with a type, HP, and attack.
- **Six types** in a ring: HW > AI > WEB > DSGN > SEC > SYS > HW. Advantage hits 1.5x.
- **Wild encounters** come from NFC stickers. A sticker holding the text `HKM07` spawns
  creature 7. `HKM07L5` spawns it at level 5.
- **Battles** are turn based: A attack, B special (1.6x, 30% miss), UP defend (halve the
  next hit), DOWN catch (only below half HP, likelier as the wild weakens).
- **Progression**: wins and catches give XP. Levels raise HP and attack. Switch your
  active creature among the ones you've caught.
- **Hackadex**: every creature you've seen or caught, with stats and sprite.
- **Saves** survive exit and reboot.

| Button | Menu | Battle |
| --- | --- | --- |
| A | Scan for a sticker | Attack |
| B | Hackadex | Special |
| UP | Switch active creature | Defend |
| DOWN | | Catch |
| HOME | Exit | Exit |

## Tools

`tools/scanner.lua` is a plain NFC tag scanner. Install it alongside the game to check
that a sticker was written correctly before hiding it.

## Installing an app

1. Open the [badge IDE](https://badge.hackthenorth.com/ide/) in Chrome or Edge.
2. Click **Import app**, paste the entire `.lua` file including the header block, then
   **Replace editor files**.
3. Remove `icon.bin` from the workspace unless you want a custom icon.
4. Turn the badge off, plug in a USB data cable, turn it on. Click **Connect**, pick
   **USB JTAG/serial debug unit**.
5. Click **Push**. The console should show the app's slug and `2 files`.
6. Open the app from the launcher.

If the console says `main.lua is not a regular file`, the code file in the workspace is
not named `main.lua`. If it says `manifest.cfg is missing a slug= line`, the header block
was pasted into `main.lua` instead of going through Import app.

## Sticker codes

Write one of these as an NDEF **Text** record onto an NTAG215 sticker with the NFC Tools
phone app. Codes are uppercase with no spaces.

| Code | Hackemon | Type | Base HP | Base ATK | Notes |
| --- | --- | --- | --- | --- | --- |
| `HKM01` | Soldrat | HW | 22 | 6 | Starter option |
| `HKM02` | Neuron | AI | 20 | 7 | Starter option |
| `HKM03` | Crawly | WEB | 18 | 8 | Starter option |
| `HKM04` | Pixie | DSGN | 17 | 8 | |
| `HKM05` | Lockjaw | SEC | 26 | 5 | Tanky |
| `HKM06` | Kernel | SYS | 24 | 6 | |
| `HKM07` | Voltra | HW | 19 | 9 | Glass cannon |
| `HKM08` | Gradient | AI | 21 | 7 | |
| `HKM09` | Cachemander | SYS | 23 | 8 | Rare, hide it well |
| `HKM10` | Rootkat | SEC | 25 | 9 | Rare, hide it well |

Append `L` and a number for a stronger wild, for example `HKM09L5` for a level 5
Cachemander. Each level adds 3 HP and 1 ATK. A caught Hackemon keeps the level it was
caught at. Full writing and placement guide: [docs/stickers.md](docs/stickers.md).

## Hardware findings

The badge has hard memory limits that shaped every design decision here. They are
written up in [docs/hardware-notes.md](docs/hardware-notes.md). The short version:
NFC is cheap, Bluetooth costs 50 KB of the 77 KB available, and a Lua app with the
radio on has about 4 KB to spare.

The official badge API reference is kept at
[docs/badge-api-reference.md](docs/badge-api-reference.md).

## Roadmap

- Badge-vs-badge battles as a separate tiny arena app that reads the same save data,
  once the two-badge radio path is confirmed working.
- Gym stickers that heal or grant a type boost.
- Sponsor booth stickers that unlock exclusive Hackemon.
