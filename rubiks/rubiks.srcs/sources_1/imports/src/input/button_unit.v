`timescale 1ns / 1ps

// button_unit.v
// Debounces the five push buttons and makes 1-cycle press pulses.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module button_unit (
    input clk, // 100 MHz clock
    input debounce_clk,
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

    always @(posedge clk) begin
    
        if (btn_pressed[3]) selectedoption <= selectedoption == 3'd1 ? 3'd6 : selectedoption-1; //up button
        else if (btn_pressed[0]) selectedoption <= selectedoption == 3'd6 ? 3'd1 : selectedoption+1; //down button

    end


endmodule
