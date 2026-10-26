`timescale 1ns / 1ps

// solver: IDA* using BRAM pattern tables, stores the plan then plays it back. Owner: Advait

module solver (
    input wire clk,
    input wire rst,
    input wire start, // 1-cycle pulse, samples perm_idx / ori_idx
    input wire cancel,
    input wire tick_slow, // playback rate
    input wire [12:0] perm_idx,
    input wire [9:0] ori_idx,
    output wire [4:0] sol_move,
    output wire sol_valid, // 1-cycle per played move
    output wire busy,
    output wire solve_done, // 1-cycle pulse after last move played
    output wire solve_err, // watchdog / cancel
    output wire [3:0] sol_len, // length of found solution
    output wire [3:0] progress // moves played so far
);
    `include "cube_defs.vh"
endmodule
