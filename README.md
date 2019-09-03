# Broken labels in RISC-V ELF from GCC

*Solved, sorta, but still, wtf*

## Problem

When compiling an assembly source file into an ELF executable using
GCC for RISC-V, non-global symbols have bogus addresses.

When assembling using GAS directly, this issue is not observed.

Notice the values for `run_program` and `endless_loop` in the output
below. The first approach (run `as` directly) results in the expected
values (`80000004` and `80000006` respectively).

Building with GCC instead gives bogus values for those two symbols,
which differ based on whether the linker script is provided to the
compile step or not. See the second and third paragraphs in the output
below.

## Actual vs expected

| Symbol name  | Expected value    | AS+LD result      | GCC-with-T result | GCC-without-T result |
|--------------|-------------------|-------------------|-------------------|----------------------|
| _start       | 00000000_80000000 | 00000000_80000000 | 00000000_80000000 | 00000000_80000000    |
| run_program  | 00000000_80000004 | 00000000_80000004 | 00000001_00001004 | 00000000_80010104    |
| endless_loop | 00000000_80000006 | 00000000_80000006 | 00000001_00001006 | 00000000_80010106    |

## Also tried

I also tried using the GCC 9 package that's available on Ubuntu;
problem still appears.

I also tried building my own toolchain using crosstools-NG on Centos.
Problem still appears.

## Output

This was run on a clean Ubuntu Server 19.04 installation, using the
tool versions documented in the [Makefile](Makefile).

```
sjohnson@testing-riscv-tools:~/nop$ make
riscv64-linux-gnu-as -march=rv64imc -o nop.as.o nop.s
riscv64-linux-gnu-ld -o nop.as.elf -T sim.ld nop.as.o
riscv64-linux-gnu-objdump --syms nop.as.elf

nop.as.elf:     file format elf64-littleriscv

SYMBOL TABLE:
0000000080000000 l    d  .text  0000000000000000 .text
0000000000000000 l    df *ABS*  0000000000000000 nop.as.o
0000000080000004 l       .text  0000000000000000 run_program
0000000080000006 l       .text  0000000000000000 endless_loop
0000000080000000 g       .text  0000000000000000 _start
0000000080000042 g       .text  0000000000000000 _end


riscv64-linux-gnu-gcc-8 -march=rv64imc -nostartfiles -T sim.ld -o nop.gcc.withT.o nop.s
riscv64-linux-gnu-ld -o nop.gcc.withT.elf -T sim.ld nop.gcc.withT.o
riscv64-linux-gnu-objdump --syms nop.gcc.withT.elf

nop.gcc.withT.elf:     file format elf64-littleriscv

SYMBOL TABLE:
0000000080000000 l    d  .text  0000000000000000 .text
0000000080000044 l    d  .note.gnu.build-id     0000000000000000 .note.gnu.build-id
0000000000000000 l    df *ABS*  0000000000000000 /tmp/cctpGVW8.o
0000000100001004 l       .text  0000000000000000 run_program
0000000100001006 l       .text  0000000000000000 endless_loop
0000000080000000 g       .text  0000000000000000 _start
0000000080000042 g       .text  0000000000000000 _end


riscv64-linux-gnu-gcc-8 -march=rv64imc -nostartfiles -o nop.gcc.noT.o nop.s
riscv64-linux-gnu-ld -o nop.gcc.noT.elf -T sim.ld nop.gcc.noT.o
riscv64-linux-gnu-objdump --syms nop.gcc.noT.elf

nop.gcc.noT.elf:     file format elf64-littleriscv

SYMBOL TABLE:
0000000080000000 l    d  .text  0000000000000000 .text
0000000080000044 l    d  .note.gnu.build-id     0000000000000000 .note.gnu.build-id
0000000000000000 l    df *ABS*  0000000000000000 /tmp/ccZc4cmc.o
0000000080010104 l       .text  0000000000000000 run_program
0000000080010106 l       .text  0000000000000000 endless_loop
0000000000011942 g       *ABS*  0000000000000000 __global_pointer$
0000000080001042 g       .text  0000000000000000 __SDATA_BEGIN__
0000000080000000 g       .text  0000000000000000 _start
0000000080001048 g       .text  0000000000000000 __BSS_END__
0000000080001042 g       .text  0000000000000000 __bss_start
0000000080001042 g       .text  0000000000000000 __DATA_BEGIN__
0000000080001042 g       .text  0000000000000000 _edata
0000000080000042 g       .text  0000000000000000 _end
```

# Solution

I needed to add `-c` to the GCC compile line; otherwise GCC tries to
do a final link.

Shouldn't it have puked when I tried to re-link an already linked
file? At least, shouldn't it have not screwed up the symbol values?
