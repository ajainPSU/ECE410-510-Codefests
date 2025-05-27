// Testbench for Monolithic QR Reed-Solomon Hardware Accelerator (NSYM=102)
`timescale 1ns / 1ps

module qr_rs_hw_accel_tb();

    parameter NSYM = 102;
    parameter WIDTH = 8;

    reg clk, rst, start;
    reg [WIDTH-1:0] codeword [0:255];
    reg [7:0] len;

    wire done;
    wire [WIDTH-1:0] syndromes [0:(2*NSYM)-1];

    // DUT: Syndrome calculator (as example)
    syndrome_calc #(.NSYM(NSYM)) DUT (
        .clk(clk),
        .rst(rst),
        .start(start),
        .codeword(codeword),
        .len(len),
        .syndromes(syndromes),
        .done(done)
    );

    integer i;

    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end

    initial begin
        rst = 1;
        start = 0;
        len = 16; // sample input length

        // Sample known-good RS-encoded data (16 symbols)
        codeword[0] = 8'h10;
        codeword[1] = 8'h23;
        codeword[2] = 8'h34;
        codeword[3] = 8'h45;
        codeword[4] = 8'h56;
        codeword[5] = 8'h67;
        codeword[6] = 8'h78;
        codeword[7] = 8'h89;
        codeword[8] = 8'h9A;
        codeword[9] = 8'hAB;
        codeword[10] = 8'hBC;
        codeword[11] = 8'hCD;
        codeword[12] = 8'hDE;
        codeword[13] = 8'hEF;
        codeword[14] = 8'hF0;
        codeword[15] = 8'h01;

        #10 rst = 0;
        #20 start = 1;
        #10 start = 0;

        wait(done);
        #10;

        $display("Syndromes:");
        for (i = 0; i < 2*NSYM; i = i + 1)
            $display("Syndrome[%0d] = %02x", i, syndromes[i]);

        $finish;
    end

endmodule
