# Stopwatch simulation

From the repository root, run:

```sh
sh verification/run.sh
```

Requires GHDL (`sudo apt install ghdl` on Ubuntu). Success prints
`ALL STOPWATCH TESTS PASSED`; a failed assertion exits with an error.
The script compiles the actual `SW_CORE.vhd` and `SW_IO.vhd`, uses a temporary
build directory, and does not modify the Quartus project.

The testbench connects both modules to a simulated SCOMP-style bus master.
It checks the default divider, start/pause/resume and partial milliseconds,
capture on a tick, all 2,048 read and write addresses, all invalid 16-bit command
values, clear, asynchronous reset, reset write suppression, saturation, and
Resume coincident with overflow. Most tests use four clocks per millisecond to
reach overflow quickly; a second core checks the default 10,000-clock divider.

These are peripheral RTL tests. They do not simulate the SCOMP CPU, PLL,
schematic, assembly program, or post-fit timing.

Execution status when prepared: **not run**. The development environment had no
VHDL simulator and package downloads failed due to DNS resolution.
