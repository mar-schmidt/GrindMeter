GrindMeter 0.1.1 för WoW Forever, interface 16001.

Åtgärdar uppstartsmeddelandet **“GrindMeter has been blocked from an action only available to the Blizzard UI”** från version 0.1.0.

- Registrerar eller läser aldrig den blockerade combatloggen.
- Använder Forevers separata `PARTY_KILL(attackerGUID, targetGUID)` för killcredit. `UNIT_DIED` kan inte dubbelräkna en kill.
- Samlar läsbara mobnamn från target, mouseover och namnplattor för XP-attribuering.
- Bevarar konservativa regler för pets, gruppcredit, hemliga identiteter och okända källor.
- Åtta nya regressionstester; totalt 54 Lua- och 3 Python-tester. Befintlig historik och inställningar behålls.

**Installera bifogad `GrindMeter-0.1.1.zip`.** Ersätt den tidigare `GrindMeter`-mappen i `_forever_/Interface/AddOns/` och kör `/reload`. Behåll SavedVariables. Om du valde att avaktivera GrindMeter i Blizzards ruta behöver du aktivera det igen i addonlistan.

Den korrigerade versionen är automatiskt testad men ännu inte verifierad inne i WoW. Lootkatalog och AH-begränsningar kvarstår enligt README. Se docs/IN_GAME_TESTING.md för klienttest.

Data from Everloot (https://everloot.app), CC BY-SA 4.0. Independently written addon code: MIT.
