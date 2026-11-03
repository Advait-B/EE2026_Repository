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
    wire [54:0] plan_left; // queued solve moves from solver, for the VGA HUD
    wire [4:0] move_req; // move sent to cube_engine
    wire move_valid; // pulse when move_req is applied

    // oled menu & anode debugging
    wire [2:0] selectedoption;
    wire [3:0] debugpage;

    //VGA STUFF
    wire [9:0] pix_x;
    wire [9:0] pix_y;
    wire [2:0] pixel_colour;
    wire pixel_on_cube;
    wire pixel_dim; // cube pixel outside the selected manual-mode layer
    wire frame_start;
    wire [7:0] camera_angle_id; //rn we have 256 camera angles
    wire row_done; // one-cycle pulse when a row buffer becomes valid


/* CLOCKS / TICK GENERATORS */

    wire clk_6p25MHz;
    flexclock clk_6p25MHz_unit (
        .clock(clk),
        .reset(0),
        .m(32'd7),
        .slow_clock(clk_6p25MHz)
    );

    // 4 Hz one-cycle tick (tick_gen is still empty)
    // reg [24:0] t4_count = 25'd0;
    // always @(posedge clk)
    //     t4_count <= (t4_count == 25'd24_999_999) ? 25'd0 : t4_count + 25'd1;
    // assign tick_4hz = (t4_count == 25'd0);

    // tick_4hz: autoscrambler, solver, led blinking
    wire tick_4hz;
    flex_tick_gen tick_4hz_unit(
        .clk(clk),
        .rst(rst),
        .enable(1),
        .m(32'd24_999_999),
        .tick(tick_4hz)
    );
    // tick_50hz: btn debouncing
    wire tick_50hz;
    flex_tick_gen tick_50hz_unit(
        .clk(clk),
        .rst(rst),
        .enable(1),
        .m(32'd1_999_999),
        .tick(tick_50hz)
    );
    // tick_1khz: anode digit cycling
    wire tick_1khz;
    flex_tick_gen tick_1khz_unit(
        .clk(clk),
        .rst(rst),
        .enable(1),
        .m(32'd99_999),
        .tick(tick_1khz)
    );
    // tick_25mhz: vga_unit, cube_render
    wire tick_25mhz;
    flex_tick_gen tick_25mhz_unit(
        .clk(clk),
        .rst(rst),
        .enable(1),
        .m(32'd3),
        .tick(tick_25mhz)
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
        .debounce_clk(tick_50hz),
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
        .oled_pmod(JC)
    );

    //- ANODE
    anode_unit anode_unit (
        .clk(clk),
        .rst(rst),
        .digitcycle_clk(tick_1khz),
        .debugpage(debugpage),
        
        .mouse_x(mouse_x),
        .mouse_y(mouse_y),
        .mouse_dx(mouse_dx),
        .mouse_dy(mouse_dy),
        .camera_angle_id(camera_angle_id),
        .moves_left(moves_left),

        .seg(seg),
        .dp(dp),
        .an(an)
    );

    //- VGA
    vga_unit vga_unit (
        .clk(clk),
        .rst(rst),
        .tick_25mhz(tick_25mhz), // per-pixel update rate

        .stage(stage),
        .pixel_colour(pixel_colour),
        .pixel_on_cube(pixel_on_cube),
        .pixel_dim(pixel_dim),
        .mouse_x(mouse_x), .mouse_y(mouse_y),
        .move_req(move_req), .move_valid(move_valid),
        .moves_left(moves_left), .plan_left(plan_left),
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
        .tick_25mhz(tick_25mhz),
        .frame_start(frame_start),
        .camera_angle_id(camera_angle_id),
        .pix_x(pix_x), .pix_y(pix_y),
        .cube(cube),
        // in manual mode, highlight the layer the selected face turns
        .hl_face((stage == STAGE_MANUAL_SCRAMBLE) ? selectedoption : 3'd0),
        .pixel_colour(pixel_colour),
        .pixel_on_cube(pixel_on_cube),
        .pixel_dim(pixel_dim),
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

    wire [2:0] fsm_stage; // TODO: drive `stage` from this once game_fsm is done
    wire scramble_start, solve_start, solve_cancel, cube_reset;
    wire [4:0] manual_move;
    wire manual_valid;
    wire [4:0] scr_move;
    wire scr_valid, scr_busy, scr_done;
    wire [4:0] sol_move;
    wire sol_valid, sol_busy, sol_done, sol_err;
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
        .moves_left(moves_left), .plan_left(plan_left)
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

    reg blink_2hz = 1'b0;
    always @(posedge tick_4hz) blink_2hz <= ~blink_2hz; 
    
    assign led[0] = (stage == 3'd0) ? 1 : 0;
    assign led[1] = (stage == 3'd1) ? blink_2hz : 0;
    assign led[2] = (stage == 3'd2) ? 1 : 0;
    assign led[3] = (stage == 3'd3) ? 1 : 0;
    assign led[4] = (stage == 3'd4) ? blink_2hz : 0;
    assign led[5] = (stage == 3'd5) ? 1 : 0;
    assign led[6] = (stage == 3'd6) ? blink_2hz : 0; //error

    

    reg t_scramble_start = 1'b0, t_solve_start = 1'b0;
    reg t_solve_cancel = 1'b0, t_cube_reset = 1'b0;
    assign scramble_start = t_scramble_start;
    assign solve_start = t_solve_start;
    assign solve_cancel = t_solve_cancel; // = 1'b0;
    assign cube_reset = t_cube_reset; // = 1'b0;
    reg [4:0] t_manual_move = MV_NONE;
    reg t_manual_valid = 1'b0;
    assign manual_move = t_manual_move;
    assign manual_valid = t_manual_valid;

    wire manual_override = sw[0];

    always @(posedge clk) begin
        // command pulses last one cycle, so we need to reset all the pulses
        t_scramble_start <= 1'b0;
        t_solve_start <= 1'b0;
        t_solve_cancel <= 1'b0;
        t_cube_reset <= 1'b0;
        t_manual_valid <= 1'b0;

    /* FSM START */
        if (rst) begin
            t_cube_reset <= 1'b1;
            t_solve_cancel <= sol_busy;
            stage <= STAGE_START;
        end
        else if (manual_override && stage != STAGE_ERROR) begin
            stage <= STAGE_MANUAL_SCRAMBLE;
            //TODO MAKE THIS ONEPULSE
                
        end

        if (sol_err) begin
            stage <= STAGE_ERROR;
        end
        else begin
            case (stage) 
                STAGE_START: begin
                    if (btn_pressed[BTN_C] && selectedoption == 3'd1 && !scr_busy) begin
                        t_scramble_start <= 1'b1;
                        stage <= STAGE_AUTO_SCRAMBLE;
                    end
                    if (btn_pressed[BTN_C] && selectedoption == 3'd2) begin
                        stage <= STAGE_MANUAL_SCRAMBLE;
                    end

                end
                STAGE_AUTO_SCRAMBLE: begin
                    if (scr_done) stage <= STAGE_SCRAMBLED;
                end
                STAGE_MANUAL_SCRAMBLE: begin
                    if (btn_pressed[BTN_C]) stage <= STAGE_SCRAMBLED;
                    else begin
                        if (btn_pressed [BTN_R]) begin //clockwise
                            
                            t_manual_valid <= 1'b1;
                            case (selectedoption)
                                3'd1: //FRONT
                                    t_manual_move <= MV_F;
                                3'd2: //BACK
                                    t_manual_move <= MV_B;
                                3'd3: //LEFT
                                    t_manual_move <= MV_L;
                                3'd4: //RIGHT
                                    t_manual_move <= MV_R;
                                3'd5: //UP
                                    t_manual_move <= MV_U;
                                3'd6: //DOWN
                                    t_manual_move <= MV_D;
                                default: begin
                                    t_manual_move <= MV_NONE;
                                    t_manual_valid <= 1'b0;
                                end
                            endcase

                        end
                        else if (btn_pressed[BTN_L]) begin //anticlockwise

                            t_manual_valid <= 1'b1;
                            case (selectedoption)
                                3'd1: //FRONT
                                    t_manual_move <= MV_FP;
                                3'd2: //BACK
                                    t_manual_move <= MV_BP;
                                3'd3: //LEFT
                                    t_manual_move <= MV_LP;
                                3'd4: //RIGHT
                                    t_manual_move <= MV_RP;
                                3'd5: //UP
                                    t_manual_move <= MV_UP;
                                3'd6: //DOWN
                                    t_manual_move <= MV_DP;
                                default: begin
                                    t_manual_move <= MV_NONE;
                                    t_manual_valid <= 1'b0;
                                end
                            endcase
                            
                        end
                        
                    end
                end
                STAGE_SCRAMBLED: begin
                    if (btn_pressed[BTN_C]) begin
                        t_solve_start <= 1'b1;
                        stage <= STAGE_SOLVING;
                    end
                end
                STAGE_SOLVING: begin
                    if (sol_err) stage <= STAGE_ERROR;
                    else if (sol_done) stage <= STAGE_SOLVED;
                end
                STAGE_SOLVED: begin
                    if (btn_pressed[BTN_C]) begin
                        t_cube_reset <= 1'b1;
                        t_solve_cancel <= sol_busy;
                        stage <= STAGE_START;
                    end
                end
                default: begin //STAGE_ERROR
                    stage <= STAGE_ERROR;
                    if (btn_pressed[BTN_C]) begin
                        t_cube_reset <= 1'b1;
                        t_solve_cancel <= sol_busy;
                        stage <= STAGE_START;
                        //TODO MORE RESET LOGIC?
                    end
                end

            endcase
        end
    end

    assign led[10] = scr_busy;
    assign led[11] = sol_busy;
    assign led[15:12] = moves_left; // move this to anode?

endmodule
