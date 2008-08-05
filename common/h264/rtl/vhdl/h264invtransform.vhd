-------------------------------------------------------------------------
-- H264 inverse core transform - VHDL
-- 
-- Written by Andy Henson
-- Copyright (c) 2008 Zexia Access Ltd
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:
--    * Redistributions of source code must retain the above copyright
--      notice, this list of conditions and the following disclaimer.
--    * Redistributions in binary form must reproduce the above copyright
--      notice, this list of conditions and the following disclaimer in the
--      documentation and/or other materials provided with the distribution.
--    * Neither the name of the Zexia Access Ltd nor the
--      names of its contributors may be used to endorse or promote products
--      derived from this software without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY ZEXIA ACCESS LTD ``AS IS'' AND ANY
-- EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL ZEXIA ACCESS LTD OR ANDY HENSON BE LIABLE FOR ANY
-- DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-------------------------------------------------------------------------

-- This is the inverse core transform for H264, without quantisation
-- this acts on a 4x4 matrix

-- We compute a result matrix X from Cf W CfT
-- where W is the input matrix, X the result matrix
-- Cf is the inverse transform matrix, and CfT its transpose.
-- The vertical part Cf W is done first (opposite order from std, but
-- "mathematically identical" as required by the std)

-- the intermediate matrix F is initially a placeholder for the input coeffs
-- and later the result of Cf W computation
-- FF00 is x=0,y=0,  FF01 is x=1 etc

-- Input: WIN the input matrix X at time TT..TT+15
-- 16 beats of clock output W in reverse zigzag order (than pause of 4 clk min)
-- Outputs: XOUT the output matrix  TT+? to
-- 4 beats of clock horizontal rows; 4 x 9bit residuals each row; little endian order.

-- XST: 409 slices; 149 MHz; Xpower 20mW @ 120MHz

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.ALL;

entity h264invtransform is
	generic (
		LASTADVANCE : integer := 1
	);
	port (
		CLK : in std_logic;					--fast io clock
		ENABLE : in std_logic;				--values input only when this is 1
		WIN : in std_logic_vector(15 downto 0);	--input (reverse zigzag order)
		LAST : out std_logic := '0';		--set when last coeff about to be input
		VALID : out std_logic := '0';				--values output only when this is 1
		XOUT : out std_logic_vector(35 downto 0):= (others => '0')	--4 x 9bit, first px is lsbs
	);
end h264invtransform;

architecture hw of h264invtransform is
	--
	signal g0 : std_logic_vector(15 downto 0) := (others => '0');
	signal g1 : std_logic_vector(15 downto 0) := (others => '0');
	signal g2 : std_logic_vector(15 downto 0) := (others => '0');
	signal g3 : std_logic_vector(15 downto 0) := (others => '0');
	signal ff00 : std_logic_vector(15 downto 0) := (others => '0');
	signal ff01 : std_logic_vector(15 downto 0) := (others => '0');
	signal ff02 : std_logic_vector(15 downto 0) := (others => '0');
	signal ff03 : std_logic_vector(15 downto 0) := (others => '0');
	signal ff10 : std_logic_vector(15 downto 0) := (others => '0');
	signal ff11 : std_logic_vector(15 downto 0) := (others => '0');
	signal ff12 : std_logic_vector(15 downto 0) := (others => '0');
	signal ff13 : std_logic_vector(15 downto 0) := (others => '0');
	signal ff20 : std_logic_vector(15 downto 0) := (others => '0');
	signal ff21 : std_logic_vector(15 downto 0) := (others => '0');
	signal ff22 : std_logic_vector(15 downto 0) := (others => '0');
	signal ff23 : std_logic_vector(15 downto 0) := (others => '0');
	signal ff30 : std_logic_vector(15 downto 0) := (others => '0');
	signal ff31 : std_logic_vector(15 downto 0) := (others => '0');
	signal ff32 : std_logic_vector(15 downto 0) := (others => '0');
	signal ff33 : std_logic_vector(15 downto 0) := (others => '0');
	signal ii33 : std_logic_vector(15 downto 0) := (others => '0');
	signal e0 : std_logic_vector(15 downto 0) := (others => '0');
	signal e1 : std_logic_vector(15 downto 0) := (others => '0');
	signal e2 : std_logic_vector(15 downto 0) := (others => '0');
	signal e3 : std_logic_vector(15 downto 0) := (others => '0');
	signal x0 : std_logic_vector(15 downto 0) := (others => '0');
	signal x1 : std_logic_vector(15 downto 0) := (others => '0');
	signal x2 : std_logic_vector(15 downto 0) := (others => '0');
	signal x3 : std_logic_vector(15 downto 0) := (others => '0');
	--
	signal iww : std_logic_vector(3 downto 0) := b"0000";
	signal ixx : std_logic_vector(2 downto 0) := b"000";
	signal valid1 : std_logic := '0';
	--
	alias xout0 : std_logic_vector(8 downto 0) is XOUT(8 downto 0);
	alias xout1 : std_logic_vector(8 downto 0) is XOUT(17 downto 9);
	alias xout2 : std_logic_vector(8 downto 0) is XOUT(26 downto 18);
	alias xout3 : std_logic_vector(8 downto 0) is XOUT(35 downto 27);
