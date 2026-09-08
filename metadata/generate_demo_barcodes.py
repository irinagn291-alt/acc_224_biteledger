#!/usr/bin/env python3
"""Write App Review QR and EAN-13 PNGs for the bundled oat-milk code."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont
import segno

CODE = "7394376616037"
ROOT = Path(__file__).resolve().parent

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


def encode_ean13(code: str) -> str:
    first, left, right = code[0], code[1:7], code[7:]
    bits = ["101"]
    for digit, kind in zip(left, PARITY[first]):
        bits.append(L[digit] if kind == "L" else G[digit])
    bits.append("01010")
    for digit in right:
        bits.append(R[digit])
    bits.append("101")
    return "".join(bits)


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    name = "Arial Bold.ttf" if bold else "Arial.ttf"
    path = Path("/System/Library/Fonts/Supplemental") / name
    if path.exists():
        return ImageFont.truetype(str(path), size)
    return ImageFont.load_default()


def write_qr() -> Path:
    qr = segno.make(CODE, error="M", micro=False)
    raw = ROOT / "demo-qr-oat-milk-1bit.png"
    qr.save(raw, scale=36, border=6, dark="#000000", light="#FFFFFF")
    rgb = Image.open(raw).convert("RGB")
    out = ROOT / "demo-qr-oat-milk.png"
    rgb.save(out, "PNG")
    raw.unlink(missing_ok=True)

    card_w, card_h = 1400, 1700
    card = Image.new("RGB", (card_w, card_h), (255, 255, 255))
    side = 1100
    fitted = rgb.resize((side, side), Image.Resampling.NEAREST)
    card.paste(fitted, ((card_w - side) // 2, 80))
    draw = ImageDraw.Draw(card)
    lines = [
        (font(42, bold=True), "BiteLedger App Review — demo QR"),
        (font(32), "Oat Milk  •  EAN-13  7394376616037"),
        (font(28), "Open Scan, fill the red square, hold still."),
    ]
    y = 80 + side + 40
    for face, line in lines:
        bbox = draw.textbbox((0, 0), line, font=face)
        tw = bbox[2] - bbox[0]
        draw.text(((card_w - tw) // 2, y), line, fill=(0, 0, 0), font=face)
        y += (bbox[3] - bbox[1]) + 16
    card_path = ROOT / "demo-qr-oat-milk-card.png"
    card.save(card_path, "PNG")
    print(f"qr {out} {rgb.size} version={qr.designator}")
    print(f"card {card_path}")
    return out


def write_ean13() -> Path:
    pattern = encode_ean13(CODE)
    quiet = 12
    module_w = 10
    bar_h = 360
    text_h = 80
    width = (len(pattern) + quiet * 2) * module_w
    height = bar_h + text_h
    image = Image.new("RGB", (width, height), (255, 255, 255))
    pixels = image.load()
    for y in range(bar_h):
        for x in range(width):
            idx = x // module_w - quiet
            if 0 <= idx < len(pattern) and pattern[idx] == "1":
                pixels[x, y] = (0, 0, 0)
    draw = ImageDraw.Draw(image)
    label = " ".join([CODE[0], CODE[1:7], CODE[7:]])
    face = font(36)
    bbox = draw.textbbox((0, 0), label, font=face)
    tw = bbox[2] - bbox[0]
    draw.text(((width - tw) // 2, bar_h + 18), label, fill=(0, 0, 0), font=face)
    out = ROOT / "demo-ean13-oat-milk.png"
    image.save(out, "PNG")
    print(f"ean {out} {image.size}")
    return out


if __name__ == "__main__":
    write_qr()
    write_ean13()
