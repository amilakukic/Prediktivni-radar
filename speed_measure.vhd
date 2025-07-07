library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity speed_measure is
    port(
        clk: in std_logic;
        echo1: in std_logic;  -- Prvi sonic
        echo2: in std_logic;  -- Drugi sonic
        sw0: in std_logic;    -- Switch 0 za kontrolu stanja - kada je 1 onda je to neaktivno stanje a kada je 0 onda je poluaktivno
        sw1: in std_logic; --Za kontrolu uart slanja
        uartPort: out std_logic; --Port za UART
        trig1: out std_logic; -- Trigger za prvi senzor
        trig2: out std_logic; -- Trigger za drugi senzor
        led1: out std_logic;  -- LED za prvi senzor
        led2: out std_logic;  -- LED za drugi senzor
		  led3 : out std_logic;
        hex3, hex2, hex1, hex4: out std_logic_vector(6 downto 0); -- Četiri seven-segment displaya za brzinu
        buzzer: out std_logic -- Buzzer za prekoračenje brzine
    );
end speed_measure;

architecture behavior of speed_measure is

    -- Komponenta sevenDisplay
    component sevenDisplay is
        port(
            BCD : in std_logic_vector(3 downto 0);
            HEX : out std_logic_vector(6 downto 0)
        );
    end component;

--Komponenta RAM-a
component ram_module is
    Port (
        clk              : in  std_logic;
        we               : in  std_logic;
        data_in          : in  std_logic_vector(7 downto 0);
        read_addr        : in  std_logic_vector(7 downto 0);
        data_out         : out std_logic_vector(7 downto 0);     -- from last written address
        data_from_addr   : out std_logic_vector(7 downto 0);     -- from custom address
        first_write_addr : out std_logic_vector(7 downto 0);
        last_write_addr  : out std_logic_vector(7 downto 0)
    );
end component;
-- Komponenta UART za slanje
component uart_sender is
    Port (
        clk             : in  std_logic;
        send_trigger    : in  std_logic;
        ram_data_out    : in  std_logic_vector(7 downto 0);
        ram_last_addr   : in  std_logic_vector(7 downto 0);
        uart_tx_out         : out std_logic;
        ram_addr        : out std_logic_vector(7 downto 0);
        uart_busy       : out std_logic
    );
end component;

    -- Konstante
    constant DISTANCE_BETWEEN_SENSORS : integer := 10; -- Udaljenost između senzora u cm
    constant TRIGGER_WIDTH : integer := 500; -- Širina trigger pulsa
    constant TRIGGER_PERIOD : integer := 7_000_000; -- Period između trigger pulseva (0.14s na 50MHz -> 50 000 000 je 1s)
    constant DETECTION_THRESHOLD : integer := 30; -- Prag detekcije objekta u cm - udaljenost objekta od senzora
    constant SPEED_LIMIT : integer := 50; -- Ograničenje brzine u cm/s (50 cm/s = 1.8 km/h)

    -- Stanja ploče
    type board_state_type is (INACTIVE, SEMI_ACTIVE, ACTIVE);
    signal board_state: board_state_type;

    -- Signali za upravljanje trigger pulsevima
    signal period1, period1_next: integer range 0 to TRIGGER_PERIOD := 0;
    signal period2, period2_next: integer range 0 to TRIGGER_PERIOD := 0;
    
    -- Signali za mjerenje udaljenosti
    signal echo1_width, echo1_width_next: integer := 0;
    signal echo2_width, echo2_width_next: integer := 0;
    signal distance1, distance1_next: integer range 0 to 500 := 500;
    signal distance2, distance2_next: integer range 0 to 500 := 500;
    
    -- Signali za detekciju objekta
    signal object1_detected, object1_detected_next: std_logic := '0';
    signal object2_detected, object2_detected_next: std_logic := '0';
    
    -- Signali za mjerenje vremena
    signal timer, timer_next: integer := 0;
    signal display_timer, display_timer_next: integer := 0; -- Odvojen timer za prikaz
    signal timing_active, timing_active_next: std_logic := '0';
    
    -- Signali za računanje brzine
    signal speed, speed_next: integer range 0 to 999 := 0;
    signal speed_calculated, speed_calculated_next: std_logic := '0';
    
    -- Signali za buzzer kontrolu
    signal speed_exceeded, speed_exceeded_next: std_logic := '0';
    signal buzzer_active, buzzer_active_next: std_logic := '0';
    signal buzzer_timer, buzzer_timer_next: integer := 0;
    
    -- Signali za state machine
    type state_type is (IDLE, WAITING_FOR_FIRST, TIMING, CALCULATE_SPEED, DISPLAY_RESULT);
    signal current_state, next_state: state_type := IDLE;

    -- Dodatni signali za debug
    signal measured_time: integer := 0;

    -- Signali za kontrolu funkcionalnosti
    signal traffic_monitoring_enabled: std_logic;
    signal alarm_enabled: std_logic;

	 --pomocne ledice za uart
		signal uart_led_signal : std_logic := '0';
		signal uart_led_timer : integer := 0;


	-- signali za kontrolu RAM-a
		signal ram_we        : std_logic := '0';
		signal ram_data_in   : std_logic_vector(7 downto 0);
		signal ram_data_out_signal  : std_logic_vector(7 downto 0);
		signal ram_first_addr: std_logic_vector(7 downto 0);
		signal ram_last_addr_signal : std_logic_vector(7 downto 0);
		signal ram_read_addr   : std_logic_vector(7 downto 0) := (others => '0');
