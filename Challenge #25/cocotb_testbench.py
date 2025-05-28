import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, Timer
from cocotb.clock import Clock
from cocotb.result import TestFailure
import random
import time

class SpiMaster:
    def __init__(self, clk, mosi, miso, cs, clk_period=1000):
        self.clk = clk
        self.mosi = mosi
        self.miso = miso
        self.cs = cs
        self.clk_period = clk_period  # in ps

    async def transfer(self, data_out):
        data_in = []
        await FallingEdge(self.clk)  # Wait for SPI system clock sync
        self.cs.value = 0

        for byte in data_out:
            shift_in = 0
            for bit in range(8):
                self.mosi.value = (byte >> (7 - bit)) & 1
                await Timer(self.clk_period // 2, units='ps')
                self.clk.value = 1
                await Timer(self.clk_period // 2, units='ps')
                shift_in = (shift_in << 1) | self.miso.value.integer
                self.clk.value = 0
            data_in.append(shift_in)

        self.cs.value = 1
        return data_in

@cocotb.test()
async def test_spi_rs_correction(dut):
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    dut.cs.value = 1
    dut.clk.value = 0
    dut.sck.value = 0
    dut.mosi.value = 0

    spi = SpiMaster(dut.sck, dut.mosi, dut.miso, dut.cs)

    # Generate test input (raw codewords)
    codewords = [random.randint(0, 255) for _ in range(102)]
    command = [0x02]  # SPI RS correction command

    # Start timer
    start_time = time.time()
    response = await spi.transfer(command + codewords)
    end_time = time.time()

    # Throughput and latency metrics
    num_bytes = len(command) + len(codewords)
    latency = end_time - start_time  # seconds
    throughput = num_bytes / latency if latency > 0 else float('inf')

    # Log results
    dut._log.info(f"Latency: {latency:.6f} seconds")
    dut._log.info(f"Throughput: {throughput:.2f} bytes/second")

    # Basic validity check (this test doesn't validate correction result)
    if len(response) != len(codewords):
        raise TestFailure("Response length mismatch")
