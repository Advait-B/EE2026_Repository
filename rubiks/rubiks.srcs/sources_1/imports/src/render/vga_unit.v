`timescale 1ns / 1ps

// vga_unit.v
// 640x480 VGA timing, status overlay and cursor; outputs 12-bit vga_rgb.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module vga_unit (
    input clk, // 100 MHz clock
    input rst, // reset
    input clk_25MHz, // pixel pulse
    input [2:0] stage, // current game stage
    input [2:0] pixel_colour, // cube colour from renderer
    input pixel_on_cube, // renderer hit flag
    input [9:0] mouse_x,
    input [9:0] mouse_y, // cursor position
    output [9:0] pix_x,
    output [9:0] pix_y, // current pixel position
    output reg frame_start, // pulse at start of vblank
    output [11:0] vga_rgb, // {r[3:0], g[3:0], b[3:0]}
    output hsync, vsync // VGA syncs
);
`include "cube_defs.vh"

    vga_helper vga_helper(
        .clk_25MHz(clk_25MHz),
        .hsync(hsync),
        .vsync(vsync),
        .pix_x(pix_x),
        .pix_y(pix_y),
        .video_on(1) //unused
    );
    always @(posedge clk_25MHz) begin
        if (frame_start) frame_start <= 0;
        else if (!vsync) frame_start <= 1;
    end
    // like oled, the vga_helper will increment the values of pix_x and pix_y correctly

    // right now cube_renderer_unit will give us a value of pixel_on_cube based on the
    // value of pix_x and pix_y, so we just need to ASSIGN vga_rgb BASED ON pixel_on_cube

    assign vga_rgb = colour_to_rgb(pixel_colour); //rgb values for vga defined in cube_defs.vh

endmodule