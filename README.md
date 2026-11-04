# Gather Together

Gather Together is a fishing and gathering guide for **WoW Forever** (interface 1.60.1).

## Features

- One dark, gold accented journal with a selector for fishing, mining, herbalism, skinning, and cloth. Fishing retains its 57 Classic locations.
- A cloth tab lists zones where linen, wool, silk, mageweave, runecloth, and felcloth may drop, with broad areas on the map and clickable cloth filters. It shows the cloth needed for each basic bolt without a gathering skill requirement. Mooncloth is identified as a crafted material. The pinned small window continues to show fishing when this tab is selected.
- Mining and herbalism list the resources reported in each zone, their required skill, in-game item icons, and broad highlighted areas on the map.
- Click a fish or resource below the map to show only its associated halos. Click it again to show all halos. The selected row is highlighted, and changing zones or professions clears the filter.
- Skinning lists beast-level bands, required skill ranges, common leather, and suggested zones. Its map previews have no precise halos because the source does not provide reliable beast positions.
- A resource and zone search below the Current Zone button that filters the location list for the selected profession.
- A fully revealed map preview for every listed location, regardless of character exploration. Dungeons and subzones use their parent region's map, clearly labeled as a regional preview.
- Large cyan regions on map previews for reported WoW Forever catches and documented Classic fishing schools. Hover over a region to see its associated fish. Gather Together also remembers where this character catches fish and adds those areas to the map.
- Fish lists with in-game item icons and tooltips, the minimum fishing skill, the skill at which catches no longer get away, and known conditions for specific fish. The main title bar shows your base fishing skill and active bonus.
- A small, scrollable window that opens while fishing or during a recognized gathering cast. It follows the selected profession when pinned. Its title shows base skill and the combined active bonus reported by the game.
- A movable minimap button using the supplied Gather Together icon. Click it to open or close the journal.
- A local catch history that learns items caught while fishing, including Forever-specific catches.
- User interface text for enUS, enGB, frFR, deDE, esES, esMX, itIT, ptBR, ruRU, koKR, zhCN, and zhTW. Zone and item names come from the game client when available.

## Commands

| Command | Action |
| --- | --- |
| `/gt` or `/gathertogether` | Open or close the journal. |
| `/gt mini` | Pin or unpin the small profession window. |
| `/gt sound` or `/gt son` | Toggle sound effect boosting during a cast. |
| `/gt help` or `/gt aide` | Show the command list. |

## Fishing sound

WoW does not expose the exact instant when a fish bites to addons. Gather Together boosts sound effects while a fishing cast is active so the bobber splash is easier to hear, then restores the prior settings. It cannot produce an exact bite-triggered alert.

## Data and limitations

The zone skill thresholds follow the [ForeverChanges fishing guide](https://foreverchanges.pro/fr/professions/fishing). Classic fish lists are condensed factual data from [Extreme Anglin' Atlas](https://github.com/Radical-Egg/extreme-anglin-atlas). Forever may change catches, and pools, seasons, time of day, and the exact body of water can change the fish available. Fish shown for a nearby parent zone are marked as estimates. New Forever zones have no confirmed skill threshold in this release.

Special condition notes currently cover Nightfin Snapper, Sunscale Salmon, Summer Bass, Winter Squid, Deviate Fish, and Zulian Mudskunk. These notes describe Classic behavior and have not been independently confirmed on Forever. The title's bonus is the total modifier reported by the client; the API does not separate its equipment and lure contributions.

Bundled fishing regions are broad estimates generated from [GatherLite's WoW Forever reported catches](https://github.com/Wuild/GatherLite/blob/master/plugins/fishing/data.lua) and [GatherMate2 Data Classic](https://github.com/Thurdi/GatherMate2_Data_Classic/blob/master/GatherMate2_Data/FishData.lua) school coordinates. Reported catch data covers 41 zone maps; it does not guarantee a current spawn or a fishing pool. Maps without usable coordinates gain regions as this character catches known fish there. Open-water fishing is possible beyond the shown regions.

The fish list covers known catches for a zone, but only fish with mapped catch or school coordinates have halos. Selecting a fish without mapped coordinates shows no halos and a message on the map. Nearby reported areas no longer suppress a Classic school area for a different fish.

Mining and herbalism areas are broad groups of reported nodes from [GatherLite's WoW Forever database](https://github.com/Wuild/GatherLite/blob/master/plugins/database/data/forever.lua), under its [MIT license](GATHERLITE_LICENSE.md). The required skill values come from GatherLite's [node definitions](https://github.com/Wuild/GatherLite/blob/master/scripts/nodes.lua). The bundled catalog contains 10 ore veins and 28 herbs. A highlighted area is a possible location, not a guarantee that a node is active now.

Skinning bands and suggested zones follow the [ForeverChanges skinning guide](https://foreverchanges.pro/professions/skinning). A beast's exact requirement depends on its level; the listed skill range covers the band. No individual beast spawn coordinates are bundled.

The cloth tab follows the [ForeverChanges Tailoring route](https://foreverchanges.pro/fr/professions/tailoring). The five base cloths are used throughout the route and drop mainly from humanoids. Felcloth drops from demons and satyrs and makes mooncloth, which appears in advanced recipes. Bundled map areas are approximate, generated from the installed QuestieDB Forever Classic drop table and NPC spawn metadata; they do not confirm a current Forever drop. All data needed at runtime is bundled in GatherTogether, with no Questie or QuestieDB dependency.

The original artwork is stored as `Media/GatherTogetherSource.png` in the development folder. Its game-compatible 256 px TGA version is used for the addon list, journal header, and minimap button. Full map previews use overlay data generated from the WoW Forever 1.60.1 client by [Map Tab](https://github.com/jonlipin/map-tab), under its [MIT license](MAP_OVERLAYS_LICENSE.md). Client updates can change the map art IDs or textures.

## Development check

From the AddOns directory, run `GatherTogether/tests/smoke.lua` and `GatherTogether/tests/resource_filter.lua` with a Lua interpreter such as Fengari. The checks cover loading, journal filtering, map areas, resource halo filtering, the fishing window, a fishing cast, learned areas, and restoring sound settings. An in-game visual check is still needed after UI changes.
