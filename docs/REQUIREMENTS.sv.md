# GrindMeter – kravspecifikation för ett grinding-addon

**Version:** 1.0  
**Datum:** 2026-11-12  
**Målplattform:** World of Warcraft Forever, macOS och Windows  
**Dokumentets syfte:** Självständigt byggunderlag för en annan agent.  
**Arbetsnamn:** GrindMeter. Slutligt namn kan ändras utan att funktionerna ändras.

## 1. Uppdrag och mål

Bygg ett addon där spelaren väljer en mob som finns framför karaktären, startar en mätning och grindar i normalt tio minuter. Addonet visar därefter kills per timme, XP per timme och lootvärde i guld per timme. Resultatet ska även innehålla mobbens kända möjliga loot med riktiga itemikoner, klickbara WoW-itemlänkar och vanliga itemtooltips.

Spelaren ska kunna besvara:

1. Hur många av just den här mobtypen dödar jag per timme i mitt nuvarande tempo?
2. Hur mycket XP får jag per timme från den mobtypen?
3. Vad är looten jag faktiskt plockade upp värd hos vendor respektive på AH?
4. Vilka andra items kan mobben droppa, och hur påverkar de ett långsiktigt förväntat värde?
5. Är en annan mob eller plats bättre enligt mina tidigare mätningar?

**Avgörande produktbeslut:** Skilj tydligt mellan uppmätta händelser och beräknade försäljningsvärden. Ett högt AH-pris är inte mottaget guld. Ett item i en droppkatalog är inte ett item spelaren fått.

Detta uppdrag gäller addonets implementation. En fungerande leverans ska innehålla installerbara addonfiler, inte endast en ny plan eller UI-skiss. Detta dokument kräver ingen extern tjänst för grundmätningen.

## 2. Plattform och prioriteringar

### 2.1 Plattform

- Primärt WoW Forever. Anta inte att Retail- eller Classic Era-API:er fungerar oförändrade.
- Ska fungera på Mac utan Windows-program, extern skärmlösning eller krav på `/combatlog`.
- Grundfunktionerna ska använda spelets tillåtna addon-API och fungera utan annan addon.
- Ska kunna köras tillsammans med exempelvis RestedXP utan att ändra deras data eller beteende.
- Svenska är förvalt språk i addonets eget gränssnitt. Engelska ska finnas som alternativ. Item- och mobnamn följer klientens tillgängliga språk; det krävs inte en svensk spelklient.
- Första referensmiljön är **EU → Normal → Alliance**. Resultat och marknadsdata måste identifiera den faktiska spelarens miljö och får inte vara hårdkodade till referensmiljön.

### 2.2 Prioriteter

| Prioritet | Betydelse |
|---|---|
| P0 | Krävs i första användbara versionen. |
| P1 | Nästa steg; ska förberedas i modellen utan att blockera P0. |
| P2 | Möjlig vidareutveckling. |

P0 omfattar val av mob, timer, korrekt attribuering, kills/h, XP/h, vendorvärde/h, möjlig AH-värdering genom en verifierad datakälla, möjlig loot, native itemlänkar samt sessionshistorik. Datakvalitet och tydliga lägen för saknade uppgifter är P0.

AH-funktionen ska ha minst en fungerande, verifierad inläsningsväg: ett kompatibelt prisaddons dokumenterade gränssnitt eller en versionsmärkt prisfil som uppdateras utanför spelklienten. Addonet ska fortfarande vara användbart med vendorvärden när AH-källan saknas. Om byggagenten inte kan leverera en faktisk AH-källa ska det redovisas som en kvarvarande lucka, inte beskrivas som en färdig integration.

## 3. Användarflöde

### 3.1 Välj mob och starta

1. Spelaren markerar en levande eller död fientlig NPC.
2. Öppnar addonet via `/grindmeter` eller en valfri minimapknapp.
3. Klickar **Välj nuvarande target**.
4. Ser mobnamn, NPC-ID, zon och tillgänglig lootinformation.
5. Väljer mätlängd: **10 minuter** som standard; även 5, 15, 30 minuter eller tills spelaren stoppar.
6. Klickar **Starta**. Mätningen startar omedelbart och kräver inget första kill för att tiden ska börja räknas.

En annan target under pågående pass ändrar inte vald mob. Mätning ska vara möjlig även om mobben saknas i den medföljande lootkatalogen. Om inget giltigt target finns visas ett kort meddelande med hur spelaren väljer en mob.

### 3.2 Under passet

En liten, flyttbar panel visar:

- Vald mob och sessionens status.
- Återstående respektive förfluten mättid.
- Kills av vald mob, kills/h, mob-XP/h och lootvärde/h.
- Aktuell värderingsmetod: **Vendor** eller **Bästa kända försäljningsvärde**.
- Antal andra mobbar som dödats och indikator för osäkert attribuerade händelser.
- **Pausa**, **Fortsätt** och **Stoppa**.

Panelen ska inte täcka action bars som standard. Spelaren kan stänga eller minimera panelen medan passet fortsätter. Ett aktivt pass får aldrig nollställas av att fönstret stängs.

### 3.3 När tiden är slut

