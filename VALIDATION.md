# Validation - ForeverPlates 0.3.1

Version 0.3.2 adds packaging configuration and updates the version identifier; in-game behaviour is unchanged. CurseForge packaging excludes this document and README.md.

Checked on 2026-10-06. This version retains the established nameplate layout; layout, health text ownership, fonts, masks, and health bar color logic are retained.

## Evidence

- TOC Interface 16001 comes from the user's actual fourth GetBuildInfo() return for Forever 1.60.1, rather than a calculated value.
- MCP source status remains a mismatch: source 1.60.1.70205, installed client 1.60.1.70235.
- Relevant nameplate/health implementations were previously compared with Gethe/wow-ui-source commit a84e2b1b41d3d4137127c07e4da448aa3251d6f1 (70235) and were unchanged after line-ending normalization. Settings/mask API evidence comes from the MCP's 70205 source.
- Previous API scan findings were reviewed against generated documentation and Blizzard implementation. Shared method names caused scanner ambiguity and false deprecation reports. No raw unit health or secret text is calculated.
- The user confirmed the classic appearance and improved fonts look good. This does not establish combat, taint, restricted-instance safety, or correct loading after the rename.

## Rename checks

The folder, TOC, title, Settings identifiers, slash registration, messages, and artwork paths use ForeverPlates. Both /fplates and /foreverplates share one handler. Appearance preferences are stored in ForeverPlatesDB. When updating an existing local installation, migrate the saved table identifier with the client closed and retain a backup.

The GitHub preparation contains only addon Lua, TOC, artwork, license, documentation, and Git metadata. Development tools, MCP source, and Codex configuration are excluded. Syntax parsing uses the external development workspace's vendored luaparse 0.3.1 with Lua 5.1 grammar; those tools are not included in this addon-only repository.

## Runtime checks

Restart the client after installing the renamed folder. Verify /fplates options and /foreverplates options open the same category; test every existing subcommand and reload/relog persistence. Confirm migrated style/class-color choices. Check names, health text in all modes, large values, compact/classic switching, damaged/reused plates, casts/channels, Size/UI scale, combat, and restricted instances. Lua, taint, forbidden-frame, secret-value errors, stale colors, or incorrect geometry are failure indicators. See README.md.

Static checks cannot prove these runtime behaviors.

PASS - All six Lua files parse using Lua 5.1 grammar. MCP TOC validation reports version 0.3.0, all referenced Lua files present, no errors. Independent rename review found no actionable defects in slash registration, load identity, media paths, Settings names, or settings-file compatibility.

## PvP name colors (0.3.1)

PvP-flagged player names become green independently of health bar coloring. Original public RGBA is cached before applying green, preserving alpha; it is restored on unflagging or plate removal/reuse. The existing player sweep and flag/faction events refresh it. A secure post-hook of CompactUnitFrame_UpdateName reapplies green after client name refreshes and updates the cached native color. Hidden native updates are ignored because the client does not recolor hidden names. Name text and visibility remain client-owned.

MCP verified UnitIsPVP identity restrictions, GetTextColor secret RGBA and MayReturnNothing behavior, and Blizzard's global secure-hook usage. Secret player/flag/color/visibility values and missing RGBA cause the addon to yield. Forbidden frames are excluded. Source CompactUnitFrame.lua lines 827-892 verifies native name color assignment; source/client remain 70205/70235.

Version 0.3.1 TOC validates without errors. API scan: 56 unresolved, 10 documented, 23 deprecated, 25 restricted, 20 ambiguous. New unresolved entries are local helpers and the hooksecurefunc global verified in Blizzard source; GetTextColor's method ambiguity was resolved against FontString documentation. Existing scanner false positives were investigated in earlier validation.

After reload, check flagged/unflagged friendly and enemy players, flags changing while plates remain visible, class colors on/off, target/mouseover name refreshes, name-only visibility, recycled NPC plates, and combat/restricted instances. No runtime success is claimed for this update.

PASS - All six Lua files parse. Independent review found no actionable defects for normal live nameplates. Native name overrides occur in commentator/settings-preview paths, rather than ordinary live nameplates. In-game flag-change and reuse checks remain necessary.
