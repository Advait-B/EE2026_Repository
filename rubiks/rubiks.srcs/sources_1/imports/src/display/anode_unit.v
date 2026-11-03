`timescale 1ns / 1ps

// anode_unit.v
// Multiplexes the 4-digit 7-segment display.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module anode_unit (
    input clk, // 100 MHz clock
    input rst, // reset
    input digitcycle_clk, // digit multiplex tick (1khz?)
    input [3:0] debugpage,

    input [9:0] mouse_x, //0 to 1023
    input [9:0] mouse_y, //0 to 1023
    input signed [10:0] mouse_dx, //-256 to +255
    input signed [10:0] mouse_dy, //-256 to +255
    input [7:0] camera_angle_id,
    input [3:0] moves_left,         // solve moves remaining

    // input [2:0] stage, // current game stage
    // input [15:0] move_count, // moves applied

    output reg [6:0] seg, // segments
    output reg dp, // decimal point
    output reg [3:0] an // anodes
);
`include "cube_defs.vh"

    reg [1:0] activedisplay; //0 refers to rightmost anode,
    initial begin
        activedisplay <= 2'd0;
    end
    always @(posedge digitcycle_clk) begin
        case (activedisplay)
        2'd0: an <= 4'b1101;
        2'd1: an <= 4'b1011;
        2'd2: an <= 4'b0111;
        2'd3: an <= 4'b1110;
        endcase
        activedisplay <= activedisplay + 1;
    end

    function [6:0] bcd_to_sevenseg;
        input [3:0] bcd_value;
        begin
            case (bcd_value)
            4'd0: bcd_to_sevenseg = 7'b1000000; //G
            4'd1: bcd_to_sevenseg = 7'b1111001; //cb
            4'd2: bcd_to_sevenseg = 7'b0100100; //FC
            4'd3: bcd_to_sevenseg = 7'b0110000; //FE
            4'd4: bcd_to_sevenseg = 7'b0011001; //gfcb
            4'd5: bcd_to_sevenseg = 7'b0010010; //EB
            4'd6: bcd_to_sevenseg = 7'b0000010; //B
            4'd7: bcd_to_sevenseg = 7'b1111000; //cba
            4'd8: bcd_to_sevenseg = 7'b0000000; //all on
            4'd9: bcd_to_sevenseg = 7'b0011000; //DE
            default: bcd_to_sevenseg = 7'b0001001; //gefcb "X"
            endcase
        end
    endfunction

    //NEGATIVE TRANSFORMATION

/*
- basically every digit multiplex tick, cycle activedisplay
- leftmost digit can be minus sign
*/
    wire [9:0] binarytoconvert;
    wire [3:0] thousands;
    wire [3:0] hundreds;
    wire [3:0] tens;
    wire [3:0] ones;
//    initial begin
//        binarytoconvert <= 10'b0;
//    end

    assign binarytoconvert = 
        debugpage==4'd1 ? mouse_x :
        debugpage==4'd2 ? mouse_y :
        debugpage==4'd3 ? mouse_dx[10] ? (~(mouse_dx[9:0])+1) : mouse_dx[9:0] :
        debugpage==4'd4 ? mouse_dy[10] ? (~(mouse_dy[9:0])+1) : mouse_dy[9:0] :
        debugpage==4'd5 ? {2'b0, camera_angle_id} :
        debugpage==4'd6 ? {6'b0, moves_left} :
        // debugpage==4'd4 ? <YOUR VARIABLE> : // TODO
        10'b0; // debugpage==4'd0

    double_dabble_unit double_dabble_unit (binarytoconvert, thousands, hundreds, tens, ones);

    always @(posedge clk) begin
        case (debugpage)

        4'd0: begin
            seg <= 7'b1111111; //turn that shit off!!!!
            dp <= 1'b1;
        end //for DBPAGE_OFF

        4'd1: begin //MOUSE X POS
            case (activedisplay)
            2'd0: seg <= bcd_to_sevenseg(ones);
            2'd1: seg <= bcd_to_sevenseg(tens); 
            2'd2: seg <= bcd_to_sevenseg(hundreds);        
            2'd3: seg <= bcd_to_sevenseg(thousands);
            endcase
        end //for DBPAGE_MOUSE_X

        4'd2: begin //MOUSE Y POS
            case (activedisplay)
            2'd0: seg <= bcd_to_sevenseg(ones);
            2'd1: seg <= bcd_to_sevenseg(tens); 
            2'd2: seg <= bcd_to_sevenseg(hundreds);        
            2'd3: seg <= bcd_to_sevenseg(thousands);
            endcase
        end

        4'd3: begin //MOUSE DELTA X
            
            case (activedisplay)
            2'd0: seg <= bcd_to_sevenseg(ones);
            2'd1: seg <= bcd_to_sevenseg(tens); 
            2'd2: seg <= bcd_to_sevenseg(hundreds);  
            2'd3: seg <= mouse_dx[10] ? 7'b0111111 : 7'b1111111;
            //last anode is minus sign if negative (MSB is 1)
            endcase

        end

        4'd4: begin //MOUSE DELTA Y

            case (activedisplay)
            2'd0: seg <= bcd_to_sevenseg(ones);
            2'd1: seg <= bcd_to_sevenseg(tens); 
            2'd2: seg <= bcd_to_sevenseg(hundreds);  
            2'd3: seg <= mouse_dy[10] ? 7'b0111111 : 7'b1111111;
            //last anode is minus sign if negative (MSB is 1)
            endcase

        end

        4'd5: begin //CAMERA ANGLE ID
            case (activedisplay)
            2'd0: seg <= bcd_to_sevenseg(ones);
            2'd1: seg <= bcd_to_sevenseg(tens); 
            2'd2: seg <= bcd_to_sevenseg(hundreds);        
            2'd3: seg <= bcd_to_sevenseg(thousands);
            endcase 
        end

        4'd6: begin //MOVES LEFT
            case (activedisplay)
            2'd0: seg <= bcd_to_sevenseg(ones);
            2'd1: seg <= bcd_to_sevenseg(tens); 
            2'd2: seg <= bcd_to_sevenseg(hundreds);        
            2'd3: seg <= bcd_to_sevenseg(thousands);
            endcase 
        end

        // TODO: ADD MORE CASES FOR THE REST OF THE DEBUG PAGES
        // 4'd5: begin
        //     case (activedisplay)

        //     endcase 
        // end

        endcase
    end


endmodule
