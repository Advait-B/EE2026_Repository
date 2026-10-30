`timescale 1ns / 1ps

// Converts twelve depth-ordered sticker spans into color-change segments.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module cube_row_segments (
    input clk,
    input rst,
    input start,
    input [71:0] cube,
    input [59:0] sticker_ids,   // slot i: [i*5 +: 5], actual sticker IDs
    input [119:0] span_lefts,   // slot i: [i*10 +: 10]
    input [119:0] span_rights,  // slot i: [i*10 +: 10]
    input [11:0] span_valid,

    output reg busy,
    output reg done,
    output reg seg_valid,       // one-cycle pulse for a new segment
    output reg [4:0] seg_index,
    output reg [9:0] seg_x_start,
    output reg [3:0] seg_value, // {on_cube, colour[2:0]}
    output reg [4:0] seg_count
);
`include "cube_defs.vh"

    localparam VISIBLE_SLOT_COUNT = 12;

    localparam [1:0] STATE_IDLE = 2'd0;
    localparam [1:0] STATE_SCAN = 2'd1;
    localparam [1:0] STATE_EVALUATE = 2'd2;
    localparam [1:0] STATE_FINISH = 2'd3;

    localparam [10:0] SCREEN_END_X = 11'd640;

    reg [1:0] state;
    reg [3:0] slot_index;
    reg [10:0] segment_start_x;
    reg [10:0] best_boundary_x;
    reg selected_sticker_found;
    reg [2:0] selected_colour;
    reg have_previous_value;
    reg [3:0] previous_value;

    reg [4:0] slot_sticker_id;
    reg [9:0] slot_span_left, slot_span_right;
    reg slot_span_is_valid;
    reg [10:0] slot_span_end_x;
    reg slot_hit;
    reg [2:0] slot_colour;
    reg [10:0] slot_next_boundary_x;

    // Inspect one slot per clock. Slot order is front-to-back, so the first
    // hit supplies the color for the current interval.
    always @* begin
        slot_sticker_id = sticker_ids[slot_index*5 +: 5];
        slot_span_left = span_lefts[slot_index*10 +: 10];
        slot_span_right = span_rights[slot_index*10 +: 10];
        slot_span_is_valid = span_valid[slot_index] &&
            (slot_sticker_id < N_STICKERS) &&
            (slot_span_left <= slot_span_right);

        slot_hit = slot_span_is_valid &&
            ({1'b0, slot_span_left} <= segment_start_x) &&
            (segment_start_x <= {1'b0, slot_span_right});

        slot_colour = COL_BLANK;
        if (slot_hit)
            slot_colour = get_sticker(cube, slot_sticker_id);

        slot_span_end_x = {1'b0, slot_span_right} + 11'd1;
        if (slot_span_end_x > SCREEN_END_X)
            slot_span_end_x = SCREEN_END_X;

        slot_next_boundary_x = best_boundary_x;
        if (slot_span_is_valid &&
            ({1'b0, slot_span_left} > segment_start_x) &&
            ({1'b0, slot_span_left} < slot_next_boundary_x))
            slot_next_boundary_x = {1'b0, slot_span_left};
        if (slot_span_is_valid &&
            (slot_span_end_x > segment_start_x) &&
            (slot_span_end_x < slot_next_boundary_x))
            slot_next_boundary_x = slot_span_end_x;
    end

    always @(posedge clk) begin
        if (rst) begin
            state <= STATE_IDLE;
            slot_index <= 4'd0;
            segment_start_x <= 11'd0;
            best_boundary_x <= SCREEN_END_X;
            selected_sticker_found <= 1'b0;
            selected_colour <= COL_BLANK;
            have_previous_value <= 1'b0;
            previous_value <= 4'd0;
            busy <= 1'b0;
            done <= 1'b0;
            seg_valid <= 1'b0;
            seg_index <= 5'd0;
            seg_x_start <= 10'd0;
            seg_value <= 4'd0;
            seg_count <= 5'd0;
        end else begin
            done <= 1'b0;
            seg_valid <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    busy <= 1'b0;
                    if (start) begin
                        state <= STATE_SCAN;
                        slot_index <= 4'd0;
                        segment_start_x <= 11'd0;
                        best_boundary_x <= SCREEN_END_X;
                        selected_sticker_found <= 1'b0;
                        selected_colour <= COL_BLANK;
                        have_previous_value <= 1'b0;
                        previous_value <= 4'd0;
                        seg_index <= 5'd0;
                        seg_x_start <= 10'd0;
                        seg_value <= 4'd0;
                        seg_count <= 5'd0;
                        busy <= 1'b1;
                    end
                end

                STATE_SCAN: begin
                    busy <= 1'b1;
                    if (slot_hit && !selected_sticker_found) begin
                        selected_sticker_found <= 1'b1;
                        selected_colour <= slot_colour;
                    end
                    if (slot_next_boundary_x < best_boundary_x)
                        best_boundary_x <= slot_next_boundary_x;

                    if (slot_index == VISIBLE_SLOT_COUNT - 1) begin
                        slot_index <= 4'd0;
                        state <= STATE_EVALUATE;
                    end else begin
                        slot_index <= slot_index + 4'd1;
                    end
                end

                STATE_EVALUATE: begin
                    busy <= 1'b1;
                    if (!have_previous_value ||
                        ({selected_sticker_found, selected_colour} != previous_value)) begin
                        seg_valid <= 1'b1;
                        seg_index <= seg_count;
                        seg_x_start <= segment_start_x[9:0];
                        if (selected_sticker_found)
                            seg_value <= {1'b1, selected_colour};
                        else
                            seg_value <= 4'b0000;
                        seg_count <= seg_count + 5'd1;
                        previous_value <= selected_sticker_found ?
                            {1'b1, selected_colour} : 4'b0000;
                        have_previous_value <= 1'b1;
                    end

                    if (best_boundary_x == SCREEN_END_X) begin
                        state <= STATE_FINISH;
                    end else begin
                        segment_start_x <= best_boundary_x;
                        best_boundary_x <= SCREEN_END_X;
                        selected_sticker_found <= 1'b0;
                        selected_colour <= COL_BLANK;
                        state <= STATE_SCAN;
                    end
                end

                STATE_FINISH: begin
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
