`timescale 1ns / 1ps

// move_rules.v
// Combinational: the sticker permutation for each of the 18 moves.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh
//
// Each case branch passes a constant move to apply_move, so synthesis folds
// move_sticker_dest into fixed wiring. Each output bit then becomes a single
// parallel 18:1 mux on move instead of a 24-deep chain of runtime index compares.

module move_rules (
    input [71:0] cube_in, // cube before move
    input [4:0] move, // move to apply
    output [71:0] cube_out // cube after move
);
`include "cube_defs.vh"

    // permute every sticker of c by the (constant) move m
    function [71:0] apply_move(input [4:0] m,
                               input [71:0] c);
        integer src;
        reg [4:0] dest;
        begin
            apply_move = c;
            for (src = 0; src < N_STICKERS; src = src + 1) begin
                dest = move_sticker_dest(m, src[4:0]);
                apply_move[dest*3 +: 3] = c[src*3 +: 3];
            end
        end
    endfunction

    reg [71:0] cube_next;

    always @* begin
        case (move)
            MV_U:  cube_next = apply_move(MV_U,  cube_in);
            MV_UP: cube_next = apply_move(MV_UP, cube_in);
            MV_U2: cube_next = apply_move(MV_U2, cube_in);
            MV_R:  cube_next = apply_move(MV_R,  cube_in);
            MV_RP: cube_next = apply_move(MV_RP, cube_in);
            MV_R2: cube_next = apply_move(MV_R2, cube_in);
            MV_F:  cube_next = apply_move(MV_F,  cube_in);
            MV_FP: cube_next = apply_move(MV_FP, cube_in);
            MV_F2: cube_next = apply_move(MV_F2, cube_in);
            MV_D:  cube_next = apply_move(MV_D,  cube_in);
            MV_DP: cube_next = apply_move(MV_DP, cube_in);
            MV_D2: cube_next = apply_move(MV_D2, cube_in);
            MV_L:  cube_next = apply_move(MV_L,  cube_in);
            MV_LP: cube_next = apply_move(MV_LP, cube_in);
            MV_L2: cube_next = apply_move(MV_L2, cube_in);
            MV_B:  cube_next = apply_move(MV_B,  cube_in);
            MV_BP: cube_next = apply_move(MV_BP, cube_in);
            MV_B2: cube_next = apply_move(MV_B2, cube_in);
            default: cube_next = cube_in; // MV_NONE / invalid: no change
        endcase
    end

    assign cube_out = cube_next;

endmodule
