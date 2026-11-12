# Kvarstående verifiering i WoW

**Status 2026-11-12: inget av nedanstående är utfört i spelklienten.** Lokal installationsmetadata och installerat Auctionator-API har lästs. Syntetiska tester är separat dokumenterade och kan inte ersätta denna kontroll.

Installera testreleasen. Använd `/gm diagnostics` före och efter ett kort pass. Diagnostiken visar build, interface, locale, marknad, API-tillgänglighet och eventräknare; inga kontonycklar eller råa combatloggar exporteras.

| Steg | Verifiera | Status |
|---|---|---|
| 1 | Addonet laddas med interface 16001. Minimapikon och `/gm` öppnar samma fönster utan Lua-fel. | Ej speltestat |
| 2 | Välj en mob; NPC-ID stämmer. Byt target; huvudmobben ändras inte. | Ej speltestat |
| 3 | Döda en egen mob; PARTY_KILL-credit registreras en gång. Kontrollera manuell killräkning. | Ej speltestat |
| 4 | Andra spelare dödar mobbar nära dig. Skada även en annans tag. Ingen säker credit ska skapas för dessa. | Ej speltestat |
| 5 | Pet/summon och gruppmedlem ger sista slaget på gruppens mob. Kontrollera exakt en credit och spelarens personliga XP/loot. | Ej speltestat |
| 6 | Kontrollera att killdata är läsbar i Forever, även i strid. Begränsningar ska ge tydligt okänt/delvärde utan försök att kringgå dem. | Ej speltestat |
| 7 | Jämför XP-meddelanden med faktiska XP-förändringar; prova rested, gruppbonus, quest mellan kills och level up. | Ej speltestat |
| 8 | Manuell loot och autoloot. Kontrollera full itempayload, stackantal, source-GUID och kvittotid. | Ej speltestat |
| 9 | Fulla väskor, delvis uttagen stack och återöppnad kropp. Ingen extra receipt eller falsk drop-nämnare. | Ej speltestat |
| 10 | Två olika mobtyper, snabb dubbelkill, flera lootkällor och skinning efter vanlig loot. Tvetydiga källor hålls separat. | Ej speltestat |
| 11 | Mobmynt jämfört med handel, post, questpengar, reparation och vendor-försäljning under passet. Bara bekräftad mobloot räknas. | Ej speltestat |
| 12 | Pausa i två minuter under ett tolvminuterspass. Varken kills, XP eller loot under pausen räknas. | Ej speltestat |
| 13 | Tio minuters timeout i strid. Inga events vid/efter stopptiden tas med och inget stort fönster öppnas automatiskt. | Ej speltestat |
| 14 | `/reload` och normal logout mitt i pass. Återställ pausat, offline-tid exkluderad och tidigare mängder bevarade. | Ej speltestat |
| 15 | Native itemtooltip, klick för detaljer, spelets Mac-modifierare och knappen Länka till chatten. | Ej speltestat |
| 16 | Auctionator-skanning i rätt region/realm/faction. Kontrollera styckpris, dygnsålder, suffixfallback och bound-items. | Ej speltestat |
| 17 | Kontrollera faktisk faction-/neutral-AH-avgift och avrundning. 5 % i releasen är endast ett modellantagande. | Ej speltestat |
| 18 | Verklig lokal prisfil: import, reload, fel scope, gammal fil och omvärdering av historik utan att originalet ändras. | Ej speltestat |
| 19 | Svenska UI:t i engelsk klient på Mac, engelskt UI, andra upplösningar/UI-skalor, dragpositioner och fyrkantig minimap. | Ej speltestat |
| 20 | RestedXP och Auctionator aktiva, extern `/combatlog` av. Inga ändringar av andra addons inställningar. | Ej speltestat |

För referenssekvensen i kravställningen: 600 sekunder, 6 Huntress och 9 Patriarch ska ge 36/h, 54/h och totalt 90/h. Detta test säger inget om mobbarnas faktiska XP, drop rates eller priser. Dokumentera verklig build, locale, group/solo, autoloot/manuell och eventprecision vid godkännande.
