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
    input [4:0] seg_value,
    input [4:0] seg_count,
    input segments_done,
    input [9:0] pix_x,
    input [9:0] pix_y,
    output reg [2:0] pixel_colour,
    output reg pixel_on_cube,
    output reg pixel_dim, // 1 = sticker outside the selected layer
    output reg row_done
);
`include "cube_defs.vh"

    localparam MAX_SEGMENT_COUNT = 25;
    localparam [1:0] COMMIT_IDLE = 2'd0;
    localparam [1:0] COMMIT_VALID = 2'd1;

    // Each entry is {x_start[9:0], {dim, on_cube, colour[2:0]}}.
    reg [14:0] even_row_segments [0:MAX_SEGMENT_COUNT-1];
    reg [14:0] odd_row_segments [0:MAX_SEGMENT_COUNT-1];
    reg [4:0] even_row_count, odd_row_count;
    reg even_row_valid, odd_row_valid;

    reg capture_buffer; // 0 = even row, 1 = odd row
    reg capture_active;
    reg capture_error;
    reg [1:0] commit_state;

    wire [4:0] scan_segment_count;
    wire scan_buffer_valid;

    // A padded 32-leaf tree picks the rightmost segment whose start is at or
    // before pix_x. The segment table is written in increasing x order.
    wire [31:0] run_hit_l0;
    wire [15:0] run_hit_l1;
    wire [7:0] run_hit_l2;
    wire [3:0] run_hit_l3;
    wire [1:0] run_hit_l4;
    wire run_hit_l5;
    wire [4:0] run_value_l0 [0:31];
    wire [4:0] run_value_l1 [0:15];
    wire [4:0] run_value_l2 [0:7];
    wire [4:0] run_value_l3 [0:3];
    wire [4:0] run_value_l4 [0:1];
    wire [4:0] run_value_l5;
    genvar scan_leaf;
    genvar tree_node;

    wire scan_active;
    wire target_buffer_is_scanned;

    assign scan_active = (pix_y < SCREEN_H);
    assign target_buffer_is_scanned = scan_active && (capture_buffer == pix_y[0]);

    assign scan_segment_count = pix_y[0] ? odd_row_count : even_row_count;
    assign scan_buffer_valid = pix_y[0] ? odd_row_valid : even_row_valid;

    generate
        for (scan_leaf = 0; scan_leaf < 32; scan_leaf = scan_leaf + 1) begin : scan_leaves
            localparam [4:0] LEAF_INDEX = scan_leaf;

            if (scan_leaf < MAX_SEGMENT_COUNT) begin : stored_segment
                wire [14:0] run_entry;

                assign run_entry = pix_y[0] ? odd_row_segments[scan_leaf] :
                                              even_row_segments[scan_leaf];
                assign run_hit_l0[scan_leaf] = scan_buffer_valid &&
                    (scan_segment_count > LEAF_INDEX) && (run_entry[14:5] <= pix_x);
                assign run_value_l0[scan_leaf] = run_entry[4:0];
            end else begin : unused_leaf
                assign run_hit_l0[scan_leaf] = 1'b0;
                assign run_value_l0[scan_leaf] = 5'd0;
            end
        end

        for (tree_node = 0; tree_node < 16; tree_node = tree_node + 1) begin : tree_level_1
            assign run_hit_l1[tree_node] = run_hit_l0[2*tree_node] |
                                           run_hit_l0[2*tree_node+1];
            assign run_value_l1[tree_node] = run_hit_l0[2*tree_node+1] ?
                run_value_l0[2*tree_node+1] : run_value_l0[2*tree_node];
        end

        for (tree_node = 0; tree_node < 8; tree_node = tree_node + 1) begin : tree_level_2
            assign run_hit_l2[tree_node] = run_hit_l1[2*tree_node] |
                                           run_hit_l1[2*tree_node+1];
            assign run_value_l2[tree_node] = run_hit_l1[2*tree_node+1] ?
                run_value_l1[2*tree_node+1] : run_value_l1[2*tree_node];
        end

        for (tree_node = 0; tree_node < 4; tree_node = tree_node + 1) begin : tree_level_3
            assign run_hit_l3[tree_node] = run_hit_l2[2*tree_node] |
                                           run_hit_l2[2*tree_node+1];
            assign run_value_l3[tree_node] = run_hit_l2[2*tree_node+1] ?
                run_value_l2[2*tree_node+1] : run_value_l2[2*tree_node];
        end

        for (tree_node = 0; tree_node < 2; tree_node = tree_node + 1) begin : tree_level_4
            assign run_hit_l4[tree_node] = run_hit_l3[2*tree_node] |
                                           run_hit_l3[2*tree_node+1];
            assign run_value_l4[tree_node] = run_hit_l3[2*tree_node+1] ?
                run_value_l3[2*tree_node+1] : run_value_l3[2*tree_node];
        end
    endgenerate

    assign run_hit_l5 = run_hit_l4[0] | run_hit_l4[1];
    assign run_value_l5 = run_hit_l4[1] ? run_value_l4[1] : run_value_l4[0];

    // STAGE 4 COMBINATIONAL: select the current segment's pixel value.
    always @* begin
        pixel_colour = COL_BLANK;
        pixel_on_cube = 1'b0;
        pixel_dim = 1'b0;

        if ((pix_x < SCREEN_W) && scan_active && scan_buffer_valid && run_hit_l5) begin
            pixel_on_cube = run_value_l5[3];
            pixel_colour = run_value_l5[2:0];
            pixel_dim = run_value_l5[4];
        end
    end

    // STAGE 4 SEQUENTIAL: store row segments and mark a row valid when complete.
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
