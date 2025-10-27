----------------------------------------------------------------------------------
-- Engineer: Ember Ipek
-- 
-- Create Date: 10/26/2025 06:27:27 PM
-- Module Name: FSM - Behavioral
-- 
-- A program that moves a 0 character on the SSEG display.
--    • There is no reset switch in this program. Only the SSEG and SW are used, as well as CLK.
--    • The movement direction and the speed is controlled with the SW(0) and SW(1) switches.
--
-- SW(0) controls the speed as follows:
--    o SW(0)='0' is fast. Precisely one jump per 1 second; approximate timing is not accepted
--    o SW(0)='1' is slow. Precisely one jump per 2 seconds; approximate timing is not accepted
-- SW(1) controls the direction as follows:
--    o SW(1)='0' is moving right: 0 _ _ _ ? _ 0 _ _ ? _ _ 0 _ ? _ _ _ 0 ? 0 _ _ _ …
--    o SW(1)='1' is moving left: _ _ _ 0 ? _ _ 0 _ ? _ 0 _ _ ? 0 _ _ _ ? _ _ _ 0 …
-- SW(2) is the meltdown switch.
--    o SW(2)='0' is normal. It has no effect
--    o SW(2)='1' melts down the character on the current SSEG.
--       • Melt-down is a visual effect; it depicts what happens to the character on one of the 
--         segments as a time sequence.
--       • When the SW(2) is set to '1', the segment-to-segment movement stops and the segment
--         that has the 0 character melts down that character 1 second per cathode. During the
--         meltdown, the "f" cathode melts down, then and "e" melts down, and if the melting is not
--         stopped, the character turns into the last one (upper dash, leaving only "a"
--         cathode turned ON) and one more second later, it totally disappears. It doesn't melt beyond
--         totally blank.
--       ? If during melting, the SW(2) switch is changed back to '0', the melting of that segment stops
--         and the character resumes its moving; however, the "melted" version moves; for example if
--         the melting was 5 seconds, the character melted down to the second from the right (leaving
--         only "a" and "b" cathodes active); this is the character that continues moving (left or right,
--         based on the direction switches).
-- SW(3) is the UNmeltdown switch.
--    o SW(3)='0' is normal. It has no effect
--    o SW(3)='1' does exactly the opposite of what SW(2) does; i.e., it keeps adding dashes until it
--      reaches 0. It doesn't unmelt beyond 0; it stays there.
--    o When SW(3) is flicked back to 0, whatever is on the segment starts moving based on the direction
--      switch…
-- SW(4) implements TURTLE mode as follows:
--    o SW(4)='0' has no effect
--    o SW(4)='1' is TURTLE mode. This mode ignores the SW(0) switch. Everything is identical to what
--      is described, except the movement speed is 3 seconds per move.
--       • TURTLE switch has no effect on meltdown or unmeltdown speeds; the only change in TURTLE mode is
--         the movement speed, which becomes 3 seconds per move (whether left or right).
--       • You must use additional states to implement this functionality.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FSM is
    port(CLK: in std_logic;
         SW: in std_logic_vector(4 downto 0);
         SSEGseg: out std_logic_vector(7 downto 0);
         SSEGdisplay: out std_logic_vector(3 downto 0)
         );
end FSM;

architecture Behavioral of FSM is
type State is(Right, Left, None, Melt, Unmelt, TurtleRight, TurtleLeft, TurtleNone0, TurtleNone1);

signal CurrentState, NextState: State := Right;
signal SegmentsCurr: std_logic_vector(7 downto 0) := "11000000";
signal SegmentsNext: std_logic_vector(7 downto 0) := "11000000";
signal DisplayCurr: std_logic_vector(3 downto 0) := "0111";
signal DisplayNext: std_logic_vector(3 downto 0) := "0111";
signal Mctr: unsigned(31 downto 0) := (others => '0');
constant SpeedCtr: unsigned(31 downto 0) := x"05F5_E100";

