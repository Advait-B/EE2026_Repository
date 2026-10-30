`timescale 1ns / 1ps

// cube_engine.v
// Holds the live sticker-colour state in fixed face/tile order; applies moves.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module cube_engine (
    input clk, // 100 MHz clock
    input rst, // reset
    input cube_reset, // reset cube to solved
    input [4:0] move_req, // move to apply
    input move_valid, // apply move this cycle
    output [71:0] cube, // 24 live sticker colours; index = face*4 + tile
    output [15:0] move_count // moves applied since reset
);
`include "cube_defs.vh"

    reg [71:0] cube_reg;
    reg [15:0] move_count_reg;
    wire [71:0] next_cube;

    assign cube = cube_reg;
    assign move_count = move_count_reg;

    move_rules rules (
        .cube_in(cube_reg),
        .move(move_req),
        .cube_out(next_cube)
    );

    always @(posedge clk) begin
        if (rst || cube_reset) begin
            cube_reg <= SOLVED_CUBE;
            move_count_reg <= 16'd0;
        end else if (move_valid && move_is_valid(move_req)) begin
            cube_reg <= next_cube;
            move_count_reg <= move_count_reg + 16'd1;
        end
    end

endmodule
