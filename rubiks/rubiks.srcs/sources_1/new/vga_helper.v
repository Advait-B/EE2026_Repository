`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.11.2026 13:01:56
// Design Name: 
// Module Name: vga_helper
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module vga_helper (
    input tick_25mhz,
    input reset,
    output reg hsync,
    output reg vsync,
    output reg [9:0] pix_x,
    output reg [9:0] pix_y,
    output video_on
);
    //Adapted FROM YOUTUBE VIDEO
    //https://www.youtube.com/watch?v=MVu5OAFZhKA

    // Timing parameters for 640x480 @ 60Hz
    localparam H_DISPLAY = 640;
    localparam H_FRONT = 16;
    localparam H_RETRACE = 96;
    localparam H_BACK = 48;
    localparam H_MAX = H_DISPLAY + H_FRONT + H_RETRACE + H_BACK; // 800

    localparam V_DISPLAY = 480;
    localparam V_FRONT = 10;
    localparam V_RETRACE = 2;
    localparam V_BACK = 33;
    localparam V_MAX = V_DISPLAY + V_FRONT + V_RETRACE + V_BACK; // 525

    reg [9:0] h_count = 0;
    reg [9:0] v_count = 0;

    always @(posedge tick_25mhz) begin
        if (reset)
        begin
            h_count <= 0;
            v_count <= 0;
        end

        else if (h_count == H_MAX - 1)
        begin
            h_count <= 0;
            if (v_count == V_MAX - 1)   v_count <= 0;               //bottom right hit, reset to 0,0
            else                    v_count <= v_count + 1;     //right side hit, so go down
        end

        else h_count <= h_count + 1;
        
        pix_x <= h_count;
        pix_y <= v_count;
        
        
    end

    // hsync show be LOW during horizontal retrace
    // this is meant to tell the old CRTs to do a hori retrace
    always @(posedge tick_25mhz) begin
        hsync <= ~(
            ((H_DISPLAY + H_FRONT) <= h_count) && 
                                     (h_count <  (H_DISPLAY + H_FRONT + H_RETRACE))
        );
    end

    // vsync should be LOW during vertical retrace
    // this is meant to tell the old CRTs to do a vert retrace
    always @(posedge tick_25mhz) begin
        vsync <= ~(
            ((V_DISPLAY + V_FRONT) <= v_count) && 
                                     (v_count <  (V_DISPLAY + V_FRONT + V_RETRACE))
        );
    end

    // video_on is only on when pixels coords are within the displaay area
    assign video_on = (h_count < H_DISPLAY) && (v_count < V_DISPLAY);

endmodule

