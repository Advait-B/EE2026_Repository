`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.11.2026 12:39:26
// Design Name: 
// Module Name: double_dabble_unit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

//converts bin into bcd for 7segs
module double_dabble_unit (
    input  wire [9:0] binary,
    output reg  [3:0] thousands,
    output reg  [3:0] hundreds,
    output reg  [3:0] tens,
    output reg  [3:0] ones
);

    reg [15:0] bcd;
    integer i;

    always @(*) begin
        bcd = 16'd0;

        for (i = 9; i >= 0; i = i - 1) begin

            //for each of the 4 places inspect every 4 bits from the right (LSB)
            //if its >=5, add 3 to the place

            if (bcd[3:0] >= 5)                  //ONES
                bcd[3:0] = bcd[3:0] + 4'd3;

            if (bcd[7:4] >= 5)                  //TENS
                bcd[7:4] = bcd[7:4] + 4'd3;

            if (bcd[11:8] >= 5)                 //HUNDREDS
                bcd[11:8] = bcd[11:8] + 4'd3;

            if (bcd[15:12] >= 5)                //THOUSANDS
                bcd[15:12] = bcd[15:12] + 4'd3;

            bcd = {bcd[14:0], binary[i]};       //SHIFT BINARY INTO THE LSB
        end

        thousands = bcd[15:12];
        hundreds = bcd[11:8];
        tens = bcd[7:4];
        ones = bcd[3:0];
    end

endmodule
