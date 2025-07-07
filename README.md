# Prediktivni-radar

Projekat na predmetu Projektovanje i sinteza digitalnih sistema na Elektrotehničkom fakultetu u Sarajevu

# Opis projekta

Ploˇca A ima mogu ́cnost biti u sljede ́ca 3 stanja:

• Neaktivno stanje - niti jedna akcija koju ploˇca moˇze poduzeti ne smije biti realizo-
vana

• Aktvno stanje - ploˇca moˇze poduzeti sve akcije
• Polu-aktivno stanje - ploˇca moˇze poduzeti sve akcije osim slanja podataka drugoj
ploˇci
Stanja se definiˇsu putem switcheva na FPGA ploˇci.
Ploˇca A moˇze poduzeti sljede ́ce akcije:
• Snimanje saobra ́caja
• Dizanje alarma (potjenice) u sluˇcaju prekoraˇcenja brzine
• Slanje podataka ploˇci B
Snimanje saobra ́caja je potrebno izvesti koriˇstenjem dva ultra-sonic senzora tako da
se brzina raˇcuna, uzorkovanjem na ova dva senzora u trenutku t1 i t2 (svaki senzor prati
po jednu vrijednost t), sa formulom v =
d
t2−t1
gdje d predstavlja distancu izmedu dva
senzora. Iznenadne promjene vrijednosti na ultrasonicu su znak da se desio prolaz vozila.
Dizanje alarma (potjernice) se realizuje koriˇstenjem buzzer senzora koji  ́ce se ukljuˇciti u
sluˇcaju prekoraˇcene brzine i ispuˇstati zvuk 3 sekunde. Potrebno je da pri izradi projekta
se definiˇse prekoraˇcena brzina.
Slanje podataka ploˇci B se realizira koriˇstenjem nekog dugmeta koje  ́ce na klik poslati
podatke spremljene u memorijski spremnik putem ethernet protokola ili nekog drugog
protokola ploˇci B.


## Clanovi tima:

- [Sara Kardaš](https://github.com/skardas1)

- [Amila Kukić](https://github.com/amilakukic)

- [Harun Goralija](https://github.com/goralija)

- [Nedim Kalajdžija](https://github.com/nkalajdzij1)

##

© 2025 Sara Kardaš & Amila Kukić & Harun Goralija & Nedim Kalajdžija

Faculty of Electrical Engineering

University of Sarajevo
