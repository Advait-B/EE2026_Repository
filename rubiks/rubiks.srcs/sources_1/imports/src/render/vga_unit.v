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
    input pixel_dim, // 1 = draw this cube pixel at half brightness
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
    // frame_start: one clk-cycle pulse on the falling edge of vsync (start of retrace),
    // so the renderer and scanline buffers reset once per frame, not on every tick of vsync low
    reg vsync_q;
    always @(posedge clk) begin
        if (rst) begin
            vsync_q <= 1'b1;
            frame_start <= 1'b0;
        end else begin
            vsync_q <= vsync;
            frame_start <= vsync_q && !vsync;
        end
    end
    // like oled, the vga_helper will increment the values of pix_x and pix_y correctly

    // MAUS: coords are mouse_x (0-639) and mouse_y (0-479)
    // wire cursor_on = (
    //     (mouse_x <= pix_x+1 && pix_x <= mouse_x+1 && mouse_y <= pix_y+3 && pix_y <= mouse_y+3) ||
    //     (mouse_x <= pix_x+3 && pix_x <= mouse_x+3 && mouse_y <= pix_y+1 && pix_y <= mouse_y+1)
    // );
    // wire [11:0] cursor_rgb = 12'b0111_0011_1111; //purple

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

    // cube colour, halved when the sticker is outside the selected manual-mode layer
    wire [11:0] cube_rgb = colour_to_rgb(pixel_colour);
    wire [11:0] cube_rgb_dim = (cube_rgb >> 1) & 12'h777;

    // priority: cursor, HUD, then cube, then black background; black outside the visible area
    wire video_on = (pix_x < SCREEN_W) && (pix_y < SCREEN_H);
    assign vga_rgb = !video_on    ? 12'h000 :
                    // cursor_on     ? cursor_rgb :
                    hud_on        ? hud_rgb :
                    pixel_on_cube ? (pixel_dim ? cube_rgb_dim : cube_rgb) : //rgb values for vga defined in cube_defs.vh
                                    12'h000;

endmodule