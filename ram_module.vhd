library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ram_module is
    Port (
        clk              : in  std_logic;
        we               : in  std_logic;                               -- write enable
        data_in          : in  std_logic_vector(7 downto 0);            -- input data
        read_addr        : in  std_logic_vector(7 downto 0);            -- external read address
        data_out         : out std_logic_vector(7 downto 0);            -- value at last written address
        data_from_addr   : out std_logic_vector(7 downto 0);            -- value from specific address
        first_write_addr : out std_logic_vector(7 downto 0);            -- first write address
        last_write_addr  : out std_logic_vector(7 downto 0)             -- last write address
    );
end ram_module;

architecture Behavioral of ram_module is
    type ram_type is array (0 to 255) of std_logic_vector(7 downto 0);
    signal ram : ram_type := (others => (others => '0'));

    signal first_written : boolean := false;
    signal first_addr    : std_logic_vector(7 downto 0) := (others => '0');
    signal last_addr     : std_logic_vector(7 downto 0) := (others => '0');
    signal write_ptr     : std_logic_vector(7 downto 0) := (others => '0'); -- internal write pointer
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                -- Write data to internal write pointer
                ram(to_integer(unsigned(write_ptr))) <= data_in;

                -- Record addresses
                last_addr <= write_ptr;
                if not first_written then
                    first_addr <= write_ptr;
                    first_written <= true;
                end if;

                -- Increment with wraparound
                if write_ptr = "11111111" then
                    write_ptr <= (others => '0');
                else
                    write_ptr <= std_logic_vector(unsigned(write_ptr) + 1);
                end if;
            end if;

            -- Always read from last written address and custom address
            data_out       <= ram(to_integer(unsigned(last_addr)));
            data_from_addr <= ram(to_integer(unsigned(read_addr)));
        end if;
    end process;

    -- Output address info
    first_write_addr <= first_addr;
    last_write_addr  <= last_addr;
end Behavioral;
