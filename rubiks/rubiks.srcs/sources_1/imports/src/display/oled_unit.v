`timescale 1ns / 1ps

// oled_unit.v
// Drives the Pmod OLED: 2D cube net, stage, solver errors, solve progress.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module oled_unit (
    input clk, // 100 MHz clock
    input clk_6p25mhz, // OLED driver clock
    input rst, // reset
    input [2:0] stage, // current game stage
    input [71:0] cube, // for the 2D net view
    input [3:0] moves_left, // solve progress
    output [7:0] oled_pmod // Pmod OLED pins
);
`include "cube_defs.vh"

    wire my_fb;
    wire [12:0] my_pixel_index; //the oled module will keep changing this number
    reg [15:0] oled_colour;
    
    Oled_Display oled_helper (
        .clk(clk_6p25mhz),
        .reset(0),
        .frame_begin(my_fb),
        .sending_pixels(),
        .sample_pixel(),
        .pixel_index(my_pixel_index),
        .pixel_data(oled_colour),
        
        .cs(oled_pmod[0]),
        .sdin(oled_pmod[1]),
        .sclk(oled_pmod[3]),
        .d_cn(oled_pmod[4]),
        .resn(oled_pmod[5]),
        .vccen(oled_pmod[6]),
        .pmoden(oled_pmod[7])
    );
    
    wire [6:0] x;
    wire [5:0] y;
    assign x = my_pixel_index % 96;	//this makes x always the x coord of the current pixel
    assign y = my_pixel_index / 96;	//this makes y always the y coord of the current pixel

    /* OLED LOGIC START */
    
    

endmodule
