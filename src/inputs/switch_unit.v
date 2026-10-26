`timescale 1ns / 1ps

// switch_unit: synchronise the 16 switches to the clock. Owner: Su Yi

module switch_unit (
    input wire clk,
    input wire [15:0] sw_raw,
    output wire [15:0] sw
);
    `include "cube_defs.vh"
endmodule
