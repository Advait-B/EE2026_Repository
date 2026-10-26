`timescale 1ns / 1ps

// cube_encode: sticker cube -> solver state (corner perm + twist) and validity check. Owner: Advait

module cube_encode (
    input wire clk,
    input wire [71:0] cube,
    output wire [12:0] perm_idx, // 0..5039
    output wire [9:0] ori_idx, // 0..728
    output wire cube_valid,
    output wire [2:0] err_code // ERR_NONE / ERR_COLOUR_COUNT / ERR_BAD_CORNER / ERR_TWIST
);
    `include "cube_defs.vh"
endmodule
