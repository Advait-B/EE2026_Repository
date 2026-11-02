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

    // debouncer outputs live in the 5 Hz domain; their pulses are 100 ms wide
    wire [4:0] held_5hz;
    wire [4:0] pressed_5hz_unused;

    debouncer DBbtnC(
        clk_5hz,
        btn_raw[4],
        held_5hz[4],
        pressed_5hz_unused[4]
    );
    debouncer DBbtnU(
        clk_5hz,
        btn_raw[3],
        held_5hz[3],
        pressed_5hz_unused[3]
    );
    debouncer DBbtnL(
        clk_5hz,
        btn_raw[2],
        held_5hz[2],
        pressed_5hz_unused[2]
    );
    debouncer DBbtnR(
        clk_5hz,
        btn_raw[1],
        held_5hz[1],
        pressed_5hz_unused[1]
    );
    debouncer DBbtnD(
        clk_5hz,
        btn_raw[0],
        held_5hz[0],
        pressed_5hz_unused[0]
    );

    // bring the debounced level into the 100 MHz domain and edge-detect it,
    // so btn_pressed is a true 1-cycle pulse as module_ports.txt requires
    reg [4:0] held_s1 = 5'd0, held_s2 = 5'd0, held_prev = 5'd0;
    always @(posedge clk) begin
        held_s1 <= held_5hz;
        held_s2 <= held_s1;
        held_prev <= held_s2;
    end
    assign btn_held = held_s2;
    assign btn_pressed = held_s2 & ~held_prev;

endmodule
