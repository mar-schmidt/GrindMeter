# Changelog

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
