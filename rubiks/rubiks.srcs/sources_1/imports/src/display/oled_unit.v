`timescale 1ns / 1ps

// oled_unit.v
// Drives the Pmod OLED: 2D cube net, stage, solver errors, solve progress.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module oled_unit (
    input clk, // 100 MHz clock
    input oledclock, // OLED driver clock
    input rst, // reset
    input [2:0] stage, // current game stage
    input [2:0] selectedoption,
    input [71:0] cube, // for the 2D net view
    input [3:0] moves_left, // solve progress
    // output debugled,
    output [7:0] oled_pmod // Pmod OLED pins
);
`include "cube_defs.vh"
`include "glyphs.vh"

    wire my_fb;
    wire [12:0] my_pixel_index; //the oled module will keep changing this number
    reg [15:0] oled_colour;
    
    Oled_Display oled_helper (
        .clk(oledclock), //rec: 6.25MHz
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
    
    wire [6:0] oledx;
    wire [5:0] oledy;
    assign oledx = my_pixel_index % 96;	//this makes x always the x coord of the current pixel
    assign oledy = my_pixel_index / 96;	//this makes y always the y coord of the current pixel

/* OLED LOGIC START */

    reg [3:0] activesegment;
    //reg [6:0] Gx;
    reg [5:0] Gy;
    always @(posedge oledclock) begin
    
        if      (1 <= oledy && oledy <= 7) activesegment <= 4'd0; //LINE 0: STAGENAME
        else if (10 <= oledy && oledy <= 10) activesegment <= 4'd7; //BIG BAR
        else if (13 <= oledy && oledy <= 19) activesegment <= 4'd1; //LINE 1: OPTION
        else if (21 <= oledy && oledy <= 27) activesegment <= 4'd2; //LINE 2: OPTION
        else if (29 <= oledy && oledy <= 35) activesegment <= 4'd3; //LINE 3: OPTION
        else if (37 <= oledy && oledy <= 43) activesegment <= 4'd4; //LINE 4: OPTION
        else if (45 <= oledy && oledy <= 51) activesegment <= 4'd5; //LINE 5: OPTION
        else if (53 <= oledy && oledy <= 59) activesegment <= 4'd6; //LINE 6: OPTION
        else if (61 <= oledy && oledy <= 61) activesegment <= 4'd8; //SMOL BAR
        // else if (62 <= oledy && oledy <= 62) activesegment <= 4'd10; //animation maybe?
        else                                 activesegment <= 4'd9; //blank buffers
        
        case (stage)


        STAGE_START: begin
            case (activesegment)
            4'd0: begin
                Gy <= 6'd1; //d1(stagename), d13, d21, d29, d37, d45, d53
                if (7'd3<=oledx && oledx<7'd8)          oled_colour <= GLYPH_S[34 - (oledy - Gy)*5 - (oledx - 3)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd9<=oledx && oledx<7'd14)    oled_colour <= GLYPH_T[34 - (oledy - Gy)*5 - (oledx - 9)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd15<=oledx && oledx<7'd20)   oled_colour <= GLYPH_A[34 - (oledy - Gy)*5 - (oledx - 15)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd21<=oledx && oledx<7'd26)   oled_colour <= GLYPH_R[34 - (oledy - Gy)*5 - (oledx - 21)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd27<=oledx && oledx<7'd32)   oled_colour <= GLYPH_T[34 - (oledy - Gy)*5 - (oledx - 27)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
//                else if (7'd33<=oledx && oledx<7'd38)   oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 33)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
//                else if (7'd39<=oledx && oledx<7'd44)   oled_colour <= GLYPH_w[34 - (oledy - Gy)*5 - (oledx - 39)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
//                else if (7'd45<=oledx && oledx<7'd50)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 45)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
//                else if (7'd51<=oledx && oledx<7'd56)   oled_colour <= GLYPH_r[34 - (oledy - Gy)*5 - (oledx - 51)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
//                else if (7'd57<=oledx && oledx<7'd62)   oled_colour <= GLYPH_l[34 - (oledy - Gy)*5 - (oledx - 57)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
//                else if (7'd63<=oledx && oledx<7'd68)   oled_colour <= GLYPH_d[34 - (oledy - Gy)*5 - (oledx - 63)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
//                else if (7'd69<=oledx && oledx<7'd74)   oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 69)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
//                else if (7'd75<=oledx && oledx<7'd80)   oled_colour <= GLYPH_y[34 - (oledy - Gy)*5 - (oledx - 75)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
//                else if (7'd81<=oledx && oledx<7'd86)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 81)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
//                else if (7'd87<=oledx && oledx<7'd92)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 87)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd1: begin
                Gy <= 6'd13; //d1(stagename), d13, d21, d29, d37, d45, d53
                if (7'd3<=oledx && oledx<7'd8)          oled_colour <= G_BULET[34 - (oledy - Gy)*5 - (oledx - 3)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd9<=oledx && oledx<7'd14)    oled_colour <= GLYPH_A[34 - (oledy - Gy)*5 - (oledx - 9)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd15<=oledx && oledx<7'd20)   oled_colour <= GLYPH_u[34 - (oledy - Gy)*5 - (oledx - 15)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd21<=oledx && oledx<7'd26)   oled_colour <= GLYPH_t[34 - (oledy - Gy)*5 - (oledx - 21)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd27<=oledx && oledx<7'd32)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 27)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd33<=oledx && oledx<7'd38)   oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 33)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd39<=oledx && oledx<7'd44)   oled_colour <= GLYPH_S[34 - (oledy - Gy)*5 - (oledx - 39)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd45<=oledx && oledx<7'd50)   oled_colour <= GLYPH_c[34 - (oledy - Gy)*5 - (oledx - 45)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd51<=oledx && oledx<7'd56)   oled_colour <= GLYPH_r[34 - (oledy - Gy)*5 - (oledx - 51)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd57<=oledx && oledx<7'd62)   oled_colour <= GLYPH_a[34 - (oledy - Gy)*5 - (oledx - 57)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd63<=oledx && oledx<7'd68)   oled_colour <= GLYPH_m[34 - (oledy - Gy)*5 - (oledx - 63)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd69<=oledx && oledx<7'd74)   oled_colour <= GLYPH_b[34 - (oledy - Gy)*5 - (oledx - 69)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd75<=oledx && oledx<7'd80)   oled_colour <= GLYPH_l[34 - (oledy - Gy)*5 - (oledx - 75)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd81<=oledx && oledx<7'd86)   oled_colour <= GLYPH_e[34 - (oledy - Gy)*5 - (oledx - 81)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
//                else if (7'd87<=oledx && oledx<7'd92)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 87)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd2: begin
                Gy <= 6'd21; //d1(stagename), d13, d21, d29, d37, d45, d53
                if (7'd3<=oledx && oledx<7'd8)          oled_colour <= G_BULET[34 - (oledy - Gy)*5 - (oledx - 3)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd9<=oledx && oledx<7'd14)    oled_colour <= GLYPH_M[34 - (oledy - Gy)*5 - (oledx - 9)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd15<=oledx && oledx<7'd20)   oled_colour <= GLYPH_a[34 - (oledy - Gy)*5 - (oledx - 15)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd21<=oledx && oledx<7'd26)   oled_colour <= GLYPH_n[34 - (oledy - Gy)*5 - (oledx - 21)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd27<=oledx && oledx<7'd32)   oled_colour <= GLYPH_u[34 - (oledy - Gy)*5 - (oledx - 27)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd33<=oledx && oledx<7'd38)   oled_colour <= GLYPH_a[34 - (oledy - Gy)*5 - (oledx - 33)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd39<=oledx && oledx<7'd44)   oled_colour <= GLYPH_l[34 - (oledy - Gy)*5 - (oledx - 39)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd45<=oledx && oledx<7'd50)   oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 45)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd51<=oledx && oledx<7'd56)   oled_colour <= GLYPH_S[34 - (oledy - Gy)*5 - (oledx - 51)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd57<=oledx && oledx<7'd62)   oled_colour <= GLYPH_c[34 - (oledy - Gy)*5 - (oledx - 57)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd63<=oledx && oledx<7'd68)   oled_colour <= GLYPH_r[34 - (oledy - Gy)*5 - (oledx - 63)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd69<=oledx && oledx<7'd74)   oled_colour <= GLYPH_a[34 - (oledy - Gy)*5 - (oledx - 69)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd75<=oledx && oledx<7'd80)   oled_colour <= GLYPH_m[34 - (oledy - Gy)*5 - (oledx - 75)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd81<=oledx && oledx<7'd86)   oled_colour <= GLYPH_b[34 - (oledy - Gy)*5 - (oledx - 81)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd87<=oledx && oledx<7'd92)   oled_colour <= GLYPH_l[34 - (oledy - Gy)*5 - (oledx - 87)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd3: begin
                Gy <= 6'd29; //d1(stagename), d13, d21, d29, d37, d45, d53
                oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd4: begin
                Gy <= 6'd37; //d1(stagename), d13, d21, d29, d37, d45, d53
                oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd5: begin
                Gy <= 6'd45; //d1(stagename), d13, d21, d29, d37, d45, d53
                oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd6: begin
                Gy <= 6'd55; //d1(stagename), d13, d21, d29, d37, d45, d53
                oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd7: oled_colour <= COLOUR_RED; //big bar: red
            4'd8: oled_colour <= COLOUR_BLUE; //small bar: blue
            default: oled_colour <= COLOUR_BLACK; //set buffers to black
            endcase
        end // for if stage == STAGE_START

        STAGE_AUTO_SCRAMBLE: begin
            case (activesegment)
            4'd0: begin
                Gy <= 6'd1; //d1(stagename), d13, d21, d29, d37, d45, d53
                if (7'd3<=oledx && oledx<7'd8)          oled_colour <= GLYPH_A[34 - (oledy - Gy)*5 - (oledx - 3)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd9<=oledx && oledx<7'd14)    oled_colour <= GLYPH_U[34 - (oledy - Gy)*5 - (oledx - 9)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd15<=oledx && oledx<7'd20)   oled_colour <= GLYPH_T[34 - (oledy - Gy)*5 - (oledx - 15)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd21<=oledx && oledx<7'd26)   oled_colour <= GLYPH_O[34 - (oledy - Gy)*5 - (oledx - 21)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd27<=oledx && oledx<7'd32)   oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 27)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd33<=oledx && oledx<7'd38)   oled_colour <= GLYPH_S[34 - (oledy - Gy)*5 - (oledx - 33)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd39<=oledx && oledx<7'd44)   oled_colour <= GLYPH_C[34 - (oledy - Gy)*5 - (oledx - 39)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd45<=oledx && oledx<7'd50)   oled_colour <= GLYPH_R[34 - (oledy - Gy)*5 - (oledx - 45)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd51<=oledx && oledx<7'd56)   oled_colour <= GLYPH_A[34 - (oledy - Gy)*5 - (oledx - 51)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd57<=oledx && oledx<7'd62)   oled_colour <= GLYPH_M[34 - (oledy - Gy)*5 - (oledx - 57)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd63<=oledx && oledx<7'd68)   oled_colour <= GLYPH_B[34 - (oledy - Gy)*5 - (oledx - 63)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd69<=oledx && oledx<7'd74)   oled_colour <= GLYPH_L[34 - (oledy - Gy)*5 - (oledx - 69)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd75<=oledx && oledx<7'd80)   oled_colour <= GLYPH_E[34 - (oledy - Gy)*5 - (oledx - 75)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd81<=oledx && oledx<7'd86)   oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 81)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd87<=oledx && oledx<7'd92)   oled_colour <= G_BULET[34 - (oledy - Gy)*5 - (oledx - 87)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd1: begin
                Gy <= 6'd13; //d1(stagename), d13, d21, d29, d37, d45, d53
                if (7'd3<=oledx && oledx<7'd8)          oled_colour <= G_BULET[34 - (oledy - Gy)*5 - (oledx - 3)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd9<=oledx && oledx<7'd14)    oled_colour <= GLYPH_S[34 - (oledy - Gy)*5 - (oledx - 9)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd15<=oledx && oledx<7'd20)   oled_colour <= GLYPH_t[34 - (oledy - Gy)*5 - (oledx - 15)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd21<=oledx && oledx<7'd26)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 21)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd27<=oledx && oledx<7'd32)   oled_colour <= GLYPH_p[34 - (oledy - Gy)*5 - (oledx - 27)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd33<=oledx && oledx<7'd38)   oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 33)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd39<=oledx && oledx<7'd44)   oled_colour <= GLYPH_S[34 - (oledy - Gy)*5 - (oledx - 39)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd45<=oledx && oledx<7'd50)   oled_colour <= GLYPH_c[34 - (oledy - Gy)*5 - (oledx - 45)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd51<=oledx && oledx<7'd56)   oled_colour <= GLYPH_r[34 - (oledy - Gy)*5 - (oledx - 51)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd57<=oledx && oledx<7'd62)   oled_colour <= GLYPH_a[34 - (oledy - Gy)*5 - (oledx - 57)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd63<=oledx && oledx<7'd68)   oled_colour <= GLYPH_m[34 - (oledy - Gy)*5 - (oledx - 63)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd69<=oledx && oledx<7'd74)   oled_colour <= GLYPH_b[34 - (oledy - Gy)*5 - (oledx - 69)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd75<=oledx && oledx<7'd80)   oled_colour <= GLYPH_l[34 - (oledy - Gy)*5 - (oledx - 75)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd81<=oledx && oledx<7'd86)   oled_colour <= GLYPH_e[34 - (oledy - Gy)*5 - (oledx - 81)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
//                else if (7'd87<=oledx && oledx<7'd92)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 87)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd2: begin
                Gy <= 6'd21; //d1(stagename), d13, d21, d29, d37, d45, d53
                oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd3: begin
                Gy <= 6'd29; //d1(stagename), d13, d21, d29, d37, d45, d53
                oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd4: begin
                Gy <= 6'd37; //d1(stagename), d13, d21, d29, d37, d45, d53
                oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd5: begin
                Gy <= 6'd45; //d1(stagename), d13, d21, d29, d37, d45, d53
                oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd6: begin
                Gy <= 6'd55; //d1(stagename), d13, d21, d29, d37, d45, d53
                oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd7: oled_colour <= COLOUR_RED; //big bar: red
            4'd8: oled_colour <= COLOUR_BLUE; //small bar: blue
            default: oled_colour <= COLOUR_BLACK; //set buffers to black
            endcase
        end // for if stage == STAGE_AUTO_SCRAMBLE

        STAGE_MANUAL_SCRAMBLE, STAGE_MANUAL_SOLVING: begin
            case (activesegment)
            4'd0: begin
                Gy <= 6'd1; //d1(stagename), d13, d21, d29, d37, d45, d53
                if (7'd3<=oledx && oledx<7'd8)          oled_colour <= GLYPH_M[34 - (oledy - Gy)*5 - (oledx - 3)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd9<=oledx && oledx<7'd14)    oled_colour <= GLYPH_A[34 - (oledy - Gy)*5 - (oledx - 9)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd15<=oledx && oledx<7'd20)   oled_colour <= GLYPH_N[34 - (oledy - Gy)*5 - (oledx - 15)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd21<=oledx && oledx<7'd26)   oled_colour <= GLYPH_U[34 - (oledy - Gy)*5 - (oledx - 21)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd27<=oledx && oledx<7'd32)   oled_colour <= GLYPH_A[34 - (oledy - Gy)*5 - (oledx - 27)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd33<=oledx && oledx<7'd38)   oled_colour <= GLYPH_L[34 - (oledy - Gy)*5 - (oledx - 33)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd39<=oledx && oledx<7'd44)   oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 39)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd45<=oledx && oledx<7'd50)   oled_colour <= GLYPH_S[34 - (oledy - Gy)*5 - (oledx - 45)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd51<=oledx && oledx<7'd56)   oled_colour <= GLYPH_C[34 - (oledy - Gy)*5 - (oledx - 51)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd57<=oledx && oledx<7'd62)   oled_colour <= GLYPH_R[34 - (oledy - Gy)*5 - (oledx - 57)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd63<=oledx && oledx<7'd68)   oled_colour <= GLYPH_A[34 - (oledy - Gy)*5 - (oledx - 63)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd69<=oledx && oledx<7'd74)   oled_colour <= GLYPH_M[34 - (oledy - Gy)*5 - (oledx - 69)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd75<=oledx && oledx<7'd80)   oled_colour <= GLYPH_B[34 - (oledy - Gy)*5 - (oledx - 75)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd81<=oledx && oledx<7'd86)   oled_colour <= GLYPH_L[34 - (oledy - Gy)*5 - (oledx - 81)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd87<=oledx && oledx<7'd92)   oled_colour <= GLYPH_E[34 - (oledy - Gy)*5 - (oledx - 87)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd1: begin
                Gy <= 6'd13; //d1(stagename), d13, d21, d29, d37, d45, d53
                if (7'd3<=oledx && oledx<7'd8)          oled_colour <= G_BULET[34 - (oledy - Gy)*5 - (oledx - 3)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd9<=oledx && oledx<7'd14)    oled_colour <= GLYPH_F[34 - (oledy - Gy)*5 - (oledx - 9)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd15<=oledx && oledx<7'd20)   oled_colour <= GLYPH_r[34 - (oledy - Gy)*5 - (oledx - 15)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd21<=oledx && oledx<7'd26)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 21)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd27<=oledx && oledx<7'd32)   oled_colour <= GLYPH_n[34 - (oledy - Gy)*5 - (oledx - 27)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd33<=oledx && oledx<7'd38)   oled_colour <= GLYPH_t[34 - (oledy - Gy)*5 - (oledx - 33)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd39<=oledx && oledx<7'd44)   oled_colour <= GLYPH_S[34 - (oledy - Gy)*5 - (oledx - 39)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd45<=oledx && oledx<7'd50)   oled_colour <= GLYPH_c[34 - (oledy - Gy)*5 - (oledx - 45)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd51<=oledx && oledx<7'd56)   oled_colour <= GLYPH_r[34 - (oledy - Gy)*5 - (oledx - 51)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd57<=oledx && oledx<7'd62)   oled_colour <= GLYPH_a[34 - (oledy - Gy)*5 - (oledx - 57)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd63<=oledx && oledx<7'd68)   oled_colour <= GLYPH_m[34 - (oledy - Gy)*5 - (oledx - 63)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd69<=oledx && oledx<7'd74)   oled_colour <= GLYPH_b[34 - (oledy - Gy)*5 - (oledx - 69)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd75<=oledx && oledx<7'd80)   oled_colour <= GLYPH_l[34 - (oledy - Gy)*5 - (oledx - 75)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd81<=oledx && oledx<7'd86)   oled_colour <= GLYPH_e[34 - (oledy - Gy)*5 - (oledx - 81)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
//                else if (7'd87<=oledx && oledx<7'd92)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 87)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd2: begin
                Gy <= 6'd21; //d1(stagename), d13, d21, d29, d37, d45, d53
                if (7'd3<=oledx && oledx<7'd8)          oled_colour <= G_BULET[34 - (oledy - Gy)*5 - (oledx - 3)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd9<=oledx && oledx<7'd14)    oled_colour <= GLYPH_B[34 - (oledy - Gy)*5 - (oledx - 9)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd15<=oledx && oledx<7'd20)   oled_colour <= GLYPH_a[34 - (oledy - Gy)*5 - (oledx - 15)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd21<=oledx && oledx<7'd26)   oled_colour <= GLYPH_c[34 - (oledy - Gy)*5 - (oledx - 21)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd27<=oledx && oledx<7'd32)   oled_colour <= GLYPH_k[34 - (oledy - Gy)*5 - (oledx - 27)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd33<=oledx && oledx<7'd38)   oled_colour <= GLYPH_t[34 - (oledy - Gy)*5 - (oledx - 33)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd39<=oledx && oledx<7'd44)   oled_colour <= GLYPH_S[34 - (oledy - Gy)*5 - (oledx - 39)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd45<=oledx && oledx<7'd50)   oled_colour <= GLYPH_c[34 - (oledy - Gy)*5 - (oledx - 45)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd51<=oledx && oledx<7'd56)   oled_colour <= GLYPH_r[34 - (oledy - Gy)*5 - (oledx - 51)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd57<=oledx && oledx<7'd62)   oled_colour <= GLYPH_a[34 - (oledy - Gy)*5 - (oledx - 57)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd63<=oledx && oledx<7'd68)   oled_colour <= GLYPH_m[34 - (oledy - Gy)*5 - (oledx - 63)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd69<=oledx && oledx<7'd74)   oled_colour <= GLYPH_b[34 - (oledy - Gy)*5 - (oledx - 69)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd75<=oledx && oledx<7'd80)   oled_colour <= GLYPH_l[34 - (oledy - Gy)*5 - (oledx - 75)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd81<=oledx && oledx<7'd86)   oled_colour <= GLYPH_e[34 - (oledy - Gy)*5 - (oledx - 81)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
//                else if (7'd87<=oledx && oledx<7'd92)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 87)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd3: begin
                Gy <= 6'd29; //d1(stagename), d13, d21, d29, d37, d45, d53
                if (7'd3<=oledx && oledx<7'd8)          oled_colour <= G_BULET[34 - (oledy - Gy)*5 - (oledx - 3)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd9<=oledx && oledx<7'd14)    oled_colour <= GLYPH_L[34 - (oledy - Gy)*5 - (oledx - 9)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd15<=oledx && oledx<7'd20)   oled_colour <= GLYPH_e[34 - (oledy - Gy)*5 - (oledx - 15)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd21<=oledx && oledx<7'd26)   oled_colour <= GLYPH_f[34 - (oledy - Gy)*5 - (oledx - 21)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd27<=oledx && oledx<7'd32)   oled_colour <= GLYPH_t[34 - (oledy - Gy)*5 - (oledx - 27)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd33<=oledx && oledx<7'd38)   oled_colour <= GLYPH_t[34 - (oledy - Gy)*5 - (oledx - 33)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd39<=oledx && oledx<7'd44)   oled_colour <= GLYPH_S[34 - (oledy - Gy)*5 - (oledx - 39)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd45<=oledx && oledx<7'd50)   oled_colour <= GLYPH_c[34 - (oledy - Gy)*5 - (oledx - 45)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd51<=oledx && oledx<7'd56)   oled_colour <= GLYPH_r[34 - (oledy - Gy)*5 - (oledx - 51)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd57<=oledx && oledx<7'd62)   oled_colour <= GLYPH_a[34 - (oledy - Gy)*5 - (oledx - 57)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd63<=oledx && oledx<7'd68)   oled_colour <= GLYPH_m[34 - (oledy - Gy)*5 - (oledx - 63)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd69<=oledx && oledx<7'd74)   oled_colour <= GLYPH_b[34 - (oledy - Gy)*5 - (oledx - 69)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd75<=oledx && oledx<7'd80)   oled_colour <= GLYPH_l[34 - (oledy - Gy)*5 - (oledx - 75)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd81<=oledx && oledx<7'd86)   oled_colour <= GLYPH_e[34 - (oledy - Gy)*5 - (oledx - 81)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
//                else if (7'd87<=oledx && oledx<7'd92)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 87)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd4: begin
                Gy <= 6'd37; //d1(stagename), d13, d21, d29, d37, d45, d53
                if (7'd3<=oledx && oledx<7'd8)          oled_colour <= G_BULET[34 - (oledy - Gy)*5 - (oledx - 3)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd9<=oledx && oledx<7'd14)    oled_colour <= GLYPH_R[34 - (oledy - Gy)*5 - (oledx - 9)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd15<=oledx && oledx<7'd20)   oled_colour <= GLYPH_i[34 - (oledy - Gy)*5 - (oledx - 15)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd21<=oledx && oledx<7'd26)   oled_colour <= GLYPH_g[34 - (oledy - Gy)*5 - (oledx - 21)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd27<=oledx && oledx<7'd32)   oled_colour <= GLYPH_h[34 - (oledy - Gy)*5 - (oledx - 27)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd33<=oledx && oledx<7'd38)   oled_colour <= GLYPH_t[34 - (oledy - Gy)*5 - (oledx - 33)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd39<=oledx && oledx<7'd44)   oled_colour <= GLYPH_S[34 - (oledy - Gy)*5 - (oledx - 39)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd45<=oledx && oledx<7'd50)   oled_colour <= GLYPH_c[34 - (oledy - Gy)*5 - (oledx - 45)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd51<=oledx && oledx<7'd56)   oled_colour <= GLYPH_r[34 - (oledy - Gy)*5 - (oledx - 51)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd57<=oledx && oledx<7'd62)   oled_colour <= GLYPH_a[34 - (oledy - Gy)*5 - (oledx - 57)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd63<=oledx && oledx<7'd68)   oled_colour <= GLYPH_m[34 - (oledy - Gy)*5 - (oledx - 63)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd69<=oledx && oledx<7'd74)   oled_colour <= GLYPH_b[34 - (oledy - Gy)*5 - (oledx - 69)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd75<=oledx && oledx<7'd80)   oled_colour <= GLYPH_l[34 - (oledy - Gy)*5 - (oledx - 75)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd81<=oledx && oledx<7'd86)   oled_colour <= GLYPH_e[34 - (oledy - Gy)*5 - (oledx - 81)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
//                else if (7'd87<=oledx && oledx<7'd92)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 87)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd5: begin
                Gy <= 6'd45; //d1(stagename), d13, d21, d29, d37, d45, d53
                if (7'd3<=oledx && oledx<7'd8)          oled_colour <= G_BULET[34 - (oledy - Gy)*5 - (oledx - 3)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd9<=oledx && oledx<7'd14)    oled_colour <= GLYPH_U[34 - (oledy - Gy)*5 - (oledx - 9)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd15<=oledx && oledx<7'd20)   oled_colour <= GLYPH_p[34 - (oledy - Gy)*5 - (oledx - 15)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd21<=oledx && oledx<7'd26)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 21)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd27<=oledx && oledx<7'd32)   oled_colour <= GLYPH_n[34 - (oledy - Gy)*5 - (oledx - 27)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd33<=oledx && oledx<7'd38)   oled_colour <= GLYPH_t[34 - (oledy - Gy)*5 - (oledx - 33)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd39<=oledx && oledx<7'd44)   oled_colour <= GLYPH_S[34 - (oledy - Gy)*5 - (oledx - 39)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd45<=oledx && oledx<7'd50)   oled_colour <= GLYPH_c[34 - (oledy - Gy)*5 - (oledx - 45)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd51<=oledx && oledx<7'd56)   oled_colour <= GLYPH_r[34 - (oledy - Gy)*5 - (oledx - 51)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd57<=oledx && oledx<7'd62)   oled_colour <= GLYPH_a[34 - (oledy - Gy)*5 - (oledx - 57)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd63<=oledx && oledx<7'd68)   oled_colour <= GLYPH_m[34 - (oledy - Gy)*5 - (oledx - 63)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd69<=oledx && oledx<7'd74)   oled_colour <= GLYPH_b[34 - (oledy - Gy)*5 - (oledx - 69)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd75<=oledx && oledx<7'd80)   oled_colour <= GLYPH_l[34 - (oledy - Gy)*5 - (oledx - 75)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd81<=oledx && oledx<7'd86)   oled_colour <= GLYPH_e[34 - (oledy - Gy)*5 - (oledx - 81)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
//                else if (7'd87<=oledx && oledx<7'd92)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 87)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd6: begin
                Gy <= 6'd53; //d1(stagename), d13, d21, d29, d37, d45, d53
                if (7'd3<=oledx && oledx<7'd8)          oled_colour <= G_BULET[34 - (oledy - Gy)*5 - (oledx - 3)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd9<=oledx && oledx<7'd14)    oled_colour <= GLYPH_D[34 - (oledy - Gy)*5 - (oledx - 9)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd15<=oledx && oledx<7'd20)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 15)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd21<=oledx && oledx<7'd26)   oled_colour <= GLYPH_w[34 - (oledy - Gy)*5 - (oledx - 21)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd27<=oledx && oledx<7'd32)   oled_colour <= GLYPH_n[34 - (oledy - Gy)*5 - (oledx - 27)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd33<=oledx && oledx<7'd38)   oled_colour <= GLYPH_t[34 - (oledy - Gy)*5 - (oledx - 33)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd39<=oledx && oledx<7'd44)   oled_colour <= GLYPH_S[34 - (oledy - Gy)*5 - (oledx - 39)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd45<=oledx && oledx<7'd50)   oled_colour <= GLYPH_c[34 - (oledy - Gy)*5 - (oledx - 45)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd51<=oledx && oledx<7'd56)   oled_colour <= GLYPH_r[34 - (oledy - Gy)*5 - (oledx - 51)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd57<=oledx && oledx<7'd62)   oled_colour <= GLYPH_a[34 - (oledy - Gy)*5 - (oledx - 57)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd63<=oledx && oledx<7'd68)   oled_colour <= GLYPH_m[34 - (oledy - Gy)*5 - (oledx - 63)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd69<=oledx && oledx<7'd74)   oled_colour <= GLYPH_b[34 - (oledy - Gy)*5 - (oledx - 69)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd75<=oledx && oledx<7'd80)   oled_colour <= GLYPH_l[34 - (oledy - Gy)*5 - (oledx - 75)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd81<=oledx && oledx<7'd86)   oled_colour <= GLYPH_e[34 - (oledy - Gy)*5 - (oledx - 81)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
//                else if (7'd87<=oledx && oledx<7'd92)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 87)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd7: oled_colour <= COLOUR_RED; //big bar: red
            4'd8: oled_colour <= COLOUR_BLUE; //small bar: blue
            default: oled_colour <= COLOUR_BLACK; //set buffers to black
            endcase
        end // for if stage == STAGE_MANUAL_SCRAMBLE

        STAGE_SCRAMBLED: begin
            case (activesegment)
            4'd0: begin
                Gy <= 6'd1; //d1(stagename), d13, d21, d29, d37, d45, d53
                if (7'd3<=oledx && oledx<7'd8)          oled_colour <= GLYPH_S[34 - (oledy - Gy)*5 - (oledx - 3)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd9<=oledx && oledx<7'd14)    oled_colour <= GLYPH_C[34 - (oledy - Gy)*5 - (oledx - 9)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd15<=oledx && oledx<7'd20)   oled_colour <= GLYPH_R[34 - (oledy - Gy)*5 - (oledx - 15)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd21<=oledx && oledx<7'd26)   oled_colour <= GLYPH_A[34 - (oledy - Gy)*5 - (oledx - 21)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd27<=oledx && oledx<7'd32)   oled_colour <= GLYPH_M[34 - (oledy - Gy)*5 - (oledx - 27)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd33<=oledx && oledx<7'd38)    oled_colour <= GLYPH_B[34 - (oledy - Gy)*5 - (oledx - 33)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd39<=oledx && oledx<7'd44)    oled_colour <= GLYPH_L[34 - (oledy - Gy)*5 - (oledx - 39)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd45<=oledx && oledx<7'd50)    oled_colour <= GLYPH_E[34 - (oledy - Gy)*5 - (oledx - 45)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd51<=oledx && oledx<7'd56)    oled_colour <= GLYPH_D[34 - (oledy - Gy)*5 - (oledx - 51)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            //    else if (7'd57<=oledx && oledx<7'd62)   oled_colour <= GLYPH_M[34 - (oledy - Gy)*5 - (oledx - 57)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            //    else if (7'd63<=oledx && oledx<7'd68)   oled_colour <= GLYPH_B[34 - (oledy - Gy)*5 - (oledx - 63)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            //    else if (7'd69<=oledx && oledx<7'd74)   oled_colour <= GLYPH_L[34 - (oledy - Gy)*5 - (oledx - 69)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            //    else if (7'd75<=oledx && oledx<7'd80)   oled_colour <= GLYPH_E[34 - (oledy - Gy)*5 - (oledx - 75)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            //    else if (7'd81<=oledx && oledx<7'd86)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 81)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            //    else if (7'd87<=oledx && oledx<7'd92)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 87)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd1: begin
                Gy <= 6'd13; //d1(stagename), d13, d21, d29, d37, d45, d53
                if (7'd3<=oledx && oledx<7'd8)          oled_colour <= G_BULET[34 - (oledy - Gy)*5 - (oledx - 3)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd9<=oledx && oledx<7'd14)    oled_colour <= GLYPH_A[34 - (oledy - Gy)*5 - (oledx - 9)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd15<=oledx && oledx<7'd20)   oled_colour <= GLYPH_u[34 - (oledy - Gy)*5 - (oledx - 15)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd21<=oledx && oledx<7'd26)   oled_colour <= GLYPH_t[34 - (oledy - Gy)*5 - (oledx - 21)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd27<=oledx && oledx<7'd32)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 27)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd33<=oledx && oledx<7'd38)   oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 33)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd39<=oledx && oledx<7'd44)   oled_colour <= GLYPH_S[34 - (oledy - Gy)*5 - (oledx - 39)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd45<=oledx && oledx<7'd50)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 45)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd51<=oledx && oledx<7'd56)   oled_colour <= GLYPH_l[34 - (oledy - Gy)*5 - (oledx - 51)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd57<=oledx && oledx<7'd62)   oled_colour <= GLYPH_v[34 - (oledy - Gy)*5 - (oledx - 57)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd63<=oledx && oledx<7'd68)   oled_colour <= GLYPH_e[34 - (oledy - Gy)*5 - (oledx - 63)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd69<=oledx && oledx<7'd74)   oled_colour <= GLYPH_b[34 - (oledy - Gy)*5 - (oledx - 69)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd75<=oledx && oledx<7'd80)   oled_colour <= GLYPH_l[34 - (oledy - Gy)*5 - (oledx - 75)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd81<=oledx && oledx<7'd86)   oled_colour <= GLYPH_e[34 - (oledy - Gy)*5 - (oledx - 81)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
//                else if (7'd87<=oledx && oledx<7'd92)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 87)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd2: begin
                Gy <= 6'd21; //d1(stagename), d13, d21, d29, d37, d45, d53
                if (7'd3<=oledx && oledx<7'd8)          oled_colour <= G_BULET[34 - (oledy - Gy)*5 - (oledx - 3)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd9<=oledx && oledx<7'd14)    oled_colour <= GLYPH_M[34 - (oledy - Gy)*5 - (oledx - 9)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd15<=oledx && oledx<7'd20)   oled_colour <= GLYPH_a[34 - (oledy - Gy)*5 - (oledx - 15)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd21<=oledx && oledx<7'd26)   oled_colour <= GLYPH_n[34 - (oledy - Gy)*5 - (oledx - 21)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd27<=oledx && oledx<7'd32)   oled_colour <= GLYPH_u[34 - (oledy - Gy)*5 - (oledx - 27)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd33<=oledx && oledx<7'd38)   oled_colour <= GLYPH_a[34 - (oledy - Gy)*5 - (oledx - 33)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd39<=oledx && oledx<7'd44)   oled_colour <= GLYPH_l[34 - (oledy - Gy)*5 - (oledx - 39)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd45<=oledx && oledx<7'd50)   oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 45)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd51<=oledx && oledx<7'd56)   oled_colour <= GLYPH_S[34 - (oledy - Gy)*5 - (oledx - 51)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd57<=oledx && oledx<7'd62)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 57)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd63<=oledx && oledx<7'd68)   oled_colour <= GLYPH_l[34 - (oledy - Gy)*5 - (oledx - 63)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd69<=oledx && oledx<7'd74)   oled_colour <= GLYPH_v[34 - (oledy - Gy)*5 - (oledx - 69)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd75<=oledx && oledx<7'd80)   oled_colour <= GLYPH_e[34 - (oledy - Gy)*5 - (oledx - 75)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd81<=oledx && oledx<7'd86)   oled_colour <= GLYPH_e[34 - (oledy - Gy)*5 - (oledx - 81)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
//                else if (7'd87<=oledx && oledx<7'd92)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 87)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd3: begin
                Gy <= 6'd29; //d1(stagename), d13, d21, d29, d37, d45, d53
                oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd4: begin
                Gy <= 6'd37; //d1(stagename), d13, d21, d29, d37, d45, d53
                oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd5: begin
                Gy <= 6'd45; //d1(stagename), d13, d21, d29, d37, d45, d53
                oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd6: begin
                Gy <= 6'd55; //d1(stagename), d13, d21, d29, d37, d45, d53
                oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd7: oled_colour <= COLOUR_RED; //big bar: red
            4'd8: oled_colour <= COLOUR_BLUE; //small bar: blue
            default: oled_colour <= COLOUR_BLACK; //set buffers to black
            endcase
        end // for if stage == STAGE_SCRAMBLED

        STAGE_SOLVING: begin
            case (activesegment)
            4'd0: begin
                Gy <= 6'd1; //d1(stagename), d13, d21, d29, d37, d45, d53
                if (7'd3<=oledx && oledx<7'd8)          oled_colour <= GLYPH_S[34 - (oledy - Gy)*5 - (oledx - 3)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd9<=oledx && oledx<7'd14)    oled_colour <= GLYPH_O[34 - (oledy - Gy)*5 - (oledx - 9)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd15<=oledx && oledx<7'd20)   oled_colour <= GLYPH_L[34 - (oledy - Gy)*5 - (oledx - 15)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd21<=oledx && oledx<7'd26)   oled_colour <= GLYPH_V[34 - (oledy - Gy)*5 - (oledx - 21)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd27<=oledx && oledx<7'd32)   oled_colour <= GLYPH_I[34 - (oledy - Gy)*5 - (oledx - 27)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd33<=oledx && oledx<7'd38)    oled_colour <= GLYPH_N[34 - (oledy - Gy)*5 - (oledx - 33)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd39<=oledx && oledx<7'd44)    oled_colour <= GLYPH_G[34 - (oledy - Gy)*5 - (oledx - 39)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd45<=oledx && oledx<7'd50)    oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 45)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd51<=oledx && oledx<7'd56)    oled_colour <= G_BULET[34 - (oledy - Gy)*5 - (oledx - 51)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd57<=oledx && oledx<7'd62)    oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 57)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd63<=oledx && oledx<7'd68)    oled_colour <= G_BULET[34 - (oledy - Gy)*5 - (oledx - 63)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd69<=oledx && oledx<7'd74)    oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 69)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd75<=oledx && oledx<7'd80)    oled_colour <= G_BULET[34 - (oledy - Gy)*5 - (oledx - 75)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            //    else if (7'd81<=oledx && oledx<7'd86)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 81)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            //    else if (7'd87<=oledx && oledx<7'd92)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 87)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd1: begin
                Gy <= 6'd13; //d1(stagename), d13, d21, d29, d37, d45, d53
                if (7'd3<=oledx && oledx<7'd8)          oled_colour <= G_BULET[34 - (oledy - Gy)*5 - (oledx - 3)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd9<=oledx && oledx<7'd14)    oled_colour <= GLYPH_S[34 - (oledy - Gy)*5 - (oledx - 9)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd15<=oledx && oledx<7'd20)   oled_colour <= GLYPH_t[34 - (oledy - Gy)*5 - (oledx - 15)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd21<=oledx && oledx<7'd26)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 21)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd27<=oledx && oledx<7'd32)   oled_colour <= GLYPH_p[34 - (oledy - Gy)*5 - (oledx - 27)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd33<=oledx && oledx<7'd38)   oled_colour <= GLYPH_e[34 - (oledy - Gy)*5 - (oledx - 33)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd39<=oledx && oledx<7'd44)   oled_colour <= GLYPH_S[34 - (oledy - Gy)*5 - (oledx - 39)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd45<=oledx && oledx<7'd50)   oled_colour <= GLYPH_c[34 - (oledy - Gy)*5 - (oledx - 45)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd51<=oledx && oledx<7'd56)   oled_colour <= GLYPH_r[34 - (oledy - Gy)*5 - (oledx - 51)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd57<=oledx && oledx<7'd62)   oled_colour <= GLYPH_a[34 - (oledy - Gy)*5 - (oledx - 57)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd63<=oledx && oledx<7'd68)   oled_colour <= GLYPH_m[34 - (oledy - Gy)*5 - (oledx - 63)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd69<=oledx && oledx<7'd74)   oled_colour <= GLYPH_b[34 - (oledy - Gy)*5 - (oledx - 69)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd75<=oledx && oledx<7'd80)   oled_colour <= GLYPH_l[34 - (oledy - Gy)*5 - (oledx - 75)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd81<=oledx && oledx<7'd86)   oled_colour <= GLYPH_e[34 - (oledy - Gy)*5 - (oledx - 81)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
//                else if (7'd87<=oledx && oledx<7'd92)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 87)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd2: begin
                Gy <= 6'd21; //d1(stagename), d13, d21, d29, d37, d45, d53
                oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd3: begin
                Gy <= 6'd29; //d1(stagename), d13, d21, d29, d37, d45, d53
                oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd4: begin
                Gy <= 6'd37; //d1(stagename), d13, d21, d29, d37, d45, d53
                oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd5: begin
                Gy <= 6'd45; //d1(stagename), d13, d21, d29, d37, d45, d53
                oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd6: begin
                Gy <= 6'd55; //d1(stagename), d13, d21, d29, d37, d45, d53
                oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd7: oled_colour <= COLOUR_RED; //big bar: red
            4'd8: oled_colour <= COLOUR_BLUE; //small bar: blue
            default: oled_colour <= COLOUR_BLACK; //set buffers to black
            endcase
        end // for if stage == STAGE_SOLVING

        STAGE_SOLVED: begin
            case (activesegment)
            4'd0: begin
                Gy <= 6'd1; //d1(stagename), d13, d21, d29, d37, d45, d53
                if (7'd3<=oledx && oledx<7'd8)          oled_colour <= GLYPH_S[34 - (oledy - Gy)*5 - (oledx - 3)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd9<=oledx && oledx<7'd14)    oled_colour <= GLYPH_O[34 - (oledy - Gy)*5 - (oledx - 9)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd15<=oledx && oledx<7'd20)   oled_colour <= GLYPH_L[34 - (oledy - Gy)*5 - (oledx - 15)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd21<=oledx && oledx<7'd26)   oled_colour <= GLYPH_V[34 - (oledy - Gy)*5 - (oledx - 21)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd27<=oledx && oledx<7'd32)   oled_colour <= GLYPH_E[34 - (oledy - Gy)*5 - (oledx - 27)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
               else if (7'd33<=oledx && oledx<7'd38)    oled_colour <= GLYPH_D[34 - (oledy - Gy)*5 - (oledx - 33)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            //    else if (7'd39<=oledx && oledx<7'd44)    oled_colour <= GLYPH_G[34 - (oledy - Gy)*5 - (oledx - 39)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            //    else if (7'd45<=oledx && oledx<7'd50)    oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 45)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            //    else if (7'd51<=oledx && oledx<7'd56)    oled_colour <= G_BULET[34 - (oledy - Gy)*5 - (oledx - 51)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            //    else if (7'd57<=oledx && oledx<7'd62)    oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 57)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            //    else if (7'd63<=oledx && oledx<7'd68)    oled_colour <= G_BULET[34 - (oledy - Gy)*5 - (oledx - 63)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            //    else if (7'd69<=oledx && oledx<7'd74)    oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 69)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            //    else if (7'd75<=oledx && oledx<7'd80)    oled_colour <= G_BULET[34 - (oledy - Gy)*5 - (oledx - 75)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            //    else if (7'd81<=oledx && oledx<7'd86)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 81)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            //    else if (7'd87<=oledx && oledx<7'd92)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 87)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd1: begin
                Gy <= 6'd13; //d1(stagename), d13, d21, d29, d37, d45, d53
                if (7'd3<=oledx && oledx<7'd8)          oled_colour <= G_BULET[34 - (oledy - Gy)*5 - (oledx - 3)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd9<=oledx && oledx<7'd14)    oled_colour <= GLYPH_R[34 - (oledy - Gy)*5 - (oledx - 9)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd15<=oledx && oledx<7'd20)   oled_colour <= GLYPH_e[34 - (oledy - Gy)*5 - (oledx - 15)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd21<=oledx && oledx<7'd26)   oled_colour <= GLYPH_s[34 - (oledy - Gy)*5 - (oledx - 21)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd27<=oledx && oledx<7'd32)   oled_colour <= GLYPH_e[34 - (oledy - Gy)*5 - (oledx - 27)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd33<=oledx && oledx<7'd38)   oled_colour <= GLYPH_t[34 - (oledy - Gy)*5 - (oledx - 33)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd39<=oledx && oledx<7'd44)   oled_colour <= GLYPH_S[34 - (oledy - Gy)*5 - (oledx - 39)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd45<=oledx && oledx<7'd50)   oled_colour <= GLYPH_c[34 - (oledy - Gy)*5 - (oledx - 45)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd51<=oledx && oledx<7'd56)   oled_colour <= GLYPH_r[34 - (oledy - Gy)*5 - (oledx - 51)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd57<=oledx && oledx<7'd62)   oled_colour <= GLYPH_a[34 - (oledy - Gy)*5 - (oledx - 57)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd63<=oledx && oledx<7'd68)   oled_colour <= GLYPH_m[34 - (oledy - Gy)*5 - (oledx - 63)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd69<=oledx && oledx<7'd74)   oled_colour <= GLYPH_b[34 - (oledy - Gy)*5 - (oledx - 69)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd75<=oledx && oledx<7'd80)   oled_colour <= GLYPH_l[34 - (oledy - Gy)*5 - (oledx - 75)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                // else if (7'd81<=oledx && oledx<7'd86)   oled_colour <= GLYPH_e[34 - (oledy - Gy)*5 - (oledx - 81)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
//                else if (7'd87<=oledx && oledx<7'd92)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 87)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd2: begin
                Gy <= 6'd21; //d1(stagename), d13, d21, d29, d37, d45, d53
                oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd3: begin
                Gy <= 6'd29; //d1(stagename), d13, d21, d29, d37, d45, d53
                oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd4: begin
                Gy <= 6'd37; //d1(stagename), d13, d21, d29, d37, d45, d53
                oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd5: begin
                Gy <= 6'd45; //d1(stagename), d13, d21, d29, d37, d45, d53
                oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd6: begin
                Gy <= 6'd55; //d1(stagename), d13, d21, d29, d37, d45, d53
                oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd7: oled_colour <= COLOUR_RED; //big bar: red
            4'd8: oled_colour <= COLOUR_BLUE; //small bar: blue
            default: oled_colour <= COLOUR_BLACK; //set buffers to black
            endcase
        end // for if stage == STAGE_SOLVED

        STAGE_ERROR: begin
            case (activesegment)
            4'd0: begin
                Gy <= 6'd1; //d1(stagename), d13, d21, d29, d37, d45, d53
                if (7'd3<=oledx && oledx<7'd8)          oled_colour <= GLYPH_E[34 - (oledy - Gy)*5 - (oledx - 3)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd9<=oledx && oledx<7'd14)    oled_colour <= GLYPH_R[34 - (oledy - Gy)*5 - (oledx - 9)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd15<=oledx && oledx<7'd20)   oled_colour <= GLYPH_R[34 - (oledy - Gy)*5 - (oledx - 15)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd21<=oledx && oledx<7'd26)   oled_colour <= GLYPH_O[34 - (oledy - Gy)*5 - (oledx - 21)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd27<=oledx && oledx<7'd32)   oled_colour <= GLYPH_R[34 - (oledy - Gy)*5 - (oledx - 27)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            //    else if (7'd33<=oledx && oledx<7'd38)    oled_colour <= GLYPH_D[34 - (oledy - Gy)*5 - (oledx - 33)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            //    else if (7'd39<=oledx && oledx<7'd44)    oled_colour <= GLYPH_G[34 - (oledy - Gy)*5 - (oledx - 39)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            //    else if (7'd45<=oledx && oledx<7'd50)    oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 45)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            //    else if (7'd51<=oledx && oledx<7'd56)    oled_colour <= G_BULET[34 - (oledy - Gy)*5 - (oledx - 51)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            //    else if (7'd57<=oledx && oledx<7'd62)    oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 57)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            //    else if (7'd63<=oledx && oledx<7'd68)    oled_colour <= G_BULET[34 - (oledy - Gy)*5 - (oledx - 63)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            //    else if (7'd69<=oledx && oledx<7'd74)    oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 69)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            //    else if (7'd75<=oledx && oledx<7'd80)    oled_colour <= G_BULET[34 - (oledy - Gy)*5 - (oledx - 75)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            //    else if (7'd81<=oledx && oledx<7'd86)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 81)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            //    else if (7'd87<=oledx && oledx<7'd92)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 87)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd1: begin
                Gy <= 6'd13; //d1(stagename), d13, d21, d29, d37, d45, d53
                if (7'd3<=oledx && oledx<7'd8)          oled_colour <= GLYPH_P[34 - (oledy - Gy)*5 - (oledx - 3)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd9<=oledx && oledx<7'd14)    oled_colour <= GLYPH_l[34 - (oledy - Gy)*5 - (oledx - 9)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd15<=oledx && oledx<7'd20)   oled_colour <= GLYPH_e[34 - (oledy - Gy)*5 - (oledx - 15)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd21<=oledx && oledx<7'd26)   oled_colour <= GLYPH_a[34 - (oledy - Gy)*5 - (oledx - 21)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd27<=oledx && oledx<7'd32)   oled_colour <= GLYPH_s[34 - (oledy - Gy)*5 - (oledx - 27)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd33<=oledx && oledx<7'd38)   oled_colour <= GLYPH_e[34 - (oledy - Gy)*5 - (oledx - 33)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd39<=oledx && oledx<7'd44)   oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 39)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd45<=oledx && oledx<7'd50)   oled_colour <= GLYPH_u[34 - (oledy - Gy)*5 - (oledx - 45)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd51<=oledx && oledx<7'd56)   oled_colour <= GLYPH_s[34 - (oledy - Gy)*5 - (oledx - 51)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd57<=oledx && oledx<7'd62)   oled_colour <= GLYPH_e[34 - (oledy - Gy)*5 - (oledx - 57)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd63<=oledx && oledx<7'd68)   oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 63)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd69<=oledx && oledx<7'd74)   oled_colour <= GLYPH_S[34 - (oledy - Gy)*5 - (oledx - 69)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd75<=oledx && oledx<7'd80)   oled_colour <= GLYPH_W[34 - (oledy - Gy)*5 - (oledx - 75)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd81<=oledx && oledx<7'd86)   oled_colour <= GLYPH_1[34 - (oledy - Gy)*5 - (oledx - 81)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd87<=oledx && oledx<7'd92)   oled_colour <= GLYPH_5[34 - (oledy - Gy)*5 - (oledx - 87)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd2: begin
                Gy <= 6'd21; //d1(stagename), d13, d21, d29, d37, d45, d53
                if (7'd3<=oledx && oledx<7'd8)          oled_colour <= GLYPH_t[34 - (oledy - Gy)*5 - (oledx - 3)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd9<=oledx && oledx<7'd14)    oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 9)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd15<=oledx && oledx<7'd20)   oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 15)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd21<=oledx && oledx<7'd26)   oled_colour <= GLYPH_r[34 - (oledy - Gy)*5 - (oledx - 21)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd27<=oledx && oledx<7'd32)   oled_colour <= GLYPH_e[34 - (oledy - Gy)*5 - (oledx - 27)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd33<=oledx && oledx<7'd38)   oled_colour <= GLYPH_s[34 - (oledy - Gy)*5 - (oledx - 33)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd39<=oledx && oledx<7'd44)   oled_colour <= GLYPH_e[34 - (oledy - Gy)*5 - (oledx - 39)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd45<=oledx && oledx<7'd50)   oled_colour <= GLYPH_t[34 - (oledy - Gy)*5 - (oledx - 45)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd51<=oledx && oledx<7'd56)   oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 51)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd57<=oledx && oledx<7'd62)   oled_colour <= G_BULET[34 - (oledy - Gy)*5 - (oledx - 57)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd63<=oledx && oledx<7'd68)   oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 63)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd69<=oledx && oledx<7'd74)   oled_colour <= G_BULET[34 - (oledy - Gy)*5 - (oledx - 69)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd75<=oledx && oledx<7'd80)   oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 75)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else if (7'd81<=oledx && oledx<7'd86)   oled_colour <= G_BULET[34 - (oledy - Gy)*5 - (oledx - 81)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            //    else if (7'd87<=oledx && oledx<7'd92)   oled_colour <= GLYPH_5[34 - (oledy - Gy)*5 - (oledx - 87)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
                else oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd3: begin
                Gy <= 6'd29; //d1(stagename), d13, d21, d29, d37, d45, d53
                oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd4: begin
                Gy <= 6'd37; //d1(stagename), d13, d21, d29, d37, d45, d53
                oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd5: begin
                Gy <= 6'd45; //d1(stagename), d13, d21, d29, d37, d45, d53
                oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd6: begin
                Gy <= 6'd55; //d1(stagename), d13, d21, d29, d37, d45, d53
                oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
            end
            4'd7: oled_colour <= COLOUR_RED; //big bar: red
            4'd8: oled_colour <= COLOUR_BLUE; //small bar: blue
            default: oled_colour <= COLOUR_BLACK; //set buffers to black
            endcase
        end // for if stage == STAGE_ERROR

        // STAGE_MANUAL_SOLVING: begin
        //     case (activesegment)
        //     4'd0: begin
        //         Gy <= 6'd1; //d1(stagename), d13, d21, d29, d37, d45, d53
        //         if (7'd3<=oledx && oledx<7'd8)          oled_colour <= GLYPH_M[34 - (oledy - Gy)*5 - (oledx - 3)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //         else if (7'd9<=oledx && oledx<7'd14)    oled_colour <= GLYPH_a[34 - (oledy - Gy)*5 - (oledx - 9)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //         else if (7'd15<=oledx && oledx<7'd20)   oled_colour <= GLYPH_n[34 - (oledy - Gy)*5 - (oledx - 15)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //         else if (7'd21<=oledx && oledx<7'd26)   oled_colour <= GLYPH_u[34 - (oledy - Gy)*5 - (oledx - 21)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //         else if (7'd27<=oledx && oledx<7'd32)   oled_colour <= GLYPH_a[34 - (oledy - Gy)*5 - (oledx - 27)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //        else if (7'd33<=oledx && oledx<7'd38)    oled_colour <= GLYPH_l[34 - (oledy - Gy)*5 - (oledx - 33)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //        else if (7'd39<=oledx && oledx<7'd44)    oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 39)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //        else if (7'd45<=oledx && oledx<7'd50)    oled_colour <= GLYPH_S[34 - (oledy - Gy)*5 - (oledx - 45)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //        else if (7'd51<=oledx && oledx<7'd56)    oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 51)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //        else if (7'd57<=oledx && oledx<7'd62)    oled_colour <= GLYPH_l[34 - (oledy - Gy)*5 - (oledx - 57)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //        else if (7'd63<=oledx && oledx<7'd68)    oled_colour <= GLYPH_v[34 - (oledy - Gy)*5 - (oledx - 63)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //        else if (7'd69<=oledx && oledx<7'd74)    oled_colour <= GLYPH_e[34 - (oledy - Gy)*5 - (oledx - 69)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //     //    else if (7'd75<=oledx && oledx<7'd80)    oled_colour <= G_BULET[34 - (oledy - Gy)*5 - (oledx - 75)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //     //    else if (7'd81<=oledx && oledx<7'd86)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 81)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //     //    else if (7'd87<=oledx && oledx<7'd92)   oled_colour <= GLYPH_o[34 - (oledy - Gy)*5 - (oledx - 87)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //         else oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //     end
        //     4'd1: begin
        //         Gy <= 6'd13; //d1(stagename), d13, d21, d29, d37, d45, d53
        //         if (7'd3<=oledx && oledx<7'd8)          oled_colour <= GLYPH_G[34 - (oledy - Gy)*5 - (oledx - 3)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //         else if (7'd9<=oledx && oledx<7'd14)    oled_colour <= GLYPH_i[34 - (oledy - Gy)*5 - (oledx - 9)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //         else if (7'd15<=oledx && oledx<7'd20)   oled_colour <= GLYPH_v[34 - (oledy - Gy)*5 - (oledx - 15)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //         else if (7'd21<=oledx && oledx<7'd26)   oled_colour <= GLYPH_e[34 - (oledy - Gy)*5 - (oledx - 21)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //         else if (7'd27<=oledx && oledx<7'd32)   oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 27)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //         else if (7'd33<=oledx && oledx<7'd38)   oled_colour <= GLYPH_U[34 - (oledy - Gy)*5 - (oledx - 33)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //         else if (7'd39<=oledx && oledx<7'd44)   oled_colour <= GLYPH_p[34 - (oledy - Gy)*5 - (oledx - 39)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //         else if (7'd45<=oledx && oledx<7'd50)   oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 45)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //         else if (7'd51<=oledx && oledx<7'd56)   oled_colour <= G_COLON[34 - (oledy - Gy)*5 - (oledx - 51)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //         else if (7'd57<=oledx && oledx<7'd62)   oled_colour <= G_LBRKT[34 - (oledy - Gy)*5 - (oledx - 57)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //         // else if (7'd63<=oledx && oledx<7'd68)   oled_colour <= G_BLANK[34 - (oledy - Gy)*5 - (oledx - 63)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //         // else if (7'd69<=oledx && oledx<7'd74)   oled_colour <= GLYPH_S[34 - (oledy - Gy)*5 - (oledx - 69)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //         // else if (7'd75<=oledx && oledx<7'd80)   oled_colour <= GLYPH_W[34 - (oledy - Gy)*5 - (oledx - 75)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //         // else if (7'd81<=oledx && oledx<7'd86)   oled_colour <= GLYPH_1[34 - (oledy - Gy)*5 - (oledx - 81)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //         // else if (7'd87<=oledx && oledx<7'd92)   oled_colour <= GLYPH_5[34 - (oledy - Gy)*5 - (oledx - 87)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //         else oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //     end
        //     4'd2: begin
        //         Gy <= 6'd21; //d1(stagename), d13, d21, d29, d37, d45, d53
        //         oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //     end
        //     4'd3: begin
        //         Gy <= 6'd29; //d1(stagename), d13, d21, d29, d37, d45, d53
        //         oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //     end
        //     4'd4: begin
        //         Gy <= 6'd37; //d1(stagename), d13, d21, d29, d37, d45, d53
        //         oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //     end
        //     4'd5: begin
        //         Gy <= 6'd45; //d1(stagename), d13, d21, d29, d37, d45, d53
        //         oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //     end
        //     4'd6: begin
        //         Gy <= 6'd55; //d1(stagename), d13, d21, d29, d37, d45, d53
        //         oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
        //     end
        //     4'd7: oled_colour <= COLOUR_RED; //big bar: red
        //     4'd8: oled_colour <= COLOUR_BLUE; //small bar: blue
        //     default: oled_colour <= COLOUR_BLACK; //set buffers to black
        //     endcase
        // end // for if stage == STAGE_MANUAL_SOLVING



        endcase // for case (stage)
    end
    
    

endmodule
