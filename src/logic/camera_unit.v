`timescale 1ns / 1ps

// camera_unit: mouse drag / buttons -> preset view index, never touches the cube. Owner: Lim

module camera_unit (
    input wire clk,
    input wire rst,
    input wire [2:0] stage,
    input wire [15:0] sw,
    input wire [4:0] btn_pulse,
    input wire m_left,
    input wire signed [10:0] dx,
    input wire signed [10:0] dy,
    input wire new_event,
    output wire [4:0] view_idx // {pitch, yaw} index into view_rom
);
    `include "cube_defs.vh"
endmodule
