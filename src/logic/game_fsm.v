`timescale 1ns / 1ps

// game_fsm: holds the stage and enables the module that should act, never moves the cube itself. Owner: Su Yi

module game_fsm (
    input wire clk,
    input wire rst,
    input wire [4:0] btn_pulse,
    input wire [15:0] sw,
    input wire m_left,
    input wire cursor_on_cube,
    input wire [4:0] cursor_tile,
    input wire [71:0] cube, // e.g. compare with CUBE_SOLVED
    input wire cube_valid, // from cube_encode
    input wire [2:0] enc_err,
    input wire scramble_done,
    input wire solve_done,
    input wire solve_err,
    output wire [2:0] stage, // ST_*
    output wire [1:0] menu_sel, // highlighted menu item
    output wire slow_en, // runs tick_slow in ST_SCRAMBLING / ST_SOLVING
    output wire manual_en, // manual turns allowed
    output wire scramble_start, // 1-cycle pulse
    output wire solve_start, // 1-cycle pulse, only if cube_valid
    output wire solve_cancel,
    output wire cube_reset, // 1-cycle pulse, cube back to solved
    output wire paint_en, // 1-cycle pulse, write paint_colour into paint_tile
    output wire [4:0] paint_tile,
    output wire [2:0] paint_colour, // currently selected palette colour
    output wire [2:0] err_code // ERR_*, shown in ST_ERROR
);
    `include "cube_defs.vh"
endmodule
