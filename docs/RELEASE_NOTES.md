GrindMeter 0.2.0 för WoW Forever, interface 16001.

**Nytt löpande läge:** G/h och mob-XP/h från alla mobbar i en liten flyttbar panel som uppdateras medan du spelar.

1. Öppna GrindMeter från minimappen och välj **Löpande**.
2. Klicka **Starta löpande**. Inget target eller tidsval behövs. Huvudfönstret stängs och panelen visas.
3. Alternativt: skriv **`/gm live`** för att starta direkt.

- Två stora siffror visar snitt sedan start, inte ett rullande 60-minutersfönster. Ingen förvald stopptid.
- **Pausa/Fortsätt**, **Nollställ** och **Stoppa** finns direkt i panelen. Nollställ sparar föregående period och bevarar pausläget.
- Klicka på värderingen för att växla Vendor / Bästa kända försäljning med AH-priser.
- Att dölja panelen stoppar inte mätningen. Högerklick på minimappikonen eller `/gm hud` visar den igen.
- Reload återställer passet pausat. Offline-tid, quest-XP och loot utan säker mobkälla ökar inte mobbsiffrorna.
- Återkommande loot summeras för långa pass. Historik och rapporter visar alla mobbars totaler. Ett pågående pass skrivs aldrig över vid byte av läge.

**Installera bifogad `GrindMeter-0.2.0.zip`.** Ersätt tidigare `GrindMeter`-mapp i `_forever_/Interface/AddOns/` och kör `/reload`. Behåll SavedVariables.

Tidigare AH-, uppstarts- och teckenkorrigeringar ingår. **74 Lua- och 3 Python-tester** passerar, inklusive tio nya regressionstester för löpande läge. Panelen och huvudvyerna har granskats i simulerad layout; faktisk verifiering inne i WoW återstår.

Data from Everloot (https://everloot.app), CC BY-SA 4.0. Independently written addon code: MIT.
