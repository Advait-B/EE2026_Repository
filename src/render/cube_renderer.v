`timescale 1ns / 1ps

// cube_renderer: per pixel, the front-most visible sticker quad containing (px, py) wins. Owner: Lim

module cube_renderer (
    input wire clk,
    input wire rst,
    input wire pix_en, // tick_25m
    input wire frame_start, // 1-cycle at start of vblank, snapshot the 12 quads here
    input wire [4:0] view_idx,
    input wire [71:0] cube,
    input wire [9:0] px, py,
    input wire [9:0] mouse_x, mouse_y,
    output wire [8:0] rom_addr,
    input wire [84:0] rom_data,
    output wire [2:0] pix_colour, // colour code, vga_unit maps to RGB
    output wire pix_on_cube,
    output wire [4:0] cursor_tile, // sticker under mouse, TILE_NONE if none
    output wire cursor_on_cube
);
    `include "cube_defs.vh"
endmodule
