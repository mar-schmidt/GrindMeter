GrindMeter 0.2.1 för WoW Forever, interface 16001.

Rättar en itemdataloop som kan förklara rapporterad hängning vid itemhover.

- Laddningssignaler hanteras bara för GrindMeters egna väntande items, slås ihop och behandlas på nästa UI-tick. En för tidig signal startar inte en ny explicit laddning.
- Statisk metadata cachelagras separat från AH-priser. Saknade uppgifter har väntetid mellan laddningsförsök; vanliga tooltip-events från väskorna orsakar ingen omvärderingsloop.
- Hover i GrindMeter visar en separat värderingstooltip med redan hämtade uppgifter. Den gör inga item- eller AH-uppslag och anropar inte native itemtooltip-kedjan.
- **Klick öppnar fortfarande spelets fullständiga itemdetaljer.** Riktiga itemlänkar och knappen Länka finns kvar.
- Synliga lootrader återanvänds utan att döljas/visas om vid varje uppdatering. Löpande G/h och mob-XP/h fungerar som tidigare.

**Installera bifogad `GrindMeter-0.2.1.zip`.** Ersätt tidigare `GrindMeter`-mapp i `_forever_/Interface/AddOns/` och kör `/reload`. Behåll SavedVariables. Om klienten har hängt sig behöver den startas om för uppdateringen.

**79 Lua- och 3 Python-tester** passerar, inklusive fem nya regressionstester för itemdata och hover. Eventloopen har reproducerats och brutits i den syntetiska miljön. Bekräftelse av den faktiska hängningen i WoW återstår.

Data from Everloot (https://everloot.app), CC BY-SA 4.0. Independently written addon code: MIT.
