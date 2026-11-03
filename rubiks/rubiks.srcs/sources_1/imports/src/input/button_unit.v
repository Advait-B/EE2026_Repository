`timescale 1ns / 1ps

// button_unit.v
// Debounces the five push buttons and makes 1-cycle press pulses.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module button_unit (
    input clk, // 100 MHz clock
    input rst, // reset, selection goes back to the first option
    input debounce_clk,
    input [2:0] stage,

    input [4:0] btn_raw, // raw buttons, {C, U, L, R, D}
    // output debugled,
    output [4:0] btn_held, // debounced level
    output [4:0] btn_pressed, // 1-cycle pulse on press
    output reg [2:0] selectedoption
);
`include "cube_defs.vh"

    initial begin
        selectedoption <= 3'b1;
    end

    // assign debugled = debounce_clk;
    
    debouncer DBbtnC(
        clk,
        debounce_clk,
        btn_raw[4],
        btn_held[4],
        btn_pressed[4]
    );
    debouncer DBbtnU(
        clk,
        debounce_clk,
        btn_raw[3],
        btn_held[3],
        btn_pressed[3]
    );
    debouncer DBbtnL(
        clk,
        debounce_clk,
        btn_raw[2],
        btn_held[2],
        btn_pressed[2]
    );
    debouncer DBbtnR(
        clk,
        debounce_clk,
        btn_raw[1],
        btn_held[1],
        btn_pressed[1]
    );
    debouncer DBbtnD(
        clk,
        debounce_clk,
        btn_raw[0],
        btn_held[0],
        btn_pressed[0]
    );
    
    wire [2:0] wraparound =
        stage == STAGE_START ?              3'd2 :
        stage == STAGE_AUTO_SCRAMBLE ?      3'd1 :
        stage == STAGE_MANUAL_SCRAMBLE ?    3'd6 :
        stage == STAGE_SCRAMBLED ?          3'd2 :
        stage == STAGE_SOLVING ?            3'd2 :
        stage == STAGE_SOLVED ?             3'd1 :
        stage == STAGE_ERROR ?              3'd1 :
        3'd6;

    always @(posedge clk) begin
        if (rst) selectedoption <= 3'd1;
        if (btn_pressed[3]) selectedoption <= selectedoption == 3'd1 ? wraparound : selectedoption-1; //up button
        else if (btn_pressed[0]) selectedoption <= selectedoption == wraparound ? 3'd1 : selectedoption+1; //down button

    end


endmodule
