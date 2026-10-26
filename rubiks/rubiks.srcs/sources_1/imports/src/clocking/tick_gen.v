`timescale 1ns / 1ps

// tick_gen.v
// Divides the 100 MHz clock into 1-cycle enable ticks (25 MHz, 1 kHz, 4 Hz) and the 6.25 MHz OLED clock.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module tick_gen (
    input clk, // 100 MHz clock
    input rst, // reset
    input en_25mhz, en_1khz, en_4hz, // enable each tick
    output tick_25mhz, // 1-cycle pulse every 4 clks (VGA pixel)
    output tick_1khz, // 1-cycle pulse every 100,000 clks (7-seg multiplex)
    output tick_4hz, // 1-cycle pulse every 25,000,000 clks (scramble/solve playback, LED blink)
    output clk_6p25mhz // real 6.25 MHz clock, only for the provided OLED driver
);
`include "cube_defs.vh"

endmodule
