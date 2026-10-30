`timescale 1ns / 1ps

// Task 5.7: benchmark and verify the full solver against the Python reference.
// 100 cubes from python/gen_solver_bench.py: solved, all 18 single moves, short
// scrambles, 25-move scrambles, and cubes exactly 10 and 11 moves from solved.
//
// For every cube it checks:
//   - the search plan is exactly the Python plan (same moves, same order)
//   - playback sends exactly those moves, one per tick, and solves the cube
//   - moves_left counts down, done pulses once right after the last move,
//     err never pulses, busy drops at the end
//   - time to first move <= 1 s on the board
//
// Timing: the testbench ticks every TICK_P cycles so playback is quick to
// simulate. On the board tick_4hz is free-running, so the first move waits
// up to DIV_4HZ cycles after the search ends. The worst case reported is
// search cycles + 1 + DIV_4HZ, which must be <= CLK_HZ (1 s).
// Results are also written to solver_bench_results.csv.

module tb_solver_bench;
`include "cube_defs.vh"

    localparam N_TESTS = 100;
    localparam TICK_P = 64; // testbench tick period, cycles
    localparam GUARD = 200_000_000; // per-case simulation limit, cycles

    reg clk;
    reg rst;
    reg start;
    reg cancel;
    reg tick;
    reg [71:0] cube; // live cube, updated by every played move
    wire [4:0] sol_move;
    wire sol_valid, busy, done, err;
    wire [3:0] moves_left;

    reg [71:0] cubes [0:N_TESTS-1];
    reg [54:0] plans [0:N_TESTS-1];
    reg [3:0] lengths [0:N_TESTS-1];

    solver dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .cancel(cancel),
        .tick_4hz(tick),
        .cube(cube),
        .sol_move(sol_move),
        .sol_valid(sol_valid),
        .busy(busy),
        .done(done),
        .err(err),
        .moves_left(moves_left)
    );

    // apply played moves, like cube_engine
    wire [71:0] cube_next;
    move_rules apply (
        .cube_in(cube),
        .move(sol_move),
        .cube_out(cube_next)
    );

    always #5 clk = ~clk;

    // free-running tick, like tick_gen
    integer tick_cnt;
    always @(posedge clk) begin
        if (rst) begin
            tick_cnt <= 0;
            tick <= 1'b0;
        end else begin
            tick_cnt <= (tick_cnt == TICK_P - 1) ? 0 : tick_cnt + 1;
            tick <= (tick_cnt == TICK_P - 1);
        end
    end

    // ---------------------------------------------------------------
    // Monitor: timestamps and per-case checks
    // ---------------------------------------------------------------
    integer now; // cycle counter
    integer t_start, t_found, t_first, t_last, t_done;
    integer n_moves, n_done, n_err;
    reg bad_plan, bad_move, bad_left, bad_gap;
    reg [54:0] hw_plan;
    reg [3:0] hw_len;
    reg [54:0] exp_plan;
    reg [3:0] exp_len;

    always @(posedge clk) begin
        if (rst) now <= 0;
        else now <= now + 1;

        if (sol_valid) cube <= cube_next;

        if (start && !busy) t_start <= now;

        if (dut.search.found && dut.state == 2'd1) begin
            t_found <= now;
            hw_plan <= dut.search.plan;
            hw_len <= dut.search.sol_len;
            if (dut.search.plan !== exp_plan || dut.search.sol_len !== exp_len)
                bad_plan <= 1'b1;
        end

        if (sol_valid) begin
            if (n_moves == 0) t_first <= now;
            else if (now - t_last != TICK_P) bad_gap <= 1'b1;
            t_last <= now;
            if (sol_move !== exp_plan[n_moves*5 +: 5]) bad_move <= 1'b1;
            if (moves_left !== exp_len - n_moves - 1) bad_left <= 1'b1;
            n_moves <= n_moves + 1;
        end

        if (done) begin
            n_done <= n_done + 1;
            t_done <= now;
        end
        if (err) n_err <= n_err + 1;
    end

    // ---------------------------------------------------------------
    // Test sequence
    // ---------------------------------------------------------------
    integer k, c, fd, errors, search_cyc, worst_first;
    integer max_search, max_k, sum_search;
    integer cat_max [0:5];
    integer cat_cnt [0:5];
    integer cat;
    reg ok;

    function integer category(input integer idx);
        if (idx == 0) category = 0; // solved
        else if (idx <= 18) category = 1; // single move
        else if (idx <= 39) category = 2; // 2-6 move scramble
        else if (idx <= 79) category = 3; // 25-move scramble
        else if (idx <= 89) category = 4; // distance 10
        else category = 5; // distance 11
    endfunction

    initial begin
        $readmemh("solver_bench_cubes.mem", cubes);
        $readmemh("solver_bench_plans.mem", plans);
        $readmemh("solver_bench_lengths.mem", lengths);
        fd = $fopen("solver_bench_results.csv", "w");
        $fdisplay(fd, "case,category,moves,search_cycles,search_us,worst_first_move_ms,pass");

        clk = 1'b0;
        rst = 1'b1;
        start = 1'b0;
        cancel = 1'b0;
        cube = SOLVED_CUBE;
        errors = 0;
        max_search = 0;
        max_k = 0;
        sum_search = 0;
        for (c = 0; c < 6; c = c + 1) begin
            cat_max[c] = 0;
            cat_cnt[c] = 0;
        end
        repeat (3) @(posedge clk);
        #1 rst = 1'b0;

        for (k = 0; k < N_TESTS; k = k + 1) begin
            // reset the per-case monitor state
            cube = cubes[k];
            exp_plan = plans[k];
            exp_len = lengths[k];
            n_moves = 0;
            n_done = 0;
            n_err = 0;
            t_found = -1;
            t_first = -1;
            bad_plan = 1'b0;
            bad_move = 1'b0;
            bad_left = 1'b0;
            bad_gap = 1'b0;

            @(posedge clk); #1 start = 1'b1;
            @(posedge clk); #1 start = 1'b0;
            c = 0;
            while (busy && c < GUARD) begin
                @(posedge clk); #1 c = c + 1;
            end
            repeat (2) @(posedge clk);
            #1;

            search_cyc = t_found - t_start;
            worst_first = search_cyc + 1 + DIV_4HZ;

            ok = !bad_plan && !bad_move && !bad_left && !bad_gap
                 && n_moves == exp_len && n_done == 1 && n_err == 0
                 && is_solved(cube) && !busy && moves_left == 4'd0
                 && t_found >= 0 && worst_first <= CLK_HZ
                 && (exp_len == 0 || (t_first - t_found <= TICK_P + 1 && t_done == t_last + 1));

            cat = category(k);
            cat_cnt[cat] = cat_cnt[cat] + 1;
            if (search_cyc > cat_max[cat]) cat_max[cat] = search_cyc;
            if (search_cyc > max_search) begin
                max_search = search_cyc;
                max_k = k;
            end
            sum_search = sum_search + search_cyc;

            $fdisplay(fd, "%0d,%0d,%0d,%0d,%0d.%02d,%0d.%03d,%0d", k, cat, exp_len, search_cyc,
                      search_cyc / 100, search_cyc % 100,
                      worst_first / 100_000, worst_first % 100_000 / 100, ok);

            if (ok) begin
                $display("ok   case %2d: %2d moves, search %8d cycles (%5d us), worst first move %0d ms",
                         k, exp_len, search_cyc, search_cyc / 100, worst_first / 100_000);
            end else begin
                errors = errors + 1;
                $display("FAIL case %2d: plan %h exp %h len %0d exp %0d | moves %0d done %0d err %0d solved %0d busy %0d",
                         k, hw_plan, exp_plan, hw_len, exp_len, n_moves, n_done, n_err, is_solved(cube), busy);
                $display("     bad_plan %0d bad_move %0d bad_left %0d bad_gap %0d search %0d cycles",
                         bad_plan, bad_move, bad_left, bad_gap, search_cyc);
            end
        end
        $fclose(fd);

        $display("");
        $display("Search time by category (worst case):");
        $display("  solved           %2d cases  %8d cycles", cat_cnt[0], cat_max[0]);
        $display("  single move      %2d cases  %8d cycles", cat_cnt[1], cat_max[1]);
        $display("  2-6 move scr.    %2d cases  %8d cycles", cat_cnt[2], cat_max[2]);
        $display("  25-move scr.     %2d cases  %8d cycles", cat_cnt[3], cat_max[3]);
        $display("  distance 10      %2d cases  %8d cycles", cat_cnt[4], cat_max[4]);
        $display("  distance 11      %2d cases  %8d cycles", cat_cnt[5], cat_max[5]);
        $display("Slowest search: case %0d, %0d cycles = %0d.%02d ms; mean %0d cycles",
                 max_k, max_search, max_search / 100_000, max_search % 100_000 / 1000,
                 sum_search / N_TESTS);
        $display("Worst-case time to first move: %0d.%03d ms (limit 1000 ms)",
                 (max_search + 1 + DIV_4HZ) / 100_000, (max_search + 1 + DIV_4HZ) % 100_000 / 100);
        if (errors == 0) $display("PASS: all %0d cases match Python, solve the cube, and meet 1 s", N_TESTS);
        else $display("FAILED: %0d of %0d cases", errors, N_TESTS);
        $finish;
    end

endmodule