signal ram_data_custom : std_logic_vector(7 downto 0);


--Signali za UART
signal uart_send_trigger : std_logic := '0';
signal uart_busy_signal  : std_logic;
signal uart_ram_addr     : std_logic_vector(7 downto 0);
signal uart_tx_signal    : std_logic;

signal uart_sent_in_display : std_logic := '0';

begin

    hex4<="1111111"; --da bude - na pocetku, radi lakseg prikaza na 7segm displeju

    -- Dekodiranje stanja ploče na osnovu switch-a
    -- sw0|sw1 - Stanje
    --  10  | SEMI_ACTIVE (normalno stanje - sve akcije osim slanja podataka)
    --  00  | INACTIVE (bez ikakvih akcija)
    --  11 | ACTIVE - SVE SE RADI
    
process(sw0, sw1)
begin
    if sw0 = '0' and sw1 = '0' then
        board_state <= INACTIVE;
    elsif sw0 = '1' and sw1 = '0' then
        board_state <= SEMI_ACTIVE;
    elsif sw0 = '1' and sw1 = '1' then
        board_state <= ACTIVE;
    else
        board_state <= INACTIVE;
    end if;
end process;



    -- Kontrola funkcionalnosti na osnovu stanja ploče
    traffic_monitoring_enabled <= '0' when board_state = INACTIVE else '1';
    alarm_enabled <= '0' when board_state = INACTIVE else '1';

    -- Glavni proces
    process(clk)
    
begin
    if rising_edge(clk) then

        -- Slanje brzine
        if current_state = DISPLAY_RESULT and uart_sent_in_display = '0' and uart_busy_signal = '0' then
            uart_send_trigger <= '1';
            uart_sent_in_display <= '1';  
        else
            uart_send_trigger <= '0';
        end if;

        -- Reset kad se napusti DISPLAY_RESULT
        if current_state /= DISPLAY_RESULT then
            uart_sent_in_display <= '0';
        end if;

        -- LED signal za UART (led3)
        if uart_send_trigger = '1' then
            uart_led_signal <= '1';
            uart_led_timer <= 0;
        elsif uart_led_signal = '1' then
            if uart_led_timer < 50_000_000 then
                uart_led_timer <= uart_led_timer + 1;
            else
                uart_led_signal <= '0';
            end if;
        end if;

        -- Ažuriranje svih signala
        period1 <= period1_next;
        period2 <= period2_next;
        echo1_width <= echo1_width_next;
        echo2_width <= echo2_width_next;
        distance1 <= distance1_next;
        distance2 <= distance2_next;
        object1_detected <= object1_detected_next;
        object2_detected <= object2_detected_next;
        timer <= timer_next;
        display_timer <= display_timer_next;
        timing_active <= timing_active_next;
        speed <= speed_next;
        speed_calculated <= speed_calculated_next;
        speed_exceeded <= speed_exceeded_next;
        buzzer_active <= buzzer_active_next;
        buzzer_timer <= buzzer_timer_next;
        current_state <= next_state;

    end if;
