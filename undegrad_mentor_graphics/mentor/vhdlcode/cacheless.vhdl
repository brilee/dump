-----------------------------------------------------
-- highly unoptimized. Could save one cycle on back to back ops
-- change for pipelined version - unless it doesn't matter for CPI
-- which it might not..



library ieee ;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use std.textio.all;


-----------------------------------------------------

entity no_cache is port(	
	clk, ready_in, go, read, write:		in std_logic;
	addr_out:               out std_logic_vector(15 downto 0);
	addr_in:                in std_logic_vector(15 downto 0);
	debug: out std_logic_vector(15 downto 0);
	reset:		in std_logic;
	AS, RD, WR, LD, ready_out:		out std_logic -- LD is unused
);
end no_cache;

-----------------------------------------------------

architecture version1 of no_cache is


    type state_type is (IDLE, WAITING, HOLDING, S3);
    signal next_state, current_state: state_type;

begin
    
    -- cocurrent process#1: state registers
    state_reg: process(clk, reset)
    begin

	if (reset='1') then
		AS <= '0';
		RD <= '0';
		WR <= '0';
		debug <= "0000000000000000";
		next_state <= IDLE;
                ready_out <= '0';
	elsif (clk'event and clk='1') then
--		current_state <= next_state;
--	end if;

--    end process;						  

    -- cocurrent process#2: combinational logic
--    comb_logic: process(current_state, go, ready_in)
--    begin

--	if (clk = '1' and reset = '0') then  -- make sure it is posedge triggered
	case next_state is

	    when IDLE =>	
			ready_out <= '0';
			if go = '0' then
--				AS <= '0';
--				RD <= '0';
--				WR <= '0';
					debug <= "0000000000000001";
			    next_state <= IDLE;
			elsif go ='1' then
				debug <= "0000000000000011";
				next_state <= WAITING;
--				addr_out <= addr_in;
				AS <= '1';
			if read = '1' then
				RD <= '1';
			end if;
			if write = '1' then
				WR <= '1';
			end if;
			end if;

	    when WAITING =>	 -- debug <= '1';
			if ready_in ='0' then 
				debug <= "0000000000000111";
			    next_state <= WAITING;
			elsif ready_in ='1' then 
				debug <= "0000000000001000";
			   next_state <= HOLDING;
				ready_out <= '1';
				AS <= '0'; -- this might break some stuff?
			end if;

	    when HOLDING =>	-- debug <= '2';
			--if go ='0' then
				AS <= '0';
				RD <= '0';
				WR <= '0';
				ready_out <= '0';
			    next_state <= IDLE;
			--elsif go ='1' then
			    --next_state <= HOLDING;
			--end if;
			if go = '0' then
--				AS <= '0';
--				RD <= '0';
--				WR <= '0';
					debug <= "1000000000000001";
			    next_state <= IDLE;
			elsif go ='1' then
				debug <= "1000000000000011";
				next_state <= WAITING;
				addr_out <= addr_in;
				AS <= '1';
			if read = '1' then
				RD <= '1';
			end if;
			if write = '1' then
				WR <= '1';
			end if;
			end if;


	    when others =>
--			debug <= '3';
			next_state <= IDLE;

	end case;
	end if;
--	end if;
    end process;

end version1;
































































































