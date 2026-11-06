# SCOMP Stopwatch Peripheral

A source-only copy of the Lab 8 SCOMP game, ready for development of a stopwatch peripheral. The peripheral has not been implemented yet.

Open `SCOMP_Stopwatch/SCOMP_Stopwatch.qpf` in Quartus Prime with Cyclone V support. The project targets the DE1-SoC device `5CSXFC6D6F31C6` and uses `SCOMP_Stopwatch_System.bdf` as its top-level schematic. The original pin assignments are retained.

The project includes the CPU and existing I/O HDL, editable schematics and symbols, and the PLL synthesis dependencies. Hardware module names such as `SCOMP` and `PLL_main` are retained so existing schematic connections remain valid.

`Stopwatch_Game.asm` is the original game source; `Stopwatch_Game.mif` is its memory image loaded by `SCOMP.vhd`. After modifying the assembly, regenerate the MIF with the SCOMP assembler using `scasm.cfg` before compiling the FPGA project.

Add the new peripheral and its I/O address decoding in `SCOMP_Stopwatch_System.bdf`, and add any new HDL files to the Quartus project. Update the game assembly to use the peripheral when it is ready.

The supplied `SCOMP_Stopwatch.sdc` is empty, as in the original lab. Timing constraints still need to be defined and checked before hardware timing can be considered verified.

Build databases, simulation products, programming outputs, backups, and the original pasted `SCOMP_Lab8_Fall25` folder are ignored by Git. Quartus will regenerate build outputs locally. The original lab folder is left untouched.
