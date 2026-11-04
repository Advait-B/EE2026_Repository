`timescale 1ns / 1ps

// hud_overlay.v
// VGA heads-up display drawn over the cube: stage header with move counter and
// progress line, a hint line under the cube, and a footer of recent / planned moves.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh
//
// Screen layout (640x480):
//   y   0-53   header: stage square + name (left), MOVES nn/tt (right)
//   y  54-55   divider; fills left-to-right in the stage colour as moves are made
//   y 384-397  hint line, centred (cube spans roughly y 99-381)
//   y 400-401  divider
//   y 402-479  footer: label (HISTORY / SCRAMBLE / SOLUTION) + move chips
// Text uses a 5x7 font, scale 2 (10x14) for small text and scale 3 (15x21) for large.

module hud_overlay (
    input clk, // 100 MHz clock
    input rst, // reset
    input [2:0] stage, // current game stage
    input [4:0] move_req, // move sent to the engine
    input move_valid, // pulse when move_req is applied
    input [3:0] moves_left, // solve moves remaining
    input [54:0] plan_left, // queued solution moves, next move at [4:0]
    input [9:0] pix_x, pix_y, // current VGA pixel position
    output reg hud_on, // 1 = HUD owns this pixel
    output reg [11:0] hud_rgb // HUD colour {r, g, b}
);
`include "cube_defs.vh"

    // ------------------------------------------------------------------
    // Layout constants
    // ------------------------------------------------------------------
    localparam HEADER_H   = 56;  // header rows 0-55, divider on 54-55
    localparam FOOTER_Y   = 400; // footer divider on 400-401
    localparam HINT_Y     = 384;
    localparam CHIP_X     = 136; // first move chip
    localparam CHIP_Y     = 425;
    localparam CHIP_W     = 40;
    localparam CHIP_H     = 30;
    localparam CHIP_PITCH = 44;
    localparam CHIP_TXT_Y = 433;
    localparam MAX_CHIPS  = 11;  // longest solver plan
    localparam HIST_CHIPS = 8;   // chips shown outside solving

    localparam [11:0] RGB_BLACK   = 12'h000;
    localparam [11:0] RGB_WHITE   = 12'hFFF;
    localparam [11:0] RGB_DIVIDER = 12'h333;
    localparam [11:0] RGB_LABEL   = 12'h888;
    localparam [11:0] RGB_DONE_BG = 12'h222;
    localparam [11:0] RGB_DONE_FG = 12'hBBB;
    localparam [11:0] RGB_NEXT_RG = 12'h444;
    localparam [11:0] RGB_ERROR   = 12'hF33;

    localparam [1:0] CHIP_DONE = 2'd0, CHIP_CUR = 2'd1, CHIP_NEXT = 2'd2;

    // ------------------------------------------------------------------
    // Font: 5x7 glyphs, same bitmaps as glyphs.vh, indexed by ASCII
    // ------------------------------------------------------------------
    function automatic [34:0] glyph(input [7:0] ch);
        begin
            case (ch)
            "0": glyph = {5'b01110, 5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b01110};
            "1": glyph = {5'b00100, 5'b01100, 5'b00100, 5'b00100, 5'b00100, 5'b00100, 5'b01110};
            "2": glyph = {5'b01110, 5'b10001, 5'b00001, 5'b00010, 5'b00100, 5'b01000, 5'b11111};
            "3": glyph = {5'b11110, 5'b00001, 5'b00001, 5'b01110, 5'b00001, 5'b00001, 5'b11110};
            "4": glyph = {5'b00010, 5'b00110, 5'b01010, 5'b10010, 5'b11111, 5'b00010, 5'b00010};
            "5": glyph = {5'b11111, 5'b10000, 5'b10000, 5'b11110, 5'b00001, 5'b00001, 5'b11110};
            "6": glyph = {5'b01110, 5'b10000, 5'b10000, 5'b11110, 5'b10001, 5'b10001, 5'b01110};
            "7": glyph = {5'b11111, 5'b00001, 5'b00010, 5'b00100, 5'b01000, 5'b01000, 5'b01000};
            "8": glyph = {5'b01110, 5'b10001, 5'b10001, 5'b01110, 5'b10001, 5'b10001, 5'b01110};
            "9": glyph = {5'b01110, 5'b10001, 5'b10001, 5'b01111, 5'b00001, 5'b00001, 5'b01110};
            "A": glyph = {5'b01110, 5'b10001, 5'b10001, 5'b11111, 5'b10001, 5'b10001, 5'b10001};
            "B": glyph = {5'b11110, 5'b10001, 5'b10001, 5'b11110, 5'b10001, 5'b10001, 5'b11110};
            "C": glyph = {5'b01111, 5'b10000, 5'b10000, 5'b10000, 5'b10000, 5'b10000, 5'b01111};
            "D": glyph = {5'b11110, 5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b11110};
            "E": glyph = {5'b11111, 5'b10000, 5'b10000, 5'b11110, 5'b10000, 5'b10000, 5'b11111};
            "F": glyph = {5'b11111, 5'b10000, 5'b10000, 5'b11110, 5'b10000, 5'b10000, 5'b10000};
            "G": glyph = {5'b01111, 5'b10000, 5'b10000, 5'b10111, 5'b10001, 5'b10001, 5'b01111};
            "H": glyph = {5'b10001, 5'b10001, 5'b10001, 5'b11111, 5'b10001, 5'b10001, 5'b10001};
            "I": glyph = {5'b01110, 5'b00100, 5'b00100, 5'b00100, 5'b00100, 5'b00100, 5'b01110};
            "J": glyph = {5'b00111, 5'b00010, 5'b00010, 5'b00010, 5'b10010, 5'b10010, 5'b01100};
            "K": glyph = {5'b10001, 5'b10010, 5'b10100, 5'b11000, 5'b10100, 5'b10010, 5'b10001};
            "L": glyph = {5'b10000, 5'b10000, 5'b10000, 5'b10000, 5'b10000, 5'b10000, 5'b11111};
            "M": glyph = {5'b10001, 5'b11011, 5'b10101, 5'b10101, 5'b10001, 5'b10001, 5'b10001};
            "N": glyph = {5'b10001, 5'b11001, 5'b10101, 5'b10011, 5'b10001, 5'b10001, 5'b10001};
            "O": glyph = {5'b01110, 5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b01110};
            "P": glyph = {5'b11110, 5'b10001, 5'b10001, 5'b11110, 5'b10000, 5'b10000, 5'b10000};
            "Q": glyph = {5'b01110, 5'b10001, 5'b10001, 5'b10001, 5'b10101, 5'b10010, 5'b01101};
            "R": glyph = {5'b11110, 5'b10001, 5'b10001, 5'b11110, 5'b10100, 5'b10010, 5'b10001};
            "S": glyph = {5'b01111, 5'b10000, 5'b10000, 5'b01110, 5'b00001, 5'b00001, 5'b11110};
            "T": glyph = {5'b11111, 5'b00100, 5'b00100, 5'b00100, 5'b00100, 5'b00100, 5'b00100};
            "U": glyph = {5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b01110};
            "V": glyph = {5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b10001, 5'b01010, 5'b00100};
            "W": glyph = {5'b10001, 5'b10001, 5'b10001, 5'b10101, 5'b10101, 5'b10101, 5'b01010};
            "X": glyph = {5'b10001, 5'b10001, 5'b01010, 5'b00100, 5'b01010, 5'b10001, 5'b10001};
            "Y": glyph = {5'b10001, 5'b10001, 5'b01010, 5'b00100, 5'b00100, 5'b00100, 5'b00100};
            "Z": glyph = {5'b11111, 5'b00001, 5'b00010, 5'b00100, 5'b01000, 5'b10000, 5'b11111};
            "'": glyph = {5'b00100, 5'b00100, 5'b01000, 5'b00000, 5'b00000, 5'b00000, 5'b00000};
            "/": glyph = {5'b00001, 5'b00010, 5'b00010, 5'b00100, 5'b01000, 5'b01000, 5'b10000};
            "-": glyph = {5'b00000, 5'b00000, 5'b00000, 5'b01110, 5'b00000, 5'b00000, 5'b00000};
            "|": glyph = {5'b00100, 5'b00100, 5'b00100, 5'b00100, 5'b00100, 5'b00100, 5'b00100};
            ":": glyph = {5'b00000, 5'b00100, 5'b00100, 5'b00000, 5'b00100, 5'b00100, 5'b00000};
            default: glyph = 35'd0; // space and anything unknown
            endcase
        end
    endfunction

    // 1 if (px, py) lands on a lit font pixel of str, drawn with its top-left at (x0, y0).
    // str holds len ASCII characters right-justified (the first character is the
    // most significant byte in use). big = scale 3, else scale 2. Advance is 6 font pixels.
    function automatic text_px(
        input [9:0] px, py, x0, y0,
        input [319:0] str,
        input [5:0] len,
        input big
    );
        reg [9:0] dx, dy, cx, ry;
        reg [5:0] idx;
        reg [2:0] col;
        reg [7:0] ch;
        reg [34:0] g;
        begin
            text_px = 1'b0;
            if (px >= x0 && py >= y0) begin
                dx = px - x0;
                dy = py - y0;
                cx = big ? dx / 3 : dx >> 1;
                ry = big ? dy / 3 : dy >> 1;
                if (ry < 7 && cx < len * 6) begin
                    idx = cx / 6;
                    col = cx - idx * 6;
                    ch = str >> ((len - 1 - idx) * 8);
                    g = glyph(ch);
                    if (col < 5)
                        text_px = g[34 - ry[2:0] * 5 - col];
                end
            end
        end
    endfunction

    // move code -> two ASCII characters, second is a space for quarter turns
    function automatic [15:0] move_text(input [4:0] mv);
        begin
            case (mv)
                MV_U:  move_text = "U "; MV_UP: move_text = "U'"; MV_U2: move_text = "U2";
                MV_R:  move_text = "R "; MV_RP: move_text = "R'"; MV_R2: move_text = "R2";
                MV_F:  move_text = "F "; MV_FP: move_text = "F'"; MV_F2: move_text = "F2";
                MV_D:  move_text = "D "; MV_DP: move_text = "D'"; MV_D2: move_text = "D2";
                MV_L:  move_text = "L "; MV_LP: move_text = "L'"; MV_L2: move_text = "L2";
                MV_B:  move_text = "B "; MV_BP: move_text = "B'"; MV_B2: move_text = "B2";
                default: move_text = "--";
            endcase
        end
    endfunction

    // ------------------------------------------------------------------
    // Move tracking (100 MHz domain)
    // ------------------------------------------------------------------
    reg [2:0] stage_q;
    reg [6:0] count; // moves made in this session, saturates at 127
    reg [54:0] hist; // last 11 applied moves, newest at [4:0]

    // a new session starts when entering these stages; SCRAMBLED, SOLVED and ERROR keep the count
    wire new_session = (stage != stage_q) &&
                       (stage == STAGE_START || stage == STAGE_AUTO_SCRAMBLE ||
                        stage == STAGE_MANUAL_SCRAMBLE || stage == STAGE_SOLVING ||
                        stage == STAGE_MANUAL_SOLVING);

    always @(posedge clk) begin
        if (rst) begin
            stage_q <= STAGE_START;
            count <= 7'd0;
            hist <= {11{MV_NONE}};
        end else begin
            stage_q <= stage;
            if (new_session)
                count <= 7'd0;
            else if (move_valid) begin
                hist <= {hist[49:0], move_req};
                if (count != 7'd127)
                    count <= count + 7'd1;
            end
        end
    end

    // ------------------------------------------------------------------
    // Derived values
    // ------------------------------------------------------------------
    wire solve_mode = (stage == STAGE_SOLVING) || (stage == STAGE_SOLVED);

    reg [6:0] total;
    always @* begin
        case (stage)
            STAGE_AUTO_SCRAMBLE: total = 7'd25;
            STAGE_SCRAMBLED:     total = count;
            STAGE_SOLVING,
            STAGE_SOLVED:        total = count + {3'd0, moves_left};
            default:             total = 7'd0;
        endcase
    end
    wire has_total = (total != 7'd0);

    // two-digit decimal strings
    wire [6:0] count_c = (count > 7'd99) ? 7'd99 : count;
    wire [6:0] total_c = (total > 7'd99) ? 7'd99 : total;
    wire [3:0] count_t = count_c / 10;
    wire [3:0] count_o = count_c - count_t * 10;
    wire [3:0] total_t = total_c / 10;
    wire [3:0] total_o = total_c - total_t * 10;
    wire [15:0] count_str = {8'd48 + count_t, 8'd48 + count_o};
    wire [15:0] total_str = {8'd48 + total_t, 8'd48 + total_o};

    // stage colour, name, footer label, hint
    reg [11:0] mode_rgb;
    reg [199:0] mode_str, foot_str, empty_str;
    reg [4:0] mode_len, foot_len, empty_len;
    reg [319:0] hint_str; // hint line, up to 40 characters
    reg [5:0] hint_len;
    always @* begin
        foot_str = "HISTORY";  foot_len = 5'd7;
        empty_str = "NO MOVES YET"; empty_len = 5'd12;
        case (stage)
            STAGE_START: begin
                mode_rgb = 12'hAAA; mode_str = "READY"; mode_len = 5'd5;
                hint_str = "PRESS BTNC TO SCRAMBLE"; hint_len = 6'd22;
            end
            STAGE_AUTO_SCRAMBLE: begin
                mode_rgb = 12'hF80; mode_str = "AUTO SCRAMBLE"; mode_len = 5'd13;
                foot_str = "SCRAMBLE"; foot_len = 5'd8;
                hint_str = "SCRAMBLING"; hint_len = 6'd10;
            end
            STAGE_MANUAL_SCRAMBLE: begin
                mode_rgb = 12'h0CF; mode_str = "MANUAL SCRAMBLE"; mode_len = 5'd15;
                hint_str = "BTNS - U/D: FACE | L/R: ACW/CW | C: EXIT"; hint_len = 6'd40;
            end
            STAGE_SCRAMBLED: begin
                mode_rgb = 12'hF0F; mode_str = "SCRAMBLED"; mode_len = 5'd9;
                foot_str = "SCRAMBLE"; foot_len = 5'd8;
                hint_str = "PRESS BTNC TO SOLVE"; hint_len = 6'd19;
            end
            STAGE_SOLVING: begin
                mode_rgb = 12'hFE0; mode_str = "SOLVING"; mode_len = 5'd7;
                foot_str = "SOLUTION"; foot_len = 5'd8;
                empty_str = "SEARCHING"; empty_len = 5'd9;
                if (has_total) begin
                    hint_str = {"SOLUTION FOUND - ", total_str, " MOVES"}; hint_len = 6'd25;
                end else begin
                    hint_str = "SEARCHING"; hint_len = 6'd9;
                end
            end
            STAGE_MANUAL_SOLVING: begin
                mode_rgb = 12'hF00; mode_str = "MANUAL SOLVE"; mode_len = 5'd12;
                // foot_str = "SOLUTION"; foot_len = 5'd8;
                hint_str = "BTNS - U/D: FACE | L/R: ACW/CW | C: QUIT"; hint_len = 6'd40;
            end
            STAGE_SOLVED: begin
                mode_rgb = 12'h0F4; mode_str = "SOLVED"; mode_len = 5'd6;
                foot_str = "SOLUTION"; foot_len = 5'd8;
                hint_str = {"SOLVED IN ", count_str, " MOVES"}; hint_len = 6'd18;
            end
            default: begin // STAGE_ERROR
                mode_rgb = RGB_ERROR; mode_str = "ERROR"; mode_len = 5'd5;
                foot_str = "SOLUTION"; foot_len = 5'd8;
                empty_str = "NO SOLUTION FOUND"; empty_len = 5'd17;
                hint_str = "SOLVER TIMEOUT"; hint_len = 6'd14;
            end
        endcase
    end

    // ------------------------------------------------------------------
    // Move chips
    // Solving / solved: done moves from hist, then upcoming moves from plan_left.
    // Otherwise: the last HIST_CHIPS moves of this session, newest on the right.
    // ------------------------------------------------------------------
    wire [3:0] done_n = (count > MAX_CHIPS) ? MAX_CHIPS : count[3:0];
    wire [4:0] plan_n = {1'b0, done_n} + {1'b0, moves_left};
    wire [3:0] hist_n = (count > HIST_CHIPS) ? HIST_CHIPS : count[3:0];
    wire [3:0] n_chips = (stage == STAGE_ERROR) ? 4'd0 :
                         solve_mode ? ((plan_n > MAX_CHIPS) ? MAX_CHIPS : plan_n[3:0]) :
                         hist_n;

    wire [9:0] chip_dx = pix_x - CHIP_X;
    wire [3:0] chip_k = chip_dx / CHIP_PITCH;
    wire [5:0] chip_off = chip_dx - chip_k * CHIP_PITCH;
    wire chip_row = (pix_y >= CHIP_Y) && (pix_y < CHIP_Y + CHIP_H) && (pix_x >= CHIP_X);
    wire chip_hit = chip_row && (chip_k < n_chips) && (chip_off < CHIP_W);

    reg [4:0] chip_mv;
    reg [1:0] chip_state;
    always @* begin
        if (solve_mode && chip_k >= done_n) begin
            chip_mv = plan_left >> ((chip_k - done_n) * 5);
            chip_state = CHIP_NEXT;
        end else if (solve_mode) begin
            chip_mv = hist >> ((done_n - 4'd1 - chip_k) * 5);
            chip_state = (chip_k == done_n - 4'd1) ? CHIP_CUR : CHIP_DONE;
        end else begin
            chip_mv = hist >> ((hist_n - 4'd1 - chip_k) * 5);
            chip_state = (chip_k == hist_n - 4'd1) ? CHIP_CUR : CHIP_DONE;
        end
    end

    wire [15:0] chip_txt = move_text(chip_mv);
    wire chip_one = (chip_txt[7:0] == " ");
    // centre 1 or 2 characters (10 or 22 px wide) inside the 40 px chip
    wire chip_txt_px = text_px({4'd0, chip_off}, pix_y, chip_one ? 10'd15 : 10'd9, CHIP_TXT_Y,
                               chip_one ? {192'd0, chip_txt[15:8]} : {184'd0, chip_txt},
                               chip_one ? 5'd1 : 5'd2, 1'b0);
    wire chip_ring = (chip_off < 2) || (chip_off >= CHIP_W - 2) ||
                     (pix_y < CHIP_Y + 2) || (pix_y >= CHIP_Y + CHIP_H - 2);

    // ------------------------------------------------------------------
    // Text and shapes
    // ------------------------------------------------------------------
    // right-hand counter shifts right when there is no "/tt"
    wire [9:0] cnt_shift = has_total ? 10'd0 : 10'd42;

    wire mode_px  = text_px(pix_x, pix_y, 10'd48, 10'd18, mode_str, mode_len, 1'b1);
    wire moves_px = text_px(pix_x, pix_y, 10'd479 + cnt_shift, 10'd25, "MOVES", 5'd5, 1'b0);
    wire count_px = text_px(pix_x, pix_y, 10'd545 + cnt_shift, 10'd18, {184'd0, count_str}, 5'd2, 1'b1);
    wire total_px = has_total &&
                    text_px(pix_x, pix_y, 10'd586, 10'd25, {176'd0, "/", total_str}, 5'd3, 1'b0);
    wire square   = (pix_x >= 20) && (pix_x < 36) && (pix_y >= 20) && (pix_y < 36);

    // divider fills to count/total of the width
    wire bar_px = has_total && ({7'd0, pix_x} * total < count * 17'd640);

    wire [9:0] hint_x0 = (10'd642 - hint_len * 12) >> 1;
    wire hint_px  = text_px(pix_x, pix_y, hint_x0, HINT_Y, hint_str, hint_len, 1'b0);
    wire foot_px  = text_px(pix_x, pix_y, 10'd20, CHIP_TXT_Y, foot_str, foot_len, 1'b0);
    wire empty_px = text_px(pix_x, pix_y, CHIP_X, CHIP_TXT_Y, empty_str, empty_len, 1'b0);

    // ------------------------------------------------------------------
    // Pixel colour
    // ------------------------------------------------------------------
    always @* begin
        hud_on = 1'b0;
        hud_rgb = RGB_BLACK;
        if (pix_y < HEADER_H) begin
            hud_on = 1'b1;
            if (pix_y >= HEADER_H - 2)
                hud_rgb = bar_px ? mode_rgb : RGB_DIVIDER;
            else if (square || mode_px)
                hud_rgb = mode_rgb;
            else if (count_px)
                hud_rgb = RGB_WHITE;
            else if (moves_px || total_px)
                hud_rgb = RGB_LABEL;
        end else if (pix_y >= FOOTER_Y) begin
            hud_on = 1'b1;
            if (pix_y < FOOTER_Y + 2)
                hud_rgb = RGB_DIVIDER;
            else if (foot_px)
                hud_rgb = RGB_LABEL;
            else if (n_chips == 4'd0) begin
                if (empty_px)
                    hud_rgb = (stage == STAGE_ERROR) ? RGB_ERROR : RGB_LABEL;
            end else if (chip_hit) begin
                case (chip_state)
                    CHIP_CUR:  hud_rgb = chip_txt_px ? RGB_BLACK : mode_rgb;
                    CHIP_DONE: hud_rgb = chip_txt_px ? RGB_DONE_FG : RGB_DONE_BG;
                    default:   hud_rgb = chip_txt_px ? RGB_LABEL :
                                         (chip_ring ? RGB_NEXT_RG : RGB_BLACK);
                endcase
            end
        end else if (hint_px) begin
            hud_on = 1'b1;
            hud_rgb = RGB_LABEL;
        end
    end

endmodule
