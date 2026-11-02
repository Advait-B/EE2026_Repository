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

    /* GLOBAL WIRES */
    wire rst;
    reg [2:0] stage;
    reg [71:0] cube = SOLVED_CUBE; // for the 2D net view
    reg [3:0] moves_left; // solve progress

    // oled menu & anode debugging
    wire [2:0] selectedoption;
    wire [3:0] debugpage;

    //VGA STUFF
    wire [9:0] pix_x;
    wire [9:0] pix_y;
    wire [2:0] pixel_colour;
    wire pixel_on_cube;
    wire frame_start;
    wire [7:0] camera_angle_id; //rn we have 256 camera angles
    wire row_done; // one-cycle pulse when a row buffer becomes valid

    initial begin
        
        stage <= 3'b0;

    end

/* CLOCKS, will convert to tickgen later */
    wire clk_10hz;
    flexclock clk_10hz_unit (
        .clock(clk),
        .reset(0),
        .m(32'd4999999),
        .slow_clock(clk_10hz)
    );

    wire clk_1kHz;
    flexclock clk_1kHz_unit (
        .clock(clk),
        .reset(0),
        .m(32'd49999),
        .slow_clock(clk_1kHz)
    );

    wire clk_6p25MHz;
    flexclock clk_6p25MHz_unit (
        .clock(clk),
        .reset(0),
        .m(32'd7),
        .slow_clock(clk_6p25MHz)
    );

    wire clk_25MHz;
    flexclock clk_25MHz_unit (
        .clock(clk),
        .reset(0),
        .m(32'd1),
        .slow_clock(clk_25MHz)
    );


/* IO MODULES START */
    // MOUSE, obviously
    wire [9:0] mouse_x;
    wire [9:0] mouse_y;
    wire mouse_l; wire mouse_m; wire mouse_r;
    wire signed [10:0] mouse_dx;
    wire signed [10:0] mouse_dy;
    wire mouse_event;
    mouse_unit mouse_unit(
        .clk(clk),.rst(rst),.ps2_clk(PS2Clk),.ps2_data(PS2Data),

        .dydx_clk(clk_1kHz),
        .mouse_x(mouse_x), .mouse_y(mouse_y),
        .mouse_dx(mouse_dx), .mouse_dy(mouse_dy),

        .mouse_l(mouse_l), .mouse_r(mouse_r), .mouse_m(mouse_m),
        .mouse_event(mouse_event)
    );
    
    // BUTTONS: C U L R D
    wire [4:0] btn_held;
    wire [4:0] btn_pressed;
    button_unit button_unit (
        // .debugled(led[13]),
        .clk(clk),
        .debounce_clk(clk_10hz),
        .btn_raw({btnC, btnU, btnL, btnR, btnD}),
        .btn_held(btn_held),
        .btn_pressed(btn_pressed),
        .selectedoption(selectedoption)
    );

    //- SWITCHES: 0-15 incl
    switch_unit switch_unit(
        .clk(clk),
        .sw(sw),
        .debugpage(debugpage)
    );

    //- OLED
    oled_unit oled_unit (
        .clk(clk),
        .oledclock(clk_6p25MHz),
        .rst(rst),
        .stage(stage),
        .selectedoption(selectedoption),
        .cube(cube),
        .moves_left(moves_left),
        // .debugled(led[12]),
        .oled_pmod(JC)
    );

    //- ANODE
    anode_unit anode_unit (
        .clk(clk),
        .rst(rst),
        .digitcycle_clk(clk_1kHz),
        .debugpage(debugpage),
        
        .mouse_x(mouse_x),
        .mouse_y(mouse_y),
        .mouse_dx(mouse_dx),
        .mouse_dy(mouse_dy),
        .camera_angle_id(camera_angle_id),

        .seg(seg),
        .dp(dp),
        .an(an)
    );

    //- VGA
    vga_unit vga_unit (
        .clk(clk),
        .rst(rst),
        .clk_25MHz(clk_25MHz), // per-pixel update rate

        .stage(stage),
        .pixel_colour(pixel_colour),
        .pixel_on_cube(pixel_on_cube),
        .mouse_x(mouse_x), .mouse_y(mouse_y),
        .pix_x(pix_x), .pix_y(pix_y), // pixel pos, like oledx and oledy

        .frame_start(frame_start),
        .vga_rgb({vgaRed, vgaGreen, vgaBlue}), // {RRR_GGG_BBB}
        .hsync(Hsync),
        .vsync(Vsync)
    );


/* IO MODULES END */


/* LOGIC MODULES START */

    cube_renderer cube_renderer_unit (
        .clk(clk),
        .rst(rst),
        .tick_25mhz(clk_25MHz),
        .frame_start(frame_start),
        .camera_angle_id(camera_angle_id),
        .pix_x(pix_x), .pix_y(pix_y),
        .cube(cube),
        .pixel_colour(pixel_colour),
        .pixel_on_cube(pixel_on_cube),
        .row_done(row_done) // one-cycle pulse when a row buffer becomes valid
    );

    // CHANGE CAMERA ANGLE BASED ON MOUSE_DX AND MOUSE_DY
    reg [3:0] camera_yaw = 4'b0;
    reg [3:0] camera_pitch = 4'b0;
    always @(posedge mouse_event) begin
        //camera yaw goes from 0 to 15
        //camera pitch goes from 0 to 15
        //camera_angle_id = pitch * 16 + yaw
        camera_yaw <= ~mouse_r ? camera_yaw : mouse_dx == 11'b0 ? camera_yaw : mouse_dx[10] ? camera_yaw - 1 : camera_yaw + 1;
        camera_pitch <= ~mouse_r ? camera_pitch : mouse_dy == 11'b0 ? camera_pitch : mouse_dy[10] ? camera_pitch + 1 : camera_pitch - 1;
    end
    assign camera_angle_id = {camera_pitch, camera_yaw}; // = (pitch << 4) + yaw


/* LOGIC MODULES END */

/* TEST STUFF -------------------------- */

    wire clk_2hz;
    flexclock clk_2hz_unit (
        .clock(clk),
        .reset(0),
        .m(32'd24999999),
        .slow_clock(clk_2hz)
    );
    assign led[0] = (stage == 3'd0) ? 1 : 0;
    assign led[1] = (stage == 3'd1) ? clk_2hz : 0;
    assign led[2] = (stage == 3'd2) ? 1 : 0;
    assign led[3] = (stage == 3'd3) ? 1 : 0;
    assign led[4] = (stage == 3'd4) ? clk_2hz : 0;
    assign led[5] = (stage == 3'd5) ? 1 : 0;
    assign led[6] = (stage == 3'd6) ? clk_10hz : 0; //error

    assign led[7] = btn_pressed[4];
    assign led[8] = btn_held[4];
    assign led[9] = clk_10hz; //debounce clk

    // assign led[13:10] = debugpage;

    // INCREMENT STAGE
    wire clk_0p16hz;
    flexclock clk_0p16hz_unit (
        .clock(clk),
        .reset(0),
        .m(32'd299999999),
        .slow_clock(clk_0p16hz)
    );
    always @(posedge clk_0p16hz) begin
        stage <= (stage == 3'd6) ? 3'd0 : stage + 1;
    end

endmodule
