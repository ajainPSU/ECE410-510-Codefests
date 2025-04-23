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
import cv2
from scipy.ndimage import label, center_of_mass

image_path = "C:\\Users\\jaina\\OneDrive\\Documents\\410 Project\\QR-code1.png"

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
    @staticmethod
    def compute_homography(src_pts, dst_pts):
        A = []
        for (x, y), (u, v) in zip(src_pts, dst_pts):
            A.append([-x, -y, -1, 0, 0, 0, x * u, y * u, u])
            A.append([0, 0, 0, -x, -y, -1, x * v, y * v, v])
        A = np.array(A)
        _, _, Vt = np.linalg.svd(A)
        H = Vt[-1].reshape(3, 3)
        return H / H[2, 2]

    @staticmethod
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
    def __init__(self, trace_mode=False):
        self.gf = GF256()
        self.rs = ReedSolomonDecoder(self.gf)
        self.transformer = PerspectiveTransformer()
        self.trace_mode = trace_mode
        self.trace_log = []

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

    def decode_payload(self, bits, mode):
        if mode == "byte":
            n = int(bits[4:12], 2)
            chars = [chr(int(bits[12+i*8:20+i*8], 2)) for i in range(n)]
            return ''.join(chars)
        return "[mode not implemented]"

    def recognize(self, image_path, version=1, ec_bytes=7):
        img = self.load_image(image_path)
        binary = self.threshold_image(img)
        patterns = self.find_finder_patterns(binary)
        grid = self.extract_qr_grid(binary, patterns, version)

        bits = ''.join(str(int(b > 0)) for row in grid[:version*4] for b in row[:version*4])
        mode = self.decode_mode(bits)
        self.trace("qr_mode", mode)

        raw_data = [int(bits[i:i+8], 2) for i in range(0, len(bits), 8) if len(bits[i:i+8]) == 8]
        corrected = self.decode_codewords(raw_data, ec_bytes)

        payload = self.decode_payload(bits, mode)
        self.trace("decoded_payload", payload)
        return payload

if __name__ == "__main__":
    recognizer = QRCodeRecognizer(trace_mode=True)
    image_path = "QR-code1.png"  # Replace with the actual path to your QR code image
    recognizer.recognize(image_path)
