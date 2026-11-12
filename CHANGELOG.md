# Changelog

## 0.2.1 — 2026-11-12

- Bryter en återkopplingsloop där en lyckad laddningssignal före fullständig itemdata kunde utlösa ännu en laddning. Bara egna utestående förfrågningar hanteras, dubbla signaler slås ihop och data behandlas på nästa UI-tick.
- Cachelagrar statisk itemmetadata separat från AH-prisbilden. Saknade eller misslyckade items har fem sekunders väntetid mellan laddningsförsök; en passiv kontroll efter laddningssignalen startar ingen ny explicit laddning.
- Hover använder en separat värderingstooltip med redan hämtade uppgifter. Ingen `SetHyperlink`, itemdata- eller AH-fråga görs vid hover; native itemdetaljer finns kvar via klick och riktiga itemlänkar.
- Synliga lootrader döljs/visas inte om vid varje listuppdatering. Tooltipen har skydd mot återinträde och stängs tillsammans med sin rad eller huvudfönstret.
- Fem nya regressionstester; totalt 79 Lua-tester och 3 Python-tester. Den syntetiskt reproducerade eventloopen avslutas, även om itemdata fortfarande saknas. Bekräftelse av rapporterad hängning i målklienten återstår.

## 0.2.0 — 2026-11-12

- Ny flik Löpande och `/gm live`: start utan vald mob eller förvald stopptid, med gemensamt snitt för alla säkert registrerade mobbar sedan start.
- Flyttbar panel på 308 × 216 UI-pixlar med stora separata G/h- och mob-XP/h-värden, klocka och synlig värderingsmetod. Uppdateras även med huvudfönstret stängt.
- Pausa/Fortsätt, Nollställ och Stoppa i panelen. Nollställ sparar föregående period i historiken och bevarar pausläget. Klick på värderingen växlar Vendor/AH.
- Båda lägena delar samma säkra insamling. Endast ett pass åt gången; växling skriver inte över en aktiv mätning. Reload återställer pausat och räknar inte offline-tid.
- Historik, rapport och mobfördelning visar korrekta totaler för löpande pass. Intern all-mob-markör skapar aldrig en fabricerad NPC-räknare eller mobkälla.
- Återkommande loot summeras per exakt variant/källa/kategori i löpande läge. Äldre kroppsobservationer lärs en gång och lämnar cachen, så vanliga långa pass håller begränsad detaljdata.
- Tio nya regressionstester: totalt 74 Lua-tester och 3 Python-tester. Svensk/engelsk panel och huvudvyer är granskade i simulerad layout; in-game-verifiering återstår.

## 0.1.3 — 2026-11-12

- Ersätter stjärnan efter Sortera med den utskrivna etiketten Kvalitet / Quality.
- Ersätter bockar och cirklar i inställningarna med vanliga textmarkeringar, `[x]` och `[ ]`.
- Tar bort dekorativa Unicode-symboler i knappar, statusrader, tomma värden, antal, hjälprader och tooltipar som kunde visas som fyrkanter. Svenska bokstäver och spelets itemlänkar behålls.
- Befintliga 64 Lua-tester och 3 Python-tester passerar. Kontroll av sorteringsvalen och inställningarnas båda lägen är genomförd på svenska och engelska i UI-harnessen; visningen i spelklientens font återstår.

## 0.1.2 — 2026-11-12

- Rättar saknade AH-priser som tidigare kunde fastna under hela passet. Auctionators publika databasnotifiering och lyckade itemdata-events uppdaterar nu aktiva/pausade pass även när fönstret är stängt.
- Behåller tidigare känt pris och ursprungligt datum om ett uppslag tillfälligt misslyckas, även vid avslut. Avslutade pass behåller sin frysta prisbild.
- Tooltipen för mottagen loot visar AH-styckpris, antal, avgift, AH-netto, vendorvärde och valt radtotal. Osäker lootkälla förklaras i samma tooltip.
- Tillåter AH-värdering av bind-on-use-items och utesluter kontobundna items när klientens API anger detta.
- Rättar åldersintervallet för Auctionators scan-dygn. Dagens skanning märks inte längre automatiskt som gammal vid standardgränsen 24 timmar.
- Tio nya regressionstester; totalt 64 Lua-tester och 3 Python-tester. Fyra granskade sparade styckpriser matchar Auctionators databas; ingen generell stackmultipliceringsbugg hittades.

Korrigeringen är automatiskt testad. Prisuppdatering och tooltip behöver fortfarande bekräftas inne i WoW.

## 0.1.1 — 2026-11-12

- Åtgärdar uppstartsmeddelandet “GrindMeter has been blocked from an action only available to the Blizzard UI”.
- Tar bort förbjuden combatlogregistrering. Använder Forevers separata `PARTY_KILL(attackerGUID, targetGUID)`; `pcall` används aldrig som försök att tillåta en förbjuden registrering.
- Samlar läsbara mobnamn från target, mouseover och namnplattor. GUID, NPC-ID och roster krävs fortfarande för säker credit.
- `UNIT_DIED` används bara som diagnostik. Pets stöds genom roster; okända guardians gissas inte in. Hemliga identiteter hoppas över.
- Åtta nya regressionstester; totalt 54 Lua-tester och 3 Python-tester. Inställningar och historik från 0.1.0 behålls.

Korrigeringen är automatiskt testad men behöver fortfarande bekräftas inne i WoW.

## 0.1.0 — 2026-11-12

Första testreleasen för WoW Forever, interface 16001.

- Svenska och engelska, tre steg till första mätningen, validerat target och 5/10/15/30 min eller manuell stopptid.
- Flyttbar minimappikon, flyttbar kompakt mätpanel, paus/fortsätt och tydligt avslut.
- Separata kills-, XP- och looträknare per NPC-ID. PARTY_KILL-credit, egen/pet/grupp-roster och individuell GUID-deduplicering.
- Klientformatstyrda XP-, item- och myntparsers. Osäkra källor hålls utanför säkra mobsummor.
- Riktiga itemlänkar, native tooltips, chatlänkknapp, vendor- och Auctionator-värdering, lokal prisimport och fryst historisk prisbild.
- Partiell, daterad lootkatalog för 165 NPC-ID:n samt egna observationer, med underlag och licens synliga.
- Historik, filter, jämförelserader, radering, kopierbar rapport, klientdiagnostik och återställning efter reload.
- Automatiska tester, reproducerbart zipbygge och GitHub-releaseflöde från master.

### Kända begränsningar

- Faktisk eventåtkomst, eventordning, native tooltips, Mac-modifierare, gruppcredit och minimapposition ska fortfarande verifieras inne i WoW.
- Communitykatalogen är ofullständig och saknar bekräftat underlag för de två Wildplains-referensmobbarna. Dess fönsterbaserade statistik saknar mängd-/villkorsunderlag för en killbaserad guldprognos.
- Säkert group-killcredit stöds genom PARTY_KILL. Gruppmynt och tvetydiga/multikälliga lootflöden får konservativt okänd källa. Loot kan därmed bli ett känt delvärde.
- Slumpmässiga suffix får inget generiskt Auctionator-pris. Lokala exakta variantpriser kan importeras.
- AH-avgift är ett modellantagande. Auctionators prisålder är ett dygnsintervall.
- Lokala drop-nämnare kräver ensam, fullt observerad kropp och ger ingen fullständig eller opartisk droptabell.
