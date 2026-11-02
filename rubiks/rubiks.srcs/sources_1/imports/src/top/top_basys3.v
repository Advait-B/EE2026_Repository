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
    // power-on reset: rst is high for the first 16 clocks after configuration
    reg [4:0] por_count = 5'd0;
    always @(posedge clk)
        if (!por_count[4]) por_count <= por_count + 5'd1;
    wire rst = !por_count[4];

    reg [2:0] stage = 3'd0; // TEST: driven by the board test FSM at the bottom
    wire [71:0] cube; // live cube from cube_engine
    wire [3:0] moves_left; // solve progress from solver

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

    // CHANGE CAMERA ANGLE BASED ON MOUSE_DX AND MOUSE_DY (right-drag)
    camera_unit camera_unit (
        .clk(clk), .rst(rst), .stage(stage),
        .btn_pressed(btn_pressed),
        .mouse_r(mouse_r), .mouse_dx(mouse_dx), .mouse_dy(mouse_dy),
        .mouse_event(mouse_event),
        .camera_angle_id(camera_angle_id)
    );

    // CUBE, SCRAMBLE AND SOLVE
    wire tick_4hz; // scramble/solve playback rate
    tick_gen tick_gen (
        .clk(clk), .rst(rst),
        .en_25mhz(1'b1), .en_1khz(1'b1), .en_4hz(1'b1),
        .tick_25mhz(), .tick_1khz(), .tick_4hz(), // TEST: tick_4hz made below
        .clk_6p25mhz()
    );

    wire [2:0] fsm_stage; // TODO: drive `stage` from this once game_fsm is done
    wire scramble_start, solve_start, solve_cancel, cube_reset;
    wire [4:0] manual_move;
    wire manual_valid;
    wire [4:0] scr_move;
    wire scr_valid, scr_busy, scr_done;
    wire [4:0] sol_move;
    wire sol_valid, sol_busy, sol_done, sol_err;
    wire [4:0] move_req;
    wire move_valid;
    wire [15:0] move_count;

    game_fsm game_fsm (
        .clk(clk), .rst(rst),
        .btn_pressed(btn_pressed), .sw_sync(sw),
        .scramble_done(scr_done), .solve_done(sol_done), .solve_err(sol_err),
        .stage(fsm_stage),
        // TEST: outputs disconnected, the board test FSM below drives them
        .scramble_start(), .solve_start(),
        .solve_cancel(), .cube_reset(),
        .manual_move(), .manual_valid()
    );

    scrambler scrambler (
        .clk(clk), .rst(rst),
        .start(scramble_start), .tick_4hz(tick_4hz),
        .scr_move(scr_move), .scr_valid(scr_valid),
        .busy(scr_busy), .done(scr_done)
    );

    solver solver (
        .clk(clk), .rst(rst),
        .start(solve_start), .cancel(solve_cancel),
        .tick_4hz(tick_4hz), .cube(cube),
        .sol_move(sol_move), .sol_valid(sol_valid),
        .busy(sol_busy), .done(sol_done), .err(sol_err),
        .moves_left(moves_left)
    );

    move_controller move_controller (
        .clk(clk), .rst(rst), .stage(stage),
        .manual_move(manual_move), .scr_move(scr_move), .sol_move(sol_move),
        .manual_valid(manual_valid), .scr_valid(scr_valid), .sol_valid(sol_valid),
        .move_req(move_req), .move_valid(move_valid)
    );

    cube_engine cube_engine (
        .clk(clk), .rst(rst), .cube_reset(cube_reset),
        .move_req(move_req), .move_valid(move_valid),
        .cube(cube), .move_count(move_count)
    );


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

/* BOARD TEST FSM (temporary, stands in for game_fsm) ------------------
   START          -- btnC, menu option 1 --> AUTO_SCRAMBLE
   START          -- btnC, menu option 2 --> MANUAL_SCRAMBLE
   AUTO_SCRAMBLE  -- scrambler done      --> SCRAMBLED
   MANUAL_SCRAMBLE-- btnC                --> SCRAMBLED
   SCRAMBLED      -- btnC                --> SOLVING
   SOLVING        -- solver done         --> SOLVED   (solver error --> ERROR)
   SOLVED / ERROR -- btnC                --> START
   In MANUAL_SCRAMBLE: pick a face with sw8-sw13 = U R F D L B (lowest
   switch wins), then btnR = clockwise, btnL = anticlockwise.
   btnU / btnD move the OLED menu (selectedoption) as before.
   led[6:0] stage, led[10] scrambler busy, led[11] solver busy,
   led[15:12] solve moves left
   ------------------------------------------------------------------ */

    // 4 Hz one-cycle tick (tick_gen is still empty)
    reg [24:0] t4_count = 25'd0;
    always @(posedge clk)
        t4_count <= (t4_count == 25'd24_999_999) ? 25'd0 : t4_count + 25'd1;
    assign tick_4hz = (t4_count == 25'd0);

    reg t_scramble_start = 1'b0, t_solve_start = 1'b0;
    assign scramble_start = t_scramble_start;
    assign solve_start = t_solve_start;
    assign solve_cancel = 1'b0;
    assign cube_reset = 1'b0;
    reg [4:0] t_manual_move = MV_NONE;
    reg t_manual_valid = 1'b0;
    assign manual_move = t_manual_move;
    assign manual_valid = t_manual_valid;

    // manual turns: face from sw8-sw13, move code = face*3 + turn
    wire [2:0] manual_face = sw[8]  ? FACE_U :
                             sw[9]  ? FACE_R :
                             sw[10] ? FACE_F :
                             sw[11] ? FACE_D :
                             sw[12] ? FACE_L :
                             sw[13] ? FACE_B : 3'd7; // 7 = no face picked
    wire [1:0] manual_turn = btn_pressed[BTN_R] ? TURN_CW : TURN_CCW;
    wire manual_btn = btn_pressed[BTN_R] | btn_pressed[BTN_L];
    wire btnc = btn_pressed[BTN_C];

    always @(posedge clk) begin
        // command pulses last one cycle
        t_scramble_start <= 1'b0;
        t_solve_start <= 1'b0;
        t_manual_valid <= 1'b0;

        if (rst) begin
            stage <= STAGE_START;
        end else begin
            case (stage)
                STAGE_START:
                    if (btnc && selectedoption == 3'd1 && !scr_busy) begin
                        t_scramble_start <= 1'b1;
                        stage <= STAGE_AUTO_SCRAMBLE;
                    end else if (btnc && selectedoption == 3'd2) begin
                        stage <= STAGE_MANUAL_SCRAMBLE;
                    end
                STAGE_AUTO_SCRAMBLE:
                    if (scr_done) stage <= STAGE_SCRAMBLED;
                STAGE_MANUAL_SCRAMBLE:
                    if (btnc) begin
                        stage <= STAGE_SCRAMBLED;
                    end else if (manual_btn && manual_face != 3'd7) begin
                        // move_controller only passes manual moves in this stage
                        t_manual_move <= {manual_face, 1'b0} + manual_face + manual_turn;
                        t_manual_valid <= 1'b1;
                    end
                STAGE_SCRAMBLED:
                    if (btnc) begin
                        t_solve_start <= 1'b1;
                        stage <= STAGE_SOLVING;
                    end
                STAGE_SOLVING:
                    if (sol_err) stage <= STAGE_ERROR;
                    else if (sol_done) stage <= STAGE_SOLVED;
                STAGE_SOLVED, STAGE_ERROR:
                    if (btnc) stage <= STAGE_START;
                default:
                    stage <= STAGE_START;
            endcase
        end
    end

    assign led[10] = scr_busy;
    assign led[11] = sol_busy;
    assign led[15:12] = moves_left;

endmodule
