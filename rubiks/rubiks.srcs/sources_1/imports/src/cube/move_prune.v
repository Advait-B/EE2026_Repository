`timescale 1ns / 1ps

// move_prune.v
// Task 5.4: skip moves that cannot be part of a shortest solution.
// Combinational. Turning the same face twice in a row is never needed
// (U then U' undoes it, U then U is just U2), so that move is skipped.
// The search only uses U, R and F, and no two of those faces are opposite,
// so same-face skipping is the only pruning rule needed.

module move_prune (
    input [4:0] move, // move about to be tried
    input [4:0] prev_move, // move taken one level up
    input has_prev, // 0 at the root, where there is no previous move
    output skip // 1 = do not try this move
);
`include "cube_defs.vh"

    assign skip = has_prev && same_face(move, prev_move);

endmodule
