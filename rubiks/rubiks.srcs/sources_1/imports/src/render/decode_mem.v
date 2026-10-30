`timescale 1ns / 1ps

// decode_mem.v
// Decodes camera-angle, projection-geometry, and sticker-remap memory tables.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module decode_mem (
    input clk, // 100 MHz clock
    input [7:0] camera_angle_id, // {pitch_bin[3:0], yaw_bin[3:0]}, 0-255
    input [3:0] visible_sticker_slot, // list position, 0-11; slot 0 is frontmost
    output reg [4:0] actual_sticker_id, // live cube sticker index, or 31 for empty
    output reg [79:0] sticker_corner_coords, // four corners, 10 bits per x or y
    output reg [107:0] sticker_edge_slopes // four signed 27-bit Q16 slopes
);
`include "cube_defs.vh"

    localparam VISIBLE_STICKER_SLOT_COUNT = 12;

    // 256 angles x 10 bits = 2,560 bits: {projection ID, cube rotation ID}.
    reg [9:0] camera_angle_decode_rom [0:CAMERA_ANGLE_COUNT-1];

    // 336 slots x 193 bits = 64,848 bits: {reference ID, 4 edge slopes, 4 corners}.
    reg [192:0] projection_slot_rom [0:PROJECTION_COUNT*VISIBLE_STICKER_SLOT_COUNT-1];

    // 24 rotations x 24 stickers x 5 bits = 2,880 bits.
    // Maps each reference sticker ID to its live cube-state index.
    reg [4:0] cube_rotation_sticker_map_rom [0:CUBE_ROTATION_COUNT*N_STICKERS-1];

    reg [9:0] camera_angle_decode_result;
    reg [3:0] visible_sticker_slot_prev;
    reg [CUBE_ROTATION_ID_W-1:0] cube_rotation_id_prev;
    reg [192:0] projection_slot_data;

    wire [8:0] projection_slot_addr;
    wire [9:0] cube_rotation_sticker_map_addr;
    wire [PROJECTION_ID_W-1:0] projection_id;
    wire [CUBE_ROTATION_ID_W-1:0] cube_rotation_id;

    assign projection_id = camera_angle_decode_result[9:5];
    assign cube_rotation_id = camera_angle_decode_result[4:0];

    assign projection_slot_addr =
        ({4'd0, projection_id} * 9'd12) + {5'd0, visible_sticker_slot_prev};
    assign cube_rotation_sticker_map_addr =
        ({5'd0, cube_rotation_id_prev} * 10'd24) +
        {5'd0, projection_slot_data[192:188]};

    // Vivado synthesis runs from rubiks.runs/<run>, so paths start at rubiks/.
    initial begin
        $readmemh("../../rubiks.srcs/sources_1/imports/src/render/mem/camera_angle_decode.mem", camera_angle_decode_rom);
        $readmemh("../../rubiks.srcs/sources_1/imports/src/render/mem/cube_layout.mem", projection_slot_rom);
        $readmemh("../../rubiks.srcs/sources_1/imports/src/render/mem/rotation_stickers.mem", cube_rotation_sticker_map_rom);
    end

    // STAGE 1: Pipeline angle decode, geometry read, and sticker ID remap.
    // Outputs match the request after three rising clock edges.
    always @(posedge clk) begin
        camera_angle_decode_result <= camera_angle_decode_rom[camera_angle_id];
        visible_sticker_slot_prev <= visible_sticker_slot;

        if ((projection_id < PROJECTION_COUNT) &&
            (visible_sticker_slot_prev < VISIBLE_STICKER_SLOT_COUNT))
            projection_slot_data <= projection_slot_rom[projection_slot_addr];
        else
            projection_slot_data <= {5'd31, 108'd0, 80'd0};

        cube_rotation_id_prev <= cube_rotation_id;

        if ((projection_slot_data[192:188] < N_STICKERS) &&
            (cube_rotation_id_prev < CUBE_ROTATION_COUNT))
            actual_sticker_id <= cube_rotation_sticker_map_rom[cube_rotation_sticker_map_addr];
        else
            actual_sticker_id <= 5'd31;

        if (projection_slot_data[192:188] < N_STICKERS) begin
            sticker_corner_coords <= projection_slot_data[79:0];
            sticker_edge_slopes <= projection_slot_data[187:80];
        end else begin
            sticker_corner_coords <= 80'd0;
            sticker_edge_slopes <= 108'd0;
        end
    end

endmodule
