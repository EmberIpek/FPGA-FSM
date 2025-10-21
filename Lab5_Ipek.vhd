----------------------------------------------------------------------------------
-- Engineer: Ember Ipek
-- 
-- Create Date: 10/05/2025 06:26:59 PM
-- Module Name: Lab5_Ipek - Behavioral
--
-- A program that creates a "bouncing LED" pattern on the 16 LEDs as follows:
-- • The pattern starts with the LED15 being ON, all other LEDs OFF
-- • A little bit later, LED15 turns off and LED14 turns ON (i.e., LED15 ? LED14).
-- • The pattern continues as: LED15 ? LED14 ? LED13 ? LED12 ? …
-- • At any point, only a single LED is ON.
-- • The transition times for (LED15 ? LED14), (LED14 ? LED13), and (LED13 ? LED12),
--   etc. are the same. This pattern continues all the way to … ? LED2 ? LED1 ? LED0.
-- • When the rightmost edge (LED0) turns ON, the pattern reverses (LEDs "bounce" off the
--   edge) and the repetition becomes LED0 ? LED1 ? LED2 ? LED3, …
-- • When we reach LED15 (after LED14 ? LED15), the LEDs bounce again and the pattern
--   goes back to LED15 ? LED14 ? LED13 ? …
-- • The LED-to-LED transition speed is controlled by five buttons
--    o BTNC resets the pattern back to LED15, gong LED15 ? LED14 ? …
--    o BTNC is not sticky. However, the other four buttons are sticky.
--    o BTND turns off the LEDs completely
--    o BTNL is the lowest speed; full round-trip (LED15 back to LED15) in approximately 5
--      seconds
--    o BTNR is the medium speed, full round-trip is 1 second
--    o BTNU is the highest speed, full round-trip is ½ seconds
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Lab5_Ipek is
    port(CLK : in std_logic;
         LED : out std_logic_vector(15 downto 0);
         BTNC : in std_logic;
         BTND : in std_logic;
         BTNL : in std_logic;
         BTNR : in std_logic;
         BTNU : in std_logic
         );
end Lab5_Ipek;

architecture Behavioral of Lab5_Ipek is

-- run code ONLY when Mctr changes from 0 to 1
signal Mctr, Mctr_old : unsigned(31 downto 0);
signal forward : std_logic;
signal which_LED : std_logic_vector(15 downto 0);
signal speed : std_logic_vector(1 downto 0);

begin

-- set speed signals
-- BTND turns off the LEDs completely
-- BTNL: full round-trip in approximately 5 seconds
-- BTNR: full round-trip is 1 second
-- BTNU: full round-trip is ½ seconds
speed <= "01" when BTNL = '1' else
         "10" when BTNR = '1' else
         "11" when BTNU = '1' else
         "00" when BTND = '1';
         

process(CLK) begin
    if(rising_edge(CLK)) then
        -- CLK = 10ns
        -- Mctr(x) = 2^x(20) ns
        Mctr_old <= Mctr;
        Mctr <= Mctr + 1;
        
        -- BTND: turn LEDs off
        if BTND = '1' then
            LED <= x"0000";
            which_LED <= x"0000";
            forward <= '1';
        
        -- BTNC: reset
        elsif BTNC = '1' then
            which_LED <= x"8000";
            forward <= '1';
        
        elsif BTNR = '1' then
            LED <= x"0000";
            which_LED <= x"8000";
            forward <= '1';
            
        elsif BTNL = '1' then
            LED <= x"0000";
            which_LED <= x"8000";
            forward <= '1';
            
        elsif BTNU = '1' then
            LED <= x"0000";
            which_LED <= x"8000";
            forward <= '1';
        
        else
            case speed is
                -- 5s/30 = 166.7ms = 166.7 * 2^20 ns = 2^3(20) * 2^20 ns
                -- BTNL Mctr = 23
                when "01" =>
                    if Mctr(23) = '1' and Mctr_old(23) = '0' then
                        if forward = '1' then
                            if which_LED = x"0001" then
                                forward <= '0';
                                which_LED <= which_LED(14 downto 0) & '0';
                            else
                                which_LED <= '0' & which_LED(15 downto 1);
                            end if;
                        else
                            if which_LED = x"8000" then
                                forward <= '1';
                                which_LED <= '0' & which_LED(15 downto 1);
                            else
                                which_LED <= which_LED(14 downto 0) & '0';
                            end if;
                        end if;
                    end if;
                    
                -- 1s/30 = 33.3ms = 33.3 * 2^20 ns = 2^1(20) * 2^20 ns
                -- BTNR Mctr = 21
                when "10" => 
                    if Mctr(21) = '1' and Mctr_old(21) = '0' then
                        if forward = '1' then
                            if which_LED = x"0001" then
                                forward <= '0';
                                which_LED <= which_LED(14 downto 0) & '0';
                            else
                                which_LED <= '0' & which_LED(15 downto 1);
                            end if;
                        else
                            if which_LED = x"8000" then
                                forward <= '1';
                                which_LED <= '0' & which_LED(15 downto 1);
                            else
                                which_LED <= which_LED(14 downto 0) & '0';
                            end if;
                        end if;
                    end if;
                
                -- .5s/30 = 16.7ms = 16.7 * 2^20 ns = 2^0(20) * 2^20 ns
                -- BTNU Mctr = 20
                when "11" =>
                    if Mctr(20) = '1' and Mctr_old(20) = '0' then
                        if forward = '1' then
                            if which_LED = x"0001" then
                                forward <= '0';
                                which_LED <= which_LED(14 downto 0) & '0';
                            else
                                which_LED <= '0' & which_LED(15 downto 1);
                            end if;
                        else
                            if which_LED = x"8000" then
                                forward <= '1';
                                which_LED <= '0' & which_LED(15 downto 1);
                            else
                                which_LED <= which_LED(14 downto 0) & '0';
                            end if;
                        end if;
                    end if;
                    
                when others =>
                    null;
            end case;
            LED <= which_LED;
        end if;
        
    end if;
end process;

end Behavioral;
