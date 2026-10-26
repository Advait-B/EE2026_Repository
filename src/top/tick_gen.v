`timescale 1ns / 1ps

// tick_gen: 1-cycle enable pulses from 100 MHz, plus a real 6.25 MHz clock for the OLED. Owner: Su Yi

module tick_gen #(
    parameter SLOW_DIV = 25_000_000 // 4 Hz move playback
)(
    input wire clk, // 100 MHz
    input wire rst,
    input wire en_slow, // 0 = slow counter held at 0 (stopped)
    output wire tick_25m, // every 4 clks, VGA pixel enable
    output wire tick_1k, // every 1 ms, debounce / 7-seg / blink
    output wire tick_slow, // every SLOW_DIV clks, move playback
    output wire clk6p25m // real clock for Oled_Display
);
    `include "cube_defs.vh"
endmodule
