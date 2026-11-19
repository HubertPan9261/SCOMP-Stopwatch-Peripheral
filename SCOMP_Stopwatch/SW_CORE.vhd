-- SW_CORE.vhd
-- Stopwatch core: counts milliseconds and carries out commands from SW_IO.
-- Runs on SCOMP's 10 MHz clock (the same clock SW_IO relies on).
--
-- Commands (written to SW_CONTROL, &H070):
--   1 = clear/start, 2 = pause, 3 = resume, 4 = clear, 5 = capture
--   Any other value is ignored.
-- STATUS bits: 0 = running, 1 = capture valid, 2 = overflow, 3-15 = 0

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
  SIGNAL tick_count    : INTEGER RANGE 0 TO CLKS_PER_MS - 1;  -- cycles within the current ms
  SIGNAL elapsed_ms    : UNSIGNED(15 DOWNTO 0);               -- running time
  SIGNAL captured_ms   : UNSIGNED(15 DOWNTO 0);               -- last captured time
  SIGNAL running       : STD_LOGIC;
  SIGNAL capture_valid : STD_LOGIC;
  SIGNAL overflow      : STD_LOGIC;
BEGIN

  PROCESS (RESETN, CLK)
  BEGIN
    IF RESETN = '0' THEN
      tick_count    <= 0;
      elapsed_ms    <= (OTHERS => '0');
      captured_ms   <= (OTHERS => '0');
      running       <= '0';
      capture_valid <= '0';
      overflow      <= '0';

    ELSIF RISING_EDGE(CLK) THEN

      -- 1. Normal counting. A command below can override this.
      IF running = '1' THEN
        IF tick_count = CLKS_PER_MS - 1 THEN
          tick_count <= 0;
          IF elapsed_ms = x"FFFF" THEN
            overflow <= '1';            -- hold at 65,535 ...
            running  <= '0';            -- ... and stop counting
          ELSE
            elapsed_ms <= elapsed_ms + 1;
          END IF;
        ELSE
          tick_count <= tick_count + 1;
        END IF;
      END IF;

      -- 2. Commands. In a process the last assignment wins, so these
      --    take priority over the counting above. Only values 1-5 count.
      IF COMMAND_VALID = '1' AND COMMAND(15 DOWNTO 3) = "0000000000000" THEN
        CASE COMMAND(2 DOWNTO 0) IS

          WHEN "001" | "100" =>         -- 1 = clear/start, 4 = clear
            tick_count    <= 0;
            elapsed_ms    <= (OTHERS => '0');
            captured_ms   <= (OTHERS => '0');
            capture_valid <= '0';
            overflow      <= '0';
            IF COMMAND(2 DOWNTO 0) = "001" THEN
              running <= '1';
            ELSE
              running <= '0';
            END IF;

          WHEN "010" =>                 -- 2 = pause (beats a same-edge tick)
            running    <= '0';
            tick_count <= tick_count;   -- keep the partial millisecond
            elapsed_ms <= elapsed_ms;
            overflow   <= overflow;

          WHEN "011" =>                 -- 3 = resume only when paused without overflow
            IF running = '0' AND overflow = '0' THEN
              running <= '1';
            END IF;

          WHEN "101" =>                 -- 5 = capture (value before this edge;
            captured_ms   <= elapsed_ms;--     counting continues normally)
            capture_valid <= '1';

          WHEN OTHERS =>                -- 0, 6, 7: ignored
            NULL;

        END CASE;
      END IF;

    END IF;
  END PROCESS;

  ELAPSED  <= STD_LOGIC_VECTOR(elapsed_ms);
  CAPTURED <= STD_LOGIC_VECTOR(captured_ms);
  STATUS   <= "0000000000000" & overflow & capture_valid & running;

END rtl;