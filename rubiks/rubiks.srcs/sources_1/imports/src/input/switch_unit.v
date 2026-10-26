`timescale 1ns / 1ps

// switch_unit.v
// Synchronises the slide switches into the 100 MHz domain.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module switch_unit (
    input clk, // 100 MHz clock
    input [15:0] sw_raw, // raw switches
    output [15:0] sw_sync // synced switches
);
`include "cube_defs.vh"

endmodule
