library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

entity tb_stopwatch is
end entity;

architecture test of tb_stopwatch is
  constant C : positive := 4;
  signal clk : std_logic := '0';
  signal resetn : std_logic := '0';
  signal addr : std_logic_vector(10 downto 0) := (others => '0');
  signal rd, wr : std_logic := '0';
  signal bus_data : std_logic_vector(15 downto 0);
  signal master_data : std_logic_vector(15 downto 0) := (others => 'Z');
  signal command, elapsed, captured, status : std_logic_vector(15 downto 0);
  signal valid : std_logic;
  -- A second core verifies the real, default 10,000-clock millisecond.
  signal default_resetn, default_valid : std_logic := '0';
  signal default_elapsed : std_logic_vector(15 downto 0);
begin
  clk <= not clk after 50 ns;
  bus_data <= master_data;

  core : entity work.SW_CORE
    generic map (CLKS_PER_MS => C)
    port map (CLK => clk, RESETN => resetn, COMMAND => command,
      COMMAND_VALID => valid, ELAPSED => elapsed, CAPTURED => captured,
      STATUS => status);

  io : entity work.SW_IO
    port map (RESETN => resetn, CLK => clk, IO_ADDR => addr,
      IO_READ => rd, IO_WRITE => wr, IO_DATA => bus_data,
      COMMAND => command, COMMAND_VALID => valid,
      ELAPSED => elapsed, CAPTURED => captured, STATUS => status);

  default_core : entity work.SW_CORE
    port map (CLK => clk, RESETN => default_resetn, COMMAND => x"0001",
      COMMAND_VALID => default_valid, ELAPSED => default_elapsed,
      CAPTURED => open, STATUS => open);

  stimulus : process
    procedure cycles(n : positive := 1) is
    begin
      for i in 1 to n loop
        wait until rising_edge(clk);
        wait for 1 ns;
      end loop;
    end procedure;

    -- Like SCOMP: stable data before IO_WRITE, held for one clock.
    procedure write_reg(a, value : natural) is
    begin
      wait until falling_edge(clk);
      addr <= std_logic_vector(to_unsigned(a, addr'length));
      master_data <= std_logic_vector(to_unsigned(value, 16));
      wr <= '1';
      cycles;
      wr <= '0';
      master_data <= (others => 'Z');
      wait for 1 ns;
    end procedure;

    procedure expect_regs(e, cap, flags : natural) is
    begin
      assert elapsed = std_logic_vector(to_unsigned(e, 16))
        report "Unexpected elapsed value: got " &
          integer'image(to_integer(unsigned(elapsed))) &
          ", expected " & integer'image(e) severity failure;
      assert captured = std_logic_vector(to_unsigned(cap, 16))
        report "Unexpected captured value: got " &
          integer'image(to_integer(unsigned(captured))) &
          ", expected " & integer'image(cap) severity failure;
      assert status = std_logic_vector(to_unsigned(flags, 16))
        report "Unexpected status flags: got " &
          integer'image(to_integer(unsigned(status))) &
          ", expected " & integer'image(flags) severity failure;
    end procedure;

    procedure read_reg(a : natural; expected : std_logic_vector(15 downto 0)) is
    begin
      wait until falling_edge(clk);
      addr <= std_logic_vector(to_unsigned(a, addr'length));
      rd <= '1';
      wait for 1 ns;
      assert bus_data = expected report "Incorrect I/O read at address " &
        integer'image(a) severity failure;
      cycles;
      rd <= '0';
      wait for 1 ns;
      assert bus_data = (bus_data'range => 'Z')
        report "Peripheral did not release data bus" severity failure;
    end procedure;
  begin
    cycles;
    expect_regs(0, 0, 0);

    default_resetn <= '1';
    default_valid <= '1';
    cycles;
    default_valid <= '0';
    cycles(9999);
    assert default_elapsed = x"0000"
      report "Default millisecond tick was early" severity failure;
    cycles;
    assert default_elapsed = x"0001"
      report "Default millisecond tick was late" severity failure;
    default_resetn <= '0';
    report "PASS: default 10 MHz divider";

    resetn <= '1';
    write_reg(16#70#, 1);
    expect_regs(0, 0, 1);
    cycles(C - 1);
    expect_regs(0, 0, 1);
    cycles;
    expect_regs(1, 0, 1);
    write_reg(16#70#, 2);
    cycles(10);
    expect_regs(1, 0, 0);

    write_reg(16#70#, 1);
    cycles(2);
    write_reg(16#70#, 2);
    cycles(10);
    expect_regs(0, 0, 0);
    write_reg(16#70#, 3);
    cycles;
    expect_regs(0, 0, 1);
    cycles;
    expect_regs(1, 0, 1);
    report "PASS: start, pause, resume, partial millisecond";

    write_reg(16#70#, 1);
    cycles(C - 1);
    write_reg(16#70#, 5); -- exactly on a millisecond boundary
    expect_regs(1, 0, 3); -- capture is explicitly the pre-edge value
    cycles(C);
    expect_regs(2, 0, 3);
    write_reg(16#70#, 2);
    write_reg(16#70#, 5);
    expect_regs(2, 2, 2);
    read_reg(16#70#, x"0000");
    read_reg(16#71#, x"0002");
    read_reg(16#72#, x"0002");
    read_reg(16#73#, x"0002");
    expect_regs(2, 2, 2);
    report "PASS: capture, register reads, reads have no side effects";

    -- Check every address, including aliases in the upper address bits.
    for a in 0 to 2047 loop
      wait until falling_edge(clk);
      addr <= std_logic_vector(to_unsigned(a, addr'length));
      rd <= '1';
      wait for 1 ns;
      case a is
        when 16#70# => assert bus_data = x"0000" severity failure;
        when 16#71# | 16#72# | 16#73# =>
          assert bus_data = x"0002" severity failure;
        when others =>
          assert bus_data = (bus_data'range => 'Z')
            report "Unexpected address decode at " & integer'image(a)
            severity failure;
      end case;
      rd <= '0';
    end loop;
    for a in 0 to 2047 loop
      if a /= 16#70# then
        write_reg(a, 1);
        expect_regs(2, 2, 2);
      end if;
    end loop;
    for value in 0 to 65535 loop
      if value < 1 or value > 5 then
        write_reg(16#70#, value);
        expect_regs(2, 2, 2);
      end if;
    end loop;
    report "PASS: full address decode, ignored writes and invalid commands";

    -- Each register reads back its own value (0x71 and 0x72 differ here),
    -- and a second capture replaces the first.
    write_reg(16#70#, 1);
    cycles(3 * C);
    expect_regs(3, 0, 1);
    write_reg(16#70#, 5);                -- capture 3
    expect_regs(3, 3, 3);
    cycles(2 * C);
    write_reg(16#70#, 2);                -- pause with elapsed /= captured
    expect_regs(5, 3, 2);
    read_reg(16#71#, x"0005");
    read_reg(16#72#, x"0003");
    read_reg(16#73#, x"0002");
    write_reg(16#70#, 5);                -- second capture overwrites
    expect_regs(5, 5, 2);
    read_reg(16#72#, x"0005");
    report "PASS: distinct register reads, repeated capture";

    -- Pause twice: the second pause changes nothing.
    write_reg(16#70#, 2);
    cycles(2 * C);
    expect_regs(5, 5, 2);
    -- Resume while running: no restart, the partial millisecond is kept.
    write_reg(16#70#, 1);                -- restart from 0 (tick count 0)
    cycles(2);
    write_reg(16#70#, 3);                -- resume while already running
    expect_regs(0, 0, 1);
    cycles;
    expect_regs(1, 0, 1);                -- tick arrives on time
    report "PASS: repeated pause, resume while running";

    -- Start while running: restarts from 0 and clears the capture.
    cycles(3 * C);
    write_reg(16#70#, 5);
    expect_regs(4, 4, 3);
    cycles(C);
    write_reg(16#70#, 1);
    expect_regs(0, 0, 1);
    cycles(C);
    expect_regs(1, 0, 1);
    report "PASS: start while running";

    -- Clear while running and while paused; stays stopped afterwards.
    cycles(2 * C);
    write_reg(16#70#, 4);
    expect_regs(0, 0, 0);
    cycles(3 * C);
    expect_regs(0, 0, 0);
    write_reg(16#70#, 1);
    cycles(2 * C);
    write_reg(16#70#, 5);
    write_reg(16#70#, 2);
    write_reg(16#70#, 4);
    expect_regs(0, 0, 0);
    cycles(3 * C);
    expect_regs(0, 0, 0);
    report "PASS: clear while running and while paused";

    -- Commands on consecutive clock edges (faster than SCOMP can issue them)
    -- and at SCOMP's fastest rate (one OUT every 4 clocks).
    write_reg(16#70#, 1);                -- edge 1: start
    write_reg(16#70#, 5);                -- edge 2: capture 0
    write_reg(16#70#, 2);                -- edge 3: pause
    expect_regs(0, 0, 2);
    write_reg(16#70#, 3);                -- edge 4: resume
    write_reg(16#70#, 2);                -- edge 5: pause
    write_reg(16#70#, 3);                -- edge 6: resume
    expect_regs(0, 0, 3);
    cycles(C);
    expect_regs(1, 0, 3);
    write_reg(16#70#, 2);
    cycles(3);
    write_reg(16#70#, 3);
    cycles(3);
    write_reg(16#70#, 5);
    cycles(3);
    write_reg(16#70#, 2);
    expect_regs(3, 2, 2);                -- 1 ms + 1 tick, +3 -> 2 ms (captured), +3 -> 3 ms
    report "PASS: back-to-back commands";

    write_reg(16#70#, 1);
    cycles(C - 1);
    write_reg(16#70#, 2); -- pause overrides a same-edge tick
    expect_regs(0, 0, 0);
    write_reg(16#70#, 3);
    cycles;
    expect_regs(1, 0, 1);

    write_reg(16#70#, 1);
    cycles(C * 65535);
    expect_regs(65535, 0, 1);
    cycles(C - 1);
    write_reg(16#70#, 3); -- Resume must not override same-edge overflow
    expect_regs(65535, 0, 4);
    write_reg(16#70#, 3);
    cycles(C * 2);
    expect_regs(65535, 0, 4);
    write_reg(16#70#, 5);
    expect_regs(65535, 65535, 6);
    read_reg(16#71#, x"FFFF");
    read_reg(16#72#, x"FFFF");
    read_reg(16#73#, x"0006");
    write_reg(16#70#, 4);
    expect_regs(0, 0, 0);
    cycles(C * 2);
    expect_regs(0, 0, 0);
    report "PASS: tick boundaries, overflow saturation, Resume rejection, clear";

    write_reg(16#70#, 1);
    cycles(C);
    write_reg(16#70#, 5);
    wait until falling_edge(clk);
    resetn <= '0';
    addr <= std_logic_vector(to_unsigned(16#70#, addr'length));
    master_data <= x"0001";
    wr <= '1';
    wait for 1 ns;
    expect_regs(0, 0, 0);
    assert valid = '0' report "Command allowed during reset" severity failure;
    cycles;
    wr <= '0';
    master_data <= (others => 'Z');
    resetn <= '1';
    cycles(C * 2);
    expect_regs(0, 0, 0);
    report "PASS: asynchronous reset and write suppression during reset";
    report "ALL STOPWATCH TESTS PASSED";
    finish;
    wait;
  end process;

  watchdog : process
  begin
    wait for 100 ms;
    assert false report "Testbench timed out" severity failure;
    wait;
  end process;
end architecture;