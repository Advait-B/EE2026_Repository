`timescale 1ns / 1ps

// move_rules: pure combinational, cube + move -> new cube, one definition of all 18 turns. Owner: Louisa

module move_rules (
    input wire [71:0] cube_in,
    input wire [4:0] move,
    output wire [71:0] cube_out // MV_NONE / invalid = unchanged
);
    `include "cube_defs.vh"
endmodule
