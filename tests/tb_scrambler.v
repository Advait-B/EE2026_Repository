`timescale 1ns / 1ps

module tb_scrambler;
`include "cube_defs.vh"

    reg clk;
    reg rst;
    reg start;
    reg tick_4hz;
    wire [4:0] scr_move;
    wire scr_valid;
    wire busy;
    wire done;

    integer errors;
    integer i;
    reg [2:0] previous_face;
    reg [2:0] current_face;

    scrambler dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .tick_4hz(tick_4hz),
        .scr_move(scr_move),
        .scr_valid(scr_valid),
        .busy(busy),
        .done(done)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        start = 1'b0;
        tick_4hz = 1'b0;
        errors = 0;
        previous_face = FACE_U;

        repeat (2) @(posedge clk);
        #1 rst = 1'b0;

        @(negedge clk);
        start = 1'b1;
        @(posedge clk);
        #1;
        start = 1'b0;
        if (busy !== 1'b1 || scr_valid !== 1'b0) begin
            $display("FAIL: start did not enter busy without emitting a move");
            errors = errors + 1;
        end

        for (i = 0; i < 25; i = i + 1) begin
            // The module must wait for the next pacing tick before emitting.
            repeat (3) begin
                @(posedge clk);
                #1;
                if (scr_valid !== 1'b0 || done !== 1'b0) begin
                    $display("FAIL: output pulse occurred without tick before move %0d", i + 1);
                    errors = errors + 1;
                end
            end

            @(negedge clk);
            tick_4hz = 1'b1;
            @(posedge clk);
            #1;
            tick_4hz = 1'b0;

            if (scr_valid !== 1'b1 || !move_is_valid(scr_move)) begin
                $display("FAIL: tick %0d did not produce a valid move", i + 1);
                errors = errors + 1;
            end else begin
                current_face = move_face(scr_move);
                if ((i > 0) && (current_face == previous_face)) begin
                    $display("FAIL: face %0d repeated on adjacent moves %0d and %0d",
                             current_face, i, i + 1);
                    errors = errors + 1;
                end
                previous_face = current_face;
            end

            if (done !== (i == 24)) begin
                $display("FAIL: done pulse mismatch after move %0d", i + 1);
                errors = errors + 1;
            end
            if (busy !== (i < 24)) begin
                $display("FAIL: busy mismatch after move %0d", i + 1);
                errors = errors + 1;
            end
        end

        @(posedge clk);
        #1;
        if (scr_valid !== 1'b0 || done !== 1'b0 || busy !== 1'b0) begin
            $display("FAIL: completion pulses did not clear while idle");
            errors = errors + 1;
        end

        if (errors == 0)
            $display("PASS: 25 paced moves, valid move codes, no adjacent repeated faces, one completion pulse");
        else
            $display("FAIL: %0d scrambler checks failed", errors);
        $finish;
    end
endmodule
