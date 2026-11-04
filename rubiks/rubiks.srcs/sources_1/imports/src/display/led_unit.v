`timescale 1ns / 1ps

module led_unit (
    input [2:0] stage,
    input blink_hz,
    input congratulate,
    input scr_busy,
    input sol_busy,
    input sw15,
    output [15:0] led
);

    assign led[0] = (stage == STAGE_START) ? 1 : 0;
    assign led[1] = (stage == STAGE_AUTO_SCRAMBLE) ? blink_hz : 0;
    assign led[2] = (stage == STAGE_MANUAL_SCRAMBLE) ? 1 : 0;
    assign led[3] = (stage == STAGE_SCRAMBLED) ? 1 : 0;
    assign led[4] = (stage == STAGE_SOLVING) ? blink_hz : 0;
    assign led[5] = (stage == STAGE_MANUAL_SOLVING) ? 1 : 0;
    assign led[6] = (stage == STAGE_SOLVED) ? 1 : 0;
    assign led[7] = (stage == STAGE_ERROR) ? blink_hz : 0; //error

    assign led[8] = congratulate ? blink_hz : 0;
    assign led[9] = congratulate ? blink_hz : 0;
    assign led[10] = congratulate ? blink_hz : 0;
    assign led[11] = congratulate ? blink_hz : 0;
    assign led[12] = congratulate ? blink_hz : 0;
    
    assign led[13] = scr_busy;
    assign led[14] = sol_busy;
    assign led[15] = sw15;

`include "cube_defs.vh"

endmodule
