`timescale 1ns / 1ps

// led_unit: stage indicator, solve progress bar and error blink on the 16 LEDs. Owner: Su Yi

module led_unit (
    input wire clk,
    input wire rst,
    input wire tick_1k, // count for blink rate
    input wire [2:0] stage,
    input wire [3:0] progress,
    input wire [3:0] sol_len,
    input wire [2:0] err_code,
    output wire [15:0] led
);
    `include "cube_defs.vh"
endmodule
