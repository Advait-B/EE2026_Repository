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

    wire [9:0] mouse_x;
    wire [9:0] mouse_y;
    wire mouse_l;
    wire mouse_r;
    wire mouse_m;
    wire signed [8:0] mouse_dx;
    wire signed [8:0] mouse_dy;
    wire mouse_event;
    mouse_unit mouse_unit(
        .clk(clk),.rst(rst),.ps2_clk(PS2Clk),.ps2_data(PS2Data),
        .mouse_x(mouse_x), .mouse_y(mouse_y),
        .mouse_l(mouse_l), .mouse_r(mouse_r), .mouse_m(mouse_m),
        .mouse_dx(mouse_dx), .mouse_dy(mouse_dy),
        .mouse_event(mouse_event)
    );

    assign led[0] = mouse_l;
    assign led[1] = mouse_m;
    assign led[2] = mouse_r;


/* CLOCKS START */
/* CLOCKS END */

/* IO MODULES START */

/* IO MODULES END */


/* LOGIC MODULES START */

/* LOGIC MODULES END */

endmodule
