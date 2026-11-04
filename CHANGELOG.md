# Changelog

## 0.6.1 — 2026-10-22

- Added bundled cloth loot zones and approximate map areas for linen, wool, silk, mageweave, runecloth, and felcloth.
- Made the cloth tab use the journal's zone list, search, and clickable map filters without requiring Questie at runtime.
- Marked mooncloth as crafted from felcloth rather than a looted material.

## 0.6.0 — 2026-10-22

- Added a cloth tab with the five base Tailoring cloths plus felcloth and mooncloth, their item icons, and bolt conversion quantities.
- Kept cloth separate from gathering skill thresholds and map halos.

## 0.5.1 — 2026-10-14

- Made fish and resource rows below the map clickable. Selecting a row shows only its associated map halos; clicking it again restores all halos. The selected row is highlighted, and the filter resets when changing zones or professions.
- Kept a Classic fishing school halo when it identifies a different fish near a reported catch area.
- Clarified that some listed fish have no mapped coordinates, while skinning has no precise beast locations.
- Updated the smoke check and added a focused test for the halo filter.

## 0.5.0 — 2026-10-14

- Renamed the addon to Gather Together and moved it to the `GatherTogether` folder.
- Replaced the addon list, journal header, and minimap brand icons with the supplied gathering emblem.
- Migrated saved settings and catch history from FishNTips.

## 0.4.0 — 2026-10-14

- Added a profession selector for Fishing, Mining, Herbalism, and Skinning in the same journal.
- Added ore and herb lists with item icons, required skill, search, and broad map areas generated from reported WoW Forever nodes.
- Added six skinning beast-level bands, their required skill ranges, common leather, and suggested zones. Skinning maps omit precise halos because the available source does not establish beast spawn coordinates.
- Show the selected profession and its current skill in the journal title and pinned mini window. The mini window opens automatically during recognized mining, herbalism, and skinning casts.
- Preserved the fishing sound aid and catch history when switching professions.

## 0.3.3 — 2026-10-13

- Hide the special conditions scrollbar when all text fits and use the available panel width.
- Show the scrollbar only when the text exceeds the visible area.

## 0.3.2 — 2026-10-13

- Moved fishing skill and the active bonus to the main journal title bar.
- Removed the repeated personal skill and lure advice from each zone's Fishing panel.
- Used the freed panel space for a scrollable summary of fish conditions in the selected zone.

## 0.3.1 — 2026-10-13

- Added broad fishing areas derived from reported WoW Forever catches, expanding bundled map coverage from 15 to 41 zone maps.
- Kept Classic school areas where they add distinct locations and labeled reported catches separately in tooltips.
- Added a regression check for Dun Morogh, which previously had no fishing halo.

## 0.3.0 — 2026-10-13

- Moved fishing skill and its active bonus into the small window title and removed the repeated skill and lure sections from its body.
- Made the small fishing window scrollable so long fish lists remain accessible.
- Added localized conditions for six fish in the journal and small window, covering time of day, season, or a specific body of water.
- Added fish and zone search below the Current Zone button.
- Added broad, hoverable fishing pool areas to map previews. Their tooltips list the fish associated with each area.
- Added per-character fishing area learning from successful catches for maps without bundled pool data.
- Resized the supplied round minimap artwork inside the standard tracking border to match nearby buttons.

## 0.2.1 — 2026-10-13

- Revealed all known areas in the journal's map previews, independently of character exploration.
- Added WoW Forever 1.60.1 map overlay data with its MIT license notice.
- Replaced only the minimap button artwork with the supplied round icon; the addon list and journal retain the original square artwork.

## 0.2.0 — 2026-10-13

- Rebuilt the main interface with a scrollable zone list, map previews, skill and lure details, and fish rows with in-game icons and tooltips.
- Added the original supplied artwork to the addon list and a draggable minimap button that opens or closes the journal.
- Added UI translations for all twelve WoW game locales and localized zone and item names from the client where available.
- Added regional map fallbacks for dungeons and subzones and an English README.
- Kept the small fishing window, catch history, and cast-time splash volume boost.
- Fixed client compatibility issues involving missing button font strings, the absence of global `GetItemInfo`, and an unsupported spellcast event.

## 0.1.0 — 2026-10-13

- Added the initial fishing guide, small fishing window, catch history, and sound effect boost.
