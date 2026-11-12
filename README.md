# GrindMeter

Ett fristående addon för **WoW Forever** som mäter kills/h, faktiskt erhållen mob-XP/h och värdet av loot du plockar upp. Svenska är förvalt språk; engelska väljs under Inställningar.

**0.1.2 rättar prisuppdateringen och förklarar varje lootrads värde.** AH-priser uppdateras när Auctionator skannar eller saknad itemdata laddas. Tooltipen visar styckpris, antal, avgift och valt totalvärde. Korrigeringen från 0.1.1 för Blizzards blockeringsruta ingår också. Automatiska tester är genomförda; ändringarna behöver fortfarande bekräftas inne i WoW. Installerad klient: Forever **1.60.1.70888**, TOC **16001**. Se [klienttestlistan](docs/IN_GAME_TESTING.md).

## Installera

1. Ladda ned **GrindMeter-0.1.2.zip** från Releases. GitHubs automatiska “Source code”-zip är källkoden, inte installationspaketet.
2. Packa upp. Flytta hela mappen **GrindMeter** till spelets `Interface/AddOns`.
3. Starta om WoW om mappen är ny. Kontrollera att GrindMeter är aktiverat i addonlistan. Efter uppdatering av ett redan upptäckt addon räcker normalt `/reload`.

Mac, med den här datorns installation:

```text
/Applications/World of Warcraft/_forever_/Interface/AddOns/GrindMeter/GrindMeter.toc
```

Windows, byt början till din egen WoW-mapp:

```text
C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\GrindMeter\GrindMeter.toc
```

Vid uppdatering: ersätt den gamla addonmappen, behåll spelets SavedVariables och kör `/reload`. Om du valde att avaktivera GrindMeter i Blizzards ruta behöver du aktivera det igen i addonlistan.

TOC-filen ska ligga direkt i `GrindMeter`. En extra yttre `GrindMeter-0.1.2`-mapp gör att spelet inte hittar addonet.

## Din första mätning

1. Markera en fientlig NPC, levande eller död.
2. Klicka på **fickursikonen vid minimappen**, eller skriv `/grindmeter` eller `/gm`.
3. Klicka **Välj nuvarande target**. Kontrollera mobnamn och NPC-ID.
4. Välj mättid. **10 minuter** är förvalt; 5, 15, 30 minuter och manuell stopptid finns också.
5. Klicka **Starta mätning** och spela som vanligt.

Mobtypen låses när passet börjar. En annan target ändrar inte huvudmobben. Springande, vila, väntan på respawn, looting och död ingår i mättiden. **Pausa** stoppar både tiden och insamlingen; **Fortsätt** återupptar dem tillsammans.

Den lilla flyttbara panelen visar tid, kills/h, XP/h och lootvärde/h. Stäng panelen eller stora fönstret utan att avsluta passet. **Avsluta och spara** avslutar mätningen. Vid timeout sparas resultatet med en diskret chattrad; inget stort fönster öppnas över strid.

### Minimap och kommandon

| Kontroll | Beteende |
|---|---|
| Vänsterklick på minimappikonen | Öppna/stäng huvudfönstret |
| Högerklick på minimappikonen | Visa/dölj den lilla panelen |
| Dra ikonen | Flytta den runt minimappen |
| Dra fönstrets/panelens rubrik | Flytta gränssnittet |
| `/gm` | Öppna/stäng huvudfönstret |
| `/gm hud` | Visa/dölj den lilla panelen |
| `/gm reset` | Återställ positioner och visa minimappikonen |
| `/gm diagnostics` | Kopierbar klient- och eventdiagnostik |
| `/gm help` | Kort hjälprad |

## Förstå resultatet

De tre stora rutorna gäller **vald mob**. **Hela passet** har en egen rad och kan dessutom omfatta andra säkert krediterade mobbar. Alla timvärden använder samma mättid. Mindre än fem minuter eller färre än tio kills märks som preliminärt.

| Siffra | Innebörd |
|---|---|
| Kills/h | Säkert krediterade kills × 3600 / mätta sekunder |
| XP/h | Faktiskt erhållen, säkert attribuerad mob-XP × 3600 / mätta sekunder, inklusive verkliga rested-/gruppbonusar |
| Plockade mynt | Bekräftade mynt från mobloot; aldrig förändringen av kontantsaldot |
| Vendor | Mynt + vendorvärdet av mottagna items |
| Bästa kända försäljning | Mynt + det högsta kända tillåtna styckvärdet av vendor eller AH efter vald försäljningsavgift |
| Känt delvärde | Uppgifter eller säkra källkopplingar saknas; siffran är ofullständig |

Klicka på **G/h-rutan** eller byt under Inställningar för att växla värdering. Vendor- och AH-värden är alternativa modeller. AH-värde betyder inte att guldet redan har tjänats in. Värderingen är före förbrukning och reparation och antar lyckad försäljning utan förlorad deposition. Förvald AH-avgift **5 % är ett konfigurerbart modellantagande**, ännu inte validerat i denna klient.

