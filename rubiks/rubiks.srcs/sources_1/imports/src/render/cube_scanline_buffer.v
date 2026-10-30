`timescale 1ns / 1ps

// Stores two rows of color segments and scans out the row selected by pix_y.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module cube_scanline_buffer (
    input clk,
    input rst,
    input frame_start,
    input start,
    input [9:0] row_y,
    input seg_valid,
    input [4:0] seg_index,
    input [9:0] seg_x_start,
    input [3:0] seg_value,
    input [4:0] seg_count,
    input segments_done,
    input [9:0] pix_x,
    input [9:0] pix_y,
    output reg [2:0] pixel_colour,
    output reg pixel_on_cube,
    output reg row_done
);
`include "cube_defs.vh"

    localparam MAX_SEGMENT_COUNT = 25;
    localparam [1:0] COMMIT_IDLE = 2'd0;
    localparam [1:0] COMMIT_VALID = 2'd1;

    // Each entry is {x_start[9:0], {on_cube, colour[2:0]}}.
    reg [13:0] even_row_segments [0:MAX_SEGMENT_COUNT-1];
    reg [13:0] odd_row_segments [0:MAX_SEGMENT_COUNT-1];
    reg [4:0] even_row_count, odd_row_count;
    reg even_row_valid, odd_row_valid;

    reg capture_buffer; // 0 = even row, 1 = odd row
    reg capture_active;
    reg capture_error;
    reg [1:0] commit_state;

    reg [4:0] scan_segment_count;
    reg scan_buffer_valid;
    reg [13:0] scan_segment_entry;
    integer scan_index;

    wire scan_active;
    wire target_buffer_is_scanned;

    assign scan_active = (pix_y < SCREEN_H);
    assign target_buffer_is_scanned = scan_active && (capture_buffer == pix_y[0]);

    // Select the current scanline's table and find the last segment start
    // that is not greater than pix_x. Segment starts are emitted in order.
    always @* begin
        pixel_colour = COL_BLANK;
        pixel_on_cube = 1'b0;
        scan_segment_count = 5'd0;
        scan_buffer_valid = 1'b0;
        scan_segment_entry = 14'd0;

        if (pix_y[0]) begin
            scan_segment_count = odd_row_count;
            scan_buffer_valid = odd_row_valid;
        end else begin
            scan_segment_count = even_row_count;
            scan_buffer_valid = even_row_valid;
        end

        if ((pix_x < SCREEN_W) && scan_active && scan_buffer_valid) begin
            for (scan_index = 0; scan_index < MAX_SEGMENT_COUNT; scan_index = scan_index + 1) begin
                if (pix_y[0])
                    scan_segment_entry = odd_row_segments[scan_index];
                else
                    scan_segment_entry = even_row_segments[scan_index];

                if ((scan_index < scan_segment_count) &&
                    (scan_segment_entry[13:4] <= pix_x)) begin
                    pixel_on_cube = scan_segment_entry[3];
                    pixel_colour = scan_segment_entry[2:0];
                end
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            even_row_count <= 5'd0;
            odd_row_count <= 5'd0;
            even_row_valid <= 1'b0;
            odd_row_valid <= 1'b0;
            capture_buffer <= 1'b0;
            capture_active <= 1'b0;
            capture_error <= 1'b0;
            commit_state <= COMMIT_IDLE;
            row_done <= 1'b0;
        end else if (frame_start) begin
            even_row_count <= 5'd0;
            odd_row_count <= 5'd0;
            even_row_valid <= 1'b0;
            odd_row_valid <= 1'b0;
            capture_active <= 1'b0;
            capture_error <= 1'b0;
            commit_state <= COMMIT_IDLE;
            row_done <= 1'b0;
        end else begin
            row_done <= 1'b0;

            if (start && (commit_state == COMMIT_IDLE)) begin
                capture_buffer <= row_y[0];
                capture_error <= 1'b0;
                capture_active <= 1'b0;

                // Do not invalidate or write the row currently supplying scanout.
                if (!(scan_active && (row_y[0] == pix_y[0]))) begin
                    capture_active <= 1'b1;
                    if (row_y[0]) begin
                        odd_row_count <= 5'd0;
                        odd_row_valid <= 1'b0;
                    end else begin
                        even_row_count <= 5'd0;
                        even_row_valid <= 1'b0;
                    end
                end
            end

            if (seg_valid && capture_active) begin
                if (target_buffer_is_scanned || (seg_index >= MAX_SEGMENT_COUNT)) begin
                    // Abort an overrun rather than changing the active scan buffer.
                    capture_error <= 1'b1;
                    capture_active <= 1'b0;
                end else if (capture_buffer) begin
                    odd_row_segments[seg_index] <= {seg_x_start, seg_value};
                end else begin
                    even_row_segments[seg_index] <= {seg_x_start, seg_value};
                end
            end

            if (segments_done && capture_active) begin
                if (!capture_error && !target_buffer_is_scanned &&
                    (seg_count <= MAX_SEGMENT_COUNT)) begin
                    if (capture_buffer)
                        odd_row_count <= seg_count;
                    else
                        even_row_count <= seg_count;
                    commit_state <= COMMIT_VALID;
                end else begin
                    capture_error <= 1'b1;
                    capture_active <= 1'b0;
                    commit_state <= COMMIT_IDLE;
                end
            end

            // The count is committed one clock before the valid flag.
            if (commit_state == COMMIT_VALID) begin
                if (capture_error) begin
                    capture_active <= 1'b0;
                    commit_state <= COMMIT_IDLE;
                end else if (!target_buffer_is_scanned) begin
                    if (capture_buffer)
                        odd_row_valid <= 1'b1;
                    else
                        even_row_valid <= 1'b1;
                    capture_active <= 1'b0;
                    commit_state <= COMMIT_IDLE;
                    row_done <= 1'b1;
                end
            end
        end
    end

endmodule
