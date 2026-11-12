GrindMeter 0.1.3 för WoW Forever, interface 16001.

Rättar symboler som kunde visas som fyrkanter i gränssnittet.

- **Sortera: Kvalitet** / **Sort: Quality** ersätter stjärnsymbolen.
- Inställningarnas bockar och cirklar ersätts med `[x]` och `[ ]`.
- Vanliga texttecken används för stängknappar, antal, avskiljare, åldersintervall, tomma värden och hjälprader.
- Svenska bokstäver och spelets itemlänkar behålls. Korrigeringarna för AH-priser och uppstartsblockeringen ingår.

**Installera bifogad `GrindMeter-0.1.3.zip`.** Ersätt den tidigare `GrindMeter`-mappen i `_forever_/Interface/AddOns/` och kör `/reload`. Behåll SavedVariables.

Befintliga **64 Lua- och 3 Python-tester** passerar. Sortering och inställningar är dessutom kontrollerade i båda UI-språken i den simulerade miljön; slutlig kontroll av spelklientens fontrendering återstår.

Data from Everloot (https://everloot.app), CC BY-SA 4.0. Independently written addon code: MIT.
