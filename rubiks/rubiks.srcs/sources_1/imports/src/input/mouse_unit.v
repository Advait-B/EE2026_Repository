`timescale 1ns / 1ps

// mouse_unit.v
// PS/2 mouse: decodes packets into cursor position, buttons and movement.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module mouse_unit (
    input clk, // 100 MHz clock
    input rst, // reset
    input dydx_clk,
    inout ps2_clk, ps2_data, // PS/2 clock, data
    output reg [9:0] mouse_x, mouse_y, // cursor position, x 0-639, y 0-479
    output mouse_l, mouse_m, mouse_r, // buttons held: left, middle, right
    output reg signed [10:0] mouse_dx, mouse_dy, // movement this packet
    output mouse_event // 1-cycle pulse per new packet
);
`include "cube_defs.vh"

    wire signed [10:0] temp_mouse_x; //to simplify the math
    wire signed [10:0] temp_mouse_y; //to simplify the math
    wire [9:0] raw_input_x;
    wire [9:0] raw_input_y;
    initial begin
        mouse_x <= 10'd320;
        mouse_y <= 10'd240;
        mouse_dx <= 11'd0;
        mouse_dy <= 11'd0;
    end

    // reg [11:0] setvalue = 12;
    // reg setxandy = 0;
    reg resetxandy = 1;
    MouseCtl mouse_helper ( // given mouse code
        .clk(clk),.rst(rst),.new_event(mouse_event),
        .ps2_clk(ps2_clk),.ps2_data(ps2_data),
        // .value(0),
        .value(10'd512),
        .setx(resetxandy),.sety(resetxandy),
        
        .setmax_x(0), //might have to set this
        .setmax_y(0), //might have to set this
        
        .xpos(raw_input_x),.ypos(raw_input_y),
        .left(mouse_l),.right(mouse_r),.middle(mouse_m)   
    );

    assign temp_mouse_x = $signed({1'b0, mouse_x}) + mouse_dx;
    assign temp_mouse_y = $signed({1'b0, mouse_y}) + mouse_dy;

    always @(posedge mouse_event) begin

        if (resetxandy) begin
            // when we get here in the code it means the current mouse_event
            // was spent setting x and y to 0
            resetxandy <= 0;
        end
        else begin

            /* make it so that x and y directly depend on dx and dy */
            if (mouse_m)    mouse_dx <= ($signed({1'b0, raw_input_x}) - $signed({1'b0, 10'd512})) >>> 3;
            else            mouse_dx <= ($signed({1'b0, raw_input_x}) - $signed({1'b0, 10'd512})) >>> 2;
            
            if (temp_mouse_x[10])   mouse_x <= 10'd0;
            else                    mouse_x <= (temp_mouse_x[9:0] >= SCREEN_W) ? SCREEN_W-1 : temp_mouse_x[9:0]; 

            if (mouse_m)    mouse_dy <= ($signed({1'b0, raw_input_y}) - $signed({1'b0, 10'd512})) >>> 3;
            else            mouse_dy <= ($signed({1'b0, raw_input_y}) - $signed({1'b0, 10'd512})) >>> 2;
            if (temp_mouse_y[10])   mouse_y <= 10'd0;
            else                    mouse_y <= (temp_mouse_y[9:0] >= SCREEN_H) ? SCREEN_H-1 : temp_mouse_y[9:0]; 

            resetxandy <= 1;
        end

        // else begin
        //     mouse_x <= prev_x + raw_mouse_x;
        //     mouse_y <= prev_y + raw_mouse_y;
        //     prev_x <= mouse_x;
        //     prev_y <= mouse_y;

        //     mouse_dx <= raw_mouse_x;
        //     mouse_dy <= raw_mouse_y;
        //     resetxandy <= 1;
        // end
    end

    // always @(posedge mouse_event) begin : maus
    //      reg [9:0] scaled_mouse_x;
    //      reg [9:0] scaled_mouse_y;
    //     // scaled_mouse_x = raw_mouse_x >> MOUSE_SENS;
    //     // scaled_mouse_y = raw_mouse_y >> MOUSE_SENS;
    //     scaled_mouse_x = raw_mouse_x;
    //     scaled_mouse_y = raw_mouse_y;

    //     mouse_x <= (scaled_mouse_x < SCREEN_W) ? scaled_mouse_x : SCREEN_W-1;
    //     mouse_y <= (scaled_mouse_y < SCREEN_H) ? scaled_mouse_y : SCREEN_H-1;
    //     mouse_dx <= mouse_x - prev_x;
    //     mouse_dy <= mouse_y - prev_y;
    //     // mouse_dx <= mouse_dx >> 2;

    //     prev_x <= mouse_x;
    //     prev_y <= mouse_y;
    // end
    
    

endmodule
