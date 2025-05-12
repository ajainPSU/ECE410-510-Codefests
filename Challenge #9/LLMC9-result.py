import time
import tracemalloc
import functools
import sys
import inspect
import io
from contextlib import redirect_stdout
from qr_recognizer import QRCodeRecognizer

# Timing decorator
def profile_step(label):
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            print(f"[RUNNING] {label}...")
            start_time = time.perf_counter()
            tracemalloc.start()
            result = func(*args, **kwargs)
            current, peak = tracemalloc.get_traced_memory()
            end_time = time.perf_counter()
            print(f"[FINISHED] {label} in {(end_time - start_time):.4f}s")
            print(f" - Memory used: {current / 1024:.2f} KB; Peak: {peak / 1024:.2f} KB\n")
            tracemalloc.stop()
            return result
        return wrapper
    return decorator

class QRBenchmark:
    def __init__(self, image_path):
        self.image_path = image_path
        self.qr = QRCodeRecognizer()
        self.intermediate = {}

    @profile_step("Load Image")
    def step_load_image(self):
        img = self.qr.load_image(self.image_path)
        self.intermediate["img"] = img
        print(f" - Image shape: {img.shape}")
        return img

    @profile_step("Threshold Image")
    def step_threshold(self):
        binary = self.qr.threshold_image(self.intermediate["img"])
        self.intermediate["binary"] = binary
        print(f" - Binary shape: {binary.shape}")
        return binary

    @profile_step("Find Position Patterns")
    def step_patterns(self):
        patterns = self.qr.find_position_patterns(self.intermediate["binary"])
        self.intermediate["patterns"] = patterns
        print(f" - Found {len(patterns)} patterns: {patterns}")
        return patterns

    @profile_step("Extract QR Grid")
    def step_grid(self):
        qr_grid = self.qr.extract_qr_grid(self.intermediate["binary"])
        self.intermediate["qr_grid"] = qr_grid
        print(f" - Grid shape: {qr_grid.shape if qr_grid is not None else 'None'}")
        return qr_grid

    @profile_step("Decode QR Code")
    def step_decode(self):
        result = self.qr.decode_qr_code(self.intermediate["qr_grid"])
        print(f" - Decode result: {result}")
        return result

    def run_all(self):
        print("=== QR Code Benchmark Analyzer ===")
        self.step_load_image()
        self.step_threshold()
        self.step_patterns()
        self.step_grid()
        self.step_decode()

# Optional: Call graph output
def generate_call_graph(cls):
    print("\n=== Call Graph ===")
    members = inspect.getmembers(cls, predicate=inspect.isfunction)
    for name, _ in members:
        print(f" - {cls.__name__}.{name}()")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python benchmark_qr.py <path_to_image>")
        sys.exit(1)

    image_path = sys.argv[1]
    benchmark = QRBenchmark(image_path)
    benchmark.run_all()
    generate_call_graph(QRCodeRecognizer)
