`timescale 1ns / 1ps

// move_controller: picks the active move source (manual, scrambler, solver) and decodes manual button moves. Owner: Louisa

module move_controller (
    input wire clk,
    input wire rst,
    input wire [2:0] stage,
    input wire manual_en,
    input wire [4:0] btn_pulse,
    input wire [15:0] sw, // e.g. sw[2:0] selects face
    input wire [4:0] scr_move,
    input wire scr_valid,
    input wire [4:0] sol_move,
    input wire sol_valid,
    output wire [4:0] move_req, // MV_*
    output wire move_valid // 1-cycle, at most one move per cycle
);
    `include "cube_defs.vh"
endmodule
