`timescale 1ns / 1ps

// button_unit: sync and debounce the 5 push buttons. Owner: Su Yi

module button_unit (
    input wire clk,
    input wire rst,
    input wire tick_1k,
    input wire [4:0] btn_raw, // {C, U, L, R, D}, index with BTN_*
    output wire [4:0] btn_level, // debounced, high while held
    output wire [4:0] btn_pulse // 1-cycle pulse per press (200 ms lockout)
);
    `include "cube_defs.vh"
endmodule
