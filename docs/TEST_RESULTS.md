# Testresultat — GrindMeter 0.1.0

Datum: **2026-11-12**. Testtyp: syntetiska eventsekvenser och mockad WoW-UI, inte spelklient.

## Genomfört

**46 Lua-tester och 3 Python-tester passerar.** Lua kördes med LuaJIT i Lua 5.1-läge. GitHub Actions kör samma Lua-testsvit med Lua 5.1 och kontrollerar syntax för alla distribuerade Lua-filer.

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
| Priser | Fel scope avvisas, gammalt pris märks, Auctionator-adapter använder rätt publika anrop, suffix får ingen generisk fallback och bound loot får inget AH-värde |
| Historik | Prisbild är fryst, alternativ värdering ändrar inte originalet, 50 pass behålls, radering bevarar settings och korrupt sparad data hindrar inte ny start |
| Dropdata | 2/8 kroppar och 6 enheter = 25 % och 0,75 enheter/kropp; olootade kills används inte som nämnare; egna fullt observerade kroppar hålls per NPC |
| Katalog | 165 NPC-ID:n/1 264 rader; fönsterdata är separat från killprognoser; sällsynt syntetisk prognos bevarar fraktionell koppar och höjer inte uppmätt värde |
| Språk | Klientens engelska format och positionsnumrerad tyska; inga hårdkodade engelska “You”-antaganden i parsern |
| Restriktioner | Begränsad combatkälla ger okänt, inte fabricerade kills; saknad lootkälla ger ofullständigt värde; extern combatlog och RestedXP ändras inte |
| UI | Ladda addon, välj target, starta, stäng utan stopp, pausa/fortsätt via HUD, avsluta, historik, språkväljare, minimappväxling och kopierbar rapport |
| Prisimportverktyg | Scope, framtidsdatum, stack-/styckpris, Lua-escaping, icke-finita tal och exkludering av extra fält/hemligheter |

De 32 acceptans-ID:na har syntetiska testfall, med AT-21/22 i ett gemensamt fall och kompletterande gränsfall. Detta innebär inte att alla klientberoende delar av acceptanskraven är godkända i spelet.

## Visuell granskning

Den faktiska UI-kodens frame-träd exporterades genom testharnessen och renderades lokalt för kontroll av startvy, resultatsida och kompakt panel. Renderingen använder systemfont och emulerar inte Blizzard-texturer/native tooltips. Den är en layoutkontroll med syntetiska siffror, inte en skärmbild från WoW.

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
