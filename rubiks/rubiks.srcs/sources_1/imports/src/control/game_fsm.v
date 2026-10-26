`timescale 1ns / 1ps

// game_fsm.v
// Main game state machine: menu, free play, scramble, solve, solved, error.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module game_fsm (
    input clk, // 100 MHz clock
    input rst, // reset
    input [4:0] btn_pressed, // button pulses
    input [15:0] sw_sync, // switches
    input scramble_done, solve_done, // pulses: scrambler finished, solver finished
    input solve_err, // solver failed or timed out
    output [2:0] stage, // current game stage
    output scramble_start, solve_start, solve_cancel, cube_reset, // 1-cycle command pulses
    output [4:0] manual_move, // move chosen by the user
    output manual_valid // pulse when manual_move is ready
);
`include "cube_defs.vh"

endmodule
