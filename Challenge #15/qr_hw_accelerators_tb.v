`timescale 1ns/1ps

module qr_hw_accelerators_tb;

    // Clock and reset
    reg clk = 0;
    reg rst = 1;
    always #5 clk = ~clk;  // 10ns period (100MHz)

    initial begin
        #20 rst = 0;  // Release reset after 20ns
    end

    // Inputs for warp_image
    reg start_warp;
    reg [9:0] x_in, y_in;
    reg [15:0] H [0:8];
    wire [15:0] x_warp, y_warp;
    wire done_warp;

    // Inputs for correct_errors
    reg start_corr;
    reg valid_in;
    reg [7:0] codeword_in;
    wire [7:0] codeword_out;
    wire valid_out;
    wire done_corr;

    // Instantiate warp_image
    warp_image warp_inst (
        .clk(clk),
        .rst(rst),
        .start(start_warp),
        .x_in(x_in),
        .y_in(y_in),
        .H(H),
        // .pixel_in(8'h00),  unused
        .x_warp(x_warp),
        .y_warp(y_warp),
        .done(done_warp)
    );

    // Instantiate correct_errors
    correct_errors corr_inst (
        .clk(clk),
        .rst(rst),
        .start(start_corr),
        .codeword_in(codeword_in),
        .valid_in(valid_in),
        .codeword_out(codeword_out),
        .valid_out(valid_out),
        .done(done_corr)
    );

    // Test Data
    reg [7:0] test_codewords [0:7];

    integer i, count;

    initial begin
        // Initialize homography matrix as identity (scaled by 256 for fixed-point)
        H[0] = 16'd256; H[1] = 0;      H[2] = 0;
        H[3] = 0;       H[4] = 16'd256; H[5] = 0;
        H[6] = 0;       H[7] = 0;      H[8] = 16'd256;

        // Test input point
        x_in = 10;
        y_in = 20;

        // Trigger warp_image
        @(negedge rst);
        #10 start_warp = 1;
        #10 start_warp = 0;

        wait (done_warp == 1);
        $display("Starting QR HW Accelerators Testbench");
        $display("Warp Result: x_warp = %5d, y_warp = %5d", x_warp, y_warp);

        // Prepare test codewords
        test_codewords[0] = 8'hA0;
        test_codewords[1] = 8'hA1;
        test_codewords[2] = 8'hA2;
        test_codewords[3] = 8'hA3;
        test_codewords[4] = 8'hA4;
        test_codewords[5] = 8'hA5;
        test_codewords[6] = 8'hA6;
        test_codewords[7] = 8'hA7;

        // Feed codewords
        @(posedge clk);
        start_corr = 1;
        valid_in = 1;

        for (i = 0; i < 8; i = i + 1) begin
            codeword_in = test_codewords[i];
            @(posedge clk);
        end

        valid_in = 0;
        start_corr = 0;

        // Wait and collect outputs
        $display("[CORRECTED CODEWORDS]:");
        count = 0;
        repeat (1000) begin
            @(posedge clk);
            if (valid_out) begin
                $display("OUT[%0d] = %h", count, codeword_out);
                count = count + 1;
            end
            if (done_corr && count == 8) begin
                $finish;
            end
        end
      
      	$finish;
    end
endmodule