- Stoppa automatiskt vid vald tidsgräns.
- Spara resultatet och ge en diskret avisering. Visa inte en stor modal över en pågående strid.
- Visa en resultatsida med vald mob som huvudresultat och en separat översikt för hela passet.
- Erbjud **Ny mätning med samma mob**, **Välj annan mob** och **Historik**.
- Visa exempelvis: ”Uppmätt under 10:00. Timvärdena är extrapolerade.”

## 4. Funktionella krav

### 4.1 Identitet, timer och session

| ID | Pri | Krav |
|---|---|---|
| SES-01 | P0 | Identifiera mobtyp med NPC-ID från tillgänglig, giltig GUID. Namn används för presentation, inte som primär databasnyckel. |
| SES-02 | P0 | Bevara individuell creature-GUID för varje observerad mob så att samma död inte räknas flera gånger. |
| SES-03 | P0 | Lås vald NPC-ID vid start. Ett pass har exakt en huvudmob i P0. |
| SES-04 | P0 | Registrera andra dödade NPC-ID:n separat. De får inte läggas till huvudmobbens resultat eller lootmodell. |
| SES-05 | P0 | Tiden omfattar strid, springande, looting, väntan på respawn, vila och död. Automatisk paus vid inaktivitet eller frånvaro av strid är avstängd. |
| SES-06 | P0 | Explicit paus stoppar mättiden och insamlingen av kills, XP och nya lootintäkter. Det får inte gå att pausa tiden men fortsätta räkna belöningar. |
| SES-07 | P0 | Registrera pausad tid separat. Visa både mättid och total kalendertid när ett pass har pausats. |
| SES-08 | P0 | Endast en aktiv session åt gången. Ny start får inte tyst skriva över en pågående session. |
| SES-09 | P0 | Vid manuell stopptid eller timeout ska gränsen vara entydig: start ingår, stopp ingår inte, alltså `[start, stopp)`. |
| SES-10 | P0 | Använd monotont tidsmått för mättid under klientkörning, samt datum/tid för historik. Lokal klockjustering får inte ändra kills/h. |
| SES-11 | P0 | Vid normal logout eller `/reload` sparas pågående läge. Återkomst visar ett avbrutet/pausat pass som spelaren kan fortsätta eller avsluta; offline-tid räknas inte. |
| SES-12 | P1 | Tillåt att flera uttryckligen valda NPC-ID:n bildar ett gemensamt grindmål, med separat och sammanlagt resultat. |

Vid abrupt klientkrasch går det inte att lova att osparade SavedVariables överlever. Visa eventuellt återställd session utifrån faktiskt sparat läge, utan att konstruera saknade händelser.

### 4.2 Kills och ägarskap

| ID | Pri | Krav |
|---|---|---|
| KIL-01 | P0 | Räkna endast bekräftade kills som tillhör spelarens eller spelargruppens grind. Dödsfall från andra spelare i närheten ska inte räknas. |
| KIL-02 | P0 | Stöd solo samt spelarens pets/ägda enheter. Pet, spelare och flera dödsevent får tillsammans ge högst ett kill för samma creature-GUID. |
| KIL-03 | P0 | Använd bekräftad kill credit och observerad koppling till spelaren/gruppen. Enbart `UNIT_DIED`, närhet eller ett enda skadeslag på en annans tag är otillräckligt. |
| KIL-04 | P0 | Ett giltigt kill kräver inte att spelaren utdelar sista slaget. I grupp krävs en verifierad regel för delad credit, inte bara att vilken gruppmedlem som helst syns i en combatlograd. |
| KIL-05 | P0 | Visa solo/grupp och ändrad gruppsammansättning i sessionens metadata. Räkna spelarens erhållna XP och loot, inte hela gruppens hypotetiska inkomster. |
| KIL-06 | P0 | Om credit är oklar lägg händelsen i osäkra/ej inkluderade händelser, med orsak. Den får inte tyst räknas som säker. |

Grå mobbar som ger noll XP ska fortfarande kunna räknas som kills. En mob som började bekämpas före start kan räknas om dess bekräftade död sker under mättiden; detta ska dokumenteras konsekvent i implementationen.

### 4.3 XP

| ID | Pri | Krav |
|---|---|---|
| XP-01 | P0 | Räkna faktiskt erhållen XP från mobkills, inklusive rested XP och aktuella bonusar. Visa att resultatet inkluderar dessa bonusar. |
| XP-02 | P0 | Koppla XP till huvudmob respektive andra mobtyper när källan kan fastställas. Visa XP med okänd mobkälla separat. |
| XP-03 | P0 | Quest rewards, exploration, PvP och annan XP ska inte ingå i mob-XP/h. En separat siffra för all XP under passet får visas, med egen etikett. |
| XP-04 | P0 | Hantera level up korrekt utan att XP-räknaren blir negativ eller samma XP räknas två gånger. |
| XP-05 | P0 | Vid max level eller avstängd XP ska noll erhållen XP presenteras begripligt. Saknad mätdata är däremot ”okänt”, inte noll. |
| XP-06 | P0 | Ett chatmeddelandes generella `guid`-fält får inte antas vara den dödade mobbens GUID utan verifiering. Namn och eventordning får bara ge en matchning när kandidaterna faktiskt kan särskiljas. |
| XP-07 | P1 | Visa separat bas-XP och bonus-XP om klienten ger säkra uppgifter. Skatta inte bas-XP genom att rutinmässigt halvera rested-belopp. |

