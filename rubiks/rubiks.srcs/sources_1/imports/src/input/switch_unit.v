`timescale 1ns / 1ps

// switch_unit.v
// Synchronises the slide switches into the 100 MHz domain.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module switch_unit (
    input clk, // 100 MHz clock
    input [15:0] sw,
    output reg [3:0] debugpage
    // input [15:0] sw_raw, // raw switches
    // output [15:0] sw_sync // synced switches
);
`include "cube_defs.vh"

    always @(posedge clk) begin
        
        // if (sw[7]) debugpage <= 4'd7; else 
        // if (sw[6]) debugpage <= 4'd6; else 
        if (sw[5]) debugpage <= 4'd5; else //camera angle id
        if (sw[4]) debugpage <= 4'd4; else //maus dy
        if (sw[3]) debugpage <= 4'd3; else //maus dx
        if (sw[2]) debugpage <= 4'd2; else //maus y
        if (sw[1]) debugpage <= 4'd1; else //maus x
        debugpage <= 4'd0;

    end


endmodule
