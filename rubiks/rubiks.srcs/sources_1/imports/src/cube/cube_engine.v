`timescale 1ns / 1ps

// cube_engine.v
// Holds the live sticker-colour state in fixed face/tile order; applies moves.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module cube_engine (
    input clk, // 100 MHz clock
    input rst, // reset
    input cube_reset, // reset cube to solved
    input [4:0] move_req, // move to apply
    input move_valid, // apply move this cycle
    output [71:0] cube, // 24 live sticker colours; index = face*4 + tile
    output [15:0] move_count // moves applied since reset
);
`include "cube_defs.vh"

endmodule