Om lokaliserade XP-meddelanden behöver tolkas ska parsern använda klientens formatsträngar och vara testad för stödda språk. Hårdkodad matchning av engelska ”You” eller första heltalet i godtycklig text är inte godkänd. Totala XP-deltan kan användas som kontroll, men är inte bevis på XP från en viss mob.

### 4.4 Faktiskt erhållen loot och pengar

| ID | Pri | Krav |
|---|---|---|
| LOO-01 | P0 | Registrera items som spelaren faktiskt mottar: full itemlänk/variant, item-ID, antal och källa när den är säker. En rad i ett öppet lootfönster är inte i sig mottagen loot. |
| LOO-02 | P0 | Stöd autoloot, manuell loot, stacks och återöppnade kroppar utan dubblering. Fulla väskor ska inte ge värde för items som inte gick att plocka upp. |
| LOO-03 | P0 | Fånga tillgänglig lootkälla innan slots försvinner. Använd GUID-källor när klienten stödjer det. En lootstack kan ha flera källor; fördela bara när underlaget tillåter det. |
| LOO-04 | P0 | Om källan inte kan avgöras hamnar looten under **Loot utan säker mobkälla**. Den får inte tillskrivas senaste target eller senast dödade mob av bekvämlighet. |
| LOO-05 | P0 | Räkna upphämtade mynt från bekräftad mobloot separat från föremålsvärde. Kontantsaldo är inte en tillräcklig källa: handel, post, reparationer och questpengar påverkar också saldot. |
| LOO-06 | P0 | Skilj vanlig mobloot från skinning, mining, herbalism, kistor och innehåll i öppnade föremål. Professionsloot får inte automatiskt höja huvudmobbens vanliga lootvärde. |
| LOO-07 | P0 | En lootkälla som inte kan knytas till en registrerad kill under mättiden får inte bli säker loot för huvudmobben. Äldre kroppar kan visas som övrig/okänd loot. |
| LOO-08 | P0 | Deduplikera bekräftelser mellan lootfönster, chatt och inventory-events. Inventory-diff får användas för kontroll men inte ensam avgöra lootkälla. |
| LOO-09 | P0 | Mottagna mängder efter stopptid ingår inte i den avslutade mätningen. Fördröjd laddning av pris, ikon och itemnamn får uppdatera presentationen utan att skapa nya receipts. |
| LOO-10 | P1 | Valbar professionsloot med separat resultat och redovisat arbetsmoment. |

Räkna inte en kista/lockbox både till sitt eget värde och till hypotetiskt innehåll. Om inget föremål lootas trots flera kills ska kill- och XP-resultatet fungera; visa att lootresultatet bara omfattar det spelaren plockat upp. Utebliven lootobservation bevisar inte att kroppen saknade loot.

## 5. Beräkningsregler

### 5.1 Gemensam tidsbas

Låt `T` vara sessionens mätta sekunder, efter avdrag för explicit paus, och `K_m` antalet säkra kills av mobtyp `m`.

```text
Kills/h för m = K_m × 3600 / T
Mob-XP/h för m = faktiskt attribuerad mob-XP_m × 3600 / T
Sekunder per kill för m = T / K_m
```

Använd samma `T` för huvudmobben, andra mobbar och totalen. Fördela inte tiden i efterhand efter andelen kills. En Huntress-mätning får inte få ”ren Huntress-tid” genom att dra bort all tid då Patriarch dödades.

Vid `T = 0` visas ännu inget timvärde. Vid `K_m = 0` och positiv mättid visas noll kills/h och streck för sekunder per kill. Visa att timvärden är preliminära vid kortare pass än fem minuter eller färre än tio kills; detta är en enkel indikator, inte ett statistiskt konfidensintervall.

### 5.2 Tre olika guldsiffror

Resultatet ska hålla följande åtskilda:

| Siffra | Innehåll | Vad den betyder |
|---|---|---|
| **Plockade mynt** | Bekräftade mynt från mobloot. | Faktisk valuta mottagen från grind. |
| **Lootvärde – vendor** | Plockade mynt + vendorvärdet av faktiskt mottagna items. | Vad den mottagna looten motsvarar vid vendorförsäljning. |
| **Lootvärde – bästa kända försäljning** | Plockade mynt + högsta kända tillåtna nettovärde per mottaget item, vendor eller AH. | Uppskattat värde om föremålen säljs på respektive rekommenderat sätt. |

Vendor- och AH-värde är alternativa värderingar, inte belopp som ska summeras. Alla tre kan visas som totalsumma och per timme. Visa enheten **G/h (lootvärde)** där det behövs för att skilja från kontanter.

```text
Vendorvärde = C + Σ(n_i × v_i)

AH-netto_i = a_i × (1 − f_i)
Bästa kända styckvärde_i = max(v_i, tillåtet och tillgängligt AH-netto_i)
Bästa kända lootvärde = C + Σ(n_i × bästa kända styckvärde_i)

Värde/h = respektive värde × 3600 / T
```

Där `C` är säkert attribuerade plockade mynt, `n_i` mottaget antal, `v_i` vendorpris per styck, `a_i` valt AH-pris per styck och `f_i` relevant försäljningsavgift. Saknad prisuppgift är `nil/unknown`, inte automatiskt noll.

