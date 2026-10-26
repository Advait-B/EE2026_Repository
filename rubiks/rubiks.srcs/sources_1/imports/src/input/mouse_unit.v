`timescale 1ns / 1ps

// mouse_unit.v
// PS/2 mouse: decodes packets into cursor position, buttons and movement.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module mouse_unit (
    input clk, // 100 MHz clock
    input rst, // reset
    inout ps2_clk, ps2_data, // PS/2 clock, data
    output [9:0] mouse_x, mouse_y, // cursor position, x 0-639, y 0-479
    output mouse_l, mouse_m, mouse_r, // buttons held: left, middle, right
    output signed [8:0] mouse_dx, mouse_dy, // movement this packet
    output mouse_event // 1-cycle pulse per new packet
);
`include "cube_defs.vh"

    MouseCtl mouse_helper ( // given mouse code
        .clk(clk),.rst(rst),.new_event(mouse_event),
        .ps2_clk(ps2_clk),.ps2_data(ps2_data),
        .value(0),.setx(0),.sety(0),
        
        .setmax_x(0), //might have to set this
        .setmax_y(0), //might have to set this
        
        .xpos(mouse_x),.ypos(mouse_y),
        .left(mouse_l),.right(mouse_r),.middle(mouse_m)   
    );
    
    

endmodule
