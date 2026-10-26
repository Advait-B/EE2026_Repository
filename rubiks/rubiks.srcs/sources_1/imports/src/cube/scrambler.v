`timescale 1ns / 1ps

// scrambler.v
// Sends 25 random moves, one per 4 Hz tick, never repeating a face back to back.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module scrambler (
    input clk, // 100 MHz clock
    input rst, // reset
    input start, // pulse to begin scramble
    input tick_4hz, // one move per tick
    output [4:0] scr_move, // next scramble move
    output scr_valid, // pulse when scr_move is ready
    output busy, // scramble in progress
    output done // pulse when 25 moves are sent
);
`include "cube_defs.vh"

endmodule