- Vendorpriser hämtas från klientens iteminformation när tillgänglig.
- AH-värdering får inte användas för soulbound, otillåtna eller på annat sätt osäljbara varianter.
- Pris och försäljningsavgift ska motsvara rätt marknad. Ett föreslaget förval om 5 procent för faction-AH måste valideras för målklienten; avgiften ska vara konfigurerbar.
- Lyckad försäljning antas i AH-modellen. Osålda auktioner, förlorade depositioner och tidsåtgång för försäljning ingår inte utan separat uttryckligt stöd.
- Reparation, mat, ammunition och andra kostnader är inte automatiskt avdragna. Etiketten ska ange **före förbrukning och reparation**. Kalla inte siffran nettovinst.
- Saknas ett AH-pris kan vendor användas som bästa kända värde, med indikator **AH-pris saknas**. Det innebär inte att vendor säkert är bästa marknadsalternativet.
- Saknas även vendoruppgift är totalen ett **känt delvärde**, med antal ej värderade items. Ett verifierat osäljbart item kan däremot ha faktiskt värde noll.
- Om ett lootat item senare säljs får dess försäljningspengar inte läggas till ovanpå samma items redan räknade lootvärde. Faktiska försäljningsintäkter är en separat eventuell framtida vy.

### 5.3 Långsiktigt förväntat värde från möjlig loot

Visa detta som en egen, tydligt märkt prognos: **Förväntat G/h enligt lootkatalog**. Blanda inte prognosen med värdet av faktiskt mottagen loot.

För varje mobtyp `m` och item `i`:

```text
Förväntade enheter_i per kill = p_mi × q_mi
Förväntat värde per kill_m = c_m + Σ(p_mi × q_mi × s_i)
Förväntat värde/h_m = kills/h_m × förväntat värde per kill_m
```

`p_mi` är sannolikheten att kroppen droppar itemet, `q_mi` förväntad mängd när det droppar, `s_i` vald försäljningsvärdering och `c_m` känt genomsnitt av plockbara mynt per kill. Om källan redan anger förväntade enheter per kill ska mängden inte multipliceras en gång till.

- Flera items kan droppa från samma mob. Normalisera därför inte alla drop rates till sammanlagt 100 procent.
- Använd inte `q = 1` som ett dolt antagande när stackstorlek är okänd. Visa saknad mängduppgift eller en uttryckligt märkt beräkningsförutsättning.
- Questloot, skinning och villkorade drops ska bara ingå i relevant läge. Okända villkor får inte antas uppfyllda.
- Saknade drop rates eller priser gör prognosen ofullständig. Visa delprognos med täckning eller att underlaget är otillräckligt.
- Små datamängder och mycket sällsynta drops ska framgå. Tio minuters mätning gör inte en sällsynt drop sannolik under nästa timme.
- För blandade pass används varje mobtyps egen lootmodell. Huntress-data får aldrig användas som ersättning för Patriarch-data.

### 5.4 Egen observerad drop rate

```text
Observerad drop rate_i = kroppar som gav item_i / kvalificerade observerade kroppar
Observerade enheter_i per kropp = total mottagen mängd_i / samma nämnare
```

Den lokala nämnaren måste avse kroppar där lootutfallet faktiskt kunnat observeras enligt en definierad regel. Alla kills är inte automatiskt undersökta kroppar. Selektiv manuell loot, gruppfördelning och villkorad questloot ska markeras som möjliga urvalsfel. Om klienten inte kan skilja en tom kropp från en oöppnad kropp ska addonet avstå från en tvärsäker egen drop rate. Visa alltid underlaget, till exempel **2 av 8 observerade kroppar**.

## 6. Möjlig loot och riktiga itemlänkar

### 6.1 Separata vyer

1. **Din loot:** Items spelaren faktiskt mottagit i sessionen.
2. **Möjlig loot:** Items som en versionsmärkt katalog anger att den valda mobben kan droppa, även om spelaren ännu inte fått dem.

Vyernas rader ska kunna visa:

| Kolumn | Krav |
|---|---|
| Item | Riktig ikon, kvalitetens färg och native itemlänk. |
| Kategori | Vanlig drop, questitem, professionsloot eller annat villkor. |
| Antal fått | Mottagen mängd från sessionen, separat från kataloguppgift. |
| Drop rate | Katalogens uppgift med källa/underlag, samt eventuell lokal observation tydligt åtskild. |
| Vendor/st | Styckpris eller saknad uppgift. |
| AH/st | Vald pristyp, källa, marknad och prisålder via detaljvy/tooltip. |
| Rekommenderad försäljning | Vendor, AH eller otillräckligt underlag, efter avgift. |
| Sessionsvärde | Endast mottagen mängd × styckvärde; inte hypotetiska katalogdrops. |

Krav på iteminteraktion:

- Mouseover visar spelets vanliga itemtooltip, inklusive tillgängliga stats och krav.
- Klick öppnar standardbeteende för itemlänk; länkning till chatten ska fungera med klientens modifierinställning och genom en tillgänglig knapp/meny.
- På Mac får funktionen inte kräva en viss Windows-tangent. Återanvänd spelets inställning för modifierad itemklickning.
- Använd full faktisk itemlänk för mottagna random-suffix-/variantitems. Ett generiskt katalogitem får inte få pris som om en viss suffixvariant garanterades.
- Om itemdata inte är laddad: visa item-ID och laddningsstatus, begär data genom stödd klientfunktion och uppdatera när den kommer. Ingen fejkad ikon, statistik eller itemlänk.
- Sortering på namn, drop rate och försäljningsvärde; förval är kvalitet och därefter värde. Okända värden sorteras begripligt.

