`timescale 1ns / 1ps

// scrambler: 25 random moves via LFSR, never the same face twice in a row. Owner: Louisa

module scrambler #(
    parameter N_SCRAMBLE = 25
)(
    input wire clk,
    input wire rst,
    input wire start, // 1-cycle pulse from game_fsm
    input wire tick_slow,
    output wire [4:0] scr_move,
    output wire scr_valid, // 1-cycle, on tick_slow
    output wire busy,
    output wire scramble_done // 1-cycle pulse after last move
);
    `include "cube_defs.vh"
endmodule
