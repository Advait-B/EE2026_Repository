`timescale 1ns / 1ps

// solver.v
// Finds a solution for the current cube, then plays it back one move per 4 Hz tick.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module solver (
    input clk, // 100 MHz clock
    input rst, // reset
    input start, cancel, // pulses: begin solving, abort
    input tick_4hz, // one move per tick during playback
    input [71:0] cube, // cube to solve
    output [4:0] sol_move, // next solution move
    output sol_valid, // pulse when sol_move is ready
    output busy, // searching or playing back
    output done, err, // pulses: cube solved, timeout or cancel
    output [3:0] moves_left // solution moves remaining
);
`include "cube_defs.vh"

endmodule
