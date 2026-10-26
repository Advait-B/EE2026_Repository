`timescale 1ns / 1ps

// mouse_unit: wraps the provided MouseCtl and clamps the cursor to 640x480. Owner: Su Yi

module mouse_unit (
    input wire clk, // 100 MHz
    input wire rst,
    inout wire ps2_clk,
    inout wire ps2_data,
    output wire [9:0] mouse_x, // 0..639
    output wire [9:0] mouse_y, // 0..479
    output wire left, middle, right, // button levels
    output wire signed [10:0] dx, // movement since last event
    output wire signed [10:0] dy,
    output wire new_event // 1-cycle pulse per mouse packet
);
    `include "cube_defs.vh"
endmodule