### 6.2 Katalog och datakvalitet

En addon kan inte förväntas fråga en webbsida om en godtycklig mobs kompletta lootlista under spel. Leverera därför en separat, lokalt laddad lootkatalog/provider med:

- Spelvariant, dataversion, källhänvisning och datum.
- NPC-ID → item-ID/variantpolicy, kategori, sannolikhet, mängduppgift och villkor.
- Antal observationer eller annan förklaring till drop rate när uppgiften finns.
- Täckningsstatus per mob: **verifierad katalog**, **delvis känd** eller **saknas**.

Mätning ska fungera för godtyckliga stödda NPC-ID:n. Möjlig loot kan bara visas där underlag finns; saknad katalog ska synas och får inte ersättas av en generell lista som låtsas gälla mobben.

Första leveransen ska minst ha kontrollerade referensposter för **Wildplains Huntress, NPC-ID 259055**, och **Wildplains Patriarch, NPC-ID 259054**, om ID:n och mobbarna bekräftas i målklienten/datakällan. De är skilda mobtyper. Samla ingen gemensam droptabell baserat enbart på namnen. Redovisa sedan hur mycket av Forever som katalogen täcker och hur fler mobbar läggs till. Gör inte anspråk på komplett täckning utan en källa som stödjer det.

Byggagenten ska kontrollera rättigheter och datakällans användningsvillkor innan någon databas paketeras. Detta är ett val av faktisk datakälla, inte ett krav på en egen webbtjänst.

## 7. AH-priser

### 7.1 Providerkontrakt

Prislagret ska kunna bytas utan ändringar i sessionsräknaren. Varje svar behöver minst:

```text
itemID och eventuell variantKey
unitPriceCopper
priceType                 exempel: minimumBuyout eller medianListing
sourceName, sourceVersion
observedAt                 när marknadsuppgiften observerades
importedAt                 när den laddades in
gameFlavor, region, realm/connectedRealm och faction/marketScope
```

- Priser avser per styck, inte hela stackens pris. Mottagen valuta lagras i heltal koppar. Prognoser får behålla bråkdelar av koppar internt så att tidig avrundning inte förvanskar sällsynta drops; avrunda slutpresentationen konsekvent. Validera avgiftsavrundning mot den faktiska AH-marknaden.
- Kontrollera scope innan användning. Retail, annan region eller fel marknad får inte användas för att fylla en lucka i Forever Normal EU Alliance.
- Förval är en konsekvent, namngiven pristyp, exempelvis lägsta buyout. Median av listningar kan finnas som jämförelse, men får inte beskrivas som faktiskt genomförda försäljningar.
- Blanda inte lägsta buyout och median tyst mellan items. Saknad vald pristyp ska visas eller en tydlig fallback anges.
- Prisålder ska synas. Föreslaget förval för varning är äldre än 24 timmar, konfigurerbart.
- Använd inte gammal snapshot utan märkning och kalla den inte livepris.
- Historiska resultat behåller den prisbild som användes när de avslutades. **Värdera om med senaste priser** skapar en tydligt märkt alternativ vy.

### 7.2 Integrationsordning

1. Undersök kompatibla prisaddons och verifiera att deras API och datatäckning fungerar i Forever.
2. Om användaren har exempelvis SnapPrice installerat får en adapter byggas **efter** kontroll av det verkliga gränssnittet. Namnet ensamt är inte ett API-kontrakt.
3. Alternativt stöd en lokal, versionsmärkt prisfil som produceras utanför klienten och laddas vid addonstart/reload. Dokumentera uppdateringsflöde och intervall.
4. Om ingen AH-källa finns: visa vendorresultat och **AH-data saknas**. Krävs inga manuella priser för att göra en grundmätning.

Ingen API-nyckel eller nätverkshemlighet ska behöva ligga i addonets Lua-filer. Försök inte göra godtyckliga HTTP-anrop eller läsa en combatlogfil från addonets sandbox.

## 8. Resultatsida och historik

Resultatsidan ska visa huvudmobben först:

- Mobnamn, NPC-ID, plats, datum, levelintervall och solo/grupp.
- Mättid, eventuell paus och kills.
- Kills/h, XP totalt, XP/h och sekunder per kill.
- Plockade mynt, vendorvärde/h och bästa kända försäljningsvärde/h.
- Förväntat värde/h från katalog som separat prognos, om underlaget räcker.
- Antal andra mobkills, okänd XP/lootkälla, ej värderade items och inaktuella priser.
- Flikarna **Din loot**, **Möjlig loot** och **Övriga mobbar**.

Siffror för huvudmobben och för hela passet får inte ha samma etikett. ”Totalt i passet” får inkludera säkert registrerade andra mobbar; okända källor redovisas som eget tillägg och fördelas inte i smyg på mobbar. Om osäker attribuering kan göra huvudmobbens XP/h eller lootvärde/h ofullständigt ska även själva nyckeltalet märkas **känt delvärde**, inte bara en dold detaljrad. Skilj alltid ett bekräftat nollresultat från saknad observation.

