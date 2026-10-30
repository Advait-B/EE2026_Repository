`timescale 1ns / 1ps

// cube_encode.v
// Combinational: turns a cube into the two pattern_rom addresses.
// The cube must already be recoloured so the DBL corner is solved.
// Address numbering matches Python/generate_tables.py.

module cube_encode (
    input [71:0] cube, // recoloured cube
    output reg [11:0] ori_addr, // orientation coordinate, 0-2186
    output reg [15:0] perm_addr // permutation coordinate, 0-40319
);
`include "cube_defs.vh"

    // twist = position (0, 1, 2) of the white or yellow sticker
    function automatic [1:0] corner_twist(input [8:0] cols);
        begin
            if (cols[2:0] == COL_WHITE || cols[2:0] == COL_YELLOW)
                corner_twist = 2'd0;
            else if (cols[5:3] == COL_WHITE || cols[5:3] == COL_YELLOW)
                corner_twist = 2'd1;
            else
                corner_twist = 2'd2;
        end
    endfunction

    // piece = which corner this is, from its white/yellow colour and the
    // colour clockwise after it
    function automatic [2:0] corner_piece(input [8:0] cols,
                                          input [1:0] twist);
        reg [2:0] ud, next;
        begin
            case (twist)
                2'd0: begin ud = cols[2:0]; next = cols[5:3]; end
                2'd1: begin ud = cols[5:3]; next = cols[8:6]; end
                default: begin ud = cols[8:6]; next = cols[2:0]; end
            endcase
            case ({ud, next})
                {COL_WHITE,  COL_RED}:    corner_piece = 3'd0; // URF
                {COL_WHITE,  COL_GREEN}:  corner_piece = 3'd1; // UFL
                {COL_WHITE,  COL_ORANGE}: corner_piece = 3'd2; // ULB
                {COL_WHITE,  COL_BLUE}:   corner_piece = 3'd3; // UBR
                {COL_YELLOW, COL_GREEN}:  corner_piece = 3'd4; // DFR
                {COL_YELLOW, COL_ORANGE}: corner_piece = 3'd5; // DLF
                {COL_YELLOW, COL_BLUE}:   corner_piece = 3'd6; // DBL
                default:                  corner_piece = 3'd7; // DRB
            endcase
        end
    endfunction

    reg [1:0] twist [0:7];
    reg [2:0] piece [0:7];
    reg [15:0] weight;
    reg [2:0] smaller;
    integer i, j;

    always @* begin
        for (i = 0; i < 8; i = i + 1) begin
            twist[i] = corner_twist(corner_colours(cube, i));
            piece[i] = corner_piece(corner_colours(cube, i), twist[i]);
        end

        // first 7 twists in base 3, corner 0 most significant
        ori_addr = 12'd0;
        for (i = 0; i < 7; i = i + 1)
            ori_addr = ori_addr * 3 + twist[i];

        // Lehmer rank: for each corner, count smaller pieces to its right,
        // weighted by 7!, 6!, ..., 0!
        perm_addr = 16'd0;
        weight = 16'd5040;
        for (i = 0; i < 7; i = i + 1) begin
            smaller = 3'd0;
            for (j = i + 1; j < 8; j = j + 1)
                if (piece[j] < piece[i])
                    smaller = smaller + 3'd1;
            perm_addr = perm_addr + smaller * weight;
            weight = weight / (7 - i);
        end
    end

endmodule
