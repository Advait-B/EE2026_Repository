`timescale 1ns / 1ps

// Self-checking testbench for solver_search (task 5.3).
// Each test cube's plan is applied with move_rules and must leave the cube
// solved, using exactly the expected (shortest) number of moves.
// Cubes and lengths come from python/solver.py: solved, 1-3 move and 25-move scrambles.

module tb_solver_search;
`include "cube_defs.vh"

    localparam N_TESTS = 10;

    reg clk;
    reg rst;
    reg start;
    reg cancel;
    reg [71:0] cube;
    wire busy, found, fail;
    wire [3:0] sol_len;
    wire [54:0] plan;

    reg [71:0] cubes [0:N_TESTS-1];
    reg [3:0] lengths [0:N_TESTS-1];
    reg [71:0] check_cube;
    reg [4:0] check_move;
    wire [71:0] check_next;
    integer k, m, cycles, errors;

    solver_search dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .cancel(cancel),
        .cube(cube),
        .busy(busy),
        .found(found),
        .fail(fail),
        .sol_len(sol_len),
        .plan(plan)
    );

    move_rules apply (
        .cube_in(check_cube),
        .move(check_move),
        .cube_out(check_next)
    );

    always #5 clk = ~clk;

    initial begin
        $readmemh("solver_search_cubes.mem", cubes);
        $readmemh("solver_search_lengths.mem", lengths);
        clk = 1'b0;
        rst = 1'b1;
        start = 1'b0;
        cancel = 1'b0;
        cube = SOLVED_CUBE;
        errors = 0;
        repeat (3) @(posedge clk);
        #1 rst = 1'b0;

        for (k = 0; k < N_TESTS; k = k + 1) begin
            cube = cubes[k];
            @(posedge clk); #1 start = 1'b1;
            @(posedge clk); #1 start = 1'b0;
            cycles = 0;
            while (!found && !fail) begin
                @(posedge clk); #1 cycles = cycles + 1;
            end

            // replay the plan on the original cube
            check_cube = cubes[k];
            for (m = 0; m < sol_len; m = m + 1) begin
                check_move = plan[m*5 +: 5];
                #1 check_cube = check_next;
            end

            if (fail || !is_solved(check_cube) || sol_len != lengths[k]) begin
                $display("FAIL test %0d: fail=%0d sol_len=%0d expected=%0d plan=%h",
                         k, fail, sol_len, lengths[k], plan);
                errors = errors + 1;
            end else begin
                $display("ok   test %0d: %0d moves, %0d cycles", k, sol_len, cycles);
            end
        end

        if (errors == 0) $display("PASS: all %0d tests", N_TESTS);
        else $display("FAILED: %0d of %0d tests", errors, N_TESTS);
        $finish;
    end

endmodule
