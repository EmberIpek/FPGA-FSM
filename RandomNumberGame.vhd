----------------------------------------------------------------------------------
-- Engineer: Ember Ipek
-- 
-- Create Date: 11/09/2025 08:23:35 PM
-- Module Name: RandomNumberGame - Behavioral
-- 
-- A game that shows random numbers on the leftmost SSEG segment one
-- second at a time. 1 second timing must be precise.
--    • Each displayed number is between 1 and 13, displayed as a hex digit (1, 2, …, 9, A, B, C, D).
--    • Use the LSB 4 bits of the 24-bit LFSR to pick the random number, which will guarantee excellent
--      randomness. Of course, the LFSR may give you a 0, 14, or 15, since a 4-bit number is between 0-15.
--      The best thing to do in this case is to ignore (skip) that number and get a new one.
--    • Each time the FPGA shows a number, the user has 1 second to flick the correct switch up; the user's
--      time runs out when the next random number is displayed. For example, if the segment shows B, the user
--      is supposed to turn SW(11) ON, while all other switches are OFF, since the hex B means decimal 11.
--    • When the next number shows up (say A), the user is supposed to turn OFF the previous switch and turn
--      ON the switch corresponding to the new number - SW(10) in this case, since "A" in hex is decimal 10.
--    • Turning ON the correct switch adds 1 point to user score. Otherwise, score stays the same.
--    • The goal of the game is to get the highest Score.
--    • The user score will be tracked by a 4 bit unsigned variable called Score.
--    • When the user pushes down BTNC, the Score is reset to 0 and the game begins.
--    • The value of the Score will be shown in "gas gauge" style on the LEDs as follows:
--        o 0 is all blank LEDs
--        o 1 is one lit LED on the left: ooooooooooooooo•
--        o 2 is two lit LEDs:            oooooooooooooo•• etc
--    • The computer displays 15 numbers and the game stops after the 15th number. The Score (between 0
--      and 15) will stay on the LEDs indefinitely until the RESET button pushed and the Score is set back to 0
--      and the game begins again.
--    • To indicate that the game is over, the final score on the LEDs must be flashing at a 1 second period (0.5
--      second ON, 0.5 second OFF).
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RandomNumberGame is
    port(CLK: in std_logic;
         RST: in std_logic;
         SW: in std_logic_vector(15 downto 0);
         LED: out std_logic_vector(15 downto 0);
         SSEG_out: out std_logic_vector(7 downto 0) := x"FF";
         SSEG_out_loc: out std_logic_vector(3 downto 0) := x"7"
         );
end RandomNumberGame;

architecture Behavioral of RandomNumberGame is

type GameState is (START, NEXTNUM, GAMEOVER);
signal CurrentState, NextState: GameState := GAMEOVER;

signal Num: unsigned(3 downto 0);
signal Score: unsigned(3 downto 0);
signal Round: unsigned(3 downto 0);
signal MCtr: unsigned(31 downto 0);
signal LEDOn: std_logic := '1';
signal LFSR: std_logic_vector(23 downto 0) := x"AAAAAA";
constant SpeedCtr: unsigned(31 downto 0) := x"05F5_E100";

--type HexDigits is range 0 to 15;
type sseg_digits is array (0 to 15) of std_logic_vector(7 downto 0);
constant digit_table: sseg_digits := (
    "11000000",  -- 0
    "11111001",  -- 1 
    "10100100",  -- 2 
    "10110000",  -- 3
    "10011001",  -- 4
    "10010010",  -- 5
    "10000010",  -- 6
    "11111000",  -- 7 
    "10000000",  -- 8
    "10011000",  -- 9 
    "10001000",  -- A
    "10000011",  -- b 
    "11000110",  -- C 
    "10100001",  -- d 
    "10000110",  -- E 
    "10001110"   -- F
);
signal SelectedNumber: integer range 0 to 15;

begin
process(CLK) begin
    if(rising_edge(CLK)) then
        MCtr <= MCtr + 1;
        LFSR <= not(LFSR(23) xor LFSR(22) xor LFSR(21) xor LFSR(16)) & LFSR(23 downto 1);
        
        if(RST = '1') then
            Round <= "0000";
            LFSR <= x"AAAAAA";
            Score <= "0000";
--            Score <= "0000";
--            LED <= x"0000";
--            Round <= "0000";
            NextState <= START;
        else
            if(MCtr = SpeedCtr) then
                -- reset MCtr after 1 s
                MCtr <= (others => '0');
                if(not(CurrentState = GAMEOVER)) then
                    NextState <= NEXTNUM;
                else
                    NextState <= GAMEOVER;
                end if;
                -- the LFSR may give you a 0, 14, or 15, since a 4-bit number is between 0-15.
                -- The best thing to do in this case is to ignore (skip) that number and get a new one.
                if unsigned(LFSR(3 downto 0)) > 0 and unsigned(LFSR(3 downto 0)) < 14 then
                    Num <= unsigned(LFSR(3 downto 0));
                    SelectedNumber <= TO_INTEGER(Num);
                end if;
                -- Turning ON the correct switch adds 1 point to user score.
                -- Otherwise, score stays the same.
                if(SW = std_logic_vector(to_unsigned(2 ** SelectedNumber, 16))) then
                    Score <= Score + 1;
                end if;
                if(CurrentState = NEXTNUM) then
                    Round <= Round + 1;
                end if;
                if(Round = "1110") then
                    NextState <= GAMEOVER;
                end if;
            end if;
        end if;
        CurrentState <= NextState;
    end if;
end process;

process(CurrentState, MCtr, SW, Num, Score, LEDOn) begin
    NextState <= CurrentState;
    case CurrentState is
        when START =>
            LED <= x"0000";
            SSEG_out <= x"FF";
            LEDOn <= '1';
        when NEXTNUM =>
            -- show random numbers on the leftmost SSEG segment one second at a time
            SSEG_out <= digit_table(SelectedNumber);
            SSEG_out_loc <= "0111";
            -- The value of the Score will be shown in "gas gauge" style on the LEDs
            LED <= std_logic_vector(shift_left(TO_UNSIGNED(1, 16), TO_INTEGER(Score)) - 1);
        when GAMEOVER =>
            -- Flash LEDs
            -- To indicate that the game is over, the final score on the LEDs must be flashing at a
            -- 1 second period (0.5 second ON, 0.5 second OFF).
            if((MCtr = SpeedCtr/2) or (MCtr = SpeedCtr)) then
                if(LEDOn = '1') then
                    LED <= x"0000";
                    LEDOn <= '0';
                else
                    LED <= std_logic_vector(shift_left(TO_UNSIGNED(1, 16), TO_INTEGER(Score)) - 1);
                    LEDOn <= '1';
                end if;
            end if;
    end case;
end process;

end Behavioral;
