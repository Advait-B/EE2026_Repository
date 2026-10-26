`timescale 1ns / 1ps

// vga_unit.v
// 640x480 VGA timing, status overlay and cursor; outputs 12-bit vga_rgb.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module vga_unit (
    input clk, // 100 MHz clock
    input rst, // reset
    input tick_25mhz, // pixel pulse
    input [2:0] stage, // current game stage
    input [2:0] pixel_colour, // cube colour from renderer
    input pixel_on_cube, // renderer hit flag
    input [9:0] mouse_x, mouse_y, // cursor position
    output [9:0] pix_x, pix_y, // current pixel position
    output frame_start, // pulse at start of vblank
    output [11:0] vga_rgb, // {r[3:0], g[3:0], b[3:0]}
    output hsync, vsync // VGA syncs
);
`include "cube_defs.vh"

endmodule
