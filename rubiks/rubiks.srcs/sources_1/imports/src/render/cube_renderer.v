`timescale 1ns / 1ps

// cube_renderer.v
// Per-pixel hit test against the projected sticker quads.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module cube_renderer (
    input clk, // 100 MHz clock
    input rst, // reset
    input tick_25mhz, // pixel pulse
    input frame_start, // pulse at start of vblank, reload quads
    input [9:0] pix_x, pix_y, // current pixel position
    input [71:0] cube, // live cube state
    input [4:0] rom_sticker_id, // sticker id from view_rom
    input [79:0] rom_quad, // corners from view_rom
    output [3:0] rom_slot, // slot to read from view_rom
    output [2:0] pixel_colour, // colour code of this pixel
    output pixel_on_cube // 1 = this pixel is on the cube
);
`include "cube_defs.vh"

endmodule