end process;


   

    -- Generiranje trigger pulseva za oba senzora (samo ako je monitoring omogućen)
    period1_next <= 0 when (period1 = TRIGGER_PERIOD and traffic_monitoring_enabled = '1') else 
                    period1 + 1 when traffic_monitoring_enabled = '1' else
                    period1;
    period2_next <= 0 when (period2 = TRIGGER_PERIOD and traffic_monitoring_enabled = '1') else 
                    period2 + 1 when traffic_monitoring_enabled = '1' else
                    period2;
    
    trig1 <= '1' when (period1 < TRIGGER_WIDTH and traffic_monitoring_enabled = '1') else '0';
    trig2 <= '1' when (period2 < TRIGGER_WIDTH and traffic_monitoring_enabled = '1') else '0';

    -- Mjerenje širine echo pulseva (samo ako je monitoring omogućen)
    echo1_width_next <= echo1_width + 1 when (echo1 = '1' and traffic_monitoring_enabled = '1') else 
                        0 when traffic_monitoring_enabled = '1' else
                        echo1_width;
    echo2_width_next <= echo2_width + 1 when (echo2 = '1' and traffic_monitoring_enabled = '1') else 
                        0 when traffic_monitoring_enabled = '1' else
                        echo2_width;

    -- Računanje udaljenosti (u cm) - samo ako je monitoring omogućen
    distance1_next <= echo1_width / 2900 when (echo1 = '0' and echo1_width > 0 and traffic_monitoring_enabled = '1') else 
                      500 when traffic_monitoring_enabled = '0' else
                      distance1;
    distance2_next <= echo2_width / 2900 when (echo2 = '0' and echo2_width > 0 and traffic_monitoring_enabled = '1') else 
                      500 when traffic_monitoring_enabled = '0' else
                      distance2;

    -- State machine za upravljanje procesom mjerenja
    process(current_state, object1_detected, object2_detected, distance1, distance2, timer, display_timer, speed_calculated, timing_active, speed, buzzer_timer, traffic_monitoring_enabled)
    begin
        -- Default vrijednosti
        next_state <= current_state;
        object1_detected_next <= object1_detected;
        object2_detected_next <= object2_detected;
        timer_next <= timer;
        display_timer_next <= display_timer;
        timing_active_next <= timing_active;
        speed_next <= speed;
        speed_calculated_next <= speed_calculated;
        speed_exceeded_next <= speed_exceeded;
        buzzer_active_next <= buzzer_active;
        buzzer_timer_next <= buzzer_timer;

		ram_we <= '1'; -- na adresi 0 je nula
			ram_data_in <= (others => '0'); -- pocni od adrese 1
		ram_we <= '0';

        -- Ako je monitoring onemogućen, ostani u IDLE stanju
        if traffic_monitoring_enabled = '0' then
            next_state <= IDLE; -- IDLE je pocetno ili reset stanje
            object1_detected_next <= '0';
            object2_detected_next <= '0';
            timer_next <= 0;
            display_timer_next <= 0;
            timing_active_next <= '0';
            speed_calculated_next <= '0';
            speed_next <= 0;
            speed_exceeded_next <= '0';
            buzzer_active_next <= '0';
            buzzer_timer_next <= 0;
        else
            case current_state is
                when IDLE =>
                    -- Reset svih signala
                    object1_detected_next <= '0';
                    object2_detected_next <= '0';
                    timer_next <= 0;
                    display_timer_next <= 0;
                    timing_active_next <= '0';
                    speed_calculated_next <= '0';
                    speed_next <= 0; -- Resetuj brzinu
                    speed_exceeded_next <= '0';
                    buzzer_active_next <= '0';
                    buzzer_timer_next <= 0;
                    next_state <= WAITING_FOR_FIRST;
			ram_we <= '0';

                when WAITING_FOR_FIRST =>
			ram_we <= '0';
                    -- Čekamo da objekat prođe prvi senzor
                    if distance1 < DETECTION_THRESHOLD and object1_detected = '0' then
                        object1_detected_next <= '1';
                        timer_next <= 0;
                        timing_active_next <= '1';
                        next_state <= TIMING;
                    end if;

                when TIMING =>
			ram_we <= '0';
                    -- Brojimo vrijeme dok čekamo drugi senzor
                    if timing_active = '1' then
                        timer_next <= timer + 1;
                    end if;
                    
                    -- Dodaj timeout za slučaj da se objekat ne detektuje na drugom senzoru
                    if timer > 100_000_000 then -- 2 sekunde timeout
                        next_state <= IDLE;
                    elsif distance2 < DETECTION_THRESHOLD and object2_detected = '0' then
                        object2_detected_next <= '1';
                        timing_active_next <= '0';
                        measured_time <= timer; -- Sačuvaj izmjereno vrijeme
                        next_state <= CALCULATE_SPEED;
                    end if;

                when CALCULATE_SPEED =>
                    -- Ispravno računanje brzine
                    if timer > 50_000 then -- Minimalna vrijednost (1ms) da izbjegnemo dijeljenje sa malim brojem
                    
                        -- Formula: brzina = (rastojanje_cm * 50_000_000) / timer_ciklusi
                        speed_next <= (DISTANCE_BETWEEN_SENSORS * 50_000_000) / timer;
                        
                        -- Provjera prekoračenja brzine sa istom formulom
                        if (DISTANCE_BETWEEN_SENSORS * 50_000_000) / timer > SPEED_LIMIT then
                            speed_exceeded_next <= '1';
                            buzzer_active_next <= '1';
                            buzzer_timer_next <= 0;
                        else
                            speed_exceeded_next <= '0';
                            buzzer_active_next <= '0';
                        end if;
                    else
                        -- Ako je vrijeme premalo, brzina je ogromna
                        speed_next <= 999; -- Maksimalna brzina za prikaz
                        speed_exceeded_next <= '1';
                        buzzer_active_next <= '1';
                        buzzer_timer_next <= 0;
                    end if;
                    
                    speed_calculated_next <= '1';
                    display_timer_next <= 0; -- Reset display timer-a

					-- Convert speed to 8-bit vector and write to RAM
					ram_we        <= '1';
					ram_data_in <= std_logic_vector(to_unsigned((DISTANCE_BETWEEN_SENSORS * 50000000) / timer, 8));

		next_state <= DISPLAY_RESULT;

                when DISPLAY_RESULT =>
						  ram_we <= '0';
                    -- Prikazujemo rezultat 5 sekundi pa resetujemo
                    if display_timer < 250_000_000 then -- 5 sekundi na 50MHz
                        display_timer_next <= display_timer + 1;  
                        -- Upravljanje buzzer-om tokom prikaza (3 sekunde aktivnosti)
                        if buzzer_active = '1' and buzzer_timer < 150_000_000 then -- 3 sekunde
                            buzzer_timer_next <= buzzer_timer + 1;
                        else
                            buzzer_active_next <= '0'; -- Isključi buzzer nakon 3 sekunde
                        end if;
                    else
                        next_state <= IDLE;
                    end if;

                when others =>
                    next_state <= IDLE;
            end case;
        end if;
    end process;

    -- LED kontrola (samo ako je monitoring omogućen)
    led1 <= object1_detected when traffic_monitoring_enabled = '1' else '0';
    led2 <= object2_detected when traffic_monitoring_enabled = '1' else '0';

	--Mapiranje RAM modula
	ram_inst: ram_module port map (
    		clk              => clk,
    		we               => ram_we,
    		data_in          => ram_data_in,
    		read_addr        => ram_read_addr,
    		data_out         => ram_data_out_signal,
    		data_from_addr   => ram_data_custom,
    		first_write_addr => ram_first_addr,
    		last_write_addr  => ram_last_addr_signal
	);


	--Mapiranje UART modula
	uart_sender_inst: uart_sender port map (
		 clk           => clk,
		 send_trigger  => uart_send_trigger,
		 ram_data_out  => ram_data_out_signal,
		 ram_last_addr => ram_last_addr_signal,
		 uart_tx_out       => uart_tx_signal,
		 ram_addr      => uart_ram_addr,
		 uart_busy     => uart_busy_signal
	);

	ram_read_addr <= uart_ram_addr;
		 -- Mapiranje seven-segment displaya za prikaz brzine


	seg1_disp: sevenDisplay port map(
		 BCD => std_logic_vector(to_unsigned((to_integer(unsigned(ram_data_out_signal))) mod 10, 4)),
		 --BCD => ram_data_out_signal(3 downto 0),
		 HEX => hex1
	);

	seg2_disp: sevenDisplay port map(
		 BCD => std_logic_vector(to_unsigned((to_integer(unsigned(ram_data_out_signal)) / 10) mod 10, 4)),
		 HEX => hex2
	);

	seg3_disp: sevenDisplay port map(
		 BCD => std_logic_vector(to_unsigned((to_integer(unsigned(ram_data_out_signal)) / 100) mod 10, 4)),
		 HEX => hex3
	);


		--ledica za uart
		 led3 <= uart_led_signal;

		 -- Buzzer kontrola (samo ako su i monitoring i alarm omogućeni)
		 buzzer <= '0' when (current_state = DISPLAY_RESULT and speed_exceeded = '1' and buzzer_active = '1' and alarm_enabled = '1') else '1';

	uartPort <= uart_tx_signal;

end architecture;




