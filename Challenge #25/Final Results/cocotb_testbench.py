import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, FallingEdge
import time

class SpiMaster:
    def __init__(self, sck, mosi, miso, cs, clk_period=1000):
        self.sck = sck
        self.mosi = mosi
        self.miso = miso
        self.cs = cs
        self.clk_period = clk_period

    async def transfer(self, data_out):
        data_in = []
        self.cs.value = 0
        await Timer(self.clk_period, units='ps')

        for byte in data_out:
            shift_in = 0
            for bit in range(8):
                self.mosi.value = (byte >> (7 - bit)) & 1
                await Timer(self.clk_period // 2, units='ps')
                self.sck.value = 1
                await Timer(self.clk_period // 2, units='ps')
                shift_in = (shift_in << 1) | self.miso.value.integer
                self.sck.value = 0
            data_in.append(shift_in)

        self.cs.value = 1
        return data_in

@cocotb.test()
async def test_spi_throughput_latency(dut):
    spi_freq_mhz = 5.0
    clk_period_ns = 1_000 / spi_freq_mhz
    cocotb.start_soon(Clock(dut.clk, clk_period_ns, units="ns").start())

    # Initial SPI line states
    dut.cs.value = 1
    dut.sck.value = 0
    dut.mosi.value = 0

    spi = SpiMaster(dut.sck, dut.mosi, dut.miso, dut.cs, clk_period=1000)

    packet_sizes = [1, 8, 16, 32, 64, 128, 256, 512, 1024]
    latency_list = []
    throughput_list = []
    efficiency_list = []

    protocol_overhead_us = None

    dut._log.info("SPI BENCHMARK SUMMARY")
    dut._log.info("=" * 60)

    for size in packet_sizes:
        data = [0x02] + [0x55] * size  # Command + payload
        start = time.time()
        _ = await spi.transfer(data)
        end = time.time()

        elapsed_us = (end - start) * 1e6
        bits_sent = len(data) * 8
        throughput_kbps = bits_sent / elapsed_us
        overhead_us = elapsed_us - (bits_sent / (spi_freq_mhz * 1e6)) * 1e6
        efficiency = 100 * (1 - overhead_us / elapsed_us)

        protocol_overhead_us = protocol_overhead_us or overhead_us

        latency_list.append(elapsed_us)
        throughput_list.append(throughput_kbps)
        efficiency_list.append(efficiency)

    avg_latency = sum(latency_list) / len(latency_list)
    max_throughput = max(throughput_list)

    dut._log.info(f"Average Latency: {avg_latency:.2f} µs")
    dut._log.info(f"Maximum Throughput: {max_throughput:.2f} kbps")
    dut._log.info(f"SPI Clock Frequency: {spi_freq_mhz:.2f} MHz")
    dut._log.info(f"Protocol Overhead: {protocol_overhead_us:.2f} µs\n")
    dut._log.info("Performance by Packet Size:")
    dut._log.info("Size (bytes)    Throughput (kbps)    Efficiency (%)")
    dut._log.info("-" * 50)
    for size, tput, eff in zip(packet_sizes, throughput_list, efficiency_list):
        dut._log.info(f"{size:<15}{tput:>10.2f}          {eff:>10.2f}")
