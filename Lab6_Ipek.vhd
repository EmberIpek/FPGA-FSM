----------------------------------------------------------------------------------
-- Engineer: Ember Ipek
-- 
-- Create Date: 10/20/2025 01:38:51 PM
-- 
-- A program that generates moving 11s (or 111, 1111, depending on SW(1 downto 0)):
--  • SW(1 downto 0)="00" completely turns OFF all LEDs
--  • SW(1 downto 0)="01" generates the moving 11s pattern
--  • SW(1 downto 0)="10" generates the moving 111s pattern
--  • SW(1 downto 0)="11" generates the moving 1111s pattern
--  • Note: "11" means two LEDs are ON ON consecutively. "111" ? ON ON ON, etc.
--  • When the patterns get close to the left side, they could "vanish" one LED at a time.
--  • When all LEDs vanish on the left side, the pattern cycles back to starting from the left.
--  • Movement speed -to the left- can be approximately 0.5s per jump.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Lab6_Ipek is
    port(SW : in std_logic_vector(1 downto 0);
         CLK : in std_logic;
         LED : out std_logic_vector(15 downto 0)
         );
end Lab6_Ipek;

architecture Behavioral of Lab6_Ipek is
signal Mctr: unsigned(31 downto 0);
signal CurrentState, NextState: std_logic_vector(15 downto 0);
signal PrevSW: std_logic_vector(1 downto 0);
-- Movement speed -to the left- can be approximately 0.5s per jump.
constant WhenToChange: unsigned(31 downto 0):= x"02FA_F080";
begin

LED <= CurrentState;

process(SW, CurrentState)
begin
    -- SW(1 downto 0)="00" completely turns OFF all LEDs
    if(SW = "00") then
        NextState <= x"0000";
    -- SW(1 downto 0)="01" generates the moving 11s pattern
    elsif(SW = "01") then
        if(CurrentState = x"0000" or CurrentState = x"C000") then
            NextState <= x"0003";
        elsif(CurrentState = x"0003") then
            NextState <= x"000C";
        elsif(CurrentState = x"000C") then
            NextState <= x"0030";
        elsif(CurrentState = x"0030") then
            NextState <= x"00C0";
        elsif(CurrentState = x"00C0") then
            NextState <= x"0300";
        elsif(CurrentState = x"0300") then
            NextState <= x"0C00";
        elsif(CurrentState = x"0C00") then
            NextState <= x"3000";
        else
            NextState <= x"C000";
        end if;
    -- SW(1 downto 0)="10" generates the moving 111s pattern
    elsif(SW = "10") then
        if(CurrentState = x"0000" or CurrentState = x"8000") then
            NextState <= x"0007";
        elsif(CurrentState = x"0007") then
            NextState <= x"0038";
        elsif(CurrentState = x"0038") then
            NextState <= x"01C0";
        elsif(CurrentState = x"01C0") then
            NextState <= x"0E00";
        elsif(CurrentState = x"0E00") then
            NextState <= x"7000";
        else
            NextState <= x"8000"; 
        end if;
    -- SW(1 downto 0)="11" generates the moving 1111s pattern
    else
        if(CurrentState = x"0000" or CurrentState = x"F000") then
            NextState <= x"000F";
        elsif(CurrentState = x"000F") then
            NextState <= x"00F0";
        elsif(CurrentState = x"00F0") then
            NextState <= x"0F00";
        else
            NextState <= x"F000";
        end if;
    end if;
end process;

process(Clk)
begin
    if(rising_edge(Clk)) then
        Mctr <= Mctr + 1;
        -- reset LEDs when SW changes
        if(not(PrevSW = SW)) then
            CurrentState <= x"0000";
        end if;
        -- Movement speed -to the left- can be approximately 0.5s per jump.
        if(Mctr = WhenToChange) then
            CurrentState <= NextState;
            Mctr <= x"00000000";
        end if;
        PrevSW <= SW;
    end if;
end process;

end Behavioral;
