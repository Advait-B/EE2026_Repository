`timescale 1ns / 1ps

// solver.v
// Tasks 5.5 and 5.6: finds a solution for the current cube, then plays it back one move per 4 Hz tick.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module solver (
    input clk, // 100 MHz clock
    input rst, // reset
    input start, cancel, // pulses: begin solving, abort
    input tick, // one move per tick during playback
    input [71:0] cube, // cube to solve
    output [4:0] sol_move, // next solution move
    output sol_valid, // pulse when sol_move is ready
    output busy, // searching or playing back
    output done, err, // pulses: cube solved, timeout or cancel
    output [3:0] moves_left, // solution moves remaining
    output [54:0] plan_left // queued solution moves, next at [4:0], unused = MV_NONE
);
`include "cube_defs.vh"

    // give up if the search runs longer than this (100 MHz cycles, 5 s)
    parameter SEARCH_TIMEOUT = 500_000_000;

    localparam [1:0] S_IDLE = 2'd0, // wait for start
                     S_SEARCH = 2'd1, // solver_search is running
                     S_PLAY = 2'd2, // send one move per tick
                     S_FINISH = 2'd3; // pulse done

    reg [1:0] state;
    reg [54:0] plan_buf; // move k at plan_buf[k*5 +: 5]; next move is slot 0
    reg [3:0] left;
    reg [4:0] move_out;
    reg valid_out, done_out, err_out;
    reg [31:0] timer; // cycles spent searching

    // task 5.6 watchdog: a plan found on the last cycle still wins
    wire timeout = (state == S_SEARCH) && (timer == SEARCH_TIMEOUT - 1) && !found;
    wire abort = (state != S_IDLE) && (cancel || timeout);

    // search core (tasks 5.1-5.4)
    wire search_busy, found, fail;
    wire [3:0] sol_len;
    wire [54:0] plan;
    solver_search search (
        .clk(clk),
        .rst(rst),
        .start(start && state == S_IDLE),
        .cancel(abort),
        .cube(cube),
        .busy(search_busy),
        .found(found),
        .fail(fail),
        .sol_len(sol_len),
        .plan(plan)
    );

    assign sol_move = move_out;
    assign sol_valid = valid_out;
    assign busy = (state != S_IDLE);
    assign done = done_out;
    assign err = err_out;
    assign moves_left = left;
    assign plan_left = plan_buf;

    always @(posedge clk) begin
        valid_out <= 1'b0;
        done_out <= 1'b0;
        err_out <= 1'b0;

        if (rst) begin
            state <= S_IDLE;
            plan_buf <= {11{MV_NONE}};
            left <= 4'd0;
            move_out <= MV_NONE;
            timer <= 32'd0;
        end else if (abort) begin
            // cancel or timeout: stop searching or playing, report error
            err_out <= timeout;
            plan_buf <= {11{MV_NONE}};
            left <= 4'd0;
            state <= S_IDLE;
        end else begin
            case (state)
                S_IDLE: begin
                    if (start) begin
                        timer <= 32'd0;
                        state <= S_SEARCH;
                    end
                end

                S_SEARCH: begin
                    timer <= timer + 32'd1;
                    if (fail) begin
                        err_out <= 1'b1;
                        state <= S_IDLE;
                    end else if (found) begin
                        plan_buf <= plan;
                        left <= sol_len;
                        if (sol_len == 4'd0)
                            state <= S_FINISH;
                        else
                            state <= S_PLAY;
                    end
                end

                S_PLAY: begin
                    if (tick) begin
                        move_out <= plan_buf[4:0];
                        valid_out <= 1'b1;
                        plan_buf <= {MV_NONE, plan_buf[54:5]};
                        left <= left - 4'd1;
                        if (left == 4'd1)
                            state <= S_FINISH;
                    end
                end

                S_FINISH: begin
                    done_out <= 1'b1;
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
