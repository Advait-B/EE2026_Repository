`timescale 1ns / 1ps

module tb_cube_engine;
`include "cube_defs.vh"

    reg clk;
    reg rst;
    reg cube_reset;
    reg [4:0] move_req;
    reg move_valid;
    wire [71:0] cube;
    wire [15:0] move_count;

    reg [71:0] expected_cube;
    reg [71:0] expected_next;
    reg [15:0] expected_count;
    wire [71:0] reference_next;

    integer errors;
    integer checks;
    integer m;
    integer errors_at_group_start;

    cube_engine dut (
        .clk(clk),
        .rst(rst),
        .cube_reset(cube_reset),
        .move_req(move_req),
        .move_valid(move_valid),
        .cube(cube),
        .move_count(move_count)
    );

    // Use move_rules as the reference transition function. The existing
    // tb_move_rules independently checks its sticker permutations.
    move_rules reference_rules (
        .cube_in(expected_cube),
        .move(move_req),
        .cube_out(reference_next)
    );

    always #5 clk = ~clk;

    task check_state;
        input [71:0] wanted_cube;
        input [15:0] wanted_count;
        input [8*64-1:0] description;
        begin
            checks = checks + 1;
            if ((cube !== wanted_cube) || (move_count !== wanted_count)) begin
                $display("FAIL: %0s (cube=%h count=%0d, expected cube=%h count=%0d)",
                         description, cube, move_count, wanted_cube, wanted_count);
                errors = errors + 1;
            end
        end
    endtask

    task apply_move;
        input [4:0] code;
        begin
            @(negedge clk);
            move_req = code;
            move_valid = 1'b1;
            #1;
            expected_next = reference_next;

            @(posedge clk);
            #1;
            expected_cube = expected_next;
            expected_count = expected_count + 16'd1;
            check_state(expected_cube, expected_count, "valid engine move");
        end
    endtask

    task reset_with_move;
        input reset_kind;
        input [4:0] simultaneous_move;
        input [8*64-1:0] description;
        reg [71:0] cube_before_edge;
        reg [15:0] count_before_edge;
        begin
            @(negedge clk);
            cube_before_edge = expected_cube;
            count_before_edge = expected_count;
            rst = (reset_kind == 1'b0);
            cube_reset = (reset_kind == 1'b1);
            move_req = simultaneous_move;
            move_valid = 1'b1;
            #1;

            checks = checks + 1;
            if ((cube !== cube_before_edge) || (move_count !== count_before_edge)) begin
                $display("FAIL: synchronous reset changed state before rising edge");
                errors = errors + 1;
            end

            @(posedge clk);
            #1;
            expected_cube = SOLVED_CUBE;
            expected_count = 16'd0;
            check_state(expected_cube, expected_count, description);

            @(negedge clk);
            rst = 1'b0;
            cube_reset = 1'b0;
            move_valid = 1'b0;
            move_req = MV_NONE;
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        cube_reset = 1'b0;
        move_req = MV_NONE;
        move_valid = 1'b0;
        expected_cube = SOLVED_CUBE;
        expected_count = 16'd0;
        expected_next = SOLVED_CUBE;
        errors = 0;
        checks = 0;

        // Startup reset is synchronous and initializes both outputs.
        @(posedge clk);
        #1;
        check_state(SOLVED_CUBE, 16'd0, "rst initializes solved cube and zero count");
        @(negedge clk);
        rst = 1'b0;

        // Each of the 18 legal move codes is tested from the solved state.
        errors_at_group_start = errors;
        for (m = 0; m < N_MOVES; m = m + 1) begin
            reset_with_move(1'b1, MV_R, "cube_reset overrides simultaneous move");
            apply_move(m[4:0]);
            check_state(expected_cube, 16'd1, "isolated turn increments count once");
        end
        if (errors == errors_at_group_start)
            $display("PASS: all 18 legal turns applied through cube_engine from solved state");
        else
            $display("FAIL: isolated cube_engine turn checks reported errors");

        // Apply all 18 codes as one sequence, then undo in reverse order.
        reset_with_move(1'b1, MV_NONE, "sequence setup reset");
        errors_at_group_start = errors;
        for (m = 0; m < N_MOVES; m = m + 1)
            apply_move(m[4:0]);
        check_state(expected_cube, 16'd18, "18-move sequence count");

        for (m = N_MOVES - 1; m >= 0; m = m - 1)
            apply_move(move_inverse(m[4:0]));
        check_state(SOLVED_CUBE, 16'd36, "reverse inverse sequence restores solved cube");
        if (errors == errors_at_group_start)
            $display("PASS: cumulative 18-move sequence, exact count, and reverse-inverse restoration");
        else
            $display("FAIL: move-sequence checks reported errors");

        // A low valid flag and every unused move code must hold both outputs.
        @(negedge clk);
        move_req = MV_U;
        move_valid = 1'b0;
        @(posedge clk);
        #1;
        check_state(expected_cube, expected_count, "move_valid low leaves state and count unchanged");

        errors_at_group_start = errors;
        for (m = N_MOVES; m < 32; m = m + 1) begin
            @(negedge clk);
            move_req = m[4:0];
            move_valid = 1'b1;
            @(posedge clk);
            #1;
            check_state(expected_cube, expected_count, "invalid move code leaves state and count unchanged");
        end
        if (errors == errors_at_group_start)
            $display("PASS: move_valid gating and invalid codes 18 through 31");
        else
            $display("FAIL: ignored-move checks reported errors");

        // rst also has priority over a valid move, after state has changed.
        apply_move(MV_B);
        reset_with_move(1'b0, MV_D2, "rst overrides simultaneous move");
        check_state(SOLVED_CUBE, 16'd0, "rst reset outputs remain cleared");

        if (errors == 0)
            $display("PASS: tb_cube_engine (%0d checks)", checks);
        else
            $display("FAIL: tb_cube_engine had %0d errors across %0d checks", errors, checks);
        $finish;
    end
endmodule