**Din loot** visar faktiskt mottagna items och deras källor. Hovra för spelets itemtooltip. Klicka för itemdetaljer. Använd spelets konfigurerade modifierade itemklick eller knappen **Länka** för att lägga en länk i chattrutan. Addonet skickar inga chattmeddelanden åt dig och kräver ingen särskild Windows-tangent.

**Möjlig loot** visar en separat katalog. Den medföljande communitykatalogen täcker **165 NPC-ID:n och 1 264 item/NPC-poster**, daterad **2026-11-12**. Den är ofullständig. Dess procentsiffror gäller observerade lootfönster, inte alla dödade mobbar; mängder och villkor saknas och äldre oklassade observationer kan ingå. Dessa uppgifter används därför inte som killbaserad guldprognos. Egna säkert mottagna fynd från fullt observerade solokroppar byggs också upp separat. Inga hypotetiska katalogdrops ökar uppmätt lootvärde.

**Wildplains Huntress 259055** och **Wildplains Patriarch 259054** är separat identitetskontrollerade referensposter. Den öppna katalogkällan har inget bekräftat lootunderlag för dem i denna snapshot. Där visas saknad katalog/egna fynd. Inga Classic-droptabeller används som ersättning.

## AH-priser

**Auctionator är valfritt.** Version 345:s installerade publika API är granskat, och adaptern är automatiskt testad med syntetiska API-svar. Besök AH och gör en skanning i Auctionator; GrindMeter läser dess senast skannade lägsta buyout per styck. En tom prisdatabas ger **AH-data saknas** och användbara vendorresultat.

Priserna hämtas från Auctionators aktiva marknad. I Forever kan denna vara gemensam för ett regionalt ruleset, exempelvis PvE; GrindMeter väljer inte någon annan databas. Auktionens senast skannade styckpris används direkt, även om Auctionators egen tooltip visar stackpriset när Shift hålls nere.

Under ett aktivt eller pausat pass uppdateras priser när Auctionator rapporterar en färdig databasuppdatering eller itemdata blir tillgänglig. Saknade priser kan därmed fyllas i även med huvudfönstret stängt. Ett tillfälligt misslyckat uppslag behåller ett tidigare känt pris med dess ursprungliga datum.

Hovra över en rad i **Din loot** för att se AH-pris före avgift × antal, beräknad AH-avgift, nettovärde, vendorvärde och det valda värdet för hela raden. Exempel: **4 × 8 s 70 k = 34 s 80 k**, eller **33 s 6 k** efter 5 % avgift. G/h räknas sedan från passets totala värde och mättid. Loot utan säker mobkälla visas men ingår inte i mobbsummorna.

Auctionators prisålder har dygnsupplösning. Samma scan-dygn innebär 0–24 timmar, föregående scan-dygn 0–48 timmar. Tooltipen skiljer möjlig från säker överskridning av den valda åldersgränsen, förvalt 24 timmar. Ett skannat pris beskrivs aldrig som ett livepris. Slumpmässiga suffix får inget generiskt AH-pris. BoP-, quest- och kontobundna items föreslås inte säljas på AH; obundna, BoE- och bind-on-use-items kan värderas.

Ett alternativ är en versionsmärkt lokal JSON-prisexport som kompileras med:

```sh
python3 scripts/import_prices.py market.json GrindMeter/Data/ImportedPrices.lua
```

Kör utanför spelet och använd `/reload` efteråt. Se [datakontraktet](docs/DATA.md). Ingen prisexport, API-nyckel eller påhittad prislista följer med. En befintlig historisk mätning behåller prisbilden från avslut; **Nya priser** skapar en märkt alternativ vy utan att skriva över originalet.

## Historik och återställning

De senaste 50 passen sparas per karaktär. Filtrera på mobnamn eller NPC-ID, välj en rad och klicka **Visa resultat**. Raderna visar bland annat level, rested vid start, gruppstatus och AH-prisdatum så att skillnader i förutsättningar syns. Valda pass raderas med två klick. Inställningar ligger separat.

Vid vanlig logout eller `/reload` återkommer ett aktivt pass **pausat**. Offline-tiden räknas inte. Fortsätt eller avsluta det återställda passet. Vid en abrupt klientkrasch kan osparade SavedVariables gå förlorade.

## Utveckling och release

Lua 5.1 eller LuaJIT och Python 3 behövs bara för utveckling, inte för spelaren.

```sh
luajit tests/run.lua
python3 -m unittest discover -s tests -p 'test_*.py'
python3 scripts/build_catalog.py
python3 scripts/build_release.py
```

GitHub Actions testar varje push till **master**, bygger installationszip och kontrollsumma och publicerar en ny version som prerelease. Samma versionsnummer publiceras endast en gång; höj både TOC- och namespaceversion för en ny release. Ingen separat repohemlighet behövs.

Se [API-val och attribuering](docs/API.md), [testresultat](docs/TEST_RESULTS.md), [datakällor och licenser](docs/THIRD_PARTY.md) och [ändringshistorik](CHANGELOG.md).

Data from Everloot (https://everloot.app), CC BY-SA 4.0. Koden är MIT; den separat levererade communitydatan och dess bearbetning är CC BY-SA 4.0. Blizzardbilder refereras från spelklienten och distribueras inte.
