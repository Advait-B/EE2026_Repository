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

    reg [4:0] selected_move;
    reg selected_valid;

    assign move_req = selected_move;
    assign move_valid = selected_valid;

    // Route only the move source allowed by the seven-stage group plan. During
    // solve, manual input preempts a simultaneous solver move. The game_fsm
    // must pair that action with its solve_cancel pulse.
    always @* begin
        selected_move = MV_NONE;
        selected_valid = 1'b0;

        if (!rst) begin
            case (stage)
                STAGE_AUTO_SCRAMBLE: begin
                    if (scr_valid && move_is_valid(scr_move)) begin
                        selected_move = scr_move;
                        selected_valid = 1'b1;
                    end
                end

                STAGE_MANUAL_SCRAMBLE, STAGE_MANUAL_SOLVING: begin
                    if (manual_valid && move_is_valid(manual_move)) begin
                        selected_move = manual_move;
                        selected_valid = 1'b1;
                    end
                end

                STAGE_SOLVING: begin
                    if (manual_valid && move_is_valid(manual_move)) begin
                        selected_move = manual_move;
                        selected_valid = 1'b1;
                    end else if (sol_valid && move_is_valid(sol_move)) begin
                        selected_move = sol_move;
                        selected_valid = 1'b1;
                    end
                end

                STAGE_START, STAGE_SCRAMBLED, STAGE_SOLVED, STAGE_ERROR: begin
                    selected_move = MV_NONE;
                    selected_valid = 1'b0;
                end

                default: begin
                    selected_move = MV_NONE;
                    selected_valid = 1'b0;
                end
            endcase
        end
    end

endmodule
