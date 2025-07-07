library ieee;
use ieee.std_logic_1164.all;

entity sevenDisplay is
    port ( BCD: in std_logic_vector(3 downto 0);
           HEX: out std_logic_vector(6 downto 0));
end sevenDisplay;

architecture segment of sevenDisplay is
begin
     HEX <= "1000000" when (BCD = "0000") else --0
              "1111001" when (BCD = "0001") else --1
              "0100100" when (BCD = "0010") else --2
              "0110000" when (BCD = "0011") else --3
              "0011001" when (BCD = "0100") else --4
              "0010010" when (BCD = "0101") else --5
              "0000010" when (BCD = "0110") else --6
              "1111000" when (BCD = "0111") else --7
              "0000000" when (BCD = "1000") else --8
              "0010000" when (BCD = "1001") else --9
              "1111111";

end segment;

