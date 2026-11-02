`timescale 1ns / 1ps

// camera_unit.v
// Tracks the camera angle from buttons and mouse drags.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module camera_unit (
    input clk, // 100 MHz clock
    input rst, // reset
    input [2:0] stage, // current game stage
    input [4:0] btn_pressed, // button pulses
    input mouse_r, // right button held (drag to rotate)
    input signed [10:0] mouse_dx, mouse_dy, // movement this packet
    input mouse_event, // new mouse packet
    output [7:0] camera_angle_id // {pitch_bin[3:0], yaw_bin[3:0]}, 0-255
);
`include "cube_defs.vh"

    // yaw and pitch each go from 0 to 15 and wrap around
    reg [3:0] camera_yaw = 4'd0;
    reg [3:0] camera_pitch = 4'd0;

    // one bin step per mouse packet while the right button is held
    always @(posedge clk) begin
        if (rst) begin
            camera_yaw <= 4'd0;
            camera_pitch <= 4'd0;
        end else if (mouse_event && mouse_r) begin
            if (mouse_dx != 11'sd0)
                camera_yaw <= mouse_dx[10] ? camera_yaw - 4'd1 : camera_yaw + 4'd1;
            if (mouse_dy != 11'sd0)
                camera_pitch <= mouse_dy[10] ? camera_pitch + 4'd1 : camera_pitch - 4'd1;
        end
    end

    assign camera_angle_id = {camera_pitch, camera_yaw}; // = pitch * 16 + yaw

endmodule
