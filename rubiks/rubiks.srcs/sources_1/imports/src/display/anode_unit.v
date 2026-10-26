`timescale 1ns / 1ps

// anode_unit.v
// Multiplexes the 4-digit 7-segment display.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module anode_unit (
    input clk, // 100 MHz clock
    input rst, // reset
    input tick_1khz, // digit multiplex tick
    input [2:0] stage, // current game stage
    input [15:0] move_count, // moves applied
    input [3:0] moves_left, // solve moves remaining
    output [6:0] seg, // segments
    output dp, // decimal point
    output [3:0] an // anodes
);
`include "cube_defs.vh"

endmodule
