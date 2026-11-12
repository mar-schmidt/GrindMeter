# Changelog

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
