# Third-party notices and source review

## Everloot community observations

**Data from Everloot (https://everloot.app), CC BY-SA 4.0.**

Copyright and database attribution: Everloot contributors. Licence: [Creative Commons Attribution-ShareAlike 4.0 International](https://creativecommons.org/licenses/by-sa/4.0/); [legal code](https://creativecommons.org/licenses/by-sa/4.0/legalcode.en).

The separately identifiable files `data/everloot-snapshot.json` and `GrindMeter/Data/CommunityCatalog.lua` are a modified/filtered compilation of public NPC/item loot-window observations from the Everloot `/api/rollups/drops` API. These files and the derived compilation are distributed under **CC BY-SA 4.0**. The surrounding independently written addon code is MIT. Retain the data attribution, licence link and modification notice when sharing or adapting the dataset.

Changes: excluded GameObject sources and unconfirmed records; retained NPC/item IDs, source-window counts, item-window counts, rates and reporter counts; renamed the API's misleading `kills` field to `windowCount`; compiled an offline Lua table; added explicit unknown quantity/condition and base-item variant policies. No player/install pseudonyms, artwork, third-party addon code or game-file database is included.

Data snapshot: **2026-11-12T07:40:17.460Z**. Included coverage: 165 NPC IDs and 1,264 item/source records. Counts describe observed windows, not all kills or a complete list of Forever NPCs. Missing NPCs are unknown.

Primary terms and method reviewed 2026-11-12:

- https://everloot.app/docs/addon-authors
- https://everloot.app/docs/api/rollups-drops
- https://everloot.app/terms#licences
- The response's attribution block and `dataAsOf` are retained in the checked-in snapshot.

## Blizzard

World of Warcraft and its item/NPC names, UI fonts, textures and in-game artwork belong to Blizzard Entertainment. GrindMeter references installed textures such as `Interface/Icons/INV_Misc_PocketWatch_01`; no image assets, font files, client binaries or exported Blizzard UI source files are redistributed.

API reference: Blizzard-generated Forever interface documentation mirrored at https://github.com/reckhou/WoWBlzCode. The reference export was build 70658; current local installed metadata was 70888. Runtime probes and in-game verification remain necessary.

## Auctionator

The original installed Auctionator 345 public API implementation and documentation were read for interoperability. The addon calls the public v1 API only. No Auctionator source code, scan data, library or logo is copied into this release.

Primary source: https://github.com/plusmouse/Auctionator and the installed `Source/API/v1/README.md`, `GetAuctionPrice.lua`, `GetAuctionAge.lua`, `Source/Database/Mixin.lua`, `Source_LegacyAH/Variables/Main.lua`. The installed TOC explicitly lists interface 16001.

## Identity reference checks

The separate reference IDs/names Wildplains Huntress 259055 and Wildplains Patriarch 259054 were checked on their NPC pages on 2026-11-12:

- https://db.icy-veins.com/wow-forever/npcs/259055
- https://db.icy-veins.com/wow-forever/npcs/259054

Only these identity facts and reference links are included. No Icy Veins drop table, probability, map, description or database export is redistributed. There is no third-party data coverage claim for these two mobs.

GrindMeter has no bundled third-party Lua libraries and no affiliation with or endorsement by any of these providers.
