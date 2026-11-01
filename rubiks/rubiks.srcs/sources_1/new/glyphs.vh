/*
    each glyph is 7 pixels tall, 5 pix wide

    USAGE: pixel_colour = GLYPH_x[34 - blocky*5 - blockx] ? text_colour : bg_colour.
*/

localparam [15:0] COLOUR_WHITE = 16'b11111_111111_11111;
localparam [15:0] COLOUR_RED = 16'b11111_000000_00000;
localparam [15:0] COLOUR_BLUE = 16'b00000_000000_11111;
localparam [15:0] COLOUR_BLACK = 16'b0;
localparam [15:0] COLOUR_SELECTED = 16'b00000_111111_00000;

localparam [34:0] G_BLANK = 35'b0;
localparam [34:0] G_BULET = {5'b00000, 5'b00000, 5'b01110, 5'b01110, 5'b01110, 5'b00000, 5'b00000};


// digits
localparam [34:0] GLYPH_0 = {5'b01110, 5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b01110};
localparam [34:0] GLYPH_1 = {5'b00100, 5'b01100, 5'b00100, 5'b00100, 5'b00100, 5'b00100, 5'b01110};
localparam [34:0] GLYPH_2 = {5'b01110, 5'b10001, 5'b00001, 5'b00010, 5'b00100, 5'b01000, 5'b11111};
localparam [34:0] GLYPH_3 = {5'b11110, 5'b00001, 5'b00001, 5'b01110, 5'b00001, 5'b00001, 5'b11110};
localparam [34:0] GLYPH_4 = {5'b00010, 5'b00110, 5'b01010, 5'b10010, 5'b11111, 5'b00010, 5'b00010};
localparam [34:0] GLYPH_5 = {5'b11111, 5'b10000, 5'b10000, 5'b11110, 5'b00001, 5'b00001, 5'b11110};
localparam [34:0] GLYPH_6 = {5'b01110, 5'b10000, 5'b10000, 5'b11110, 5'b10001, 5'b10001, 5'b01110};
localparam [34:0] GLYPH_7 = {5'b11111, 5'b00001, 5'b00010, 5'b00100, 5'b01000, 5'b01000, 5'b01000};
localparam [34:0] GLYPH_8 = {5'b01110, 5'b10001, 5'b10001, 5'b01110, 5'b10001, 5'b10001, 5'b01110};
localparam [34:0] GLYPH_9 = {5'b01110, 5'b10001, 5'b10001, 5'b01111, 5'b00001, 5'b00001, 5'b01110};

// uppercase letters
localparam [34:0] GLYPH_A = {5'b01110, 5'b10001, 5'b10001, 5'b11111, 5'b10001, 5'b10001, 5'b10001};
localparam [34:0] GLYPH_B = {5'b11110, 5'b10001, 5'b10001, 5'b11110, 5'b10001, 5'b10001, 5'b11110};
localparam [34:0] GLYPH_C = {5'b01111, 5'b10000, 5'b10000, 5'b10000, 5'b10000, 5'b10000, 5'b01111};
localparam [34:0] GLYPH_D = {5'b11110, 5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b11110};
localparam [34:0] GLYPH_E = {5'b11111, 5'b10000, 5'b10000, 5'b11110, 5'b10000, 5'b10000, 5'b11111};
localparam [34:0] GLYPH_F = {5'b11111, 5'b10000, 5'b10000, 5'b11110, 5'b10000, 5'b10000, 5'b10000};
localparam [34:0] GLYPH_G = {5'b01111, 5'b10000, 5'b10000, 5'b10111, 5'b10001, 5'b10001, 5'b01111};
localparam [34:0] GLYPH_H = {5'b10001, 5'b10001, 5'b10001, 5'b11111, 5'b10001, 5'b10001, 5'b10001};
localparam [34:0] GLYPH_I = {5'b01110, 5'b00100, 5'b00100, 5'b00100, 5'b00100, 5'b00100, 5'b01110};
localparam [34:0] GLYPH_J = {5'b00111, 5'b00010, 5'b00010, 5'b00010, 5'b10010, 5'b10010, 5'b01100};
localparam [34:0] GLYPH_K = {5'b10001, 5'b10010, 5'b10100, 5'b11000, 5'b10100, 5'b10010, 5'b10001};
localparam [34:0] GLYPH_L = {5'b10000, 5'b10000, 5'b10000, 5'b10000, 5'b10000, 5'b10000, 5'b11111};
localparam [34:0] GLYPH_M = {5'b10001, 5'b11011, 5'b10101, 5'b10101, 5'b10001, 5'b10001, 5'b10001};
localparam [34:0] GLYPH_N = {5'b10001, 5'b11001, 5'b10101, 5'b10011, 5'b10001, 5'b10001, 5'b10001};
localparam [34:0] GLYPH_O = {5'b01110, 5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b01110};
localparam [34:0] GLYPH_P = {5'b11110, 5'b10001, 5'b10001, 5'b11110, 5'b10000, 5'b10000, 5'b10000};
localparam [34:0] GLYPH_Q = {5'b01110, 5'b10001, 5'b10001, 5'b10001, 5'b10101, 5'b10010, 5'b01101};
localparam [34:0] GLYPH_R = {5'b11110, 5'b10001, 5'b10001, 5'b11110, 5'b10100, 5'b10010, 5'b10001};
localparam [34:0] GLYPH_S = {5'b01111, 5'b10000, 5'b10000, 5'b01110, 5'b00001, 5'b00001, 5'b11110};
localparam [34:0] GLYPH_T = {5'b11111, 5'b00100, 5'b00100, 5'b00100, 5'b00100, 5'b00100, 5'b00100};
localparam [34:0] GLYPH_U = {5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b01110};
localparam [34:0] GLYPH_V = {5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b01010, 5'b00100};
localparam [34:0] GLYPH_W = {5'b10001, 5'b10001, 5'b10001, 5'b10101, 5'b10101, 5'b10101, 5'b01010};
localparam [34:0] GLYPH_X = {5'b10001, 5'b10001, 5'b01010, 5'b00100, 5'b01010, 5'b10001, 5'b10001};
localparam [34:0] GLYPH_Y = {5'b10001, 5'b10001, 5'b01010, 5'b00100, 5'b00100, 5'b00100, 5'b00100};
localparam [34:0] GLYPH_Z = {5'b11111, 5'b00001, 5'b00010, 5'b00100, 5'b01000, 5'b10000, 5'b11111};

// lowercase letters
localparam [34:0] GLYPH_a = {5'b00000, 5'b00000, 5'b01110, 5'b00001, 5'b01111, 5'b10001, 5'b01111};
localparam [34:0] GLYPH_b = {5'b10000, 5'b10000, 5'b10110, 5'b11001, 5'b10001, 5'b11001, 5'b10110};
localparam [34:0] GLYPH_c = {5'b00000, 5'b00000, 5'b01111, 5'b10000, 5'b10000, 5'b10000, 5'b01111};
localparam [34:0] GLYPH_d = {5'b00001, 5'b00001, 5'b01101, 5'b10011, 5'b10001, 5'b10011, 5'b01101};
localparam [34:0] GLYPH_e = {5'b00000, 5'b00000, 5'b01110, 5'b10001, 5'b11111, 5'b10000, 5'b01110};
localparam [34:0] GLYPH_f = {5'b00110, 5'b01001, 5'b01000, 5'b11100, 5'b01000, 5'b01000, 5'b01000};
localparam [34:0] GLYPH_g = {5'b00000, 5'b01111, 5'b10001, 5'b10001, 5'b01111, 5'b00001, 5'b01110};
localparam [34:0] GLYPH_h = {5'b10000, 5'b10000, 5'b10110, 5'b11001, 5'b10001, 5'b10001, 5'b10001};
localparam [34:0] GLYPH_i = {5'b00100, 5'b00000, 5'b01100, 5'b00100, 5'b00100, 5'b00100, 5'b01110};
localparam [34:0] GLYPH_j = {5'b00010, 5'b00000, 5'b00110, 5'b00010, 5'b00010, 5'b10010, 5'b01100};
localparam [34:0] GLYPH_k = {5'b10000, 5'b10000, 5'b10010, 5'b10100, 5'b11000, 5'b10100, 5'b10010};
localparam [34:0] GLYPH_l = {5'b01100, 5'b00100, 5'b00100, 5'b00100, 5'b00100, 5'b00100, 5'b01110};
localparam [34:0] GLYPH_m = {5'b00000, 5'b00000, 5'b11010, 5'b10101, 5'b10101, 5'b10101, 5'b10101};
localparam [34:0] GLYPH_n = {5'b00000, 5'b00000, 5'b10110, 5'b11001, 5'b10001, 5'b10001, 5'b10001};
localparam [34:0] GLYPH_o = {5'b00000, 5'b00000, 5'b01110, 5'b10001, 5'b10001, 5'b10001, 5'b01110};
localparam [34:0] GLYPH_p = {5'b00000, 5'b10110, 5'b11001, 5'b10001, 5'b11001, 5'b10110, 5'b10000};
localparam [34:0] GLYPH_q = {5'b00000, 5'b01101, 5'b10011, 5'b10001, 5'b10011, 5'b01101, 5'b00001};
localparam [34:0] GLYPH_r = {5'b00000, 5'b00000, 5'b10110, 5'b11001, 5'b10000, 5'b10000, 5'b10000};
localparam [34:0] GLYPH_s = {5'b00000, 5'b00000, 5'b01111, 5'b10000, 5'b01110, 5'b00001, 5'b11110};
localparam [34:0] GLYPH_t = {5'b01000, 5'b01000, 5'b11100, 5'b01000, 5'b01000, 5'b01001, 5'b00110};
localparam [34:0] GLYPH_u = {5'b00000, 5'b00000, 5'b10001, 5'b10001, 5'b10001, 5'b10011, 5'b01101};
localparam [34:0] GLYPH_v = {5'b00000, 5'b00000, 5'b10001, 5'b10001, 5'b10001, 5'b01010, 5'b00100};
localparam [34:0] GLYPH_w = {5'b00000, 5'b00000, 5'b10001, 5'b10001, 5'b10101, 5'b10101, 5'b01010};
localparam [34:0] GLYPH_x = {5'b00000, 5'b00000, 5'b10001, 5'b01010, 5'b00100, 5'b01010, 5'b10001};
localparam [34:0] GLYPH_y = {5'b00000, 5'b10001, 5'b10001, 5'b10001, 5'b01111, 5'b00001, 5'b01110};
localparam [34:0] GLYPH_z = {5'b00000, 5'b00000, 5'b11111, 5'b00010, 5'b00100, 5'b01000, 5'b11111};

//        3'd0: begin
//            case (activesegment)
//            4'd0: begin
//                Gy <= 6'd1; //d1(stagename), d13, d21, d29, d37, d45, d55(status)
//                if (7'd3<=oledx && oledx<7'd8)          oled_colour <= GLYPH_S[34 - (oledy - Gy)*5 - (oledx - 3)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
//                else if (7'd9<=oledx && oledx<7'd14)    oled_colour <= GLYPH_T[34 - (oledy - Gy)*5 - (oledx - 9)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
//                else if (7'd15<=oledx && oledx<7'd20)   oled_colour <= GLYPH_A[34 - (oledy - Gy)*5 - (oledx - 15)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
//                else if (7'd21<=oledx && oledx<7'd26)   oled_colour <= GLYPH_R[34 - (oledy - Gy)*5 - (oledx - 21)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
//                else if (7'd27<=oledx && oledx<7'd32)   oled_colour <= GLYPH_T[34 - (oledy - Gy)*5 - (oledx - 27)] ? COLOUR_WHITE : selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
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
//                else oled_colour <= selectedoption == activesegment ? COLOUR_SELECTED : COLOUR_BLACK;
//            end
//            4'd1: begin
//            end
//            4'd2: begin
//            end
//            4'd3: begin
//            end
//            4'd4: begin
//            end
//            4'd5: begin
//            end
//            4'd6: begin
//            end
//            4'd7: oled_colour <= COLOUR_RED; //big bar: red
//            4'd8: oled_colour <= COLOUR_BLUE; //small bar: blue
//            default: oled_colour <= COLOUR_BLACK; //set buffers to black
//            endcase
//        end //stage == 3'd0