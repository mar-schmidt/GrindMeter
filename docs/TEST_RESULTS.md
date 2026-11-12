# Testresultat — GrindMeter 0.2.1

Datum: **2026-11-12**. Testtyp: syntetiska eventsekvenser och mockad WoW-UI, inte spelklient.

## Genomfört

**79 Lua-tester och 3 Python-tester passerar.** Lua kördes med LuaJIT i Lua 5.1-läge. GitHub Actions kör samma Lua-testsvit med Lua 5.1 och kontrollerar syntax för alla distribuerade Lua-filer.

| Område | Automatiskt verifierat |
|---|---|
| Identitet/start | Låst NPC-ID, targetbyte, andra start nekas utan att aktivt pass skrivs över |
| Blandade kills | 6 Huntress + 9 Patriarch / 600 s = 36/h, 54/h och 90/h; 40 s/kill totalt |
| Credit | Främmande kill, damage + UNIT_DIED exkluderas; egen pet och duplicerade credit/death-events ger ett kill; grupp kräver PARTY_KILL |
| XP | Separata NPC-räknare, 7 200/11 880/19 080 XP/h i kravexemplet, quest utesluts, rested total en gång, level up, omvänd eventordning och tvetydiga namn |
| Tid | Explicit paus tar bort tid och rewards tillsammans, inaktivitet fortsätter, timeout exkluderar event exakt vid stopp |
| Loot | Endast bekräftade receipts, fulla väskor ger inget värde, dubbla lineID ignoreras, en tom LOOT_READY-snapshot kan kompletteras vid OPENED, klientdispatch använder full itemlänk och rätt lineID-position |
| Källor | Blandade source-GUID:n, tidigare kropp, professionsloot och öppnade items blir inte säker vanlig mobloot; gruppmynt är konservativt oattribuerade |
| Värdering | Vendor 23 s och 1 G 38 s/h; AH efter 5 % 31 s 50 k och 1 G 89 s/h; vendor vinner över sämre AH; saknad metadata blir delvärde |
| Priser | Fel scope avvisas, scan-dygn ger korrekt färsk/osäker/gammal-status, Auctionator-adapter använder publika anrop/notifiering, bind-on-use tillåts, kontobundna items och suffix får ingen generisk AH-värdering |
| Prisuppdatering | Saknat pris återhämtas med stängt fönster, sen itemdata fyller AH/behörighet, paus ändrar ingen tid/mängd, API-avbrott tappar inte känt citat ens vid avslut, avslutad historik ändras inte |
| Prisförklaring | Sparade styckprisexempel för Long Soft Tail, Bristly Whisker, Iron Ore och Heavy Stone; avgift, antal, vendorval och tooltipens radtotal/okänd källa |
| Historik | Prisbild är fryst, alternativ värdering ändrar inte originalet, 50 pass behålls, radering bevarar settings och korrupt sparad data hindrar inte ny start |
| Dropdata | 2/8 kroppar och 6 enheter = 25 % och 0,75 enheter/kropp; olootade kills används inte som nämnare; egna fullt observerade kroppar hålls per NPC |
| Katalog | 165 NPC-ID:n/1 264 rader; fönsterdata är separat från killprognoser; sällsynt syntetisk prognos bevarar fraktionell koppar och höjer inte uppmätt värde |
| Språk | Klientens engelska format och positionsnumrerad tyska; inga hårdkodade engelska “You”-antaganden i parsern |
| Restriktioner | Begränsad combatkälla ger okänt, inte fabricerade kills; saknad lootkälla ger ofullständigt värde; extern combatlog och RestedXP ändras inte |
| UI | Ladda addon, välj target, starta, stäng utan stopp, pausa/fortsätt via HUD, avsluta, historik, språkväljare, minimappväxling och kopierbar rapport |
| Löpande | Targetfri start, duration 0 utan att ändra fokuserad mättid, alla mobbar med samma tidsnämnare, korrekt sjunkande snitt vid inaktivitet, quest/okänd loot exkluderas |
| Löpande panel | Tick med stängt huvudfönster, dölj/visa utan stopp, paus exkluderar tid/rewards, nollställ sparar och bevarar pausläge, rätt svenska/engelska etiketter |
| Långa pass | 8 193 återkommande mottagningar summeras utan stopp, osäker källa hålls separat, gruppering fungerar efter paus, gamla kroppar lärs exakt en gång vid cachegränsen |
| Prisimportverktyg | Scope, framtidsdatum, stack-/styckpris, Lua-escaping, icke-finita tal och exkludering av extra fält/hemligheter |

De 32 acceptans-ID:na har syntetiska testfall, med AT-21/22 i ett gemensamt fall och kompletterande gränsfall. Detta innebär inte att alla klientberoende delar av acceptanskraven är godkända i spelet.

## Hover- och itemdataregression i 0.2.1

Rapporterad hängning vid itemhover undersöktes genom källgranskning och syntetiska itemladdningar. I den gamla versionen gav 100 behandlade lyckade laddningssignaler med fortsatt saknad metadata 101 explicita laddningar och en ny väntande signal: återkopplingen tog inte slut. Det är ett reproducerat kodfel, inte en verifierad reproduktion av användarens faktiska hängning inne i WoW.

Fem nya regressionstester verifierar att ofärdig metadata inte skapar en eventloop, orelaterade väsktooltips inte omvärderar loot, laddningsfel har backoff och dubbla signaler samlas, statisk metadata inte blandas med färska/historiska AH-priser och hover bara använder en privat cachebaserad värderingstooltip. Reentrant hover, upprepade listuppdateringar, native klick och chatlänkar provas. Det befintliga testet för sen metadata går nu genom Bootstrap-ticken med stängt huvudfönster.

