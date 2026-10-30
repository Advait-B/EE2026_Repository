`timescale 1ns / 1ps

// move_rules.v
// Combinational: the sticker permutation for each of the 18 moves.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module move_rules (
    input [71:0] cube_in, // cube before move
    input [4:0] move, // move to apply
    output [71:0] cube_out // cube after move
);
`include "cube_defs.vh"

    reg [71:0] cube_next;
    integer src_index;
    reg [4:0] dest_index;

    always @* begin
        cube_next = cube_in;
        dest_index = 5'd0;
        if (move_is_valid(move)) begin
            for (src_index = 0; src_index < N_STICKERS; src_index = src_index + 1) begin
                dest_index = move_sticker_dest(move, src_index[4:0]);
                cube_next[dest_index*3 +: 3] = cube_in[src_index*3 +: 3];
            end
        end
    end

    assign cube_out = cube_next;

endmodule