begin
	--
process(CLK)
begin
	if rising_edge(CLK) then
		if ENABLE='1' or iww /= 0 then
			iww <= iww + 1;
		end if;
		if iww=15 or ixx /= 0 then
			ixx <= ixx + 1;
		end if;
	end if;
	if rising_edge(CLK) then
		--input: the order shown here is reverse
		--(it starts at the end and works backwards for reverse zigzag)
		if iww = 15 then
			--ROW0&COL0 ; process col 0
			g0 <= WIN + ff20;
			g1 <= WIN - ff20;
			g2 <= (ff10(15)&ff10(15 downto 1)) - ff30;
			g3 <= ff10 + (ff30(15)&ff30(15 downto 1));
			ff01 <= g0 + g3;
			ff11 <= g1 + g2;
			ff21 <= g1 - g2;
			ff31 <= g0 - g3;
		elsif iww = 14 then
			--ROW0&COL1 ; process col 1
			g0 <= WIN + ff21;
			g1 <= WIN - ff21;
			g2 <= (ff11(15)&ff11(15 downto 1)) - ff31;
			g3 <= ff11 + (ff31(15)&ff31(15 downto 1));
		elsif iww = 13 then
			ff10 <= WIN;	--ROW1&COL0 
		elsif iww = 12 then
			ff20 <= WIN;	--ROW2&COL0 
		elsif iww = 11 then
			ff11 <= WIN;	--ROW1&COL1 
			ff02 <= g0 + g3;
			ff12 <= g1 + g2;
			ff22 <= g1 - g2;
			ff32 <= g0 - g3;
		elsif iww = 10 then
			--ROW0&COL2 ; process col 2
			g0 <= WIN + ff22;
			g1 <= WIN - ff22;
			g2 <= (ff12(15)&ff12(15 downto 1)) - ff32;
			g3 <= ff12 + (ff32(15)&ff32(15 downto 1));
			ff03 <= g0 + g3;
			ff13 <= g1 + g2;
			ff23 <= g1 - g2;
			ff33 <= g0 - g3;
		elsif iww = 9 then
			--ROW0&COL3 ; process col 3 
			g0 <= WIN + ff23;
			g1 <= WIN - ff23;
			g2 <= (ff13(15)&ff13(15 downto 1)) - ii33;
			g3 <= ff13 + (ii33(15)&ii33(15 downto 1));
		elsif iww = 8 then
			ff12 <= WIN;	--ROW1&COL2 
		elsif iww = 7 then
			ff21 <= WIN;	--ROW2&COL1 
		elsif iww = 6 then
			ff30 <= WIN;	--ROW3&COL0
		elsif iww = 5 then
			ff31 <= WIN;	--ROW3&COL1 
		elsif iww = 4 then
			ff22 <= WIN;	--ROW2&COL2 
		elsif iww = 3 then
			ff13 <= WIN;	--ROW1&COL3 
		elsif iww = 2 then
			ff23 <= WIN;	--ROW2&COL3 
		elsif iww = 1 then
			ff32 <= WIN;	--ROW3&COL2 
		elsif iww = 0 then
			ii33 <= WIN;	--ROW3&COL3;
		end if;
		if iww=15-LASTADVANCE-1 then
			LAST <= '1';
		else
			LAST <= '0';
		end if;
		--
		--output stages (start immediately after input)...
		if ixx = 1 then
			ff00 <= g0 + g3;	--complete the input stage
			ff10 <= g1 + g2;
			ff20 <= g1 - g2;
			ff30 <= g0 - g3;
		elsif ixx = 2 then
			e0 <= ff00 + ff02;		--row 0
			e1 <= ff00 - ff02;
			e2 <= (ff01(15)&ff01(15 downto 1)) - ff03;
			e3 <= ff01 + (ff03(15)&ff03(15 downto 1));
		elsif ixx = 3 then
			valid1 <= '1';
			e0 <= ff10 + ff12;		--row 1
			e1 <= ff10 - ff12;
			e2 <= (ff11(15)&ff11(15 downto 1)) - ff13;
			e3 <= ff11 + (ff13(15)&ff13(15 downto 1));
			--XOUT <= (see below)
		elsif ixx = 4 then
			e0 <= ff20 + ff22;		--row 2
			e1 <= ff20 - ff22;
			e2 <= (ff21(15)&ff21(15 downto 1)) - ff23;
			e3 <= ff21 + (ff23(15)&ff23(15 downto 1));
			--XOUT <= (see below)
		elsif ixx = 5 then
			e0 <= ff30 + ff32;		--row 3
			e1 <= ff30 - ff32;
			e2 <= (ff31(15)&ff31(15 downto 1)) - ff33;
			e3 <= ff31 + (ff33(15)&ff33(15 downto 1));
			--XOUT <= (see below)
		--elsif ixx = 6 then
			--XOUT <= (see below)
		elsif ixx=7 then
			valid1 <= '0';
		end if;
		if ixx /= 0 then
			x0 <= (e0 + e3) + 32;	--32 is rounding factor
			x1 <= (e1 + e2) + 32;
			x2 <= (e1 - e2) + 32;
			x3 <= (e0 - e3) + 32;
		end if;
		if ixx /= 0 then
			--clip to XOUT 4 segments
			--NOTE: this is optional, not in standard (clipping after reconstruct)
			if x0(15)=x0(14)  then 
				xout0 <= x0(14 downto 6);
			elsif x0(15)='0' then
				xout0 <= b"011111111";	--clip max
			else
				xout0 <= b"100000000";	--clip min
			end if;
			if x1(15)=x1(14) then 
				xout1 <= x1(14 downto 6);
			elsif x1(15)='0' then
				xout1 <= b"011111111";	--clip max
			else
				xout1 <= b"100000000";	--clip min
			end if;
			if x2(15)=x2(14) then 
				xout2 <= x2(14 downto 6);
			elsif x2(15)='0' then
				xout2 <= b"011111111";	--clip max
			else
				xout2 <= b"100000000";	--clip min
			end if;
			if x3(15)=x3(14) then 
				xout3 <= x3(14 downto 6);
			elsif x3(15)='0' then
				xout3 <= b"011111111";	--clip max
			else
				xout3 <= b"100000000";	--clip min
			end if;
		end if;
		VALID <= valid1;
	end if;
end process;
	--
end hw; --of h264invtransform;
