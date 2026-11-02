`timescale 1ns / 1ps

module top_basys3 (
    input clk, //100MHz

    input btnC, btnU, btnL, btnR, btnD,
    input [15:0] sw,
    inout PS2Clk, PS2Data,

    output [15:0] led,
    output [6:0] seg, output dp,
    output [3:0] an,
    output [7:0] JC, //OLED

    //{vgaRed, vgaGreen, vgaBlue} = vga_rgb
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output Hsync, Vsync
);
`include "cube_defs.vh"

/* RESET START */
    // power-on reset: rst is high for the first 16 clocks after configuration
    reg [4:0] por_count = 5'd0;
    always @(posedge clk)
        if (!por_count[4]) por_count <= por_count + 5'd1;
    wire rst = !por_count[4];
/* RESET END */

/* CLOCKS START */
    wire tick_25mhz, tick_1khz, tick_4hz;
    wire clk_6p25mhz;
    tick_gen tick_gen (
        .clk(clk), .rst(rst),
        .en_25mhz(1'b1), .en_1khz(1'b1), .en_4hz(1'b1),
        .tick_25mhz(tick_25mhz), .tick_1khz(tick_1khz), .tick_4hz(tick_4hz),
        .clk_6p25mhz(clk_6p25mhz)
    );
/* CLOCKS END */

/* IO MODULES START */
    wire [9:0] mouse_x, mouse_y;
    wire mouse_l, mouse_m, mouse_r;
    wire signed [8:0] mouse_dx, mouse_dy;
    wire mouse_event;
    mouse_unit mouse_unit (
        .clk(clk), .rst(rst), .ps2_clk(PS2Clk), .ps2_data(PS2Data),
        .mouse_x(mouse_x), .mouse_y(mouse_y),
        .mouse_l(mouse_l), .mouse_m(mouse_m), .mouse_r(mouse_r),
        .mouse_dx(mouse_dx), .mouse_dy(mouse_dy),
        .mouse_event(mouse_event)
    );

    // BUTTONS: C U L R D
    wire [4:0] btn_held, btn_pressed;
    button_unit button_unit (
        .clk(clk),
        .btn_raw({btnC, btnU, btnL, btnR, btnD}),
        .debugled(),
        .btn_held(btn_held),
        .btn_pressed(btn_pressed)
    );

    wire [15:0] sw_sync;
    switch_unit switch_unit (
        .clk(clk), .sw_raw(sw), .sw_sync(sw_sync)
    );
/* IO MODULES END */

/* LOGIC MODULES START */
    wire [2:0] stage;
    wire scramble_start, solve_start, solve_cancel, cube_reset;
    wire [4:0] manual_move;
    wire manual_valid;

    wire [4:0] scr_move;
    wire scr_valid, scr_busy, scr_done;

    wire [4:0] sol_move;
    wire sol_valid, sol_busy, sol_done, sol_err;
    wire [3:0] moves_left;

    wire [4:0] move_req;
    wire move_valid;

    wire [71:0] cube;
    wire [15:0] move_count;

    game_fsm game_fsm (
        .clk(clk), .rst(rst),
        .btn_pressed(btn_pressed), .sw_sync(sw_sync),
        .scramble_done(scr_done), .solve_done(sol_done), .solve_err(sol_err),
        .stage(stage),
        .scramble_start(scramble_start), .solve_start(solve_start),
        .solve_cancel(solve_cancel), .cube_reset(cube_reset),
        .manual_move(manual_move), .manual_valid(manual_valid)
    );

    scrambler scrambler (
        .clk(clk), .rst(rst),
        .start(scramble_start), .tick_4hz(tick_4hz),
        .scr_move(scr_move), .scr_valid(scr_valid),
        .busy(scr_busy), .done(scr_done)
    );

    solver solver (
        .clk(clk), .rst(rst),
        .start(solve_start), .cancel(solve_cancel),
        .tick_4hz(tick_4hz), .cube(cube),
        .sol_move(sol_move), .sol_valid(sol_valid),
        .busy(sol_busy), .done(sol_done), .err(sol_err),
        .moves_left(moves_left)
    );

    move_controller move_controller (
        .clk(clk), .rst(rst), .stage(stage),
        .manual_move(manual_move), .scr_move(scr_move), .sol_move(sol_move),
        .manual_valid(manual_valid), .scr_valid(scr_valid), .sol_valid(sol_valid),
        .move_req(move_req), .move_valid(move_valid)
    );

    cube_engine cube_engine (
        .clk(clk), .rst(rst), .cube_reset(cube_reset),
        .move_req(move_req), .move_valid(move_valid),
        .cube(cube), .move_count(move_count)
    );
/* LOGIC MODULES END */

/* RENDER START */
    wire [7:0] camera_angle_id;
    camera_unit camera_unit (
        .clk(clk), .rst(rst), .stage(stage),
        .btn_pressed(btn_pressed),
        .mouse_l(mouse_l), .mouse_dx(mouse_dx), .mouse_dy(mouse_dy),
        .mouse_event(mouse_event),
        .camera_angle_id(camera_angle_id)
    );

    wire [9:0] pix_x, pix_y;
    wire frame_start;
    wire [2:0] pixel_colour;
    wire pixel_on_cube;
    cube_renderer cube_renderer (
        .clk(clk), .rst(rst), .tick_25mhz(tick_25mhz),
        .frame_start(frame_start), .camera_angle_id(camera_angle_id),
        .pix_x(pix_x), .pix_y(pix_y), .cube(cube),
        .pixel_colour(pixel_colour), .pixel_on_cube(pixel_on_cube),
        .row_done()
    );

    wire [11:0] vga_rgb;
    vga_unit vga_unit (
        .clk(clk), .rst(rst), .tick_25mhz(tick_25mhz), .stage(stage),
        .pixel_colour(pixel_colour), .pixel_on_cube(pixel_on_cube),
        .mouse_x(mouse_x), .mouse_y(mouse_y),
        .pix_x(pix_x), .pix_y(pix_y), .frame_start(frame_start),
        .vga_rgb(vga_rgb), .hsync(Hsync), .vsync(Vsync)
    );
    assign {vgaRed, vgaGreen, vgaBlue} = vga_rgb;
/* RENDER END */

/* DISPLAY START */
    oled_unit oled_unit (
        .clk(clk), .clk_6p25mhz(clk_6p25mhz), .rst(rst),
        .stage(stage), .cube(cube), .moves_left(moves_left),
        .oled_pmod(JC)
    );

    led_unit led_unit (
        .clk(clk), .rst(rst), .tick_4hz(tick_4hz), .stage(stage),
        .solve_err(sol_err), .moves_left(moves_left), .move_count(move_count),
        .led(led)
    );

    anode_unit anode_unit (
        .clk(clk), .rst(rst), .tick_1khz(tick_1khz), .stage(stage),
        .move_count(move_count), .moves_left(moves_left),
        .seg(seg), .dp(dp), .an(an)
    );
/* DISPLAY END */

endmodule