Historik ska sparas per karaktär med minst de senaste 50 passen, kunna filtreras på mob och raderas av spelaren. Bevara settings separat från historik. En enkel jämförelse ska visa mättid, kills/h, XP/h och respektive värde/h. Pass med olika rested-status, level eller prisdatum ska inte framstå som identiska förutsättningar.

**P1:** Kopierbar textsammanfattning i en editruta. Automatisk postning till chatten är inte nödvändig. Addonet ska inte spamma andra spelare med resultat.

## 9. Teknisk utformning

### 9.1 Rekommenderade ansvarsområden

Exakta filnamn är valfria; följande ansvar ska vara tydligt separerade:

| Modul | Ansvar |
|---|---|
| ClientAdapter | API-kontroller, registrering av events, klient- och språkvariationer. |
| SessionTracker | Timer, status och sessionens avgränsning. |
| KillTracker | Individ-GUID, NPC-ID, ägarskap och deduplicering. |
| XPTracker | Faktisk XP, källa, bonusinformation och level up. |
| LootTracker | Bekräftade receipts, mängder, källor och deduplicering. |
| LootCatalog | Möjliga drops med versions- och källinformation. |
| PriceProvider | Vendorpris, AH-adaptrar och datakvalitet. |
| Calculator | Rena, testbara formler som inte behöver WoW-UI för att köras. |
| UI / Storage | Presentation respektive versionsmärkta SavedVariables. |

Använd eventdriven insamling. Uppdatera timervisning och synliga nyckeltal högst ungefär fyra gånger per sekund. Kör inte fullständiga bag- eller AH-genomsökningar varje frame. Behåll inte obegränsad rå combatlog i minnet eller SavedVariables; spara tillräckliga dedupliceringsnycklar och sammanfattningar för sessionen.

### 9.2 Minsta datamodell

```text
Session
  id, schemaVersion, addonVersion, clientBuild, locale
  characterKey, gameFlavor, region, realm, faction
  selectedNpcID, selectedName, mapID, zoneName
  startedAt, endedAt, measuredSeconds, pausedSeconds
  state, stopReason, levelStart, levelEnd, restedInfo, groupInfo
  countersByNpcID
  killRecords / boundedDedupState
  xpTotalsBySource, unattributedXP
  lootReceipts, unattributedLoot
  lootObservationCoverage
  priceSnapshot, catalogVersion
  diagnosticsSummary

KillRecord
  creatureGUID, npcID, eventTime, creditEvidence, confidence

LootReceipt
  receiptID, eventTime, itemID, itemLink, variantKey, quantity
  sourceGUIDs, sourceNpcID, category, attributionStatus
  vendorPriceStatus, tradeEligibility

Result
  measuredMetrics, valuationMetrics, catalogForecast
  missingData, assumptions, warnings
```

Separera lagrade mängder och händelser från beräknade vyer. Byte mellan vendor och AH får inte ändra mottaget antal eller XP. SavedVariables ska ha schemaVersion och enkel migrationshantering. Korrupt historik får inte hindra att ett nytt pass startas.

### 9.3 API-kontroll innan UI byggs färdigt

Första utvecklingssteget ska vara en liten verifiering i rätt klient: välj mob, döda, få XP, loota manuellt och med autoloot, samt observera relevanta eventpayloads. Bekräfta också pet/group credit och vilka data som faktiskt kan läsas.

Vid dokumentets tillkomst visar lokal installationsmetadata **Forever 1.60.1.70888**. Ett installerat Forever-addon använder TOC-interface **16001**. Detta är orienteringsdata: läs aktuellt `GetBuildInfo()` och validera TOC-värdet vid implementationen.

Följande events finns i den granskade Forever-exportens eventindex. Det bevisar att de är dokumenterade där, inte att varje payload är fri från restriktioner i varje situation:

| Funktion | Kandidater att verifiera |
|---|---|
| Combat och kills | `COMBAT_LOG_EVENT_UNFILTERED`, `CombatLogGetCurrentEventInfo`, subevents såsom `PARTY_KILL`, `UNIT_DIED` och skade-/summonhändelser. |
| XP | `CHAT_MSG_COMBAT_XP_GAIN`, `PLAYER_XP_UPDATE`, `PLAYER_LEVEL_UP`, klientens XP-formatsträngar. |
| Loot | `LOOT_READY`, `LOOT_OPENED`, `LOOT_SLOT_CLEARED`, `LOOT_CLOSED`, `CHAT_MSG_LOOT`, samt eventuell `GetLootSourceInfo` eller motsvarande stödd källfunktion. |
| Pengar | `CHAT_MSG_MONEY`, `PLAYER_MONEY` och bekräftad lootkontext. |
| Itemdata | `GET_ITEM_INFO_RECEIVED`, `ITEM_DATA_LOAD_RESULT` och klientens stödda item-/tooltipfunktioner. |
| Persistens | `PLAYER_LOGOUT`, `PLAYER_ENTERING_WORLD` och SavedVariables. |

