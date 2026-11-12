LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY SW_CORE IS
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

  -- Placeholder outputs for creating and wiring the symbol.
  -- Replace these assignments when implementing the stopwatch.
  ELAPSED  <= (OTHERS => '0');
  CAPTURED <= (OTHERS => '0');
  STATUS   <= (OTHERS => '0');

END rtl;