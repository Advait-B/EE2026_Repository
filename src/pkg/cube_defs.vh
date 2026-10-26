// =====================================================================
// cube_defs.vh: shared definitions for every module
// Usage: `include "cube_defs.vh" as the first line INSIDE each module
//        body (after the port list)
// No `ifndef guard on purpose: localparams/functions are module-scoped,
// so every module needs its own copy
// In Vivado: add as a design source (file type = Verilog Header)
// =====================================================================

    // -----------------------------------------------------------------
    // Widths
    // -----------------------------------------------------------------
    localparam CUBE_W     = 72;   // cube bus width, 24 stickers x 3 bits
    localparam COL_W      = 3;    // one sticker colour
    localparam MOVE_W     = 5;    // one move code
    localparam STAGE_W    = 3;    // game stage
    localparam TILE_W     = 5;    // sticker id 0..23
    localparam RGB_W      = 12;   // vga_rgb width, 4 bits per channel
    localparam OLED_W     = 16;   // oled pixel width, RGB 5:6:5
    localparam N_STICKERS = 24;
    localparam N_FACES    = 6;
    localparam N_MOVES    = 18;
    localparam N_CORNERS  = 8;

    // -----------------------------------------------------------------
    // Clock and tick dividers  (counts of 100 MHz cycles)
    // -----------------------------------------------------------------
    localparam CLK_HZ       = 100_000_000;
    localparam DIV_25MHZ    = CLK_HZ / 25_000_000;     // 4
    localparam DIV_1KHZ     = CLK_HZ / 1_000;          // 100_000
    localparam DIV_4HZ      = CLK_HZ / 4;              // 25_000_000
    localparam HALF_6P25MHZ = CLK_HZ / 6_250_000 / 2;  // 8: toggle clk6p25m every 8 cycles
    localparam DEBOUNCE_MS  = 200;                     // button lockout, in 1 kHz ticks

    // -----------------------------------------------------------------
    // Face numbers [2:0]
    // -----------------------------------------------------------------
    localparam [2:0] FACE_U = 3'd0;
    localparam [2:0] FACE_R = 3'd1;
    localparam [2:0] FACE_F = 3'd2;
    localparam [2:0] FACE_D = 3'd3;
    localparam [2:0] FACE_L = 3'd4;
    localparam [2:0] FACE_B = 3'd5;

    // -----------------------------------------------------------------
    // Colour codes [2:0]   (0 = blank / no colour)
    // Solved cube: face f has colour f+1 (U white, R red, F green,
    //              D yellow, L orange, B blue)
    // -----------------------------------------------------------------
    localparam [2:0] COL_BLANK  = 3'd0;
    localparam [2:0] COL_WHITE  = 3'd1;
    localparam [2:0] COL_RED    = 3'd2;
    localparam [2:0] COL_GREEN  = 3'd3;
    localparam [2:0] COL_YELLOW = 3'd4;
    localparam [2:0] COL_ORANGE = 3'd5;
    localparam [2:0] COL_BLUE   = 3'd6;
    localparam [2:0] COL_SPARE  = 3'd7;   // unused / highlight

    // -----------------------------------------------------------------
    // Sticker layout in cube[71:0]
    //   sticker id t = face*4 + idx, stored at cube[t*3 +: 3]
    //   idx on a face (looking straight at that face):
    //     0 = top-left, 1 = top-right, 2 = bottom-left, 3 = bottom-right
    // -----------------------------------------------------------------
    localparam [1:0] IDX_TL = 2'd0;
    localparam [1:0] IDX_TR = 2'd1;
    localparam [1:0] IDX_BL = 2'd2;
    localparam [1:0] IDX_BR = 2'd3;
    localparam [4:0] TILE_NONE = 5'd31;   // "no sticker" (empty slot / cursor off cube)

    localparam [CUBE_W-1:0] CUBE_SOLVED = {
        {4{COL_BLUE}},     // face 5: B
        {4{COL_ORANGE}},   // face 4: L
        {4{COL_YELLOW}},   // face 3: D
        {4{COL_GREEN}},    // face 2: F
        {4{COL_RED}},      // face 1: R
        {4{COL_WHITE}}     // face 0: U (LSBs)
    };

    // -----------------------------------------------------------------
    // Move codes [4:0]   code = face*3 + type
    //   type 0 = clockwise, 1 = counter-clockwise ('), 2 = half turn (2)
    // -----------------------------------------------------------------
    localparam [4:0] MV_U  = 5'd0,  MV_UP = 5'd1,  MV_U2 = 5'd2;
    localparam [4:0] MV_R  = 5'd3,  MV_RP = 5'd4,  MV_R2 = 5'd5;
    localparam [4:0] MV_F  = 5'd6,  MV_FP = 5'd7,  MV_F2 = 5'd8;
    localparam [4:0] MV_D  = 5'd9,  MV_DP = 5'd10, MV_D2 = 5'd11;
    localparam [4:0] MV_L  = 5'd12, MV_LP = 5'd13, MV_L2 = 5'd14;
    localparam [4:0] MV_B  = 5'd15, MV_BP = 5'd16, MV_B2 = 5'd17;
    localparam [4:0] MV_NONE = 5'd31;   // "no move"

    localparam [1:0] TURN_CW  = 2'd0;
    localparam [1:0] TURN_CCW = 2'd1;
    localparam [1:0] TURN_180 = 2'd2;

    // -----------------------------------------------------------------
    // Game stages [2:0]
    // -----------------------------------------------------------------
    localparam [2:0] ST_MENU       = 3'd0;
    localparam [2:0] ST_FREE       = 3'd1;
    localparam [2:0] ST_SCRAMBLING = 3'd2;
    localparam [2:0] ST_SOLVING    = 3'd3;
    localparam [2:0] ST_SOLVED     = 3'd4;
    localparam [2:0] ST_ERROR      = 3'd5;   // solver failed or timed out

    // -----------------------------------------------------------------
    // Error codes [2:0]
    // -----------------------------------------------------------------
    localparam [2:0] ERR_NONE         = 3'd0;
    localparam [2:0] ERR_COLOUR_COUNT = 3'd1;   // not exactly 4 of each colour
    localparam [2:0] ERR_BAD_CORNER   = 3'd2;   // impossible colour combo on a corner
    localparam [2:0] ERR_TWIST        = 3'd3;   // corner twist sum not divisible by 3
    localparam [2:0] ERR_TIMEOUT      = 3'd4;   // solver watchdog fired
    localparam [2:0] ERR_CANCELLED    = 3'd5;   // user cancelled the solve

    // -----------------------------------------------------------------
    // Button bit positions in btn[4:0] = {C, U, L, R, D}
    // -----------------------------------------------------------------
    localparam BTN_D = 0;
    localparam BTN_R = 1;
    localparam BTN_L = 2;
    localparam BTN_U = 3;
    localparam BTN_C = 4;

    // -----------------------------------------------------------------
    // Screen constants
    // -----------------------------------------------------------------
    localparam SCREEN_W = 640;
    localparam SCREEN_H = 480;
    localparam COORD_W  = 10;   // bits for an x or y pixel coordinate
    localparam OLED_SW  = 96;   // OLED width
    localparam OLED_SH  = 64;   // OLED height

    // -----------------------------------------------------------------
    // Views and view_rom
    //   entry = {tile_id[4:0], x0,y0, x1,y1, x2,y2, x3,y3}, front-to-back
    //   address = {view_idx, slot}
    // -----------------------------------------------------------------
    localparam VIEW_W    = 5;                        // 32 preset camera views
    localparam N_VIEWS   = 32;
    localparam SLOT_W    = 4;                        // slot index 0..11
    localparam N_SLOTS   = 12;                       // max visible stickers per view
    localparam ROM_W     = TILE_W + 8*COORD_W;       // 85 bits per entry
    localparam ROM_AW    = VIEW_W + SLOT_W;          // 9 address bits
    localparam ROM_DEPTH = 1 << ROM_AW;              // 512 entries

    // -----------------------------------------------------------------
    // Solver
    // -----------------------------------------------------------------
    localparam PERM_W   = 13;     // 7! = 5040 corner perms (DBL corner fixed)
    localparam ORI_W    = 10;     // 3^6 = 729 twist states
    localparam N_PERM   = 5040;
    localparam N_ORI    = 729;
    localparam LEN_W    = 4;      // solution length 0..15
    localparam MAX_LEN  = 11;     // optimal 2x2 solution <= 11 moves
    localparam DIST_W   = 4;      // pattern table entry width

    // -----------------------------------------------------------------
    // Helper functions
    // -----------------------------------------------------------------

    // colour of sticker (face, idx)
    function [2:0] get_tile;
        input [CUBE_W-1:0] c;
        input [2:0]        face;
        input [1:0]        idx;
        begin
            get_tile = c[(face*4 + idx)*3 +: 3];
        end
    endfunction

    // colour of sticker id t (0..23)
    function [2:0] get_tile_id;
        input [CUBE_W-1:0] c;
        input [TILE_W-1:0] t;
        begin
            get_tile_id = c[t*3 +: 3];
        end
    endfunction

    // cube with sticker id t set to colour col
    function [CUBE_W-1:0] set_tile_id;
        input [CUBE_W-1:0] c;
        input [TILE_W-1:0] t;
        input [2:0]        col;
        begin
            set_tile_id           = c;
            set_tile_id[t*3 +: 3] = col;
        end
    endfunction

    // face a move turns (FACE_*)
    function [2:0] move_face;
        input [MOVE_W-1:0] m;
        begin
            move_face = m / 3;
        end
    endfunction

    // turn type of a move (TURN_*)
    function [1:0] move_type;
        input [MOVE_W-1:0] m;
        begin
            move_type = m % 3;
        end
    endfunction

    // colour code -> VGA 4:4:4
    function [RGB_W-1:0] colour_rgb12;
        input [2:0] col;
        begin
            case (col)
                COL_WHITE:  colour_rgb12 = 12'hFFF;
                COL_RED:    colour_rgb12 = 12'hF00;
                COL_GREEN:  colour_rgb12 = 12'h0F0;
                COL_YELLOW: colour_rgb12 = 12'hFF0;
                COL_ORANGE: colour_rgb12 = 12'hF80;
                COL_BLUE:   colour_rgb12 = 12'h00F;
                default:    colour_rgb12 = 12'h444;   // blank / spare: grey
            endcase
        end
    endfunction

    // colour code -> OLED 5:6:5
    function [OLED_W-1:0] colour_rgb565;
        input [2:0] col;
        begin
            case (col)
                COL_WHITE:  colour_rgb565 = 16'hFFFF;
                COL_RED:    colour_rgb565 = 16'hF800;
                COL_GREEN:  colour_rgb565 = 16'h07E0;
                COL_YELLOW: colour_rgb565 = 16'hFFE0;
                COL_ORANGE: colour_rgb565 = 16'hFC00;
                COL_BLUE:   colour_rgb565 = 16'h001F;
                default:    colour_rgb565 = 16'h4208;   // blank / spare: grey
            endcase
        end
    endfunction
