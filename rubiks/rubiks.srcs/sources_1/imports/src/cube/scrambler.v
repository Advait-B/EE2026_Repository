`timescale 1ns / 1ps

// scrambler.v
// Sends 25 random moves, one per 4 Hz tick, never repeating a face back to back.
// Port contract: docs/module_ports.txt. Shared constants: src/pkg/cube_defs.vh

module scrambler (
    input clk, // 100 MHz clock
    input rst, // reset
    input start, cancel, // pulse to begin scramble
    input tick, // one move per tick
    output [4:0] scr_move, // next scramble move
    output scr_valid, // pulse when scr_move is ready
    output busy, // scramble in progress
    output done // pulse when 25 moves are sent
);
`include "cube_defs.vh"

    localparam [4:0] SCRAMBLE_LAST_INDEX = 5'd24;

    reg [15:0] lfsr;
    reg [4:0] move_count;
    reg [4:0] scr_move_reg;
    reg scr_valid_reg;
    reg busy_reg;
    reg done_reg;
    reg [2:0] previous_face;
    reg have_previous_face;

    reg [2:0] selected_face;
    reg [1:0] selected_type;

    assign scr_move = scr_move_reg;
    assign scr_valid = scr_valid_reg;
    assign busy = busy_reg;
    assign done = done_reg;

    // A 16-bit maximal-length LFSR supplies a repeatable pseudo-random stream.
    function automatic [15:0] lfsr_next(input [15:0] value);
        begin
            lfsr_next = {1'b0, value[15:1]} ^ (value[0] ? 16'hB400 : 16'h0000);
        end
    endfunction

    // Map the LFSR bits to one of six faces and three turn types. If the face
    // would repeat the previous one, advance to the next face in U-R-F-D-L-B
    // order. This keeps every emitted move valid without changing move codes.
    always @* begin
        if (lfsr[2:0] < N_FACES)
            selected_face = lfsr[2:0];
        else
            selected_face = lfsr[2:0] - N_FACES;

        if (have_previous_face && (selected_face == previous_face)) begin
            if (selected_face == FACE_B)
                selected_face = FACE_U;
            else
                selected_face = selected_face + 3'd1;
        end

        selected_type = lfsr[4:3];
        if (selected_type == 2'd3)
            selected_type = TURN_180;
    end

    always @(posedge clk) begin
        if (rst) begin
            lfsr <= 16'hACE1;
            move_count <= 5'd0;
            scr_move_reg <= MV_NONE;
            scr_valid_reg <= 1'b0;
            busy_reg <= 1'b0;
            done_reg <= 1'b0;
            previous_face <= FACE_U;
            have_previous_face <= 1'b0;
        end else if (cancel) begin
            busy_reg <= 1'b0;
            done_reg <= 1'b1;
        end else begin
            // Both status outputs are one-cycle pulses.
            scr_valid_reg <= 1'b0;
            done_reg <= 1'b0;

            if (start && !busy_reg) begin
                move_count <= 5'd0;
                have_previous_face <= 1'b0;
                busy_reg <= 1'b1;
            end else if (busy_reg && tick) begin
                scr_move_reg <= make_move(selected_face, selected_type);
                scr_valid_reg <= 1'b1;
                previous_face <= selected_face;
                have_previous_face <= 1'b1;
                lfsr <= lfsr_next(lfsr);

                if (move_count == SCRAMBLE_LAST_INDEX) begin
                    busy_reg <= 1'b0;
                    done_reg <= 1'b1;
                end else begin
                    move_count <= move_count + 5'd1;
                end
            end
        end
    end

endmodule
