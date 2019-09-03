        .text
        .align 6
        .global _start
_start:
        j run_program
        .align 2

run_program:
        nop
endless_loop:
        j endless_loop
