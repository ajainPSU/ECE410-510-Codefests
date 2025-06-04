// qr_wrapper.v
module qr_wrapper (
    input  wire clk,
    input  wire rst,
    input  wire sck,
    input  wire mosi,
    input  wire cs,
    output wire miso
);

    // Instantiate your SPI top module (DUT)
    qr_spi_top uut (
        .clk(clk),
        .rst(rst),
        .sck(sck),
        .mosi(mosi),
        .miso(miso),
        .cs(cs)
    );

endmodule

