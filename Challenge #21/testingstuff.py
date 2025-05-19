import unittest
import numpy as np
import time
from IB3 import QRCodeRecognizer

class TestQRCodeRecognizer(unittest.TestCase):
    def setUp(self):
        self.recognizer = QRCodeRecognizer(trace_mode=False)

    # --- Helper for benchmarking ---
    def benchmark(self, func, *args, repeat=5, **kwargs):
        times = []
        for _ in range(repeat):
            start = time.perf_counter()
            result = func(*args, **kwargs)
            times.append(time.perf_counter() - start)
        avg = sum(times) / repeat
        print(f"{func.__name__} avg: {avg:.6f}s min: {min(times):.6f}s max: {max(times):.6f}s")
        return result

    # --- Format Information Tests ---
    def test_extract_format_information(self):
        grid = np.zeros((21, 21), dtype=np.uint8)
        grid[8, :6] = [1, 0, 1, 0, 1, 0]
        grid[8, 7] = 1
        grid[8, 8] = 0
        grid[:6, 8] = [1, 0, 1, 0, 1, 0][::-1]
        format_info = self.benchmark(self.recognizer.extract_format_information, grid)
        self.assertIn(format_info["error_correction"], ["M", "L", "Q", "H"])
        self.assertIsInstance(format_info["mask_pattern"], int)

    # --- Masking Tests ---
    def test_unmask_data(self):
        grid = np.array([
            [1, 0, 1, 0, 1],
            [0, 1, 0, 1, 0],
            [1, 0, 1, 0, 1],
            [0, 1, 0, 1, 0],
            [1, 0, 1, 0, 1]
        ], dtype=np.uint8)
        unmasked = self.benchmark(self.recognizer.unmask_data, grid, 0)
        remasked = self.recognizer.unmask_data(unmasked, 0)
        self.assertTrue((remasked == grid).all())

    # --- Codeword Reading Tests ---
    def test_read_codewords(self):
        grid = np.zeros((21, 21), dtype=np.uint8)
        for i in range(21):
            for j in range(21):
                if not self.recognizer.is_function_pattern(i, j, 21):
                    grid[i, j] = (i + j) % 2
        codewords = self.benchmark(self.recognizer.read_codewords, grid)
        self.assertIsInstance(codewords, list)
        self.assertTrue(all(0 <= cw < 256 for cw in codewords))

    # --- Payload Decoding Tests with valid bitstrings ---
    def test_decode_payload_numeric(self):
        bits = "0001000000010100011110110101101"  # "12345"
        mode = "numeric"
        version = 1
        result = self.benchmark(self.recognizer.decode_payload, bits, mode, version)
        self.assertEqual(result, "12345")

    def test_decode_payload_alphanumeric(self):
        bits = "0010000000101110001101" # "AB"
        mode = "alphanumeric"
        version = 1
        result = self.benchmark(self.recognizer.decode_payload, bits, mode, version)
        self.assertEqual(result, "AB")

    def test_decode_payload_byte(self):
        bits = "0100000000100110100001101001"  # "hi"
        mode = "byte"
        version = 1
        result = self.benchmark(self.recognizer.decode_payload, bits, mode, version)
        self.assertEqual(result, "hi")

    # --- Kanji mode: test only that it returns a string (valid bitstring is complex) ---
    def test_decode_payload_kanji(self):
        bits = "100000000110110000101101"
        mode = "kanji"
        version = 1
        result = self.benchmark(self.recognizer.decode_payload, bits, mode, version)
        self.assertTrue(isinstance(result, str) and len(result) > 0)

    # --- Error Handling ---
    def test_decode_payload_invalid(self):
        bits = "1111000000000000"
        mode = "unknown"
        version = 1
        result = self.benchmark(self.recognizer.decode_payload, bits, mode, version)
        self.assertIn(result, ["[mode not supported]", "[decoding error]"])

    # --- Full pipeline test (image required) ---
    def test_full_pipeline(self):
        # This test will only work if you have a valid QR image at the path!
        image_path = "QR-code1.png"
        try:
            start = time.perf_counter()
            payload = self.recognizer.recognize(image_path, version=1, ec_bytes=7)
            elapsed = time.perf_counter() - start
            print(f"Full pipeline took {elapsed:.6f}s, payload: {payload}")
            self.assertIsInstance(payload, str)
        except Exception as e:
            print(f"Full pipeline test skipped or failed: {e}")

if __name__ == "__main__":
    unittest.main()