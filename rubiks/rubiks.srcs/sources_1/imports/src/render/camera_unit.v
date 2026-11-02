`timescale 1ns / 1ps

// camera_unit.v
// Tracks the camera angle from buttons and mouse drags.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module camera_unit (
    input clk, // 100 MHz clock
    input rst, // reset
    input [2:0] stage, // current game stage
    input [4:0] btn_pressed, // button pulses
    input mouse_l, // left button held (drag)
    input signed [8:0] mouse_dx, mouse_dy, // movement this packet
    input mouse_event, // new mouse packet
    output [7:0] camera_angle_id // {pitch_bin[3:0], yaw_bin[3:0]}, 0-255
);
`include "cube_defs.vh"

endmodule
