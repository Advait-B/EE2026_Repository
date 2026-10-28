`timescale 1ns / 1ps

module tb_move_rules;
`include "cube_defs.vh"

    reg [71:0] cube_in;
    reg [4:0] move;
    wire [71:0] cube_out;
    reg clk;
    reg rst;
    reg cube_reset;
    reg [4:0] engine_move_req;
    reg engine_move_valid;
    wire [71:0] engine_cube;
    wire [15:0] engine_move_count;

    reg [71:0] saved_cube;
    reg [71:0] work_cube;
    reg [23:0] seen;
    integer m;
    integer s;
    integer d;
    integer found;
    integer count;
    integer errors;
    integer turn;
    integer face;
    integer tile;
    integer expected_tile;

    move_rules dut (
        .cube_in(cube_in),
        .move(move),
        .cube_out(cube_out)
    );

    cube_engine engine (
        .clk(clk),
        .rst(rst),
        .cube_reset(cube_reset),
        .move_req(engine_move_req),
        .move_valid(engine_move_valid),
        .cube(engine_cube),
        .move_count(engine_move_count)
    );

    always #5 clk = ~clk;

    initial begin
        errors = 0;
        clk = 1'b0;
        rst = 1'b1;
        cube_reset = 1'b0;
        engine_move_req = MV_NONE;
        engine_move_valid = 1'b0;
        cube_in = 72'd0;
        move = MV_NONE;
        #1;

        // Each move must map all 24 stickers to distinct destinations.
        for (m = 0; m < N_MOVES; m = m + 1) begin
            seen = 24'd0;
            for (s = 0; s < N_STICKERS; s = s + 1) begin
                cube_in = 72'd0;
                cube_in[s*3 +: 3] = 3'd1;
                move = m;
                #1;
                found = -1;
                count = 0;
                for (d = 0; d < N_STICKERS; d = d + 1) begin
                    if (cube_out[d*3 +: 3] != 3'd0) begin
                        found = d;
                        count = count + 1;
                    end
                end
                if (count != 1) begin
                    $display("FAIL: move %0d source %0d produced %0d marked stickers", m, s, count);
                    errors = errors + 1;
                end else if (seen[found]) begin
                    $display("FAIL: move %0d maps multiple stickers to destination %0d", m, found);
                    errors = errors + 1;
                end else begin
                    seen[found] = 1'b1;
                end
            end
            for (d = 0; d < N_STICKERS; d = d + 1) begin
                if (!seen[d]) begin
                    $display("FAIL: move %0d leaves destination %0d unmapped", m, d);
                    errors = errors + 1;
                end
            end
        end

        // A clockwise face turn maps each face tile t to (t+1) mod 4.
        // Also check the corresponding counter-clockwise and half-turn maps.
        for (face = 0; face < N_FACES; face = face + 1) begin
            for (tile = 0; tile < 4; tile = tile + 1) begin
                for (turn = 0; turn < 3; turn = turn + 1) begin
                    case (turn)
                        TURN_CW: expected_tile = (tile + 1) % 4;
                        TURN_CCW: expected_tile = (tile + 3) % 4;
                        default: expected_tile = (tile + 2) % 4;
                    endcase
                    cube_in = 72'd0;
                    cube_in[sticker_idx(face, tile)*3 +: 3] = 3'd1;
                    move = face*3 + turn;
                    #1;
                    if (cube_out[sticker_idx(face, expected_tile)*3 +: 3] !== 3'd1) begin
                        $display("FAIL: face %0d tile %0d turn type %0d reached the wrong tile", face, tile, turn);
                        errors = errors + 1;
                    end
                end
            end
        end

        // Side-strip example: F0 -> L0 under a clockwise U turn.
        cube_in = 72'd0;
        cube_in[sticker_idx(FACE_F, 2'd0)*3 +: 3] = 3'd1;
        move = MV_U;
        #1;
        if (cube_out[sticker_idx(FACE_L, 2'd0)*3 +: 3] !== 3'd1) begin
            $display("FAIL: F0 did not move to L0 under U");
            errors = errors + 1;
        end

        // Exercise inverse pairs, quarter-turn order, and half-turn order.
        for (m = 0; m < N_MOVES; m = m + 1) begin
            saved_cube = 72'd0;
            for (s = 0; s < N_STICKERS; s = s + 1)
                saved_cube[s*3 +: 3] = (s * 5 + 3) % 8;

            cube_in = saved_cube;
            move = m;
            #1;
            work_cube = cube_out;
            cube_in = work_cube;
            move = move_inverse(m);
            #1;
            if (cube_out !== saved_cube) begin
                $display("FAIL: move %0d followed by its inverse did not restore the cube", m);
                errors = errors + 1;
            end

            cube_in = saved_cube;
            move = m;
            if ((m % 3) == TURN_180) begin
                turn = 2;
                for (s = 0; s < turn; s = s + 1) begin
                    #1;
                    work_cube = cube_out;
                    cube_in = work_cube;
                end
            end else begin
                turn = 4;
                for (s = 0; s < turn; s = s + 1) begin
                    #1;
                    work_cube = cube_out;
                    cube_in = work_cube;
                end
            end
            if (work_cube !== saved_cube) begin
                $display("FAIL: move %0d has the wrong turn order", m);
                errors = errors + 1;
            end
        end

        // All unused 5-bit move codes retain the established no-op behavior.
        cube_in = 72'h123456789abcdef012;
        for (m = N_MOVES; m < 32; m = m + 1) begin
            move = m;
            #1;
            if (cube_out !== cube_in) begin
                $display("FAIL: invalid move code %0d changed the cube", m);
                errors = errors + 1;
            end
        end

        // The stateful engine must consume the shared move_rules mapping.
        rst = 1'b0;
        #1;
        if ((engine_cube !== SOLVED_CUBE) || (engine_move_count !== 16'd0)) begin
            $display("FAIL: engine reset did not initialize solved cube and zero move count");
            errors = errors + 1;
        end

        cube_in = SOLVED_CUBE;
        move = MV_U;
        #1;
        saved_cube = cube_out;

        engine_move_req = MV_U;
        engine_move_valid = 1'b0;
        #10;
        if ((engine_cube !== SOLVED_CUBE) || (engine_move_count !== 16'd0)) begin
            $display("FAIL: engine applied a move without move_valid");
            errors = errors + 1;
        end

        engine_move_valid = 1'b1;
        #10;
        engine_move_valid = 1'b0;
        #1;
        if ((engine_cube !== saved_cube) || (engine_move_count !== 16'd1)) begin
            $display("FAIL: engine did not apply the shared U mapping and increment once");
            errors = errors + 1;
        end

        engine_move_req = 5'd18;
        engine_move_valid = 1'b1;
        #10;
        engine_move_valid = 1'b0;
        #1;
        if ((engine_cube !== saved_cube) || (engine_move_count !== 16'd1)) begin
            $display("FAIL: engine invalid-move handling changed cube or count");
            errors = errors + 1;
        end

        cube_reset = 1'b1;
        #10;
        cube_reset = 1'b0;
        #1;
        if ((engine_cube !== SOLVED_CUBE) || (engine_move_count !== 16'd0)) begin
            $display("FAIL: cube_reset did not restore solved cube and zero move count");
            errors = errors + 1;
        end

        if (errors == 0) begin
            $display("PASS: 18 move permutations, face tile directions, F0->L0 under U, inverse/order identities, invalid codes 18-31, cube_engine integration");
            $finish;
        end else begin
            $display("FAIL: %0d move-rule checks failed", errors);
            $finish;
        end
    end
endmodule
