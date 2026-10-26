`timescale 1ns / 1ps

// led_unit.v
// Board LEDs: stage, solve progress bar, error blink.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module led_unit (
    input clk, // 100 MHz clock
    input rst, // reset
    input tick_4hz, // blink rate
    input [2:0] stage, // current game stage
    input solve_err, // blink on error
    input [3:0] moves_left, // solve progress bar
    input [15:0] move_count, // moves applied
    output [15:0] led // board LEDs
);
`include "cube_defs.vh"

endmodule
