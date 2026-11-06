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
    // global reset: rst is high for 16 clocks after configuration, and again
    // whenever sw[15] is flicked (either direction)
    reg [4:0] por_count = 5'd0;
    reg [2:0] sw15_sync = 3'd0;
    always @(posedge clk) begin
        sw15_sync <= {sw15_sync[1:0], sw[15]};
        if (sw15_sync[2] != sw15_sync[1]) por_count <= 5'd0;    // dual edge
        else if (!por_count[4]) por_count <= por_count + 5'd1;
    end
    wire rst = !por_count[4];

    reg congratulate = 1'b0;
    reg [2:0] stage = 3'd0; // FSM state
    reg stagechanged = 1'b0; // pulses when FSM changes

    wire [71:0] cube; // live cube from cube_engine
    wire [3:0] moves_left; // solve progress from solver
    wire [54:0] plan_left; // queued solve moves from solver, for the VGA HUD
    wire [4:0] move_req; // move sent to cube_engine
    wire move_valid; // pulse when move_req is applied

    wire scramble_start, scramble_cancel, solve_start, solve_cancel, cube_reset;
    wire [4:0] manual_move;
    wire manual_valid;
    wire [4:0] scr_move;
    wire scr_valid, scr_busy, scr_done;
    wire [4:0] sol_move;
    wire sol_valid, sol_busy, sol_done, sol_err;
    wire [15:0] move_count;

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

    // tick_1hz: scrambler, solver
    wire tick_1hz;
    flex_tick_gen tick_1hz_unit(
        .clk(clk),
        .rst(rst),
        .enable(1),
        .m(32'd99_999_999), //32'd49,999,999
        .tick(tick_1hz)
    );

    // tick_4hz: stage indicator led blinking
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
        .clk(clk),
        .rst(rst),
        .debounce_clk(tick_50hz),
        .stage(stage),
        .stagechanged(stagechanged),
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

    reg blink_2hz = 1'b0;
    always @(posedge tick_4hz) blink_2hz <= ~blink_2hz; 
    led_unit led_unit(
        .stage(stage),
        .blink_hz(blink_2hz),
        .congratulate(congratulate),
        .scr_busy(scr_busy),
        .sol_busy(sol_busy),
        .sw15(sw[15]),
        .led(led)
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
        .hl_face((stage == STAGE_MANUAL_SCRAMBLE || stage == STAGE_MANUAL_SOLVING) ? selectedoption : 3'd0),
        .pixel_colour(pixel_colour),
        .pixel_on_cube(pixel_on_cube),
        .pixel_dim(pixel_dim),
        .row_done(row_done) // one-cycle pulse when a row buffer becomes valid
    );

    // CHANGE CAMERA ANGLE BASED ON MOUSE_DX AND MOUSE_DY (right-drag)
    camera_unit camera_unit (
        .clk(clk), .rst(rst), .stage(stage),
        .btn_pressed(btn_pressed),
        .mouse_btn(mouse_l), .mouse_dx(mouse_dx), .mouse_dy(mouse_dy),
        .mouse_event(mouse_event),
        .camera_angle_id(camera_angle_id)
    );

    // CUBE, SCRAMBLE AND SOLVE
    scrambler scrambler (
        .clk(clk), .rst(rst),
        .start(scramble_start), .cancel(scramble_cancel),
        .tick(tick_1hz),
        .scr_move(scr_move), .scr_valid(scr_valid),
        .busy(scr_busy), .done(scr_done)
    );

    solver solver (
        .clk(clk), .rst(rst),
        .start(solve_start), .cancel(solve_cancel),
        .tick(tick_1hz), .cube(cube),
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
        .clk(clk),
        // .clk(tick_4hz), //will miss 1 ticks
        .rst(rst), .cube_reset(cube_reset),
        .move_req(move_req), .move_valid(move_valid),
        .cube(cube), .move_count(move_count)
    );


/* LOGIC MODULES END */

/* MAIN FSM LOGIC -------------------------- */

    reg t_scramble_start = 1'b0, t_scramble_cancel = 1'b0;
    reg t_solve_start = 1'b0, t_solve_cancel = 1'b0;
    reg t_cube_reset = 1'b0;
    assign scramble_start = t_scramble_start;
    assign scramble_cancel = t_scramble_cancel;
    assign solve_start = t_solve_start;
    assign solve_cancel = t_solve_cancel; // = 1'b0;
    assign cube_reset = t_cube_reset; // = 1'b0;
    reg [4:0] t_manual_move = MV_NONE;
    reg t_manual_valid = 1'b0;
    assign manual_move = t_manual_move;
    assign manual_valid = t_manual_valid;

    reg manual_override = 1'b0;
    reg manual_canpress = 1'b1;

    always @(posedge clk) begin
        // command pulses last one cycle, so we need to reset all the pulses
        t_scramble_start <= 1'b0;
        t_scramble_cancel <= 1'b0;
        t_solve_start <= 1'b0;
        t_solve_cancel <= 1'b0;
        t_cube_reset <= 1'b0;
        t_manual_valid <= 1'b0;
        manual_override <= 1'b0;

        // pos edge
        if (manual_canpress && sw[0]) begin
            manual_override <= 1'b1; 
            manual_canpress <= 1'b0;
        end else if (!sw[0]) manual_canpress <= 1'b1;
        

    /* FSM START */
        stagechanged <= 0; // stagechanged is a one pulse signal
        if (rst) begin
            manual_canpress <= 1'b0;
            t_cube_reset <= 1'b1;
            t_solve_cancel <= sol_busy; //only need to cancel solver if solver is busy
            stage <= STAGE_START;
        end
        else begin
            if (manual_override && stage != STAGE_ERROR && stage != STAGE_MANUAL_SCRAMBLE) begin
                stage <= STAGE_MANUAL_SCRAMBLE;
                stagechanged <= 1;
                t_scramble_cancel <= scr_busy; //TEST THIS
                t_solve_cancel <= sol_busy; //TEST THIS
            end

            if (sol_err) begin
                stage <= STAGE_ERROR;
                stagechanged <= 1;
            end
            else begin
                case (stage) 
                    STAGE_START: begin
                        congratulate <= 0;
                        if (btn_pressed[BTN_C] && selectedoption == 3'd1 && !scr_busy) begin
                            t_scramble_start <= 1'b1;
                            stage <= STAGE_AUTO_SCRAMBLE;
                            stagechanged <= 1;
                        end
                        if (btn_pressed[BTN_C] && selectedoption == 3'd2) begin
                            stage <= STAGE_MANUAL_SCRAMBLE;
                            stagechanged <= 1;
                        end

                end
                STAGE_AUTO_SCRAMBLE: begin
                    if (btn_pressed[BTN_C]) begin
                        stage <= STAGE_SCRAMBLED;
                        stagechanged <= 1;
                        t_scramble_cancel <= scr_busy;
                    end
                    else if (scr_done) begin
                        stage <= STAGE_SCRAMBLED;
                        stagechanged <= 1;
                    end
                    
                end
                STAGE_MANUAL_SCRAMBLE: begin
                    if (btn_pressed[BTN_C]) begin
                        stage <= STAGE_SCRAMBLED;
                        stagechanged <= 1;
                    end
                    else begin
                        if (btn_pressed[BTN_R]) begin //clockwise
                            t_manual_valid <= 1'b1;
                            case (selectedoption)
                                3'd1: t_manual_move <= MV_F;
                                3'd2: t_manual_move <= MV_B;
                                3'd3: t_manual_move <= MV_L;
                                3'd4: t_manual_move <= MV_R;
                                3'd5: t_manual_move <= MV_U;
                                3'd6: t_manual_move <= MV_D;
                                default: begin
                                    t_manual_move <= MV_NONE;
                                    t_manual_valid <= 1'b0;
                                end
                            endcase
                        end
                        else if (btn_pressed[BTN_L]) begin //anticlockwise
                            t_manual_valid <= 1'b1;
                            case (selectedoption)
                                3'd1: t_manual_move <= MV_FP;
                                3'd2: t_manual_move <= MV_BP;
                                3'd3: t_manual_move <= MV_LP;
                                3'd4: t_manual_move <= MV_RP;
                                3'd5: t_manual_move <= MV_UP;
                                3'd6: t_manual_move <= MV_DP;
                                default: begin
                                    t_manual_move <= MV_NONE;
                                    t_manual_valid <= 1'b0;
                                end
                            endcase
                        end
                    end
                end
                STAGE_SCRAMBLED: begin
                    if (btn_pressed[BTN_C] && selectedoption == 3'd1) begin
                        t_solve_start <= 1'b1;
                        stage <= STAGE_SOLVING;
                        stagechanged <= 1;
                    end
                    else if (btn_pressed[BTN_C] && selectedoption == 3'd2) begin
                        stage <= STAGE_MANUAL_SOLVING;
                        stagechanged <= 1;
                    end
                end
                STAGE_SOLVING: begin
                    if (btn_pressed[BTN_C]) begin
                        stage <= STAGE_SCRAMBLED;
                        stagechanged <= 1;
                        t_solve_cancel <= sol_busy;
                    end
                    else if (sol_err) begin
                        stage <= STAGE_ERROR;
                        stagechanged <= 1;
                    end
                    else if (sol_done) begin
                        stage <= STAGE_SOLVED;
                        stagechanged <= 1;
                    end
                end
                STAGE_MANUAL_SOLVING: begin
                    if (is_solved(cube)) begin
                        stage <= STAGE_SOLVED;
                        stagechanged <= 1;
                    end
                    else if (btn_pressed[BTN_C]) begin
                        stage <= STAGE_SCRAMBLED;
                        stagechanged <= 1;
                    end
                    else begin
                        if (btn_pressed[BTN_R]) begin //clockwise
                            t_manual_valid <= 1'b1;
                            case (selectedoption)
                                3'd1: t_manual_move <= MV_F;
                                3'd2: t_manual_move <= MV_B;
                                3'd3: t_manual_move <= MV_L;
                                3'd4: t_manual_move <= MV_R;
                                3'd5: t_manual_move <= MV_U;
                                3'd6: t_manual_move <= MV_D;
                                default: begin
                                    t_manual_move <= MV_NONE;
                                    t_manual_valid <= 1'b0;
                                end
                            endcase
                        end
                        else if (btn_pressed[BTN_L]) begin //anticlockwise
                            t_manual_valid <= 1'b1;
                            case (selectedoption)
                                3'd1: t_manual_move <= MV_FP;
                                3'd2: t_manual_move <= MV_BP;
                                3'd3: t_manual_move <= MV_LP;
                                3'd4: t_manual_move <= MV_RP;
                                3'd5: t_manual_move <= MV_UP;
                                3'd6: t_manual_move <= MV_DP;
                                default: begin
                                    t_manual_move <= MV_NONE;
                                    t_manual_valid <= 1'b0;
                                end
                            endcase
                        end
                    end
                end
                STAGE_SOLVED: begin
                    congratulate <= 1;
                    if (btn_pressed[BTN_C]) begin
                        t_cube_reset <= 1'b1;
                        t_solve_cancel <= sol_busy;
                        stage <= STAGE_START;
                        stagechanged <= 1;
                    end
                end
                default: begin //STAGE_ERROR
                    stage <= STAGE_ERROR;
                    congratulate <= 0;
                    // FORCE USER TO RESET USING SW15
                    // if (btn_pressed[BTN_C]) begin
                    //     t_cube_reset <= 1'b1;
                    //     t_solve_cancel <= sol_busy;
                    //     stage <= STAGE_START;
                    //     stagechanged <= 1;
                    // end
                end

                endcase
            end
        end
    end

endmodule