Combat-eventet är märkt med restriktioner i exporten. Kontrollera faktisk åtkomst i Forever; kopiera inte beteende från Retail på antagande. Kandidatfunktionerna ovan är inga påhittade kompatibilitetslöften. Om en källa inte fungerar ska agenten anpassa insamlingen och öppet redovisa precisionen, inte kringgå klientrestriktioner eller fabricera data.

Ett beroende av tidssamband är inte samma sak som säker attribuering. Till exempel kan två likadana mobbar dö nära samtidigt; tilldela inte XP eller loot till en viss individ om underlaget inte kan särskilja dem. Om båda säkert är samma NPC-ID kan summering på mobtyp vara säker även om individkopplingen saknas.

## 10. Acceptanstester

Beräkningarna och attribueringen ska ha meningsfulla automatiska tester med syntetiska eventsekvenser. Verifiera dessutom de klientberoende flödena i spelet. Syntetiska tester får inte beskrivas som genomförda tester i WoW.

| ID | Scenario | Godkänt resultat |
|---|---|---|
| AT-01 | Välj target, byt target, starta/grinda. | Vald NPC-ID bevaras; ny target ändrar inte huvudmobben. |
| AT-02 | 600 sekunder, 6 Huntress och 9 Patriarch. | Huvudmob Huntress: 6 kills och 36/h. Patriarch: 9 och 54/h. Totalt: 15 och 90/h. Total snittid: 40 s/kill. Ingen gemensam droptabell antas. |
| AT-03 | Andra spelare dödar ytterligare 5 lejon i närheten. | Dessa ökar inte spelarens kills eller lootprognos. |
| AT-04 | Pet bidrar till ett kill; både credit- och dödsevent kommer. | En creature-GUID räknas en gång. Ägarregeln är testad. |
| AT-05 | Spelaren skadar en annans tag; mobben dör. | Inte automatiskt ett eget säkert kill. |
| AT-06 | 6 Huntress ger 200 XP var; 9 Patriarch ger 220 XP var, på 600 s. | Huntress 1 200 XP och 7 200 XP/h. Patriarch 1 980 och 11 880 XP/h. Totalt 3 180 och 19 080 XP/h. |
| AT-07 | Quest ger 1 000 XP mellan två mobkills. | De 1 000 ingår inte i mob-XP/h. |
| AT-08 | Level up inträffar mitt i passet. | Positiv, korrekt faktisk XP utan dubbelräkning eller negativt hopp. |
| AT-09 | Bekräftad rested-bonus ingår i XP. | Erhållen XP räknas en gång och bonusförutsättning syns. |
| AT-10 | Två mobtyper dör nära samtidigt; XP-källan är tvetydig. | Oavgjord XP redovisas separat, inte tyst hos huvudmobben. |
| AT-11 | 12 min kalendertid varav 2 min explicit paus. | T är 600 s. Kills och loot under pausen exkluderas. |
| AT-12 | Gå, vila eller dö under aktiv mätning. | Tiden fortsätter och påverkar timvärden. |
| AT-13 | Autoloot och manuell loot ger samma bekräftade mängder. | Samma resultat. Återöppnad kropp och dubbla bekräftelser ger inga extra items. |
| AT-14 | Ett item syns i lootfönstret men väskorna är fulla. | Itemet ger inget mottaget lootvärde. |
| AT-15 | Mottaget före stopp: 3 s mynt och 2 items à 10 s vendor, T=600 s. | Vendorvärde 23 s och 1 G 38 s/h. Plockade mynt visas separat. |
| AT-16 | Samma loot, AH-pris 15 s/st och testavgift 5 %. | AH-netto 14 s 25 k/st; bästa kända total 31 s 50 k; 1 G 89 s/h. |
| AT-17 | Vendor 10 s, AH 8 s och avgift 5 %. | Vendor rekommenderas; AH-värde summeras inte med vendorvärdet. |
| AT-18 | AH saknas, är gammalt eller gäller fel region. | Saknat/gammalt pris markeras. Fel region avvisas. Inget påhittat livepris. |
| AT-19 | Även vendorpris är okänt för ett mottaget item. | Resultatet märks som känt delvärde, inte komplett totalsumma. |
| AT-20 | Lootkälla kan inte skiljas mellan Huntress och Patriarch. | Looten ligger under okänd källa och höjer inte en viss mobs säkra värde. |
| AT-21 | Handel/post/quest ökar spelarens saldo; reparation minskar det. | Detta ändrar inte uppmätta plockade mynt från mobloot. |
| AT-22 | Ett redan värderat lootitem säljs till vendor under passet. | Ingen dubbelräkning av dess itemvärde och försäljningspengar. |
| AT-23 | 8 kvalificerade observerade kroppar, 2 ger itemet, totalt 6 enheter. | Lokal drop rate 25 %, inte 75 %. Mängd redovisas separat som 0,75 enheter/kropp. |
| AT-24 | 10 kills, men bara några kroppar lootades. | Alla 10 används inte utan vidare som säker drop-nämnare. |
| AT-25 | Itemdata är initialt nil och laddas senare. | Ingen Lua-error; riktig ikon/tooltip visas när data är klar. Antal ändras inte. |
| AT-26 | Random-suffix-item och soulbound-item mottas. | Full variant bevaras. Otillåten AH-försäljning föreslås inte. |
| AT-27 | En mob saknar lootkatalog. | Timer, kills och observerad loot fungerar; katalogstatus visar att data saknas. |
| AT-28 | Mobben har mycket sällsynt dyr drop i en liten extern datamängd. | Möjlig loot visar källan/underlaget; prognos är märkt och blir inte uppmätt inkomst. |
| AT-29 | `/reload` eller logout mitt i passet. | Sparat pass återkommer pausat/avbrutet; offline-tid och händelser hittas inte på. |
| AT-30 | Timer löper ut i strid; fler kills/loot kommer efter stopp. | Resultatets gräns respekteras och stora fönster stör inte striden. |
| AT-31 | Svenskt addon-UI med engelsk spelklient på Mac. | Mob/lootinsamling fungerar; native tooltip och chatlänkning kan användas. |
| AT-32 | Kör med RestedXP och med helt avstängd extern combatlog. | Grundmätningen fungerar och andra addons beteende ändras inte. |

