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
    input [9:0] mouse_x,
    input [9:0] mouse_y, // cursor position
    input [4:0] move_req, // move sent to the engine (HUD history)
    input move_valid, // pulse when move_req is applied
    input [3:0] moves_left, // solve moves remaining
    input [54:0] plan_left, // queued solution moves, next at [4:0]
    output [9:0] pix_x,
    output [9:0] pix_y, // current pixel position
    output reg frame_start, // pulse at start of vblank
    output [11:0] vga_rgb, // {r[3:0], g[3:0], b[3:0]}
    output hsync, vsync // VGA syncs
);
`include "cube_defs.vh"

    vga_helper vga_helper(
        .tick_25mhz(tick_25mhz),
        .hsync(hsync),
        .vsync(vsync),
        .pix_x(pix_x),
        .pix_y(pix_y),
        .video_on() // unused, vga_unit computes its own video_on
    );
    always @(posedge tick_25mhz) begin
        if (frame_start) frame_start <= 0;
        else if (!vsync) frame_start <= 1;
    end
    // like oled, the vga_helper will increment the values of pix_x and pix_y correctly

    // HUD: header, hint line and move footer drawn over the cube
    wire hud_on;
    wire [11:0] hud_rgb;
    hud_overlay hud_overlay (
        .clk(clk), .rst(rst),
        .stage(stage),
        .move_req(move_req), .move_valid(move_valid),
        .moves_left(moves_left), .plan_left(plan_left),
        .pix_x(pix_x), .pix_y(pix_y),
        .hud_on(hud_on), .hud_rgb(hud_rgb)
    );

    // priority: HUD, then cube, then black background; black outside the visible area
    wire video_on = (pix_x < SCREEN_W) && (pix_y < SCREEN_H);
    assign vga_rgb = !video_on     ? 12'h000 :
                     hud_on        ? hud_rgb :
                     pixel_on_cube ? colour_to_rgb(pixel_colour) : //rgb values for vga defined in cube_defs.vh
                                     12'h000;

endmodule