`timescale 1ns / 1ps

// oled_unit: wraps Oled_Display, shows mode, palette colour, errors, progress and the 2D net. Owner: Su Yi

module oled_unit (
    input wire clk,
    input wire clk6p25m,
    input wire rst,
    input wire [2:0] stage,
    input wire [71:0] cube, // for the 2D net view
    input wire [2:0] sel_colour,
    input wire [2:0] err_code,
    input wire [3:0] progress,
    input wire [3:0] sol_len,
    output wire [7:0] oled // to Pmod header
);
    `include "cube_defs.vh"
endmodule