AT-02 återger en faktisk tidigare mätning som referens för killräkning. XP- och prisexemplen i övriga tester är **syntetiska testvärden**, inte påståenden om mobbarnas aktuella XP, drop rates eller marknadspriser.

## 11. Leverans och definition av klart

Agenten ska lämna:

1. Installerbar, versionsmärkt ZIP med en tydlig addonrot och korrekt TOC för verifierad Forever-version.
2. Läsbar Lua-källkod samt eventuella XML-/databasfiler, utan dolda externa körkrav.
3. README med installation på Mac/Windows, `/grindmeter`, start/paus/stopp, tolkning av värdesiffror samt hur AH-priser och lootkatalog uppdateras.
4. Beskrivning av verkligt implementerade API-val, kill credit-regler, attribueringsbegränsningar och stödda klientspråk.
5. Datakällor, versioner, datum, täckningsgrad och eventuell licensinformation för katalog och AH-integration.
6. Testresultat: automatiska tester och en separat lista över vad som faktiskt verifierats inne i WoW. Saknad åtkomst till spelklienten ska sägas rakt ut.
7. Kort versionshistorik och lista över kvarstående kända begränsningar.

Mac-installation ska beskrivas utifrån spelarens faktiska WoW-installation, normalt:

```text
/Applications/World of Warcraft/_forever_/Interface/AddOns/GrindMeter/
```

P0 är klart när spelaren kan välja en mob, göra ett tio minuters pass, få korrekt avgränsade kills/h och XP/h, se värdet av mottagen loot, använda verkliga itemlänkar samt se katalogens möjliga drops där verifierad data finns. AH-värde kräver en faktiskt fungerande dataväg. Delvis datatäckning ska vara synlig och dokumenterad; ett snyggt resultatfönster får inte dölja att insamling eller data saknas.

## 12. Avgränsningar och nästa steg

Ingår inte i P0: automatiskt spelande, val av attacker, rörelse, lootautomation utöver klientens eget beteende, automatiska AH-köp/försäljningar, en egen molntjänst, kontoinloggning eller en komplett pris-/droppdatabas byggd från grunden.

Lämpliga nästa steg efter en korrekt första version:

- P1: flera uttryckligen valda mobtyper som ett grindmål.
- P1: separat skinning/professionsresultat och tydligare kostnadsuppföljning.
- P1: jämförelse av flera pass med viktning efter faktisk mättid, inte oviktat snitt av timvärden.
- P1: kopierbar rapport med itemlänkar eller sammanfattning.
- P2: karta över egna grindplatser och jämförelse av observerat värde mot katalogprognos.
- P2: frivillig uppdateringslösning för större loot- och priskataloger utanför spelklienten.

## 13. Referenser och verifieringsunderlag

Följande är startpunkter för utvecklaren. Rätt Forever-build och faktisk klientkörning väger tyngre än minne eller dokumentation för en annan spelvariant.

- [Exporterad Blizzard UI-kod för Forever och Retail](https://github.com/reckhou/WoWBlzCode). Repositoryt speglar klientkod; det är inte ett löfte om att spegeln alltid följer senaste build. Den granskade README:n angav Forever 1.60.1.70658, äldre än den lokala installationen vid dokumentets tillkomst.
- [Forever – dokumenterat eventindex](https://github.com/reckhou/WoWBlzCode/blob/main/index/Forever/events.txt). Verifierar förekomst och deklarerade payloads för bland annat XP-, loot-, item- och sessionsevents. Combat-eventet har restriktionsmarkering.
- [Forever – Blizzard-genererad lootdokumentation](https://github.com/reckhou/WoWBlzCode/blob/main/Forever/BlizzardInterfaceCode/Interface/AddOns/Blizzard_APIDocumentationGenerated/LootDocumentation.lua).
- [Forever – Blizzard-genererad itemdokumentation](https://github.com/reckhou/WoWBlzCode/blob/main/Forever/BlizzardInterfaceCode/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua).
- Lokalt kontrollerad installationsmetadata och TOC-exempel 2026-11-12. Kontrollera aktuell build, API-åtkomst och item-/mob-ID:n på nytt före leverans.

Ingen extern drop rate, XP-tabell eller AH-prislista i den tidigare diskussionen ska behandlas som inbyggd sanning eller aktuella marknadsdata. Sådana uppgifter måste få en verifierad källa och ett datum när implementationen byggs.
