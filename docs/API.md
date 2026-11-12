# API och attribueringsregler

## Underlag

Installerad metadata läst 2026-11-12: WoW Forever **1.60.1.70888**, installerade kompatibla addons anger **16001**. `GetBuildInfo()` läses vid körning och visas i diagnostiken; ingen spelkörning av GrindMeter har utförts under bygget.

Blizzards exporterade Forever-dokumentation har kontrollerats i [reckhou/WoWBlzCode](https://github.com/reckhou/WoWBlzCode). Exportens README anger den äldre builden 70658. Den används som API-referens, inte som bevis på åtkomst i aktuell build. Inga källfiler från exporten distribueras.

## Insamlingsvägar

| Område | Val och konservativ gräns |
|---|---|
| NPC-identitet | Creature-/Vehicle-GUID, sjätte bindestrecksseparerade fältet. Namn är presentation. Target låses vid start. |
| Kills | Forevers **separata** `PARTY_KILL(attackerGUID, targetGUID)` med läsbart attacker-GUID i aktuell player-/pet-/party-/raid-roster. Ingen combatlog registreras eller läses. `UNIT_DIED` och skada räcker aldrig. Guardians utan läsbart rosterbevis gissas inte in. |
| Gruppcredit | PARTY_KILL är creditbeviset; ett roster-GUID i en godtycklig skaderad är inte tillräckligt. Räknar spelarens XP/loot, inte gruppens sammanlagda belöningar. Gruppändringar märks. |
| Restriktioner | Combatlogregistrering är borttagen: `pcall` förhindrar inte `ADDON_ACTION_FORBIDDEN`, och combatloggens restricted-status är inte ett registreringstillstånd. Tillåtna separata events registreras med kontroll av både Lua-fel och false-retur. `issecretvalue` kontrolleras innan GUID:n läses, jämförs eller används som nycklar. Inga försök att låsa upp hemliga värden. |
| Mobnamn | Begränsad cache med publika GUID/namn-par från target, mouseover och namnplattor. Vid credit kan samma NPC-typs tidigare kända namn användas. Namnuppslag skapar aldrig killcredit. Saknas säker namnkandidat för XP förblir den oattribuerad. |
| XP | `CHAT_MSG_COMBAT_XP_GAIN`, parser kompilerad från klientens egna `COMBATLOG_XPGAIN_*`-format. Ett namngivet mobmeddelandes totala erhållna XP används en gång. Chatteventets generella GUID används aldrig som mob-GUID. |
| XP-koppling | Namn kan endast kopplas till en entydig NPC-typ bland säkra, ännu inte XP-matchade killkandidater inom ±1,25 sekunder. XP buffras 1,25 sekunder för omvänd eventordning. Samma namn på olika NPC-ID:n förblir osäkert. När individen är oklar men NPC-typen entydig summeras endast på typnivå. |
| Annan XP | Namnlös XP, exempelvis quest-XP, går inte till mobräknarna. `PLAYER_XP_UPDATE`/`PLAYER_LEVEL_UP` ger separat kontrollsumma, inte mobbevis. Kontrollsumman hanterar ett levelsteg mellan avläsningar. |
| Lootkontext | `LOOT_READY`/`LOOT_OPENED`, legacy-funktioner runtimekontrolleras: `GetNumLootItems`, `GetLootSlotLink`, `GetLootSlotInfo`, `GetLootSlotType`, `GetLootSourceInfo`. Källtuple består av GUID/antal-par. Funktionerna är inte alla med i det genererade funktionsindexet. |
| Mottagna items | En enda auktoritativ receiptkanal: `CHAT_MSG_LOOT`, matchning mot klientens SELF-format. Ett slotinnehåll eller `LOOT_SLOT_CLEARED` skapar aldrig en receipt. Positivt lineID dedupliceras. Saknas lineID används inte text/tid för att tyst kasta legitima lika stackreceipts. |
| Källkoppling för loot | Exakt full itempayload matchas mot ett entydigt öppet eller högst en sekund gammalt avslutat lootfönster. Alla angivna creature-GUID:n måste ha säker credit i samma aktiva insamlingsperiod och samma NPC-ID. Annars är källan okänd. Slotantal används som begränsning. |
| Professionsloot | Kända gather-/skinning-/pickpocket-/disenchant-/lockpicking-spells markerar fönster. Itemöppnade fönster och återöppnade färdiglootade kroppar ger inte säker vanlig mobloot. Äldre kroppar utan säkert registrerat kill får inte tillskrivas huvudmobben. |
| Mynt | `CHAT_MSG_MONEY` med klientens själv-/splitformat, tolkning av lokaliserade valörer. Säker mobkälla kräver solo och entydig coin-slot. Gruppsplit har osäker källa. `PLAYER_MONEY` används inte. |
| Itemdata | `C_Item.GetItemInfo` med legacy-fallback, laddningsbegäran och itemdata-events. Vendorpris/ikon kan fyllas när de blir tillgängliga. Inga fejkade länkar eller ikoner. |
| AH | Auctionator v1 `GetAuctionPriceByItemLink("GrindMeter", link)` och `GetAuctionAgeByItemLink`. Den installerade version 345:s publika API och LegacyAH-databasval per realm/faction är lästa. Ingen privat databasfunktion används av adaptern. |

## Tid, gränser och minne

Monoton `GetTime()` används för mättid, `time()` för datum. Eventhandlaren flyttar först klockan till eventets mottagningstid. Vid timeout stängs insamlingen innan ett event på stopptiden behandlas: intervallet är `[start, stopp)`. En tidigare påbörjad strid räknas om säker credit kommer under passet. Upphämtning efter stopp räknas inte.

Paus stänger både klocka och rewardinsamling och rensar tillfälliga källkontexter. En kropp från före pausen kan därför få osäker källa efter återupptagning. Offline-tid inkluderas inte efter normal logout/reload. Fördröjd itemmetadata ändrar inga mottagna mängder eller historiska AH-citat.

Körande sessionsdata håller högst 4 096 kill-GUID:n, 100 färska XP-kandidater, 1 024 chattdedupliceringsnycklar och sex lootkontexter. En session avslutas vid 8 192 itemreceipts. Gamla borttagna killkällor kan ge okänd lootkälla. Rå combatlog sparas inte. UI/timer uppdateras högst fyra gånger per sekund, med händelsestyrda itemuppslag och ingen bag-/AH-skanning per frame.

## Språk och faktisk verifiering

Addon-UI har svenska och engelska. Mätparsern utgår från spelklientens lokaliserade format, med syntetiska tester för engelska och positionsnumrerad tyska. Detta är inte ett påstående om full speltestning på alla klientspråk. Oförstådd XP markeras okänd.

Inne-i-WoW-verifiering återstår för samtliga klientberoende rader ovan. Vid otillgänglig data visas okänt/delvärde. Se [IN_GAME_TESTING.md](IN_GAME_TESTING.md).
