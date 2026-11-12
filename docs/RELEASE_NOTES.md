GrindMeter 0.1.2 för WoW Forever, interface 16001.

Rättar AH-priser som kunde förbli saknade under ett pågående pass och gör värderingen lättare att kontrollera.

- Auctionators färdiga skanning och laddad itemdata uppdaterar aktiva/pausade pass även med huvudfönstret stängt.
- Ett tillfälligt misslyckat prisuppslag behåller ett tidigare känt pris och dess datum, även vid avslut. Historiska pass behåller sin prisbild.
- Hovra över **Din loot** för styckpris, antal, AH-avgift, netto, vendorvärde och valt radtotal. Tooltipen förklarar om loot saknar säker mobkälla.
- Bind-on-use-items kan AH-värderas; kontobundna items utesluts när klienten anger bindningen.
- Dagens Auctionator-skanning märks inte längre automatiskt som gammal. Osäker scan-dygnsålder redovisas som ett intervall.
- Tio nya regressionstester; totalt **64 Lua- och 3 Python-tester**. Korrigeringen för uppstartsblockeringen i 0.1.1 ingår.

**Installera bifogad `GrindMeter-0.1.2.zip`.** Ersätt den tidigare `GrindMeter`-mappen i `_forever_/Interface/AddOns/` och kör `/reload`. Behåll SavedVariables.

**Så räknas värdet:** AH-pris per styck × antal, minus vald avgift (förvalt 5 %). Bästa kända försäljning väljer vendor om den ger mer. Fyra granskade sparade styckpriser matchade Auctionators databas exakt. Exempel: 4 × 8 s 70 k = 34 s 80 k före avgift, eller 33 s 6 k efter 5 %.

Ändringarna är automatiskt testade men ännu inte verifierade inne i WoW. Lootkatalog och AH-begränsningar beskrivs i README och docs/IN_GAME_TESTING.md.

Data from Everloot (https://everloot.app), CC BY-SA 4.0. Independently written addon code: MIT.
