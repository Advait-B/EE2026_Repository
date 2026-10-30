`timescale 1ns / 1ps

// pattern_rom.v
// Task 5.2: IDA* pattern tables in block RAM, data ready 1 cycle after the address.
// Tables come from Python/generate_tables.py (task 2.4).

module pattern_rom (
    input clk, // 100 MHz clock
    input [11:0] ori_addr, // orientation coordinate, 0-2186
    input [15:0] perm_addr, // permutation coordinate, 0-40319
    output reg [3:0] ori_dist, // moves to fix corner twists
    output reg [3:0] perm_dist // moves to fix corner positions
);
`include "cube_defs.vh"

    reg [3:0] ori_rom [0:2186];
    reg [3:0] perm_rom [0:40319];

    initial begin
        $readmemh("orientation.mem", ori_rom);
        $readmemh("permutation.mem", perm_rom);
    end

    always @(posedge clk) begin
        ori_dist <= ori_rom[ori_addr];
        perm_dist <= perm_rom[perm_addr];
    end

endmodule
