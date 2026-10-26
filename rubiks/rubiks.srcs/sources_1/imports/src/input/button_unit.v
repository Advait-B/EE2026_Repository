`timescale 1ns / 1ps

// button_unit.v
// Debounces the five push buttons and makes 1-cycle press pulses.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module button_unit (
    input clk, // 100 MHz clock
    input [4:0] btn_raw, // raw buttons
    output [4:0] btn_held, // debounced level
    output [4:0] btn_pressed // 1-cycle pulse on press
);
`include "cube_defs.vh"

endmodule
