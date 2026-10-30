`timescale 1ns / 1ps

// cube_renderer.v
// Loads projected sticker geometry and prepares it for scanline rendering.
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

    // Keep names aligned with decode_mem's geometry outputs. Index is the
    // front-to-back visible slot, not a cube sticker ID.
    reg [4:0] actual_sticker_id [0:VISIBLE_STICKER_SLOT_COUNT-1];
    reg [79:0] sticker_corner_coords [0:VISIBLE_STICKER_SLOT_COUNT-1];
    reg [107:0] sticker_edge_slopes [0:VISIBLE_STICKER_SLOT_COUNT-1];

    reg [7:0] camera_angle_id_latched;
    reg loading_geometry;
    reg [3:0] visible_sticker_slot;
    reg [3:0] geometry_response_count;
    reg [2:0] response_valid_pipe;
    reg [11:0] response_slot_pipe;
    reg geometry_ready;

    wire request_valid;
    wire [4:0] decoded_actual_sticker_id;
    wire [79:0] decoded_sticker_corner_coords;
    wire [107:0] decoded_sticker_edge_slopes;

    assign request_valid = loading_geometry &&
        (visible_sticker_slot < VISIBLE_STICKER_SLOT_COUNT);

    decode_mem decode_mem_inst (
        .clk(clk),
        .camera_angle_id(camera_angle_id_latched),
        .visible_sticker_slot(visible_sticker_slot),
        .actual_sticker_id(decoded_actual_sticker_id),
        .sticker_corner_coords(decoded_sticker_corner_coords),
        .sticker_edge_slopes(decoded_sticker_edge_slopes)
    );

    // Geometry outputs arrive three edges after their request. Delay each
    // slot tag and valid bit by the same three edges before storing the data.
    always @(posedge clk) begin
        if (rst) begin
            camera_angle_id_latched <= 8'd0;
            loading_geometry <= 1'b0;
            visible_sticker_slot <= 4'd0;
            geometry_response_count <= 4'd0;
            response_valid_pipe <= 3'b0;
            response_slot_pipe <= 12'd0;
            geometry_ready <= 1'b0;
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

    // Pixel selection is added with the scanline rendering stages.
    assign pixel_colour = COL_BLANK;
    assign pixel_on_cube = 1'b0;
    assign row_done = 1'b0;

endmodule
