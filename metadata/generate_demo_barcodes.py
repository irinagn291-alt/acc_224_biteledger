#!/usr/bin/env python3
"""Write an EAN-13 PPM for App Review, then convert with sips."""

from pathlib import Path

CODE = "7394376616037"

L = {
    "0": "0001101", "1": "0011001", "2": "0010011", "3": "0111101", "4": "0100011",
    "5": "0110001", "6": "0101111", "7": "0111011", "8": "0110111", "9": "0001011",
}
G = {
    "0": "0100111", "1": "0110011", "2": "0011011", "3": "0100001", "4": "0011101",
    "5": "0111001", "6": "0000101", "7": "0010001", "8": "0001001", "9": "0010111",
}
R = {
    "0": "1110010", "1": "1100110", "2": "1101100", "3": "1000010", "4": "1011100",
    "5": "1001110", "6": "1010000", "7": "1000100", "8": "1001000", "9": "1110100",
}
PARITY = {
    "0": "LLLLLL", "1": "LLGLGG", "2": "LLGGLG", "3": "LLGGGL", "4": "LGLLGG",
    "5": "LGGLLG", "6": "LGGGLL", "7": "LGLGLG", "8": "LGLGGL", "9": "LGGLGL",
}


def encode(code: str) -> str:
    first, left, right = code[0], code[1:7], code[7:]
    bits = ["101"]
    for digit, kind in zip(left, PARITY[first]):
        bits.append(L[digit] if kind == "L" else G[digit])
    bits.append("01010")
    for digit in right:
        bits.append(R[digit])
    bits.append("101")
    return "".join(bits)


def write_ppm(path: Path, code: str) -> None:
    pattern = encode(code)
    quiet = 10
    module_w = 6
    bar_h = 220
    text_h = 56
    width = (len(pattern) + quiet * 2) * module_w
    height = bar_h + text_h
    pixels = bytearray()
    for y in range(height):
        for x in range(width):
            if y >= bar_h:
                pixels.extend(b"\xff\xff\xff")
                continue
            idx = x // module_w - quiet
            on = 0 <= idx < len(pattern) and pattern[idx] == "1"
            pixels.extend(b"\x00\x00\x00" if on else b"\xff\xff\xff")
    path.write_bytes(f"P6\n{width} {height}\n255\n".encode("ascii") + pixels)


if __name__ == "__main__":
    dest = Path(__file__).resolve().parent / "demo-ean13-oat-milk.ppm"
    write_ppm(dest, CODE)
    print(dest)
