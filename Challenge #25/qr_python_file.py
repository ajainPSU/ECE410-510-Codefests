'''
Alex Jain, April 23, 2025
QR Code Analyzer

This script is an extension of the QR code detector and decoder
provided by Prof. Christof Tuescher via Claude.

This code was generated with GPT 4o & Copilot and is the first step of the project.
'''

import math
import numpy as np
from PIL import Image
from scipy.ndimage import label, center_of_mass

image_path = "C:\\Users\\jaina\\OneDrive\\Documents\\410 Project\\QR-code1.png"

import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, Timer

# Cocotb SPI Master Class (GPT 4o)
class SpiMaster:
    def __init__(self, clk, mosi, miso, cs, clk_period=1000):
        self.clk = clk
        self.mosi = mosi
        self.miso = miso
        self.cs = cs
        self.clk_period = clk_period  # ns

    async def transfer(self, byte_list):
        await FallingEdge(self.cs)  # Begin transaction
        result = []
        for byte in byte_list:
            read = 0
            for i in range(8):
                self.mosi.value = (byte >> (7 - i)) & 1
                await Timer(self.clk_period // 2, units="ns")
                self.clk.value = 1
                await Timer(self.clk_period // 2, units="ns")
                read = (read << 1) | int(self.miso.value)
                self.clk.value = 0
            result.append(read)
        await RisingEdge(self.cs)  # End transaction
        return result

import struct

async def send_to_hw_for_warp(spi, image, H, size):
    CMD = [0x01]
    h_bytes = b''.join(struct.pack('<f', f) for f in H.flatten())
    img_bytes = image.astype(np.uint8).flatten().tolist()

    tx_data = CMD + list(h_bytes) + img_bytes
    rx_data = await spi.transfer(tx_data)

    return np.array(rx_data[-(size * size):], dtype=np.uint8).reshape((size, size))

async def send_to_hw_for_correction(spi, codewords, ec_bytes):
    CMD = [0x02]
    tx_data = CMD + [len(codewords), ec_bytes] + codewords
    rx_data = await spi.transfer(tx_data)
    return rx_data[-len(codewords):]


# --- GF(256) Arithmetic --- #
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

    def div(self, a, b):
        if b == 0:
            raise ZeroDivisionError("Division by zero in GF256 arithmetic")
        return self.exp[(self.log[a] - self.log[b]) % 255]

    def poly_eval(self, poly, x):
        result = 0
        for coef in poly:
            result = self.mul(result, x) ^ coef
        return result

# --- Reed-Solomon Decoder --- #
class ReedSolomonDecoder:
    def __init__(self, gf):
        self.gf = gf

    def calculate_syndromes(self, msg, nsym):
        return [self.gf.poly_eval(msg, self.gf.exp[i]) for i in range(nsym)]

    def correct_errors(self, msg, nsym):  # Properly indented to be part of the class
        syndromes = self.calculate_syndromes(msg, nsym)
        if max(syndromes) == 0:
            return msg  # No errors

        err_loc = [1]
        old_loc = [1]
        for i in range(nsym):
            delta = syndromes[i]
            for j in range(1, len(err_loc)):
                delta ^= self.gf.mul(err_loc[-(j+1)], syndromes[i - j])
            old_loc.append(0)
            if delta != 0:
                if len(old_loc) > len(err_loc):
                    new_loc = [c for c in old_loc]
                    if self.gf.poly_eval(old_loc, 0) == 0:
                        print(f"Error: old_loc evaluates to zero at iteration {i}")
                        return msg  # Fallback to uncorrected data
                    scale = self.gf.div(delta, self.gf.poly_eval(old_loc, 0))
                    old_loc = [self.gf.mul(c, scale) for c in err_loc]
                    err_loc = new_loc
                err_loc = [c ^ self.gf.mul(delta, t) for c, t in zip(err_loc + [0], old_loc)]

        err_pos = []
        for i in range(len(msg)):
            if self.gf.poly_eval(err_loc, self.gf.exp[255 - i]) == 0:
                err_pos.append(i)
        if len(err_pos) != len(err_loc) - 1:
            raise ValueError("Too many errors to correct")

        for pos in err_pos:
            x = self.gf.exp[255 - pos]
            y = self.gf.poly_eval(syndromes[::-1], x)
            denom = 1
            for i in range(len(err_loc)):
                if i != pos:
                    denom = self.gf.mul(denom, x ^ self.gf.exp[255 - i])
            if denom == 0:
                print(f"Error: Denominator evaluates to zero at position {pos}")
                return msg  # Fallback to uncorrected data
            err_mag = self.gf.div(y, denom)
            msg[pos] ^= err_mag

        return msg

# --- Perspective Transformation --- #
class PerspectiveTransformer:
    def compute_homography(src_pts, dst_pts):
        A = []
        for (x, y), (u, v) in zip(src_pts, dst_pts):
            A.append([-x, -y, -1, 0, 0, 0, x * u, y * u, u])
            A.append([0, 0, 0, -x, -y, -1, x * v, y * v, v])
        A = np.array(A)
        _, _, Vt = np.linalg.svd(A)
        H = Vt[-1].reshape(3, 3)
        return H / H[2, 2]

    def warp_image(image, H, output_size):
        height, width = output_size
        warped = np.zeros((height, width), dtype=np.uint8)
        H_inv = np.linalg.inv(H)

        for y in range(height):
            for x in range(width):
                pt = np.array([x, y, 1])
                dst = H_inv @ pt
                dst /= dst[2]
                ix, iy = int(round(dst[0])), int(round(dst[1]))
                if 0 <= ix < image.shape[1] and 0 <= iy < image.shape[0]:
                    warped[y, x] = image[iy, ix]
        return warped

# --- QRCodeRecognizer class with decoding + hardware trace --- #
class QRCodeRecognizer:
    def __init__(self, trace_mode=False, hardware_mode=False, spi=None):
        self.gf = GF256()
        self.rs = ReedSolomonDecoder(self.gf)
        self.transformer = PerspectiveTransformer()
        self.trace_mode = trace_mode
        self.trace_log = []

        self.hardware_mode = hardware_mode
        self.spi = spi # Cocotb SPI instance

        if self.hardware_mode:
            # Override SW with HW or bypass
            self.rs.correct_errors = self.correct_errors_hw
            self.transformer.warp_image = self.warp_image_hw

    async def correct_errors_hw(self, msg, nsym):
        if self.spi is None:
            raise RuntimeError("SPI not connected")
        corrected = await send_to_hw_for_correction(self.spi, msg, nsym)
        self.trace("correct_errors_hw", corrected)
        return corrected

    async def warp_image_hw(self, image, H, output_size):
        if self.spi is None:
            raise RuntimeError("SPI not connected")
        warped = await send_to_hw_for_warp(self.spi, image, H, output_size[0])
        self.trace("warp_image_hw", warped.tolist())
        return warped
    
    # Original Software Below

    def trace(self, label, data=None):
        if self.trace_mode:
            entry = {"label": label, "data": data}
            self.trace_log.append(entry)
            print("[TRACE]", entry)

    def load_image(self, image_path):
        img = Image.open(image_path).convert('L')
        arr = np.array(img)
        self.trace("load_image", {"shape": arr.shape})
        return arr

    def threshold_image(self, img):
        threshold = np.mean(img)
        binary = (img > threshold).astype(np.uint8) * 255
        self.trace("threshold_image", {"threshold": threshold})
        return binary

    def find_finder_patterns(self, binary):
        label_img, num = label(binary)
        centers = center_of_mass(binary, label_img, range(1, num + 1))
        candidates = [tuple(map(int, c)) for c in centers if c[0] < binary.shape[0] and c[1] < binary.shape[1]]
        candidates.sort(key=lambda c: (c[0], c[1]))
        self.trace("finder_patterns", candidates[:3])
        return candidates[:3]

    def extract_qr_grid(self, img, finder_patterns, version=1):
        tl, tr, bl = finder_patterns
        module_count = 21 + (version - 1) * 4
        br = (tr[0] - tl[0] + bl[0], tr[1] - tl[1] + bl[1])
        src_pts = [tl, tr, br, bl]
        dst_pts = [(0, 0), (module_count - 1, 0), (module_count - 1, module_count - 1), (0, module_count - 1)]
        H = self.transformer.compute_homography(src_pts, dst_pts)
        warped = self.transformer.warp_image(img, H, (module_count, module_count))
        self.trace("homography_matrix", H.tolist())
        return (warped > 128).astype(np.uint8)

    def extract_format_information(self, grid):
        FORMAT_MASK = 0b101010000010010
        format_bits_1 = []
        for i in range(6):
            format_bits_1.append(grid[8, i])
        format_bits_1.append(grid[8, 7])
        format_bits_1.append(grid[8, 8])
        format_bits_1.append(grid[7, 8])
        for i in range(5, -1, -1):
            format_bits_1.append(grid[i, 8])
        format_bits_2 = []
        for i in range(grid.shape[0] - 1, grid.shape[0] - 8, -1):
            format_bits_2.append(grid[i, 8])
        for i in range(grid.shape[1] - 8, grid.shape[1]):
            format_bits_2.append(grid[8, i])
        format_bits_1 = int(''.join(map(str, format_bits_1)), 2)
        format_bits_2 = int(''.join(map(str, format_bits_2)), 2)
        format_bits_1 ^= FORMAT_MASK
        format_bits_2 ^= FORMAT_MASK
        format_bits = format_bits_1
        error_correction_level = (format_bits >> 13) & 0b11
        mask_pattern = (format_bits >> 10) & 0b111
        ec_level_map = {
            0b01: "L",
            0b00: "M",
            0b11: "Q",
            0b10: "H"
        }
        error_correction = ec_level_map.get(error_correction_level, "Unknown")
        return {
            "error_correction": error_correction,
            "mask_pattern": mask_pattern,
            "raw_format": format_bits
        }

    def validate_format_information(self, format_bits):
        BCH_POLY = 0b10100110111
        error_code = format_bits & 0b1111111111
        remainder = format_bits >> 10
        for _ in range(5):
            if remainder & (1 << 10):
                remainder ^= BCH_POLY
            remainder <<= 1
        return remainder == 0

    def unmask_data(self, grid, mask_pattern):
        unmasked = grid.copy()
        size = grid.shape[0]
        for row in range(size):
            for col in range(size):
                if self.is_function_pattern(row, col, size):
                    continue
                if self.is_masked(row, col, mask_pattern):
                    unmasked[row, col] ^= 1
        return unmasked

    def is_function_pattern(self, row, col, size):
        if (row < 9 and col < 9) or (row < 9 and col >= size - 8) or (row >= size - 8 and col < 9):
            return True
        if row == 6 or col == 6:
            return True
        if (row == 8 and col < 9) or (col == 8 and row < 9) or (row == 8 and col >= size - 8) or (col == 8 and row >= size - 8):
            return True
        return False

    def is_masked(self, row, col, mask_pattern):
        if mask_pattern == 0:
            return (row + col) % 2 == 0
        elif mask_pattern == 1:
            return row % 2 == 0
        elif mask_pattern == 2:
            return col % 3 == 0
        elif mask_pattern == 3:
            return (row + col) % 3 == 0
        elif mask_pattern == 4:
            return (row // 2 + col // 3) % 2 == 0
        elif mask_pattern == 5:
            return ((row * col) % 2) + ((row * col) % 3) == 0
        elif mask_pattern == 6:
            return (((row * col) % 2) + ((row * col) % 3)) % 2 == 0
        elif mask_pattern == 7:
            return (((row + col) % 2) + ((row * col) % 3)) % 2 == 0
        return False

    def read_codewords(self, grid):
        size = grid.shape[0]
        codewords = []
        current_bits = []
        col = size - 1
        while col > 0:
            if col == 6:
                col -= 1
            for row in (range(size - 1, -1, -1) if col % 2 == 1 else range(size)):
                if not self.is_function_pattern(row, col, size):
                    current_bits.append(grid[row, col])
                    if len(current_bits) == 8:
                        codewords.append(int(''.join(map(str, current_bits)), 2))
                        current_bits = []
                if not self.is_function_pattern(row, col - 1, size):
                    current_bits.append(grid[row, col - 1])
                    if len(current_bits) == 8:
                        codewords.append(int(''.join(map(str, current_bits)), 2))
                        current_bits = []
            col -= 2
        if current_bits:
            codewords.append(int(''.join(map(str, current_bits)).ljust(8, '0'), 2))
        return codewords

    def decode_codewords(self, codewords, ec_bytes):
        corrected = self.rs.correct_errors(codewords[:], ec_bytes)
        self.trace("corrected_codewords", corrected)
        return corrected

    def decode_mode(self, bits):
        mode_indicator = bits[:4]
        return {
            '0001': "numeric",
            '0010': "alphanumeric",
            '0100': "byte",
            '1000': "kanji"
        }.get(mode_indicator, "unknown")

    def decode_payload(self, bits, mode, version):
        try:
            if version <= 9:
                char_count_bits = {"numeric": 10, "alphanumeric": 9, "byte": 8, "kanji": 8}[mode]
            elif version <= 26:
                char_count_bits = {"numeric": 12, "alphanumeric": 11, "byte": 16, "kanji": 12}[mode]
            else:
                raise ValueError("Unsupported QR code version")
            n = int(bits[4:4 + char_count_bits], 2)
            if mode == "numeric":
                digits = []
                i = 4 + char_count_bits
                while i < len(bits):
                    if n >= 3:
                        digits.append(int(bits[i:i+10], 2))
                        i += 10
                        n -= 3
                    elif n == 2:
                        digits.append(int(bits[i:i+7], 2))
                        i += 7
                        n -= 2
                    elif n == 1:
                        digits.append(int(bits[i:i+4], 2))
                        i += 4
                        n -= 1
                return ''.join(str(d) for d in digits)
            elif mode == "alphanumeric":
                ALPHANUMERIC_TABLE = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:"
                chars = []
                i = 4 + char_count_bits
                while i < len(bits):
                    if n >= 2:
                        pair = int(bits[i:i+11], 2)
                        chars.append(ALPHANUMERIC_TABLE[pair // 45])
                        chars.append(ALPHANUMERIC_TABLE[pair % 45])
                        i += 11
                        n -= 2
                    elif n == 1:
                        char = int(bits[i:i+6], 2)
                        chars.append(ALPHANUMERIC_TABLE[char])
                        i += 6
                        n -= 1
                return ''.join(chars)
            elif mode == "byte":
                chars = []
                i = 4 + char_count_bits
                for _ in range(n):
                    chars.append(chr(int(bits[i:i+8], 2)))
                    i += 8
                return ''.join(chars)
            elif mode == "kanji":
                chars = []
                i = 4 + char_count_bits
                for _ in range(n):
                    kanji_code = int(bits[i:i+13], 2)
                    i += 13
                    if kanji_code >= 0x1F00:
                        kanji_code += 0xC140
                    else:
                        kanji_code += 0x8140
                    high_byte = (kanji_code >> 8) & 0xFF
                    low_byte = kanji_code & 0xFF
                    chars.append(bytes([high_byte, low_byte]).decode('shift_jis', errors='replace'))
                return ''.join(chars)
            else:
                return "[mode not supported]"
        except Exception as e:
            print(f"Error decoding payload: {e}")
            return "[decoding error]"

    def recognize(self, image_path, version=1, ec_bytes=7):
        if version < 1 or version > 10:
            raise ValueError("Unsupported QR code version. Supported versions are 1-10.")
        img = self.load_image(image_path)
        binary = self.threshold_image(img)
        patterns = self.find_finder_patterns(binary)
        grid = self.extract_qr_grid(binary, patterns, version)
        expected_size = 21 + (version - 1) * 4
        if grid.shape[0] != expected_size or grid.shape[1] != expected_size:
            raise ValueError(f"Extracted grid size {grid.shape} does not match expected size {expected_size}")
        format_info = self.extract_format_information(grid)
        self.trace("format_information", format_info)
        mask_pattern = format_info["mask_pattern"]
        unmasked_grid = self.unmask_data(grid, mask_pattern)
        self.trace("unmasked_grid", unmasked_grid.tolist())
        codewords = self.read_codewords(unmasked_grid)
        self.trace("codewords", codewords)
        # The following lines may need adjustment depending on your codeword/bits logic
        bits = ''.join(f"{byte:08b}" for byte in codewords)
        mode = self.decode_mode(bits)
        self.trace("qr_mode", mode)
        payload = self.decode_payload(bits, mode, version)
        if payload.startswith("[decoding error]"):
            raise ValueError("Failed to decode QR code payload.")
        self.trace("decoded_payload", payload)
        return payload

if __name__ == "__main__":
    recognizer = QRCodeRecognizer(trace_mode=True, hardware_mode=True)
    image_path = "QR-code1.png"  # Replace with the actual path to your QR code image
    recognizer.recognize(image_path)
