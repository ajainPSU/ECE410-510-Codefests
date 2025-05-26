`timescale 1ns / 1ps

module qr_hw_accelerators_tb;

    // Clock and reset
    reg clk = 0;
    reg rst = 1;
    always #5 clk = ~clk;  // 100MHz clock

    initial begin
        #20 rst = 0;
    end

    // ------------------
    // warp_image Signals
    // ------------------
    reg start_warp, enable_warp;
    reg [15:0] x_in, y_in;
    reg [143:0] H_flat;
    wire [15:0] x_warp, y_warp;
    wire done_warp;

    warp_image #(.DATA_WIDTH(16), .FIXED_SHIFT(8)) warp_inst (
        .clk(clk),
        .rst(rst),
        .start(start_warp),
        .enable(enable_warp),
        .x_in(x_in),
        .y_in(y_in),
        .H_flat(H_flat),
        .x_warp(x_warp),
        .y_warp(y_warp),
        .done(done_warp)
    );

    // ----------------------
    // correct_errors Signals
    // ----------------------
    reg start_corr, enable_corr;
    reg valid_in;
    reg [7:0] codeword_in;
    wire [7:0] codeword_out;
    wire valid_out, done_corr;

    correct_errors #(.NSYM(7), .MAX_CW(32)) corr_inst (
        .clk(clk),
        .rst(rst),
        .start(start_corr),
        .enable(enable_corr),
        .codeword_in(codeword_in),
        .valid_in(valid_in),
        .codeword_out(codeword_out),
        .valid_out(valid_out),
        .done(done_corr)
    );

    // ----------------------
    // Testbench Logic
    // ----------------------
    integer i, count;
    reg [7:0] test_codewords [0:7];

    initial begin
        @(negedge rst);

        // Load test codewords
        test_codewords[0] = 8'hA0;
        test_codewords[1] = 8'hA1;
        test_codewords[2] = 8'hA2;
        test_codewords[3] = 8'hA3;
        test_codewords[4] = 8'hA4;
        test_codewords[5] = 8'hA5;
        test_codewords[6] = 8'hA6;
        test_codewords[7] = 8'hA7;

        // ------------------
        // Test warp_image
        // ------------------
        x_in = 16'd10;
        y_in = 16'd20;
        H_flat = {
            16'd256, 16'd0,   16'd0,
            16'd0,   16'd256, 16'd0,
            16'd0,   16'd0,   16'd256
        };
        enable_warp = 1;
        start_warp = 1;
        @(posedge clk);
        start_warp = 0;
        wait(done_warp);
        $display("Warp Output: x = %d, y = %d", x_warp, y_warp);

        // ------------------
        // Test correct_errors
        // ------------------
        enable_corr = 1;
        start_corr = 1;
        @(posedge clk);
        start_corr = 0;

        valid_in = 1;
        for (i = 0; i < 8; i = i + 1) begin
            codeword_in = test_codewords[i];
            @(posedge clk);
        end
        valid_in = 0;

        $display("Corrected Codewords:");
        count = 0;
        while (count < 8) begin
            @(posedge clk);
            if (valid_out) begin
                $display("OUT[%0d] = %h", count, codeword_out);
                count = count + 1;
            end
        end

        $finish;
    end
endmodule