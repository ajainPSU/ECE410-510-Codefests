'''
Alex Jain, April 23, 2025
QR Code Benchmark Analyzer

This script is an extension of the QR code detector and decoder
provided by Prof. Christof Tuescher via Claude.

This code was generated with GPT 4o and is the first step of the project.
'''

import numpy as np
import time
import tracemalloc
import functools
import inspect
import matplotlib.pyplot as plt
from PIL import Image
import sys
from qr_recognizer import QRCodeRecognizer  # Ensure this is in the same folder or adjust path

# --- Profiling Decorator --- # 
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

# --- Galois Field GF(256) Debugger --- #
class GF256:
    def __init__(self, prim=0x11D):
        self.prim = prim
        self.exp = [0] * 512
        self.log = [0] * 256
        self._init_tables()

    def _init_tables(self):
        x = 1
        for i in range(255):
            self.exp[i] = x
            self.log[x] = i
            x <<= 1
            if x & 0x100:
                x ^= self.prim
        for i in range(255, 512):
            self.exp[i] = self.exp[i - 255]

    def mul(self, a, b):
        if a == 0 or b == 0:
            return 0
        return self.exp[self.log[a] + self.log[b]]

    def inv(self, a):
        return self.exp[255 - self.log[a]]

    def debug_mul_table(self):
        print("Galois Field Multiplication Table (Partial):")
        for i in range(1, 16):
            row = [self.mul(i, j) for j in range(1, 16)]
            print(f"{i:2} | " + " ".join(f"{x:02X}" for x in row))

# --- Matrix Visualizer --- #
def plot_matrix(matrix, title="Matrix"):
    plt.figure(figsize=(6, 6))
    plt.imshow(matrix, cmap='gray', interpolation='nearest')
    plt.title(title)
    plt.axis('off')
    plt.show()

# --- QR Benchmark Analyzer --- #
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
        plot_matrix(img, "Grayscale Image")
        return img

    @profile_step("Threshold Image")
    def step_threshold(self):
        binary = self.qr.threshold_image(self.intermediate["img"])
        self.intermediate["binary"] = binary
        print(f" - Binary shape: {binary.shape}")
        plot_matrix(binary, "Thresholded Binary Image")
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
        if qr_grid is not None:
            plot_matrix(qr_grid, "Extracted QR Grid")
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

# --- Call Graph Generator --- #
def generate_call_graph(cls):
    print("\n=== Call Graph ===")
    members = inspect.getmembers(cls, predicate=inspect.isfunction)
    for name, _ in members:
        print(f" - {cls.__name__}.{name}()")

# --- Main Entry --- #
if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python benchmark_qr.py <image_path>")
        sys.exit(1)

    image_path = sys.argv[1]

    # Run QR Analyzer Benchmark
    benchmark = QRBenchmark(image_path)
    benchmark.run_all()

    # Optional: Print Call Graph
    generate_call_graph(QRCodeRecognizer)

    # Show GF(256) Table
    gf_debugger = GF256()
    gf_debugger.debug_mul_table()
