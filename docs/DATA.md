# Data, priser och kataloguppdatering

## Medföljande data

`Data/CommunityCatalog.lua` är en deterministiskt genererad bearbetning av `data/everloot-snapshot.json`.

- Spelvariant: Forever. NPC-källor; GameObject-poster är borttagna.
- Ursprunglig snapshot: **2026-11-12T07:40:17.460Z**.
- Källa: `https://everloot.app/api/rollups/drops?limit=500` och de två returnerade `next`-sidorna, alla med identisk `dataAsOf`.
- Täckning: **165 NPC-ID:n**, **1 264 item/NPC-poster**. Totala antalet möjliga Forever-mobbar är okänt; någon procentuell total täckning påstås inte.
- Endast publika poster med minst tre rapporterande installationer, positivt antal lootfönster och giltig fönsterandel följer med.
- `kills` i källans API är **lootfönster**, inte dödade mobbar. Katalogen använder fältnamnet `windowCount` för att undvika förväxling.
- Mängd vid drop, questvillkor och full variantpolicy saknas. Äldre otypade lootfönster kan ingå. Poster är därför `category = "observed"`, `condition = "unknown"`, och används inte som normala killprognoser.
- Skinning/gathering byggs inte om till vanliga killdrops. Namn/ikon/native itemlänk hämtas från klienten efter item-ID.
- Katalogen är partiell även när en mob har flera poster. En saknad mob är okänd, inte noll loot.

Wildplains Huntress **259055** och Wildplains Patriarch **259054** har identitetsreferenser i `Data/Catalog.lua`. Deras respektive NPC-sidor hos Icy Veins kontrollerades 2026-11-12. Varken deras droptabeller eller några Icy Veins-procentsiffror distribueras. Inga bekräftade poster för dem fanns i den öppna Everloot-snapshoten.

Egna säkra solofynd lagras separat per karaktär/NPC-ID. En lokal sannolikhet visas som kroppar med item / kvalificerade observerade kroppar. Mängd per kropp är en annan siffra. Kvalifikation kräver en ensam källa med in-session-credit, hela lootfönstret infångat och alla slots cleared. Öppna fönster, gruppfördelning, selektiva uttag och oöppnade kroppar görs inte till säkra drop-nämnare. Chattbekräftelser skapar mottagna mängder; slot-clear är endast observationsunderlag.

## Uppdatera katalog

Underhållaren hämtar en ny licensierad snapshot utanför spelet, granskar scope/licens/fältskillnader och ersätter `data/everloot-snapshot.json`. Följ den returnerade `next`-länken, kräv samma `dataAsOf` på alla sidor och respektera källans gränser. Kör sedan:

```sh
python3 scripts/build_catalog.py
luajit tests/run.lua
```

Byggaren kontrollerar rapportörer, scope, licens och att `drops / kills` stämmer med källans rate. Den skapar ingen dold mängdmodell. Behåll källans datum, metod, credit och CC BY-SA 4.0 på både JSON-underlaget och den bearbetade datan. Publicera genom en ny addonversion; ingen bakgrundsnedladdning sker inne i WoW. Ingen uppdateringsautomation har skapats för användaren.

En ny, separat verifierad katalogprovider kan lägga poster i `G.Catalog.entries[npcID]`. För en prognos behövs `category = "normal"`, säker `probability` och `meanQuantity` eller direkt `expectedUnits`, känd variantpolicy och uppfyllda villkor. En okänd mängd sätts aldrig automatiskt till ett. Rena kalkylatorn har stöd för delprognoser; communitykatalogens fönsterdata räcker inte.

## AH-provider: Auctionator

Den installerade **Auctionator 345** har ett uttryckligt publikt API i `Source/API/v1`. Följande gränssnitt är lästa i originalkoden:

```lua
Auctionator.API.v1.GetAuctionPriceByItemLink("GrindMeter", itemLink)
Auctionator.API.v1.GetAuctionAgeByItemLink("GrindMeter", itemLink)
```

Pris är per styck i koppar, senaste skannade minimum buyout. Ålder är hela scan-dygn, inte ett precist scan-klockslag. GrindMeter sparar `observedAtPrecision = "day"` och visar åldersintervallet. Varning utgår konservativt från intervallets övre gräns. `sourceName`, addonversion, importtid, ålder och faktisk scope följer med varje quote.

LegacyAH:s databas väljs av Auctionator per aktuell realm/faction, i den separata spelinstallationens SavedVariables. GrindMeter anropar endast det publika API:t och jämför mot körande region/realm/faction/spelvariant; det öppnar inte en annan marknads databas. Random-suffix-priser avvisas för denna provider eftersom exakt suffixvärde inte kan garanteras.

Ingen kopia av Auctionators kod eller prisdatabas levereras. SnapPrice är inte installerat och inget SnapPrice-API har gissats fram. In-game-anrop och prisernas verkliga datatäckning återstår att prova.

## Alternativt importformat

`scripts/import_prices.py` läser en redan producerad JSON-export. Kontraktet är:

```text
schemaVersion: 1
priceType: minimumBuyout
sourceName: verklig källa
sourceVersion: exportens/dataproviderns version
scope: gameFlavor=forever, region, realm, faction
items:
  item-ID som sträng eller full item:payload för exakt variant:
    unitPriceCopper: pris per styck
    observedAt: verklig observationstid, Unix-sekunder
```

Exporten får inte innehålla hela stackens pris som styckpris. Importören avvisar fel spelvariant, otydlig scope, saknad observationstid, framtida observationstid och ogiltiga priser. Endast kontraktets fält skrivs; godtyckliga extra fält och eventuella hemligheter exporteras inte. Den genererade filen läggs i det installerade addonets `Data/ImportedPrices.lua` och läses efter `/reload`.

En validerad import används först; annars provas Auctionator. Fel scope avvisas, inte konverteras. Saknat AH-pris ger vendor som bästa **kända** alternativ. Saknas även vendorpris blir totalsumman ett känt delvärde. Ingen publik marknadsfeed, nyckel eller aktuell prislista följer med denna release.

## Historik

Receipts och XP-antal är separata från värderingar. Avslut låser `priceSnapshot` och avgift; statisk itemmetadata får laddas senare. `Nya priser` gör en tillfällig alternativ värdering och märker den i UI utan att ändra sparat original. En ändrad avgift gäller nya pass. Priser och source-meta blandas inte mellan pristyper. Ingen avgiftsavrundning påstås motsvara en verifierad AH-avräkning: modellen behåller fraktionell koppar till slutpresentationen.
