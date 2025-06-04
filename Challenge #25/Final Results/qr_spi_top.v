
module qr_spi_top #(
    parameter DATA_WIDTH = 8,
    parameter NSYM = 8
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        sck,
    input  wire        mosi,
    output wire        miso,
    input  wire        cs
);

    // === SPI Shift Logic ===
    reg [7:0] rx_shift, tx_shift, tx_byte;
    reg [2:0] bit_cnt;
    reg       spi_byte_done;
    reg       miso_reg;
    assign miso = miso_reg;

    reg [7:0] input_buffer [0:NSYM-1];
    reg [7:0] output_buffer[0:NSYM-1];

    reg [15:0] byte_index;
    reg [7:0] command;
    reg processing, send_bytes;
    reg [15:0] out_index;

    // SPI receive
    always @(posedge sck or posedge cs) begin
        if (cs) begin
            bit_cnt <= 0;
            spi_byte_done <= 0;
        end else begin
            rx_shift <= {rx_shift[6:0], mosi};
            bit_cnt <= bit_cnt + 1;
            spi_byte_done <= (bit_cnt == 3'd7);
        end
    end

    // SPI transmit
    always @(negedge sck or posedge cs) begin
        if (cs) begin
            tx_shift <= 8'h00;
            miso_reg <= 0;
        end else begin
            miso_reg <= tx_shift[7];
            tx_shift <= {tx_shift[6:0], 1'b0};
        end
    end

    // Flattened wires
    wire [DATA_WIDTH*NSYM-1:0] received_flat;
    wire [DATA_WIDTH*NSYM-1:0] corrected_flat;
    wire [DATA_WIDTH*NSYM-1:0] syndromes_flat;
    wire [DATA_WIDTH*NSYM-1:0] lambda_flat;
    wire [DATA_WIDTH*NSYM-1:0] error_magnitude_flat;
    wire [NSYM-1:0] error_position;

    // Manual flattening/unflattening
    assign received_flat = {
        input_buffer[7], input_buffer[6], input_buffer[5], input_buffer[4],
        input_buffer[3], input_buffer[2], input_buffer[1], input_buffer[0]
    };

    // Receive and command logic
    always @(posedge clk) begin
        if (rst) begin
            command <= 0;
            byte_index <= 0;
            processing <= 0;
            send_bytes <= 0;
            out_index <= 0;
        end else if (spi_byte_done) begin
            if (command == 0) begin
                command <= rx_shift;
            end else if (command == 8'h02 && byte_index < NSYM) begin
                input_buffer[byte_index] <= rx_shift;
                byte_index <= byte_index + 1;
                if (byte_index == NSYM - 1)
                    processing <= 1;
            end
        end
    end

    // Decoder logic
    syndrome_calc #(.DATA_WIDTH(DATA_WIDTH), .NSYM(NSYM)) SYND (
        .clk(clk), .rst(rst), .start(processing),
        .codeword_flat(received_flat),
        .len(NSYM[7:0]),
        .syndromes_flat(syndromes_flat),
        .done()
    );

    berlekamp_massey #(.DATA_WIDTH(DATA_WIDTH), .NSYM(NSYM)) BM (
        .clk(clk), .rst(rst), .start(processing),
        .syndromes(syndromes_flat),
        .lambda(lambda_flat),
        .done()
    );

    chien_search #(.DATA_WIDTH(DATA_WIDTH), .NSYM(NSYM), .N(255)) CHIEN (
        .clk(clk), .rst(rst), .start(processing),
        .lambda(lambda_flat),
        .error_position(error_position),
        .done()
    );

    forney_algorithm #(.DATA_WIDTH(DATA_WIDTH), .NSYM(NSYM)) FORNEY (
        .clk(clk), .rst(rst),
        .syndromes(syndromes_flat),
        .lambda(lambda_flat),
        .error_positions(error_position),
        .error_magnitude(error_magnitude_flat)
    );

    apply_corrections #(.DATA_WIDTH(DATA_WIDTH), .NSYM(NSYM)) CORR (
        .clk(clk),
        .received_flat(received_flat),
        .error_magnitude_flat(error_magnitude_flat),
        .error_position(error_position),
        .corrected_flat(corrected_flat)
    );

    // Store corrected output & respond
    always @(posedge clk) begin
        if (processing) begin
            output_buffer[0] <= corrected_flat[7:0];
            output_buffer[1] <= corrected_flat[15:8];
            output_buffer[2] <= corrected_flat[23:16];
            output_buffer[3] <= corrected_flat[31:24];
            output_buffer[4] <= corrected_flat[39:32];
            output_buffer[5] <= corrected_flat[47:40];
            output_buffer[6] <= corrected_flat[55:48];
            output_buffer[7] <= corrected_flat[63:56];
            send_bytes <= 1;
            processing <= 0;
            command <= 0;
            byte_index <= 0;
            out_index <= 0;
        end else if (send_bytes && spi_byte_done) begin
            tx_byte <= output_buffer[out_index];
            tx_shift <= output_buffer[out_index];
            out_index <= (out_index == NSYM - 1) ? 0 : out_index + 1;
        end
    end

endmodule
