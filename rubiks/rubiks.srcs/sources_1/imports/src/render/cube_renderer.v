`timescale 1ns / 1ps

// cube_renderer.v
// Loads projected sticker geometry and calculates per-sticker row spans.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module cube_renderer (
    input clk, // 100 MHz clock
    input rst, // reset all renderer state
    input tick_25mhz, // pixel pulse
    input frame_start, // pulse at start of vblank, reload geometry
    input [7:0] camera_angle_id, // {pitch_bin[3:0], yaw_bin[3:0]}
    input [9:0] pix_x, pix_y, // current pixel position
    input [71:0] cube, // live cube state
    output [2:0] pixel_colour, // colour code of this pixel
    output pixel_on_cube, // 1 = this pixel is on the cube
    output row_done // one-cycle pulse when a complete row is ready
);
`include "cube_defs.vh"

    localparam VISIBLE_STICKER_SLOT_COUNT = 12;
    localparam [1:0] SPAN_WAIT_ROW = 2'd0;
    localparam [1:0] SPAN_START_CALC = 2'd1;
    localparam [1:0] SPAN_WAIT_CALC = 2'd2;

    reg [4:0] actual_sticker_id [0:VISIBLE_STICKER_SLOT_COUNT-1];
    reg [79:0] sticker_corner_coords [0:VISIBLE_STICKER_SLOT_COUNT-1];
    reg [107:0] sticker_edge_slopes [0:VISIBLE_STICKER_SLOT_COUNT-1];

    reg [9:0] sticker_span_left [0:VISIBLE_STICKER_SLOT_COUNT-1];
    reg [9:0] sticker_span_right [0:VISIBLE_STICKER_SLOT_COUNT-1];
    reg sticker_span_valid [0:VISIBLE_STICKER_SLOT_COUNT-1];
    reg [107:0] edge_state_by_slot [0:VISIBLE_STICKER_SLOT_COUNT-1];

    reg [7:0] camera_angle_id_latched;
    reg loading_geometry;
    reg [3:0] visible_sticker_slot;
    reg [3:0] geometry_response_count;
    reg [2:0] response_valid_pipe;
    reg [11:0] response_slot_pipe;
    reg geometry_ready;
    integer geometry_reset_index;

    reg [1:0] span_controller_state;
    reg [3:0] active_slot;
    reg [9:0] row_y;
    reg [9:0] last_span_row;
    integer span_reset_index;

    wire request_valid;
    wire [4:0] decoded_actual_sticker_id;
    wire [79:0] decoded_sticker_corner_coords;
    wire [107:0] decoded_sticker_edge_slopes;

    wire row_start;
    wire calc_start;
    wire calc_rst;
    wire [107:0] calc_edge_state_in;
    wire [107:0] calc_edge_state_out;
    wire [9:0] calc_left, calc_right;
    wire calc_valid, calc_busy, calc_done;

    assign request_valid = loading_geometry &&
        (visible_sticker_slot < VISIBLE_STICKER_SLOT_COUNT);
    assign row_start = tick_25mhz && (pix_x == 10'd0) &&
        (pix_y < SCREEN_H) && (pix_y != last_span_row);
    assign calc_start = (span_controller_state == SPAN_START_CALC);
    assign calc_rst = rst || frame_start;
    assign calc_edge_state_in = edge_state_by_slot[active_slot];

    decode_mem decode_mem_inst (
        .clk(clk),
        .camera_angle_id(camera_angle_id_latched),
        .visible_sticker_slot(visible_sticker_slot),
        .actual_sticker_id(decoded_actual_sticker_id),
        .sticker_corner_coords(decoded_sticker_corner_coords),
        .sticker_edge_slopes(decoded_sticker_edge_slopes)
    );

    calc_sticker_span span_calc (
        .clk(clk),
        .rst(calc_rst),
        .start(calc_start),
        .row_y(row_y),
        .corners(sticker_corner_coords[active_slot]),
        .slopes(sticker_edge_slopes[active_slot]),
        .edge_state_in(calc_edge_state_in),
        .edge_state_out(calc_edge_state_out),
        .span_left(calc_left),
        .span_right(calc_right),
        .span_valid(calc_valid),
        .busy(calc_busy),
        .done(calc_done)
    );

    // Load all 12 decode_mem responses and keep the request slot aligned with
    // the decoder's three-clock output latency.
    always @(posedge clk) begin
        if (rst) begin
            camera_angle_id_latched <= 8'd0;
            loading_geometry <= 1'b0;
            visible_sticker_slot <= 4'd0;
            geometry_response_count <= 4'd0;
            response_valid_pipe <= 3'b0;
            response_slot_pipe <= 12'd0;
            geometry_ready <= 1'b0;
            for (geometry_reset_index = 0;
                 geometry_reset_index < VISIBLE_STICKER_SLOT_COUNT;
                 geometry_reset_index = geometry_reset_index + 1) begin
                actual_sticker_id[geometry_reset_index] <= 5'd31;
                sticker_corner_coords[geometry_reset_index] <= 80'd0;
                sticker_edge_slopes[geometry_reset_index] <= 108'd0;
            end
        end else if (frame_start) begin
            camera_angle_id_latched <= camera_angle_id;
            loading_geometry <= 1'b1;
            visible_sticker_slot <= 4'd0;
            geometry_response_count <= 4'd0;
            response_valid_pipe <= 3'b0;
            response_slot_pipe <= 12'd0;
            geometry_ready <= 1'b0;
        end else begin
            response_valid_pipe <= {response_valid_pipe[1:0], request_valid};
            response_slot_pipe <= {response_slot_pipe[7:0], visible_sticker_slot};

            if (request_valid) begin
                if (visible_sticker_slot == VISIBLE_STICKER_SLOT_COUNT - 1) begin
                    loading_geometry <= 1'b0;
                    visible_sticker_slot <= VISIBLE_STICKER_SLOT_COUNT;
                end else begin
                    visible_sticker_slot <= visible_sticker_slot + 4'd1;
                end
            end

            if (response_valid_pipe[2]) begin
                actual_sticker_id[response_slot_pipe[11:8]] <= decoded_actual_sticker_id;
                sticker_corner_coords[response_slot_pipe[11:8]] <= decoded_sticker_corner_coords;
                sticker_edge_slopes[response_slot_pipe[11:8]] <= decoded_sticker_edge_slopes;

                if (geometry_response_count < VISIBLE_STICKER_SLOT_COUNT)
                    geometry_response_count <= geometry_response_count + 4'd1;

                if (geometry_response_count == VISIBLE_STICKER_SLOT_COUNT - 1)
                    geometry_ready <= 1'b1;
            end
        end
    end

    // Calculate each sticker's span once per visible scanline. Slots are
    // traversed in the same front-to-back order used by the geometry table.
    always @(posedge clk) begin
        if (rst) begin
            span_controller_state <= SPAN_WAIT_ROW;
            active_slot <= 4'd0;
            row_y <= 10'd0;
            last_span_row <= 10'h3FF;
            for (span_reset_index = 0;
                 span_reset_index < VISIBLE_STICKER_SLOT_COUNT;
                 span_reset_index = span_reset_index + 1) begin
                sticker_span_left[span_reset_index] <= SCREEN_W;
                sticker_span_right[span_reset_index] <= 10'd0;
                sticker_span_valid[span_reset_index] <= 1'b0;
                edge_state_by_slot[span_reset_index] <= 108'd0;
            end
        end else if (frame_start) begin
            span_controller_state <= SPAN_WAIT_ROW;
            active_slot <= 4'd0;
            row_y <= 10'd0;
            last_span_row <= 10'h3FF;
            for (span_reset_index = 0;
                 span_reset_index < VISIBLE_STICKER_SLOT_COUNT;
                 span_reset_index = span_reset_index + 1) begin
                sticker_span_left[span_reset_index] <= SCREEN_W;
                sticker_span_right[span_reset_index] <= 10'd0;
                sticker_span_valid[span_reset_index] <= 1'b0;
                edge_state_by_slot[span_reset_index] <= 108'd0;
            end
        end else begin
            case (span_controller_state)
                SPAN_WAIT_ROW: begin
                    if (geometry_ready && row_start) begin
                        row_y <= pix_y;
                        active_slot <= 4'd0;
                        last_span_row <= pix_y;
                        span_controller_state <= SPAN_START_CALC;
                    end
                end

                SPAN_START_CALC: begin
                    // calc_start is high for this cycle and starts the helper.
                    span_controller_state <= SPAN_WAIT_CALC;
                end

                SPAN_WAIT_CALC: begin
                    if (calc_done) begin
                        sticker_span_left[active_slot] <= calc_left;
                        sticker_span_right[active_slot] <= calc_right;
                        sticker_span_valid[active_slot] <= calc_valid;
                        edge_state_by_slot[active_slot] <= calc_edge_state_out;

                        if (active_slot == VISIBLE_STICKER_SLOT_COUNT - 1) begin
                            span_controller_state <= SPAN_WAIT_ROW;
                        end else begin
                            active_slot <= active_slot + 4'd1;
                            span_controller_state <= SPAN_START_CALC;
                        end
                    end
                end

                default: begin
                    span_controller_state <= SPAN_WAIT_ROW;
                end
            endcase
        end
    end

    // Pixel selection and color-run scanout are added in later renderer stages.
    assign pixel_colour = COL_BLANK;
    assign pixel_on_cube = 1'b0;
    assign row_done = 1'b0;

endmodule
