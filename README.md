# Prediktivni-radar

Projekat na predmetu Projektovanje i sinteza digitalnih sistema na Elektrotehničkom fakultetu u Sarajevu

# Opis projekta

Ovaj projekat predstavlja dio sistema za adaptivno upravljanje saobraćajem, razvijenog korištenjem dvije FPGA ploče koje međusobno komuniciraju putem UART protokola.
Ploča A ima ulogu prikupljanja podataka o brzini kretanja vozila pomoću dva ultrazvučna senzora, detekciju prekoračenja brzine i slanja podataka Ploči B na obradu i donošenje odluka.

# Ciljevi Ploče A
- Izmjeriti brzinu kretanja vozila korištenjem dva ultrazvučnih senzora.

- Pohraniti izmjerene podatke o brzinama u memoriju.

- Aktivirati alarm (buzzer) u slučaju prekoračenja definisane brzine.

* Omogućiti pouzdanu komunikaciju s Pločom B putem UART-a.

- Upravljati stanjima ploče preko switcheva.

# Stanja Ploče A
Ploča A može biti u jednom od tri stanja:

- Neaktivno stanje — nijedna akcija se ne smije izvršavati.

- Aktivno stanje — omogućeno izvršavanje svih akcija.

- Polu-aktivno stanje — omogućene sve akcije osim slanja podataka Ploči B.

Stanja se biraju pomoću switcheva na FPGA ploči.

 # Funkcionalnosti
## Mjerenje brzine
Brzina vozila se izračunava na osnovu vremena prolaska između dva ultrazvučna senzora koristeći formulu:

v = (d × f_clk) / t

Gdje je:

- d = 10cm, udaljenost između senzora

- fclk = 50MHz

- t = timer

Iznenadna promjena vrijednosti na ultrazvučnim senzorima označava prolazak vozila.

## Alarm za prekoračenje brzine
Ako izmjerena brzina pređe unaprijed definisanu vrijednost (50 cm/s), aktivira se buzzer senzor koji emituje zvuk u trajanju od 3 sekunde.

## Slanje podataka Ploči B
Kada je Ploča A u aktivnom stanju, podaci pohranjeni u memoriji se šalju Ploči B putem UART komunikacije.

# Uputstvo za korištenje
- Podesiti switcheve na ploči na željeno stanje (Switch1/Switch0):

  - 00, 10 — Neaktivno

  - 01 — Polu-aktivno

  - 11 — Aktivno

- Postaviti ultrazvučne senzore i buzzer na odgovarajuće pinove i pokrenuti sistem.

- Definisati prag za prekoračenje brzine.

- Testirati sistem prolaskom vozila (ili simulacijom prolaza).

# Tehnologije korištene
- FPGA ploče

- Ultrazvučni senzori

- Buzzer senzor

- UART komunikacija

- VHDL





# Članovi tima:

- [Sara Kardaš](https://github.com/skardas1)

- [Amila Kukić](https://github.com/amilakukic)

- [Harun Goralija](https://github.com/goralija)

- [Nedim Kalajdžija](https://github.com/nkalajdzij1)

##

© 2025 Sara Kardaš & Amila Kukić & Harun Goralija & Nedim Kalajdžija

Faculty of Electrical Engineering

University of Sarajevo
