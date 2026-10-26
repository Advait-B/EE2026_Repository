`timescale 1ns / 1ps
/*
slow_clk_freq = 100MHz / [2(m+1)]		MAX m is 4,294,967,295
m = [(100MHz/slow_clk_freq) / 2] - 1
*/
module flexclock(
    input clock,
    input reset,
    input [31:0] m,
    output reg slow_clock
);
    initial slow_clock = 1'b0;
    reg [31:0] count = 0;
    always @ (posedge clock) begin
        if (reset) begin
            count <= 0;
            slow_clock <= 0;
        end
        else begin
            count <= (count >= m) ? 0 : count + 1;
            slow_clock <= (count == 0) ? ~slow_clock : slow_clock;
        end
    end
endmodule
