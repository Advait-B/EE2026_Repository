`timescale 1ns / 1ps

module debouncer(
    input clk,
    input  wire clk_db,        // sample tick, used as a clock enable
//    input  wire reset,          // synchronous, active high
    input  wire btn_in,
    output reg  button_clean,    // 1 = pressed, 0 = released
    output reg button_pressed
);

    reg previous_sample=0;
    reg button_was_pressed=0;

    always @(posedge clk) if (clk_db) begin
//        if (reset) begin
//            previous_sample <= 1'b0;
//            button_clean    <= 1'b0;
//            button_pressed <= 0;
//            button_was_pressed <= 0;
//        end else
        begin
            if (btn_in == previous_sample)
                button_clean <= btn_in;
            previous_sample <= btn_in;
                
        end
    end
    
    always @(posedge clk) begin
    
            if (button_clean) begin
                if (button_was_pressed) button_pressed <= 0;
                else begin
                    button_pressed <= 1;
                    button_was_pressed <= 1;
                end
            end
            else begin //button released
                button_pressed <= 0;
                button_was_pressed <= 0;
            end
    
    end

endmodule
