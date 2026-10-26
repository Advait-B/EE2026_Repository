`timescale 1ns / 1ps

// vga_unit: 640x480 @ 60 Hz timing, composes cube, background, cursor, palette and text. Owner: Su Yi

module vga_unit #(
    parameter RENDER_LAT = 2 // must match cube_renderer pipeline depth
)(
    input wire clk,
    input wire rst,
    input wire pix_en, // tick_25m
    input wire [2:0] pix_colour,
    input wire pix_on_cube,
    input wire [9:0] mouse_x, mouse_y,
    input wire [2:0] stage,
    input wire [2:0] sel_colour, // highlighted palette colour
    output wire [9:0] px, py, // current pixel, to renderer
    output wire frame_start, // 1-cycle at start of vblank
    output wire Hsync, Vsync,
    output wire [3:0] vgaRed, vgaGreen, vgaBlue
);
    `include "cube_defs.vh"
endmodule
