`timescale 1ns / 1ps

// Finds one sticker's horizontal span at row_y and advances its edge positions.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module calc_sticker_span (
    input clk,
    input rst,
    input start,                    // Start calculating one sticker

    input [9:0] row_y,              // Screen row to check
    input [79:0] corners,           // {x3,y3,...,x0,y0}, 10 bits per coordinate
    input [107:0] slopes,           // Four signed Q16 x-per-row slopes
    input [107:0] edge_state_in,    // Four signed Q16 x positions for this row

    output reg [107:0] edge_state_out, // Updated positions for the next row
    output reg [9:0] span_left,     // 640 means no valid span
    output reg [9:0] span_right,
    output reg span_valid,          // 1 if this sticker crosses the row

    output reg busy,
    output reg done                 // One-cycle pulse when results are ready
);
`include "cube_defs.vh"

    localparam [1:0] STATE_IDLE = 2'd0;
    localparam [1:0] STATE_SCAN = 2'd1;
    localparam [1:0] STATE_FINISH = 2'd2;

    reg [1:0] state;
    reg [1:0] edge_index;
    reg [2:0] intersection_count;
    reg [9:0] measured_left_x, measured_right_x;

    reg [9:0] edge_x0, edge_y0, edge_x1, edge_y1;
    reg [9:0] edge_low_x, edge_low_y, edge_high_y;
    reg edge_hits_row;
    reg signed [26:0] edge_slope_q16;
    reg signed [26:0] saved_edge_x_q16;
    reg signed [26:0] edge_x_at_row_q16;
    reg signed [26:0] edge_x_next_row_q16;
    reg signed [26:0] edge_floor_q16, edge_ceil_q16;
    reg [9:0] edge_left_pixel_x, edge_right_pixel_x;

    // Select endpoints, slope, and saved x position for the current edge.
    // Edge rows use a half-open vertical range: low endpoint included,
    // high endpoint excluded, so a shared corner is counted only once.
    always @* begin
        case (edge_index)
            2'd0: begin
                edge_x0 = corners[19:10]; edge_y0 = corners[9:0];
                edge_x1 = corners[39:30]; edge_y1 = corners[29:20];
                edge_slope_q16 = $signed(slopes[26:0]);
                saved_edge_x_q16 = $signed(edge_state_in[26:0]);
            end
            2'd1: begin
                edge_x0 = corners[39:30]; edge_y0 = corners[29:20];
                edge_x1 = corners[59:50]; edge_y1 = corners[49:40];
                edge_slope_q16 = $signed(slopes[53:27]);
                saved_edge_x_q16 = $signed(edge_state_in[53:27]);
            end
            2'd2: begin
                edge_x0 = corners[59:50]; edge_y0 = corners[49:40];
                edge_x1 = corners[79:70]; edge_y1 = corners[69:60];
                edge_slope_q16 = $signed(slopes[80:54]);
                saved_edge_x_q16 = $signed(edge_state_in[80:54]);
            end
            default: begin
                edge_x0 = corners[79:70]; edge_y0 = corners[69:60];
                edge_x1 = corners[19:10]; edge_y1 = corners[9:0];
                edge_slope_q16 = $signed(slopes[107:81]);
                saved_edge_x_q16 = $signed(edge_state_in[107:81]);
            end
        endcase

        if (edge_y0 <= edge_y1) begin
            edge_low_x = edge_x0;
            edge_low_y = edge_y0;
            edge_high_y = edge_y1;
        end else begin
            edge_low_x = edge_x1;
            edge_low_y = edge_y1;
            edge_high_y = edge_y0;
        end

        edge_hits_row = (edge_low_y < edge_high_y) &&
            (edge_low_y <= row_y) && (row_y < edge_high_y);

        if (row_y == edge_low_y)
            edge_x_at_row_q16 = $signed({1'b0, edge_low_x, 16'b0});
        else
            edge_x_at_row_q16 = saved_edge_x_q16;

        edge_x_next_row_q16 = edge_x_at_row_q16 + edge_slope_q16;
        edge_floor_q16 = edge_x_at_row_q16 >>> 16;
        edge_ceil_q16 = edge_floor_q16;
        if (|edge_x_at_row_q16[15:0])
            edge_ceil_q16 = edge_floor_q16 + 27'sd1;

        // Clip rounded crossings to the visible screen. Generated geometry
        // is already on-screen; clipping also protects this block on bad data.
        if (edge_ceil_q16 < 0)
            edge_left_pixel_x = 10'd0;
        else if (edge_ceil_q16 > SCREEN_W - 1)
            edge_left_pixel_x = SCREEN_W;
        else
            edge_left_pixel_x = edge_ceil_q16[9:0];

        if (edge_floor_q16 < 0)
            edge_right_pixel_x = 10'd0;
        else if (edge_floor_q16 > SCREEN_W - 1)
            edge_right_pixel_x = SCREEN_W - 1;
        else
            edge_right_pixel_x = edge_floor_q16[9:0];
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= STATE_IDLE;
            edge_index <= 2'd0;
            intersection_count <= 3'd0;
            measured_left_x <= SCREEN_W;
            measured_right_x <= 10'd0;
            edge_state_out <= 108'd0;
            span_left <= SCREEN_W;
            span_right <= 10'd0;
            span_valid <= 1'b0;
            busy <= 1'b0;
            done <= 1'b0;
        end else begin
            done <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        state <= STATE_SCAN;
                        edge_index <= 2'd0;
                        intersection_count <= 3'd0;
                        measured_left_x <= SCREEN_W;
                        measured_right_x <= 10'd0;
                        edge_state_out <= edge_state_in;
                        span_left <= SCREEN_W;
                        span_right <= 10'd0;
                        span_valid <= 1'b0;
                        busy <= 1'b1;
                    end
                end

                STATE_SCAN: begin
                    busy <= 1'b1;
                    if (edge_hits_row) begin
                        if (edge_left_pixel_x < measured_left_x)
                            measured_left_x <= edge_left_pixel_x;
                        if (edge_right_pixel_x > measured_right_x)
                            measured_right_x <= edge_right_pixel_x;
                        intersection_count <= intersection_count + 3'd1;

                        case (edge_index)
                            2'd0: edge_state_out[26:0] <= edge_x_next_row_q16;
                            2'd1: edge_state_out[53:27] <= edge_x_next_row_q16;
                            2'd2: edge_state_out[80:54] <= edge_x_next_row_q16;
                            default: edge_state_out[107:81] <= edge_x_next_row_q16;
                        endcase
                    end

                    if (edge_index == 2'd3)
                        state <= STATE_FINISH;
                    else
                        edge_index <= edge_index + 2'd1;
                end

                STATE_FINISH: begin
                    if ((intersection_count >= 3'd2) &&
                        (measured_left_x <= measured_right_x)) begin
                        span_left <= measured_left_x;
                        span_right <= measured_right_x;
                        span_valid <= 1'b1;
                    end else begin
                        span_left <= SCREEN_W;
                        span_right <= 10'd0;
                        span_valid <= 1'b0;
                    end
                    busy <= 1'b0;
                    done <= 1'b1;
                    state <= STATE_IDLE;
                end

                default: begin
                    state <= STATE_IDLE;
                    busy <= 1'b0;
                end
            endcase
        end
    end

endmodule