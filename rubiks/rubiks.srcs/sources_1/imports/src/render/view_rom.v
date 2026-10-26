`timescale 1ns / 1ps

// view_rom.v
// Precomputed projected sticker quads for every camera angle, front to back.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module view_rom (
    input clk, // 100 MHz clock
    input [6:0] view, // camera angle index
    input [3:0] slot, // visible sticker slot, 0-11, front-to-back
    output [4:0] sticker_id, // which sticker is in this slot
    output [79:0] quad // 4 projected corners {x3,y3,x2,y2,x1,y1,x0,y0}, 10 bits each
);
`include "cube_defs.vh"

endmodule
