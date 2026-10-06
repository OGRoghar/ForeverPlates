# ForeverPlates

## Overview

ForeverPlates gives World of Warcraft: Forever nameplates a clean, readable appearance with compact or classic oval borders, optional player class colors, and built-in Forever fonts. PvP-flagged player names appear green. Numerical health sits in the middle of the bar, with the percentage on the right.

Open `/fplates options` to choose your appearance. `/foreverplates` accepts the same commands. Style and class-color preferences persist across sessions.

| Command | Setting |
| --- | --- |
| `/fplates style classic` | Classic oval borders |
| `/fplates style compact` | Compact borders |
| `/fplates classcolors on` or `off` | Player class colors |
| `/fplates health percent` | Percentage on the right |
| `/fplates health value` | Numerical health in the middle |
| `/fplates health both` | Numerical health and percentage |
| `/fplates health off` | Hide health information |

## Installation

1. Close World of Warcraft: Forever.
2. Extract the download. If necessary, rename the folder containing `ForeverPlates.toc` to `ForeverPlates`.
3. Copy the entire folder, including `media`, to the Forever client's `Interface/AddOns/ForeverPlates` directory.
4. Start the game and enable **ForeverPlates** in the addon list.

For updates, replace the installed addon files and run `/reload`. Keep the folder name `ForeverPlates`.

## Client Behaviour

- The default appearance is compact, with player class colors disabled. Both styles place names above the health bar, the level or skull on the right, and the cast bar below.
- Player class colors affect living player health bars. NPC health bars retain their reaction colors. PvP-flagged player names are green independently of the health bar setting.
- Blizzard controls health values, number formatting, text visibility, casts, aura filtering, timers, and stack counts. Simplified nameplates retain the client's target-dependent health text visibility.
- Health commands change the client's persistent nameplate information setting. Appearance preferences are saved separately by ForeverPlates.
- Nameplate visibility, Size, and distance scaling follow the client's settings. Open the options panel out of combat.
- Restricted nameplates and unavailable unit information remain client-controlled. UI scaling can affect text sharpness.

For diagnostic information, use `/fplates status`.
