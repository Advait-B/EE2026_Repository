`timescale 1ns / 1ps

// move_rules.v
// Combinational: the sticker permutation for each of the 18 moves.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module move_rules (
    input [71:0] cube_in, // cube before move
    input [4:0] move, // move to apply
    output [71:0] cube_out // cube after move
);
`include "cube_defs.vh"

endmodule
