`timescale 1ns / 1ps

module tb_move_controller;
`include "cube_defs.vh"

    reg clk;
    reg rst;
    reg [2:0] stage;
    reg [4:0] manual_move;
    reg [4:0] scr_move;
    reg [4:0] sol_move;
    reg manual_valid;
    reg scr_valid;
    reg sol_valid;
    wire [4:0] move_req;
    wire move_valid;

    integer errors;
    integer checks;

    move_controller dut (
        .clk(clk),
        .rst(rst),
        .stage(stage),
        .manual_move(manual_move),
        .scr_move(scr_move),
        .sol_move(sol_move),
        .manual_valid(manual_valid),
        .scr_valid(scr_valid),
        .sol_valid(sol_valid),
        .move_req(move_req),
        .move_valid(move_valid)
    );

    always #5 clk = ~clk;

    task expect_output;
        input [4:0] expected_move;
        input expected_valid;
        input [8*48-1:0] description;
        begin
            #1;
            if (move_req !== expected_move || move_valid !== expected_valid) begin
                $display("FAIL: %0s (got move=%0d valid=%0b, expected move=%0d valid=%0b)",
                         description, move_req, move_valid, expected_move, expected_valid);
                errors = errors + 1;
            end
            checks = checks + 1;
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        stage = STAGE_START;
        manual_move = MV_U;
        scr_move = MV_F;
        sol_move = MV_B;
        manual_valid = 1'b1;
        scr_valid = 1'b1;
        sol_valid = 1'b1;
        errors = 0;
        checks = 0;

        if (STAGE_START !== 3'd0 || STAGE_AUTO_SCRAMBLE !== 3'd1 ||
            STAGE_MANUAL_SCRAMBLE !== 3'd2 || STAGE_SCRAMBLED !== 3'd3 ||
            STAGE_SOLVING !== 3'd4 || STAGE_MANUAL_SOLVING !== 3'd5 ||
            STAGE_SOLVED !== 3'd6 || STAGE_ERROR !== 3'd7) begin
            $display("FAIL: shared stage constants do not match the group stage plan");
            errors = errors + 1;
        end
        checks = checks + 1;

        expect_output(MV_NONE, 1'b0, "reset blocks all sources");

        rst = 1'b0;
        stage = STAGE_START;
        expect_output(MV_NONE, 1'b0, "start stage accepts no move source");

        stage = STAGE_AUTO_SCRAMBLE;
        expect_output(MV_F, 1'b1, "automatic scramble stage accepts scrambler move");
        scr_valid = 1'b0;
        expect_output(MV_NONE, 1'b0, "automatic scramble waits when scrambler is invalid");

        stage = STAGE_MANUAL_SCRAMBLE;
        scr_valid = 1'b1;
        expect_output(MV_U, 1'b1, "manual scramble stage accepts manual move");
        manual_move = 5'd18;
        expect_output(MV_NONE, 1'b0, "manual scramble stage rejects invalid move code");
        manual_move = MV_U;
        manual_valid = 1'b0;
        expect_output(MV_NONE, 1'b0, "manual scramble waits when manual input is invalid");

        stage = STAGE_SCRAMBLED;
        manual_valid = 1'b1;
        sol_valid = 1'b1;
        expect_output(MV_NONE, 1'b0, "scrambled stage accepts no cube moves");

        stage = STAGE_SOLVING;
        manual_valid = 1'b0;
        expect_output(MV_B, 1'b1, "solving stage accepts solver move");

        // A manual move wins over a simultaneous solver pulse, so the solver
        // move is not sent to cube_engine in this cycle.
        manual_move = MV_R2;
        manual_valid = 1'b1;
        expect_output(MV_R2, 1'b1, "manual move preempts solver during solve");

        // Invalid manual codes do not block a valid solver move.
        manual_move = 5'd18;
        expect_output(MV_B, 1'b1, "invalid manual code falls through to solver");
        manual_valid = 1'b0;
        sol_move = 5'd18;
        expect_output(MV_NONE, 1'b0, "invalid solver code is rejected");

        scr_valid = 1'b1;
        stage = STAGE_START;
        manual_move = MV_U;
        manual_valid = 1'b1;
        sol_move = MV_B;
        sol_valid = 1'b1;
        stage = STAGE_SOLVED;
        expect_output(MV_NONE, 1'b0, "solved stage rejects move requests");
        stage = STAGE_ERROR;
        expect_output(MV_NONE, 1'b0, "error stage rejects move requests");

        if (errors == 0)
            $display("PASS: manual, scramble and solver routing, stage gating, invalid codes, reset and manual solve preemption (%0d checks)", checks);
        else
            $display("FAIL: %0d move_controller checks failed (%0d checks)", errors, checks);
        $finish;
    end
endmodule
