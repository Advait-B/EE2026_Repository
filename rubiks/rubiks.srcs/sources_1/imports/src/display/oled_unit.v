`timescale 1ns / 1ps

// oled_unit.v
// Drives the Pmod OLED: 2D cube net, stage, solver errors, solve progress.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module oled_unit (
    input clk, // 100 MHz clock
    input clk_6p25mhz, // OLED driver clock
    input rst, // reset
    input [2:0] stage, // current game stage
    input [71:0] cube, // for the 2D net view
    input [3:0] moves_left, // solve progress
    output [7:0] oled_pmod // Pmod OLED pins
);
`include "cube_defs.vh"

endmodule
