import time
import numpy as np
from IB3 import GF256, ReedSolomonDecoder, PerspectiveTransformer

def benchmark_rs_correct_errors():
    gf = GF256()
    rs = ReedSolomonDecoder(gf)
    msg = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
    nsym = 5
    N = 10000
    start = time.perf_counter()
    for _ in range(N):
        rs.correct_errors(msg[:], nsym)
    elapsed = time.perf_counter() - start
    calls_per_sec = N / elapsed
    print(f"ReedSolomonDecoder.correct_errors: {calls_per_sec:.2f} calls/sec")
    return calls_per_sec

def benchmark_warp_image():
    img = np.random.randint(0, 255, (100, 100), dtype=np.uint8)
    H = np.eye(3)
    output_size = (100, 100)
    N = 100
    start = time.perf_counter()
    for _ in range(N):
        PerspectiveTransformer.warp_image(img, H, output_size)
    elapsed = time.perf_counter() - start
    warps_per_sec = N / elapsed
    print(f"PerspectiveTransformer.warp_image: {warps_per_sec:.2f} warps/sec")
    return warps_per_sec

def calculate_pipeline_throughput(rs_calls_per_sec, warp_calls_per_sec, rs_per_qr=2, warp_per_qr=1):
    # Calculate how many QR decodes/sec each stage can support
    qr_by_rs = rs_calls_per_sec / rs_per_qr
    qr_by_warp = warp_calls_per_sec / warp_per_qr
    pipeline_throughput = min(qr_by_rs, qr_by_warp)
    print(f"\nEstimated pipeline throughput: {pipeline_throughput:.2f} QR codes/sec")
    print(f"(Limited by {'ReedSolomonDecoder.correct_errors' if qr_by_rs < qr_by_warp else 'PerspectiveTransformer.warp_image'})")

if __name__ == "__main__":
    rs_calls_per_sec = benchmark_rs_correct_errors()
    warp_calls_per_sec = benchmark_warp_image()
    # Adjust rs_per_qr and warp_per_qr as needed for your pipeline
    calculate_pipeline_throughput(rs_calls_per_sec, warp_calls_per_sec, rs_per_qr=2, warp_per_qr=1)