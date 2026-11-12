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
-- CLK is the same clock the stopwatch core uses (50 MHz for now).

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
  SIGNAL SEL                 : STD_LOGIC;  -- 1 when address is 0x70-0x73
  SIGNAL CTRL_WRITE          : STD_LOGIC;  -- 1 during an OUT to 0x70
  SIGNAL cmd_reg             : STD_LOGIC_VECTOR(15 DOWNTO 0);
  SIGNAL cmd_toggle          : STD_LOGIC;  -- flips once per write to SW_CONTROL
  SIGNAL sync1, sync2, sync3 : STD_LOGIC;  -- carry the toggle onto CLK
  SIGNAL read_value          : STD_LOGIC_VECTOR(15 DOWNTO 0);
BEGIN

  -- 0. Address decoding: 0x70-0x73 all share the same top 9 bits.
  SEL <= '1' WHEN IO_ADDR(10 DOWNTO 2) = "000011100" ELSE '0';

  CTRL_WRITE <= '1' WHEN (SEL = '1') AND (IO_ADDR(1 DOWNTO 0) = "00")
                         AND (IO_WRITE = '1')
                ELSE '0';

  -- 1. Catch writes to 0x70 with the address and IO_WRITE
  --    (not by sampling them on a clock).
  PROCESS (RESETN, CTRL_WRITE)
  BEGIN
    IF RESETN = '0' THEN
      cmd_reg    <= (OTHERS => '0');
      cmd_toggle <= '0';
    ELSIF RISING_EDGE(CTRL_WRITE) THEN
      cmd_reg    <= IO_DATA;
      cmd_toggle <= NOT cmd_toggle;
    END IF;
  END PROCESS;

  -- 2. Turn each toggle flip into exactly one CLK-cycle pulse.
  PROCESS (RESETN, CLK)
  BEGIN
    IF RESETN = '0' THEN
      sync1 <= '0';
      sync2 <= '0';
      sync3 <= '0';
    ELSIF RISING_EDGE(CLK) THEN
      sync1 <= cmd_toggle;
      sync2 <= sync1;
      sync3 <= sync2;
    END IF;
  END PROCESS;

  COMMAND_VALID <= sync2 XOR sync3;  -- high for one CLK cycle per write
  COMMAND       <= cmd_reg;          -- already stable when the pulse arrives

  -- 3. Reads: choose the register, drive the bus only during an IN to us.
  WITH IO_ADDR(1 DOWNTO 0) SELECT read_value <=
    ELAPSED         WHEN "01",
    CAPTURED        WHEN "10",
    STATUS          WHEN "11",
    (OTHERS => '0') WHEN OTHERS;     -- SW_CONTROL reads as zero

  IO_DATA <= read_value WHEN (SEL = '1' AND IO_READ = '1')
             ELSE (OTHERS => 'Z');

END a;
