`timescale 1ns / 1ps

// cube_engine: owns cube[71:0] and is the only module that writes it. Owner: Louisa

module cube_engine (
    input wire clk,
    input wire rst,
    input wire cube_reset,
    input wire [4:0] move_req,
    input wire move_valid,
    input wire paint_en,
    input wire [4:0] paint_tile,
    input wire [2:0] paint_colour,
    output wire [71:0] cube,
    output wire [7:0] move_count // moves applied since last reset
);
    `include "cube_defs.vh"
endmodule
