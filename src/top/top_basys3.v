`timescale 1ns / 1ps

// top_basys3: declares global signals and wires every module, no logic. Owner: Su Yi

module top_basys3 (
    input wire clk,
    input wire btnC, btnU, btnL, btnR, btnD,
    input wire [15:0] sw,
    output wire [15:0] led,
    output wire [6:0] seg,
    output wire dp,
    output wire [3:0] an,
    output wire [3:0] vgaRed, vgaGreen, vgaBlue,
    output wire Hsync, Vsync,
    inout wire PS2Clk, PS2Data,
    output wire [7:0] JC // OLED Pmod
);
    `include "cube_defs.vh"

    // Clocks / inputs
    wire rst; // TODO: agree reset source as a team
    wire tick_25m, tick_1k, tick_slow, clk6p25m, slow_en;
    wire [4:0] btn_level, btn_pulse;
    wire [15:0] sw_s;
    wire [9:0] mouse_x, mouse_y;
    wire m_left, m_mid, m_right, m_event;
    wire signed [10:0] m_dx, m_dy;

    // Game control
    wire [2:0] stage, paint_colour, err_code, enc_err;
    wire [1:0] menu_sel;
    wire manual_en, scramble_start, solve_start, solve_cancel;
    wire cube_reset, paint_en;
    wire [4:0] paint_tile;

    // Moves / cube
    wire [4:0] scr_move, sol_move, move_req;
    wire scr_valid, scr_busy, scramble_done;
    wire sol_valid, sol_busy, solve_done, solve_err;
    wire [3:0] sol_len, sol_progress;
    wire move_valid;
    wire [71:0] cube;
    wire [7:0] move_count;
    wire [12:0] perm_idx;
    wire [9:0] ori_idx;
    wire cube_valid;

    // 3D / video
    wire [4:0] view_idx, cursor_tile;
    wire [8:0] rom_addr;
    wire [84:0] rom_data;
    wire [9:0] px, py;
    wire frame_start, pix_on_cube, cursor_on_cube;
    wire [2:0] pix_colour;

    tick_gen u_tick (
        .clk(clk), .rst(rst), .en_slow(slow_en),
        .tick_25m(tick_25m), .tick_1k(tick_1k), .tick_slow(tick_slow), .clk6p25m(clk6p25m)
    );

    button_unit u_btn (
        .clk(clk), .rst(rst), .tick_1k(tick_1k),
        .btn_raw({btnC, btnU, btnL, btnR, btnD}),
        .btn_level(btn_level), .btn_pulse(btn_pulse)
    );

    switch_unit u_sw (
        .clk(clk), .sw_raw(sw), .sw(sw_s)
    );

    mouse_unit u_mouse (
        .clk(clk), .rst(rst), .ps2_clk(PS2Clk), .ps2_data(PS2Data),
        .mouse_x(mouse_x), .mouse_y(mouse_y),
        .left(m_left), .middle(m_mid), .right(m_right),
        .dx(m_dx), .dy(m_dy), .new_event(m_event)
    );

    game_fsm u_fsm (
        .clk(clk), .rst(rst), .btn_pulse(btn_pulse), .sw(sw_s),
        .m_left(m_left), .cursor_on_cube(cursor_on_cube), .cursor_tile(cursor_tile),
        .cube(cube), .cube_valid(cube_valid), .enc_err(enc_err),
        .scramble_done(scramble_done), .solve_done(solve_done), .solve_err(solve_err),
        .stage(stage), .menu_sel(menu_sel), .slow_en(slow_en), .manual_en(manual_en),
        .scramble_start(scramble_start), .solve_start(solve_start), .solve_cancel(solve_cancel),
        .cube_reset(cube_reset), .paint_en(paint_en), .paint_tile(paint_tile),
        .paint_colour(paint_colour), .err_code(err_code)
    );

    move_controller u_mc (
        .clk(clk), .rst(rst), .stage(stage), .manual_en(manual_en),
        .btn_pulse(btn_pulse), .sw(sw_s),
        .scr_move(scr_move), .scr_valid(scr_valid),
        .sol_move(sol_move), .sol_valid(sol_valid),
        .move_req(move_req), .move_valid(move_valid)
    );

    cube_engine u_engine (
        .clk(clk), .rst(rst), .cube_reset(cube_reset),
        .move_req(move_req), .move_valid(move_valid),
        .paint_en(paint_en), .paint_tile(paint_tile), .paint_colour(paint_colour),
        .cube(cube), .move_count(move_count)
    );

    scrambler u_scr (
        .clk(clk), .rst(rst), .start(scramble_start), .tick_slow(tick_slow),
        .scr_move(scr_move), .scr_valid(scr_valid),
        .busy(scr_busy), .scramble_done(scramble_done)
    );

    cube_encode u_enc (
        .clk(clk), .cube(cube),
        .perm_idx(perm_idx), .ori_idx(ori_idx),
        .cube_valid(cube_valid), .err_code(enc_err)
    );

    solver u_solver (
        .clk(clk), .rst(rst), .start(solve_start), .cancel(solve_cancel),
        .tick_slow(tick_slow), .perm_idx(perm_idx), .ori_idx(ori_idx),
        .sol_move(sol_move), .sol_valid(sol_valid), .busy(sol_busy),
        .solve_done(solve_done), .solve_err(solve_err),
        .sol_len(sol_len), .progress(sol_progress)
    );

    camera_unit u_cam (
        .clk(clk), .rst(rst), .stage(stage), .sw(sw_s), .btn_pulse(btn_pulse),
        .m_left(m_left), .dx(m_dx), .dy(m_dy), .new_event(m_event),
        .view_idx(view_idx)
    );

    view_rom u_rom (
        .clk(clk), .addr(rom_addr), .data(rom_data)
    );

    cube_renderer u_rend (
        .clk(clk), .rst(rst), .pix_en(tick_25m), .frame_start(frame_start),
        .view_idx(view_idx), .cube(cube), .px(px), .py(py),
        .mouse_x(mouse_x), .mouse_y(mouse_y),
        .rom_addr(rom_addr), .rom_data(rom_data),
        .pix_colour(pix_colour), .pix_on_cube(pix_on_cube),
        .cursor_tile(cursor_tile), .cursor_on_cube(cursor_on_cube)
    );

    vga_unit u_vga (
        .clk(clk), .rst(rst), .pix_en(tick_25m),
        .pix_colour(pix_colour), .pix_on_cube(pix_on_cube),
        .mouse_x(mouse_x), .mouse_y(mouse_y), .stage(stage), .sel_colour(paint_colour),
        .px(px), .py(py), .frame_start(frame_start),
        .Hsync(Hsync), .Vsync(Vsync),
        .vgaRed(vgaRed), .vgaGreen(vgaGreen), .vgaBlue(vgaBlue)
    );

    oled_unit u_oled (
        .clk(clk), .clk6p25m(clk6p25m), .rst(rst),
        .stage(stage), .cube(cube), .sel_colour(paint_colour),
        .err_code(err_code), .progress(sol_progress), .sol_len(sol_len),
        .oled(JC)
    );

    led_unit u_led (
        .clk(clk), .rst(rst), .tick_1k(tick_1k), .stage(stage),
        .progress(sol_progress), .sol_len(sol_len), .err_code(err_code),
        .led(led)
    );

    anode_unit u_an (
        .clk(clk), .rst(rst), .tick_1k(tick_1k), .stage(stage),
        .menu_sel(menu_sel), .move_count(move_count), .sol_len(sol_len),
        .seg(seg), .dp(dp), .an(an)
    );
endmodule