Global tooltip, item- och pris-API:er ersätts med avsiktligt felande testdubblar under hover. Värderingsrutan fungerar ändå, och synliga rader behöver inte döljas/visas om. Ingen testad kod skickar spelinput eller kör i målklienten.

## Löpande läge i 0.2.0

Tio nya regressionstester täcker start utan target, två mobtypers G/XP per timme, inaktivitet, paus, saknade källor, HUD med stängt huvudfönster, nollställning, historik, reload utan offline-tid, upprepade kommandon och ömsesidigt skydd mot överskrivning. Tidigare historik utan mode accepteras fortfarande. Rapporter och historik använder all-mob-totalen utan att visa intern NPC-markör 0.

Den simulerade sekvensen med två mobs ger 3 000 XP/h och 4 800 koppar/h efter 600 sekunder. Efter ytterligare 600 sekunder utan rewards blir motsvarande värden 1 500 XP/h och 2 400 koppar/h. Detta verifierar snitt sedan start, inte ett rullande tidsfönster. 8 193 upprepade lootreceipts och 4 097 killcredit-events provar minnesgränsernas beteende separat från verklig klientprestanda.

## Uppstartsregression i 0.1.1

Version 0.1.0 gav en rapporterad blockeringsruta vid uppstart i WoW. 0.1.1 tar bort förbjuden combatlogregistrering och använder det dokumenterade separata `PARTY_KILL(attackerGUID, targetGUID)`-eventet. Åtta nya regressionstester simulerar bland annat att förbjuden registrering kan utlösa Blizzard-varningen utan Lua-fel: exakt noll sådana försök tillåts. Kill-/XP-flödet testas även med frånvarande combatlog-API, hemliga identiteter, pets, andra mobnamn, paus och timeout. Den korrigerade versionen behöver fortfarande bekräftas i målklienten.

## Prisgranskning i 0.1.2

Auctionator 345:s installerade API, tooltiplogik och ModernAH-marknadsval har lästs. Fyra sparade GrindMeter-citat jämfördes med motsvarande minimum buyout i Auctionators sparade databas. Alla matchade per styck i koppar:

| Item | AH-styckpris | Vendor per styck |
|---|---|---|
| Long Soft Tail (1688) | 8 s 70 k | 8 s 6 k |
| Bristly Whisker (1686) | 7 s 43 k | 7 s 33 k |
| Iron Ore (2772) | 3 s 7 k | 1 s 50 k |
| Heavy Stone (2838) | 4 s 55 k | 60 k |

Detta verifierar sparade värden och styckprisenhet, inte aktuella livepriser. Bristly Whisker ger lägre AH-netto än vendor vid 5 % avgift, så vendor är korrekt rekommendation. Long Soft Tail × 4 ger 3 480 koppar före avgift och 3 306 efter avgift. Inga kontouppgifter eller prisdatabaser ingår i paketet.

Tio nya regressionstester täcker prisuppdatering, historik, paus, API-avbrott vid avslut, bindning, prisålder, beräkning och tooltip. Sen itemdata och databasnotifiering provas med syntetiska API-svar; faktisk notifiering i spelklienten återstår.

## Textvisning i 0.1.3

Rapporterade fyrkanter efter Sortera matchar den tidigare stjärnsymbolen i UI-koden. Sorteringsetiketten är nu utskriven som Kvalitet / Quality. Övriga dekorativa Unicode-tecken har ersatts med vanliga texttecken, utan att ändra svenska bokstäver eller mottagna itemlänkar.

Sorteringens fyra lägen, inställningarnas på/av-markeringar och stängknappar har kontrollerats i UI-harnessen på svenska och engelska. En källkontroll bekräftar att addonets egna UI-strängar bara använder ASCII och svenska bokstäver. Det är inte ett test av spelklientens faktiska fontrendering.

## Visuell granskning

Den faktiska UI-kodens frame-träd exporterades genom testharnessen för åtta vyer. Löpande startvy och resultat samt den nya kompakta panelen på svenska/engelska har renderats och granskats. Renderingen använder systemfont och emulerar inte Blizzard-texturer/native tooltips. Den är en layoutkontroll med syntetiska siffror, inte en skärmbild från WoW.

## Återstår

**Ingen körning av GrindMeter har verifierats inne i WoW.** Faktisk eventåtkomst/payload, Mac-modifierare, autolootordning, gruppcredit, spelklientens formatteringar, minimappplacering, AH-priser och avgiftsavrundning återstår. Installationsmetadata och Auctionator 345:s faktiska installerade API har lästs, vilket är något annat än att köra integrationen.

Se [IN_GAME_TESTING.md](IN_GAME_TESTING.md). P0 är inte slutgodkänt förrän den klientberoende kontrollen är genomförd och de synliga dataluckorna är accepterade/lösta.

## Reproducera

```sh
luajit tests/run.lua
python3 -m unittest discover -s tests -p 'test_*.py'
python3 scripts/build_catalog.py
python3 scripts/build_release.py
```

Releasebyggaren kontrollerar TOC-filernas existens, gemensamt versionsnummer, en enda addonrot och ZIP-integritet samt skriver SHA-256. Zip innehåller inga testpriser, kontodata, byggverktyg eller utvecklingsberoenden.
