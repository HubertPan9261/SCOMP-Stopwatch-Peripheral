LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY SW_CORE IS
	GENERIC (
		 CLKS_PER_MS : INTEGER := 10000  -- 10 MHz clock -> 10,000 cycles per ms
  );
  PORT (
    CLK           : IN  STD_LOGIC;  -- Shared 10 MHz clock
    RESETN        : IN  STD_LOGIC;  -- Active-low reset
    COMMAND       : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
    COMMAND_VALID : IN  STD_LOGIC;

    ELAPSED       : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    CAPTURED      : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    STATUS        : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END SW_CORE;

ARCHITECTURE rtl OF SW_CORE IS
BEGIN
	SIGNAL tick_count    : INTEGER RANGE 0 TO CLKS_PER_MS - 1;  -- cycles within the current ms
	SIGNAL elapsed_ms    : UNSIGNED(15 DOWNTO 0);               -- running time
	SIGNAL captured_ms   : UNSIGNED(15 DOWNTO 0);               -- last captured time
	SIGNAL running       : STD_LOGIC;
	SIGNAL capture_valid : STD_LOGIC;
	SIGNAL overflow      : STD_LOGIC;
	
	PROCESS(RESETN, CLK)
	BEGIN
		IF RESETN = '0' THEN
			tick_count <= 0;
			elapsed_ms <= (OTHERS => '0');
			captured_ms <= (OTHERS => '0');
			running <= 0;
			capture_valid <= 0;
			overflow <= 0;
			
		ELSIF RISING_EDGE(CLK) THEN
			IF COMMAND_VALID = '1' THEN
				CASE COMMAND(2 DOWNTO 0) IS
					WHEN "001" || "100" =>
						tick_count <= 0;
						elapsed_ms <= (OTHERS => '0');
						captured_ms <= (OTHERS => '0');
						running <= 0;
						capture_valid <= 0;
						overflow <= 0;
						IF COMMAND(2 DOWNTO 0) = "001" THEN
							running <= '1';
						ELSE
							running <= '0';
						END IF;
					
					WHEN "010" =>
						running <= '0';
					
					WHEN "011" =>
						running <= '1';
					
					WHEN "101" =>
						captured_ms   <= elapsed_ms;
						capture_valid <= '1';
					
					WHEN OTHERS =>
						NULL;
				END CASE;
			
			ELSIF running = '1' THEN
				IF tick_count = CLKS_PER_MS - 1 THEN
					tick_count <= 0;
					IF elapsed_ms = x"FFFF" THEN
						overflow <= '1';
					ELSE
						elapsed_ms <= elapsed_ms + 1;
					END IF;
				ELSE
					tick_count <= tick_count + 1;
				END IF;
			END IF;
		
		END IF;
	END PROCESS;

  -- Replace these assignments when implementing the stopwatch.
  ELAPSED  <= STD_LOGIC_VECTOR(elapsed_ms);
  CAPTURED <= STD_LOGIC_VECTOR(captured_ms);
  STATUS   <= (15 DOWNTO 3 => '0') & overflow & capture_valid & running;

END rtl;