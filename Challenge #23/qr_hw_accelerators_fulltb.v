// -----------------------------
// HW Accelerated Modules V2 Testbench
// -----------------------------

`timescale 1ns / 1ps

module qr_rs_hw_accel_tb;

    parameter DATA_WIDTH = 8;
    parameter NSYM = 102;
    parameter CODE_LEN = 256;

    reg clk, rst, start;
    reg  [DATA_WIDTH-1:0] codeword [0:CODE_LEN-1];
    reg  [7:0] len;

    wire [DATA_WIDTH-1:0] syndromes [0:(2*NSYM)-1]; // [0:203]
    wire synd_done;

  	wire [DATA_WIDTH-1:0] lambda [0:NSYM-1]; // [0:101]
    wire bm_done;

    wire [255:0] error_locations; // packed
    wire chien_done;

    // Extract unpacked error bits [0:NSYM-1]
    wire [DATA_WIDTH-1:0] error_bits [0:NSYM-1];
    genvar e;
    generate
        for (e = 0; e < NSYM; e = e + 1) begin : unpack_error_bits
            assign error_bits[e] = { {DATA_WIDTH-1{1'b0}}, error_locations[e] };
        end
    endgenerate

    wire [DATA_WIDTH-1:0] error_magnitudes [0:NSYM-1];
    reg  [DATA_WIDTH-1:0] error_evaluator_poly [0:NSYM-1]; // dummy for forney
    wire [6:0] num_errors;

    wire [DATA_WIDTH-1:0] corrected [0:NSYM-1];
  
    wire [DATA_WIDTH-1:0] codeword_partial [0:NSYM-1];
    genvar j;
    generate
        for (j = 0; j < NSYM; j = j + 1) begin : codeword_slice
            assign codeword_partial[j] = codeword[j];
        end
    endgenerate

    integer i, k;

    // Clock generation
    always #5 clk = ~clk;

    // Stimulus
    initial begin
        clk = 0;
        rst = 1;
        start = 0;
        len = NSYM;

        for (i = 0; i < CODE_LEN; i = i + 1)
            codeword[i] = i[7:0];

	codeword[10] = codeword[10] ^ 8'h3F; // Original was 0x0A → XOR with 0x3F = 0x35
	codeword[55] = codeword[55] ^ 8'hA2; // Original was 0x37 → XOR with 0xA2 = 0x95

        #20 rst = 0;
        #20 start = 1;
        #10 start = 0;
    end

    // syndrome_calc
    syndrome_calc #(.NSYM(NSYM)) synd_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        .codeword(codeword),
        .len(len),
        .syndromes(syndromes),
        .done(synd_done)
    );

	// Berlekamp-Massey
	berlekamp_massey #(.NSYM(NSYM)) bm_inst (
    	.clk(clk),
    	.rst(rst),
    	.start(synd_done),
    	.syndrome(syndromes[0:NSYM-1]),  // ← fixed here
    	.done(bm_done),
    	.locator(lambda)
	);


    // chien_search
    chien_search #(.NSYM(NSYM)) chien_inst (
        .clk(clk),
        .rst(rst),
        .start(bm_done),
        .lambda(lambda),
        .done(chien_done),
        .error_locations(error_locations)
    );

    // forney_algorithm
    forney_algorithm #(.NSYM(NSYM)) forney_inst (
        .clk(clk),
        .rst(rst),
        .syndromes(syndromes[0:NSYM-1]),
        .error_locator_poly(lambda),
        .error_evaluator_poly(error_evaluator_poly),
        .error_positions(error_bits),
        .num_errors(NSYM[6:0]),
        .error_magnitudes(error_magnitudes)
    );

    // apply_corrections
    apply_corrections #(.DATA_WIDTH(DATA_WIDTH), .NSYM(NSYM)) corrector (
        .received(codeword_partial),
        .error_magnitude(error_magnitudes),
        .error_position(error_bits),
        .corrected(corrected)
    );

    // Monitor
    initial begin
        #1000;
        $display("Corrected Output:");
        for (k = 0; k < NSYM; k = k + 1)
            $display("corrected[%0d] = %02x", k, corrected[k]);
        $finish;
    end

endmodule