begin

-- Implement the speed functionality as "two state transitions". Create a 1 second timer 
-- and in the "fast" mode (1 second per move), jump one state at a time. During the 
-- "slow" mode, the movement does not change, however, you simply have to add another delay
-- state in which you do not move anything. 
process(SW, CurrentState) begin
    NextState <= CurrentState;
    DisplayNext <= DisplayCurr;
    SegmentsNext <= SegmentsCurr;
    case(CurrentState) is
        when Right =>
            if(SW(3) = '1') then
                NextState <= Unmelt;
            elsif(SW(2) = '1') then
                NextState <= Melt;
            elsif(SW(4) = '1' and SW(1) = '0') then
                NextState <= TurtleRight;
            elsif(SW(4) = '1' and SW(1) = '1') then
                NextState <= TurtleLeft;
            elsif(SW(1) = '1') then
                NextState <= Left;
            elsif(SW(0) = '1' and SW(1) = '0') then
                NextState <= None;
                if(DisplayCurr = "0111") then
                    DisplayNext <= "1011";
                elsif(DisplayCurr = "1011") then
                    DisplayNext <= "1101";
                elsif(DisplayCurr = "1101") then
                    DisplayNext <= "1110";
                else
                    DisplayNext <= "0111";
                end if;
            elsif(SW(1) = '0') then
                if(DisplayCurr = "0111") then
                    DisplayNext <= "1011";
                elsif(DisplayCurr = "1011") then
                    DisplayNext <= "1101";
                elsif(DisplayCurr = "1101") then
                    DisplayNext <= "1110";
                else
                    DisplayNext <= "0111";
                end if;
            end if;
        when None =>
            if(SW(3) = '1') then
                NextState <= Unmelt;
            elsif(SW(2) = '1') then
                NextState <= Melt;
            elsif(SW(4) = '0' and SW(1) = '0') then
                NextState <= Right;
            elsif(SW(4) = '0' and SW(1) = '1') then
                NextState <= Left;
            elsif(SW(4) = '1' and SW(1) = '0') then
                NextState <= TurtleRight;
            elsif(SW(4) = '1' and SW(1) = '1') then
                NextState <= TurtleLeft;
            end if;
        when Left =>
            if(SW(3) = '1') then
                NextState <= Unmelt;
            elsif(SW(2) = '1') then
                NextState <= Melt;
            elsif(SW(4) = '1' and SW(1) = '0') then
                NextState <= TurtleRight;
            elsif(SW(4) = '1' and SW(1) = '1') then
                NextState <= TurtleLeft;
            elsif(SW(1) = '0') then
                NextState <= Right;
            elsif(SW(0) = '1' and SW(1) = '1') then
                NextState <= None;
                if(DisplayCurr = "0111") then
                    DisplayNext <= "1110";
                elsif(DisplayCurr = "1011") then
                    DisplayNext <= "0111";
                elsif(DisplayCurr = "1101") then
                    DisplayNext <= "1011";
                else
                    DisplayNext <= "1101";
                end if;
            elsif(SW(0) = '0' and SW(1) = '1') then
                if(DisplayCurr = "0111") then
                    DisplayNext <= "1110";
                elsif(DisplayCurr = "1011") then
                    DisplayNext <= "0111";
                elsif(DisplayCurr = "1101") then
                    DisplayNext <= "1011";
                else
                    DisplayNext <= "1101";
                end if;
            end if;
        when Melt =>
            if(SW(3) = '1') then
                NextState <= Unmelt;
            elsif(SW(2) = '1') then
                if(SegmentsCurr = "11000000") then
                    SegmentsNext <= "11100000";
                elsif(SegmentsCurr = "11100000") then
                    SegmentsNext <= "11110000";
                elsif(SegmentsCurr = "11110000") then
                    SegmentsNext <= "11111000";
                elsif(SegmentsCurr = "11111000") then
                    SegmentsNext <= "11111100";
                elsif(SegmentsCurr = "11111100") then
                    SegmentsNext <= "11111110";
                else
                    SegmentsNext <= "11111111";
                end if;
            elsif(SW(1) = '0') then
                NextState <= Right;
            elsif(SW(1) = '1') then
                NextState <= Left;
            end if;
        when Unmelt =>
            if(SW(3) = '1') then
                if(SegmentsCurr = "11111111") then
                    SegmentsNext <= "11111110";
                elsif(SegmentsCurr = "11111110") then
                    SegmentsNext <= "11111100";
                elsif(SegmentsCurr = "11111100") then
                    SegmentsNext <= "11111000";
                elsif(SegmentsCurr = "11111000") then
                    SegmentsNext <= "11110000";
                elsif(SegmentsCurr = "11110000") then
                    SegmentsNext <= "11100000";
                else
                    SegmentsNext <= "11000000";
                end if;
            elsif(SW(2) = '1') then
                NextState <= Melt;
            elsif(SW(1) = '0') then
                NextState <= Right;
            elsif(SW(1) = '1') then
                NextState <= Left;
            end if;
        when TurtleRight =>
            if(SW(3) = '1') then
                NextState <= Unmelt;
            elsif(SW(2) = '1') then
                NextState <= Melt;
            elsif(SW(4) = '0' and SW(1) = '0') then
                NextState <= Right;
            elsif(SW(4) = '0' and SW(1) = '1') then
                NextState <= Left;
            else
                if(DisplayCurr = "0111") then
                    DisplayNext <= "1011";
                elsif(DisplayCurr = "1011") then
                    DisplayNext <= "1101";
                elsif(DisplayCurr = "1101") then
                    DisplayNext <= "1110";
                else
                    DisplayNext <= "0111";
                end if;
                NextState <= TurtleNone0;
            end if;
        when TurtleLeft =>
            if(SW(3) = '1') then
                NextState <= Unmelt;
            elsif(SW(2) = '1') then
                NextState <= Melt;
            elsif(SW(4) = '0' and SW(1) = '0') then
                NextState <= Right;
            elsif(SW(4) = '0' and SW(1) = '1') then
                NextState <= Left;
            else
                if(DisplayCurr = "0111") then
                    DisplayNext <= "1110";
                elsif(DisplayCurr = "1011") then
                    DisplayNext <= "0111";
                elsif(DisplayCurr = "1101") then
                    DisplayNext <= "1011";
                else
                    DisplayNext <= "1101";
                end if;
                NextState <= TurtleNone0;
            end if;
        when TurtleNone0 =>
            if(SW(3) = '1') then
                NextState <= Unmelt;
            elsif(SW(2) = '1') then
                NextState <= Melt;
            elsif(SW(4) = '0' and SW(1) = '0') then
                NextState <= Right;
            elsif(SW(4) = '0' and SW(1) = '1') then
                NextState <= Left;
            else
                NextState <= TurtleNone1;
            end if;
        when TurtleNone1 =>
            if(SW(3) = '1') then
                NextState <= Unmelt;
            elsif(SW(2) = '1') then
                NextState <= Melt;
            elsif(SW(1) = '1') then
                NextState <= Left;
            elsif(SW(1) = '0') then
                NextState <= Right;
            elsif(SW(4) = '1' and SW(1) = '1') then
                NextState <= Left;
            elsif(SW(4) = '1' and SW(1) = '0') then
                NextState <= Right;
            end if;
        when others =>
    end case;
end process;

process(CLK) begin
    if(rising_edge(CLK)) then
        Mctr <= Mctr + 1;
        if(Mctr = SpeedCtr) then
            CurrentState <= NextState;
            Mctr <= (others => '0');
            
            SSEGseg <= SegmentsNext;
            SegmentsCurr <= SegmentsNext;
            SSEGdisplay <= DisplayNext;
            DisplayCurr <= DisplayNext;
        end if;
    end if;
end process;
end Behavioral;