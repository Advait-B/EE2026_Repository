`timescale 1ns / 1ps

// solver_search.v
// Task 5.3: IDA* search with a growing depth limit and a bounded stack.
// Fixes the DBL corner (recolour), then searches U, R and F turns only.
// Finds a shortest solution and outputs the whole plan.

module solver_search (
    input clk, // 100 MHz clock
    input rst, // reset
    input start, // pulse: begin searching cube
    input cancel, // pulse: abort search
    input [71:0] cube, // cube to solve
    output busy, // 1 while searching
    output reg found, // pulse: plan is ready
    output reg fail, // pulse: no solution within MAX_DEPTH
    output reg [3:0] sol_len, // number of moves in plan
    output reg [54:0] plan // move k at plan[k*5 +: 5], unused slots = MV_NONE
);
`include "cube_defs.vh"

    localparam MAX_DEPTH = 11; // longest 2x2 solution with U, R, F turns
    localparam N_SEARCH_MOVES = 9; // moves 0-8: U, R, F turns

    localparam [2:0] S_IDLE = 3'd0, // wait for start
                     S_ITER = 3'd1, // restart from the root with a new bound
                     S_EXPAND = 3'd2, // pick the next move, or backtrack
                     S_ADDR = 3'd3, // register the table addresses
                     S_READ = 3'd4, // wait 1 cycle for the table output
                     S_CHECK = 3'd5; // goal test, then push or skip

    // opposite colour: white-yellow, red-orange, green-blue
    function automatic [2:0] opposite_colour(input [2:0] c);
        opposite_colour = (c <= 3'd3) ? c + 3'd3 : c - 3'd3;
    endfunction

    // recolour so the corner in the DBL slot counts as solved
    function automatic [71:0] recolour(input [71:0] c);
        reg [2:0] d_col, b_col, l_col;
        reg [2:0] col;
        integer s;
        begin
            d_col = get_sticker(c, corner_sticker(3'd6, 2'd0));
            b_col = get_sticker(c, corner_sticker(3'd6, 2'd1));
            l_col = get_sticker(c, corner_sticker(3'd6, 2'd2));
            for (s = 0; s < N_STICKERS; s = s + 1) begin
                col = c[s*3 +: 3];
                if (col == d_col) recolour[s*3 +: 3] = COL_YELLOW;
                else if (col == b_col) recolour[s*3 +: 3] = COL_BLUE;
                else if (col == l_col) recolour[s*3 +: 3] = COL_ORANGE;
                else if (col == opposite_colour(d_col)) recolour[s*3 +: 3] = COL_WHITE;
                else if (col == opposite_colour(b_col)) recolour[s*3 +: 3] = COL_GREEN;
                else recolour[s*3 +: 3] = COL_RED;
            end
        end
    endfunction

    reg [2:0] state;
    reg [3:0] depth; // current stack level
    reg [3:0] bound; // depth limit for this iteration
    reg [71:0] cube_at [0:MAX_DEPTH]; // cube at each stack level
    reg [3:0] next_move [0:MAX_DEPTH]; // next move to try at each level
    reg [4:0] move; // move being checked
    reg [71:0] child; // cube after move
    reg [11:0] ori_addr;
    reg [15:0] perm_addr;
    integer i;

    wire [4:0] try_move = {1'b0, next_move[depth]};
    wire [4:0] prev_move = plan[(depth - 4'd1)*5 +: 5];
    wire skip = (depth != 4'd0) && same_face(try_move, prev_move); // task 5.4

    // child cube for the move being tried
    wire [71:0] child_next;
    move_rules rules (
        .cube_in(cube_at[depth]),
        .move(try_move),
        .cube_out(child_next)
    );

    // child cube -> table addresses
    wire [11:0] ori_addr_next;
    wire [15:0] perm_addr_next;
    cube_encode encode (
        .cube(child),
        .ori_addr(ori_addr_next),
        .perm_addr(perm_addr_next)
    );

    // task 5.2: table lookup
    wire [3:0] ori_dist, perm_dist;
    pattern_rom tables (
        .clk(clk),
        .ori_addr(ori_addr),
        .perm_addr(perm_addr),
        .ori_dist(ori_dist),
        .perm_dist(perm_dist)
    );

    wire [3:0] h = (ori_dist > perm_dist) ? ori_dist : perm_dist;

    assign busy = (state != S_IDLE);

    always @(posedge clk) begin
        found <= 1'b0;
        fail <= 1'b0;

        if (rst || cancel) begin
            state <= S_IDLE;
        end else begin
            case (state)
                S_IDLE: begin
                    if (start) begin
                        plan <= {11{MV_NONE}};
                        if (is_solved(cube)) begin
                            sol_len <= 4'd0;
                            found <= 1'b1;
                        end else begin
                            cube_at[0] <= recolour(cube);
                            bound <= 4'd1;
                            state <= S_ITER;
                        end
                    end
                end

                S_ITER: begin
                    depth <= 4'd0;
                    next_move[0] <= 4'd0;
                    state <= S_EXPAND;
                end

                S_EXPAND: begin
                    if (next_move[depth] == N_SEARCH_MOVES) begin
                        // every move tried at this level: backtrack
                        if (depth != 4'd0) begin
                            depth <= depth - 4'd1;
                        end else if (bound == MAX_DEPTH) begin
                            fail <= 1'b1;
                            state <= S_IDLE;
                        end else begin
                            bound <= bound + 4'd1;
                            state <= S_ITER;
                        end
                    end else begin
                        next_move[depth] <= next_move[depth] + 4'd1;
                        if (!skip) begin
                            move <= try_move;
                            child <= child_next;
                            state <= S_ADDR;
                        end
                    end
                end

                S_ADDR: begin
                    ori_addr <= ori_addr_next;
                    perm_addr <= perm_addr_next;
                    state <= S_READ;
                end

                S_READ: begin
                    state <= S_CHECK;
                end

                S_CHECK: begin
                    if (h == 4'd0) begin
                        // solved: the plan is the stack plus this move
                        for (i = 0; i < MAX_DEPTH; i = i + 1)
                            if (i > depth)
                                plan[i*5 +: 5] <= MV_NONE;
                        plan[depth*5 +: 5] <= move;
                        sol_len <= depth + 4'd1;
                        found <= 1'b1;
                        state <= S_IDLE;
                    end else begin
                        if ({1'b0, depth} + 5'd1 + {1'b0, h} <= {1'b0, bound}) begin
                            // push: go one level deeper
                            plan[depth*5 +: 5] <= move;
                            cube_at[depth + 1] <= child;
                            next_move[depth + 1] <= 4'd0;
                            depth <= depth + 4'd1;
                        end
                        state <= S_EXPAND;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
