`timescale 1ns / 1ps

// anode_unit: 7-seg shows move count, solution length or menu option, multiplexed on tick_1k. Owner: Su Yi

module anode_unit (
    input wire clk,
    input wire rst,
    input wire tick_1k,
    input wire [2:0] stage,
    input wire [1:0] menu_sel,
    input wire [7:0] move_count,
    input wire [3:0] sol_len,
    output wire [6:0] seg, // active low
    output wire dp, // active low
    output wire [3:0] an // active low
);
    `include "cube_defs.vh"
endmodule
