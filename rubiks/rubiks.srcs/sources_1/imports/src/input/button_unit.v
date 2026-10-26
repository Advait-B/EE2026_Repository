`timescale 1ns / 1ps

// button_unit.v
// Debounces the five push buttons and makes 1-cycle press pulses.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module button_unit (
    input clk, // 100 MHz clock
    input [4:0] btn_raw, // raw buttons, {C, U, L, R, D}
    output debugled,
    output [4:0] btn_held, // debounced level
    output [4:0] btn_pressed // 1-cycle pulse on press
);
`include "cube_defs.vh"
    wire clk_5hz;
    flexclock clk_5hz_unit (
        .clock(clk),
        .reset(0),
        .m(32'd9999999),
        .slow_clock(clk_5hz)
    );

    assign debugled = clk_5hz;
    
    debouncer DBbtnC(
        clk_5hz,
        btn_raw[4],
        btn_held[4],
        btn_pressed[4]
    );
    debouncer DBbtnU(
        clk_5hz,
        btn_raw[3],
        btn_held[3],
        btn_pressed[3]
    );
    debouncer DBbtnL(
        clk_5hz,
        btn_raw[2],
        btn_held[2],
        btn_pressed[2]
    );
    debouncer DBbtnR(
        clk_5hz,
        btn_raw[1],
        btn_held[1],
        btn_pressed[1]
    );
    debouncer DBbtnD(
        clk_5hz,
        btn_raw[0],
        btn_held[0],
        btn_pressed[0]
    );

endmodule
