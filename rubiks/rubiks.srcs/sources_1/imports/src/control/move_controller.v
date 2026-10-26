`timescale 1ns / 1ps

// move_controller.v
// Picks which move source (user, scrambler, solver) drives the cube engine for the current stage.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module move_controller (
    input clk, // 100 MHz clock
    input rst, // reset
    input [2:0] stage, // current game stage
    input [4:0] manual_move, scr_move, sol_move, // moves from user, scrambler, solver
    input manual_valid, scr_valid, sol_valid, // matching ready pulses
    output [4:0] move_req, // move sent to engine
    output move_valid // pulse when move_req is ready
);
`include "cube_defs.vh"

endmodule
