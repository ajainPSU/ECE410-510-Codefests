import unittest
import numpy as np
from IB2 import QRCodeRecognizer  # Assuming QRCodeRecognizer is in IB2.py

class TestQRCodeRecognizer(unittest.TestCase):
    def setUp(self):
        self.recognizer = QRCodeRecognizer(trace_mode=False)

    # --- Format Information Tests ---
    def test_extract_format_information(self):
        # Mock a QR code grid with known format information
        grid = np.zeros((21, 21), dtype=np.uint8)
        # Add mock format information bits (replace with actual test data)
        grid[8, :6] = [1, 0, 1, 0, 1, 0]
        grid[8, 7] = 1
        grid[8, 8] = 0
        grid[:6, 8] = [1, 0, 1, 0, 1, 0][::-1]

        format_info = self.recognizer.extract_format_information(grid)
        self.assertEqual(format_info["error_correction"], "M")
        self.assertEqual(format_info["mask_pattern"], 0)

    # --- Masking Tests ---
    def test_unmask_data(self):
        # Mock a QR code grid with a known mask pattern
        grid = np.array([
            [1, 0, 1, 0, 1],
            [0, 1, 0, 1, 0],
            [1, 0, 1, 0, 1],
            [0, 1, 0, 1, 0],
            [1, 0, 1, 0, 1]
        ], dtype=np.uint8)

        # Apply mask pattern 0
        unmasked = self.recognizer.unmask_data(grid, mask_pattern=0)

        # Expected result after unmasking
        expected = np.array([
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0]
        ], dtype=np.uint8)

        self.assertTrue((unmasked == expected).all())

    # --- Codeword Reading Tests ---
    def test_read_codewords(self):
        # Mock a QR code grid (21x21 for version 1)
        grid = np.zeros((21, 21), dtype=np.uint8)
        # Fill the grid with a simple pattern for testing
        for i in range(21):
            for j in range(21):
                if not self.recognizer.is_function_pattern(i, j, 21):
                    grid[i, j] = (i + j) % 2  # Alternating pattern

        # Read codewords
        codewords = self.recognizer.read_codewords(grid)

        # Verify the extracted codewords (expected values depend on the test pattern)
        self.assertIsInstance(codewords, list)
        self.assertTrue(all(0 <= cw < 256 for cw in codewords))  # Each codeword is 8 bits

    # --- Payload Decoding Tests ---
    def test_decode_payload_numeric(self):
        bits = "000101000110010001001"  # Numeric mode, "12345"
        mode = "numeric"
        version = 1
        result = self.recognizer.decode_payload(bits, mode, version)
        self.assertEqual(result, "12345")

    def test_decode_payload_alphanumeric(self):
        bits = "001000001101010001011001"  # Alphanumeric mode, "HELLO"
        mode = "alphanumeric"
        version = 1
        result = self.recognizer.decode_payload(bits, mode, version)
        self.assertEqual(result, "HELLO")

    def test_decode_payload_byte(self):
        bits = "010000000110100001100101011011000110110001101111"  # Byte mode, "hello"
        mode = "byte"
        version = 1
        result = self.recognizer.decode_payload(bits, mode, version)
        self.assertEqual(result, "hello")

    def test_decode_payload_kanji(self):
        bits = "100000000110110000101101"  # Kanji mode, single character
        mode = "kanji"
        version = 1
        result = self.recognizer.decode_payload(bits, mode, version)
        self.assertTrue(len(result) > 0)  # Ensure it decodes something

    def test_decode_payload_invalid(self):
        bits = "1111000000000000"  # Invalid mode
        mode = "unknown"
        version = 1
        result = self.recognizer.decode_payload(bits, mode, version)
        self.assertEqual(result, "[mode not supported]")

# Run the tests
if __name__ == "__main__":
    unittest.main()
