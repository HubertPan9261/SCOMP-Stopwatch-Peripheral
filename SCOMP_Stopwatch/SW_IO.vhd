-- SW_IO.vhd
-- SCOMP I/O interface for the stopwatch peripheral (DRAFT for team review).
--
-- Register map:
--   0x70 SW_CONTROL  (write)  -> COMMAND / COMMAND_VALID to the core
--   0x71 SW_ELAPSED  (read)   <- ELAPSED from the core
--   0x72 SW_CAPTURED (read)   <- CAPTURED from the core
--   0x73 SW_STATUS   (read)   <- STATUS from the core
--
-- Follows the same bus style as the Lab 8 TIMER.vhd peripheral:
-- full 11-bit IO_ADDR decoded here, separate IO_READ and IO_WRITE.
-- SCOMP and the stopwatch core must share the project's 10 MHz clock.
-- SCOMP holds IO_WRITE high for one clock cycle with stable IO_DATA.
-- The core samples COMMAND when COMMAND_VALID is high at a rising edge.
-- CLK is retained for symbol compatibility; this interface is combinational.

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY SW_IO IS
  PORT (
    RESETN        : IN    STD_LOGIC;
    CLK           : IN    STD_LOGIC;
    IO_ADDR       : IN    STD_LOGIC_VECTOR(10 DOWNTO 0);
    IO_READ       : IN    STD_LOGIC;
    IO_WRITE      : IN    STD_LOGIC;
    IO_DATA       : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    -- To the stopwatch core
    COMMAND       : OUT   STD_LOGIC_VECTOR(15 DOWNTO 0);
    COMMAND_VALID : OUT   STD_LOGIC;
    -- From the stopwatch core
    ELAPSED       : IN    STD_LOGIC_VECTOR(15 DOWNTO 0);
    CAPTURED      : IN    STD_LOGIC_VECTOR(15 DOWNTO 0);
    STATUS        : IN    STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END SW_IO;

ARCHITECTURE a OF SW_IO IS
  SIGNAL SEL        : STD_LOGIC;
  SIGNAL read_value : STD_LOGIC_VECTOR(15 DOWNTO 0);
BEGIN

  -- Select exactly 0x70 through 0x73.
  SEL <= '1' WHEN IO_ADDR(10 DOWNTO 2) = "000011100" ELSE '0';

  -- Decode SCOMP's one-cycle write strobe directly. The shared clock
  -- lets the core accept the command without a toggle or synchronizer.
  COMMAND <= IO_DATA;
  COMMAND_VALID <= '1' WHEN RESETN = '1' AND SEL = '1'
                           AND IO_ADDR(1 DOWNTO 0) = "00"
                           AND IO_WRITE = '1'
                   ELSE '0';

  -- 3. Reads: choose the register, drive the bus only during an IN to us.
  WITH IO_ADDR(1 DOWNTO 0) SELECT read_value <=
    ELAPSED         WHEN "01",
    CAPTURED        WHEN "10",
    STATUS          WHEN "11",
    (OTHERS => '0') WHEN OTHERS;     -- SW_CONTROL reads as zero

  IO_DATA <= read_value WHEN (SEL = '1' AND IO_READ = '1')
             ELSE (OTHERS => 'Z');

END a;
