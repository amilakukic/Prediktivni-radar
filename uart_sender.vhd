library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_sender is
    Port (
        clk             : in  std_logic;
        send_trigger    : in  std_logic;  -- High to start sending
        ram_data_out    : in  std_logic_vector(7 downto 0);
        ram_last_addr   : in  std_logic_vector(7 downto 0);
        uart_tx_out     :out std_logic;
        ram_addr        : out std_logic_vector(7 downto 0);
        uart_busy       : out std_logic   -- '1' while sending is ongoing
    );
end uart_sender;

architecture Behavioral of uart_sender is

    component UART_TX is
        generic (
            g_CLKS_PER_BIT : integer := 434  -- For 115200 baud @ 50MHz
        );
        port (
            i_Clk       : in  std_logic;
            i_TX_DV     : in  std_logic;
            i_TX_Byte   : in  std_logic_vector(7 downto 0);
            o_TX_Active : out std_logic;
            o_TX_Serial : out std_logic;
            o_TX_Done   : out std_logic
        );
    end component;

    type state_type is (IDLE, READ, SEND, WAIT_DONE, DONE);
    signal state : state_type := IDLE;

    signal tx_data      : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_dv        : std_logic := '0';
    signal tx_done      : std_logic := '0';
    signal tx_active    : std_logic := '0';
    signal read_address : std_logic_vector(7 downto 0) := (others => '0');
    signal sending      : std_logic := '0';

begin

    -- UART transmitter instance
    uart_tx_inst: UART_TX
        generic map (
            g_CLKS_PER_BIT => 434  -- for 50MHz / 115200 baud
        )
        port map (
            i_Clk       => clk,
            i_TX_DV     => tx_dv,
            i_TX_Byte   => tx_data,
            o_TX_Active => tx_active,
            o_TX_Serial => uart_tx_out,
            o_TX_Done   => tx_done
        );

    -- Output current RAM address and busy signal
    ram_addr   <= read_address;
    uart_busy  <= sending;

    -- FSM to control sending
    process(clk)
    begin
        if rising_edge(clk) then
            case state is
                when IDLE =>
                    tx_dv        <= '0';
                    read_address <= (others => '0');
                    sending      <= '0';
                    if send_trigger = '1' then
                        sending <= '1';
                        state <= READ;
                    end if;

                when READ =>
                    tx_data <= ram_data_out;
                    tx_dv   <= '1';
                    state   <= SEND;

                when SEND =>
                    tx_dv <= '0';  -- Pulse DV for one clock
                    state <= WAIT_DONE;

                when WAIT_DONE =>
                    if tx_done = '1' then
                        if read_address = ram_last_addr then
                            state <= DONE;
                        else
                            read_address <= std_logic_vector(unsigned(read_address) + 1);
                            state <= READ;
                        end if;
                    end if;

                when DONE =>
                    sending <= '0';
                    state   <= IDLE;

                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;

end Behavioral;



