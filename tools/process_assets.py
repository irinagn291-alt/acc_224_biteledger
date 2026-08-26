#!/usr/bin/env python3
import json, os, struct, subprocess, zlib, math

ROOT = "/Users/belzephyrus/Documents/gambling/21AUG/App02_BiteLedger"
SRC = "/Users/belzephyrus/.cursor/projects/Users-belzephyrus-Documents-gambling-21AUG/assets"
CAT = os.path.join(ROOT, "BiteLedger", "Assets.xcassets")

SIZES = {
    "blg_AppIcon": (1024, 1024),
    "blg_Splash": (1290, 2796),
    "blg_Onboarding1": (1024, 1536),
    "blg_Onboarding2": (1024, 1536),
    "blg_Onboarding3": (1024, 1536),
    "blg_EmptyLog": (1024, 1024),
    "blg_EmptySearch": (1024, 1024),
    "blg_EmptyPlan": (1024, 1024),
    "blg_EmptyWish": (1024, 1024),
    "blg_SlotOpeningEntry": (512, 512),
    "blg_SlotMiddayEntry": (512, 512),
    "blg_SlotClosingEntry": (512, 512),
    "blg_SlotPettyCash": (512, 512),
    "blg_MacroProtein": (512, 512),
    "blg_MacroCarbs": (512, 512),
    "blg_MacroFat": (512, 512),
    "blg_ProductPlaceholder": (600, 600),
    "blg_CardBackdrop": (1200, 800),
    "blg_Texture": (2048, 2048),
    "blg_ControlFace": (512, 512),
    "blg_ScanOverlay": (1024, 1024),
    "blg_TwistHero": (1024, 1024),
    "blg_SuccessMark": (512, 512),
    "blg_HeaderDecor": (1200, 600),
}

COLORS = {
    "blg_background": ("0xF5", "0xF0", "0xE1"),
    "blg_surface": ("0xFF", "0xFD", "0xF5"),
    "blg_ink": ("0x3E", "0x2F", "0x1C"),
    "blg_accent": ("0xC0", "0x39", "0x2B"),
    "blg_muted": ("0xA0", "0x8B", "0x6F"),
}


def chunk(tag, data):
    crc = zlib.crc32(tag + data) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", crc)


def write_png(path, w, h, rows, alpha=True):
    raw = bytearray()
    for row in rows:
        raw.append(0)
        raw.extend(row)
    ihdr = struct.pack(">IIBBBBB", w, h, 8, 6 if alpha else 2, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


def make_texture(path, w=2048, h=2048):
    rows = []
    for y in range(h):
        row = bytearray(w * 3)
        ny = y / h
        for x in range(w):
            nx = x / w
            hatch = 0.55 + 0.10 * math.sin(2 * math.pi * (nx * 32 + ny * 2))
            hatch += 0.07 * math.sin(2 * math.pi * (ny * 28 - nx * 3))
            grain = 0.04 * math.sin(2 * math.pi * (nx * 97 + ny * 53))
            v = max(0.0, min(1.0, hatch + grain))
            r = int(245 * v + 62 * (1 - v) * 0.15)
            g = int(240 * v + 47 * (1 - v) * 0.15)
            b = int(225 * v + 28 * (1 - v) * 0.15)
            i = x * 3
            row[i] = min(255, r)
            row[i + 1] = min(255, g)
            row[i + 2] = min(255, b)
        rows.append(row)
    write_png(path, w, h, rows, alpha=False)


def make_scan_overlay(path, w=1024, h=1024):
    cx0, cy0, cx1, cy1 = int(w * 0.08), int(h * 0.40), int(w * 0.92), int(h * 0.60)
    rows = []
    for y in range(h):
        row = bytearray(w * 4)
        for x in range(w):
            i = x * 4
            inside = cx0 < x < cx1 and cy0 < y < cy1
            if inside:
                row[i:i + 4] = b"\x00\x00\x00\x00"
                continue
            edge = (
                (abs(x - cx0) < 3 or abs(x - cx1) < 3) and cy0 - 8 <= y <= cy1 + 8
            ) or (
                (abs(y - cy0) < 3 or abs(y - cy1) < 3) and cx0 - 8 <= x <= cx1 + 8
            )
            corner = False
            for bx, by in ((cx0, cy0), (cx1, cy0), (cx0, cy1), (cx1, cy1)):
                if abs(x - bx) < 36 and abs(y - by) < 36 and (abs(x - bx) < 5 or abs(y - by) < 5):
                    corner = True
            if edge or corner:
                row[i:i + 4] = bytes((62, 47, 28, 230))
            else:
                row[i:i + 4] = bytes((62, 47, 28, 120))
        rows.append(row)
    write_png(path, w, h, rows, alpha=True)


def imageset_json(filename):
    return {
        "images": [{"filename": filename, "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1},
    }


def colorset_json(r, g, b):
    return {
        "colors": [{
            "color": {
                "color-space": "srgb",
                "components": {"alpha": "1.000", "red": r, "green": g, "blue": b},
            },
            "idiom": "universal",
        }],
        "info": {"author": "xcode", "version": 1},
    }


def sips_resize(src, dest, w, h):
    subprocess.check_call(["sips", "-z", str(h), str(w), src, "--out", dest], stdout=subprocess.DEVNULL)


def flatten_icon(path):
    tmp = path + ".tmp.jpg"
    subprocess.check_call(["sips", "-s", "format", "jpeg", path, "--out", tmp], stdout=subprocess.DEVNULL)
    subprocess.check_call(["sips", "-s", "format", "png", tmp, "--out", path], stdout=subprocess.DEVNULL)
    os.remove(tmp)


def main():
    os.makedirs(CAT, exist_ok=True)
    for name, (r, g, b) in COLORS.items():
        d = os.path.join(CAT, f"{name}.colorset")
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, "Contents.json"), "w") as f:
            json.dump(colorset_json(r, g, b), f, indent=2)

    accent = os.path.join(CAT, "AccentColor.colorset")
    os.makedirs(accent, exist_ok=True)
    with open(os.path.join(accent, "Contents.json"), "w") as f:
        json.dump(colorset_json("0xC0", "0x39", "0x2B"), f, indent=2)

    for name, (w, h) in SIZES.items():
        dest_dir = os.path.join(CAT, f"{name}.imageset")
        os.makedirs(dest_dir, exist_ok=True)
        dest = os.path.join(dest_dir, f"{name}.png")
        src = os.path.join(SRC, f"{name}.png")
        if name == "blg_Texture":
            make_texture(dest, w, h)
        elif name == "blg_ScanOverlay":
            make_scan_overlay(dest, w, h)
        else:
            if not os.path.exists(src):
                raise SystemExit(f"missing {src}")
            sips_resize(src, dest, w, h)
            if name == "blg_AppIcon":
                flatten_icon(dest)
        with open(os.path.join(dest_dir, "Contents.json"), "w") as f:
            payload = imageset_json(f"{name}.png")
            if name == "blg_ScanOverlay":
                payload["properties"] = {"template-rendering-intent": "original", "preserves-vector-representation": False}
            json.dump(payload, f, indent=2)

    icon_set = os.path.join(CAT, "AppIcon.appiconset")
    os.makedirs(icon_set, exist_ok=True)
    icon_src = os.path.join(CAT, "blg_AppIcon.imageset", "blg_AppIcon.png")
    icon_dest = os.path.join(icon_set, "blg_AppIcon.png")
    subprocess.check_call(["cp", icon_src, icon_dest])
    with open(os.path.join(icon_set, "Contents.json"), "w") as f:
        json.dump({
            "images": [{
                "filename": "blg_AppIcon.png",
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024",
            }],
            "info": {"author": "xcode", "version": 1},
        }, f, indent=2)

    print("assets ready")


if __name__ == "__main__":
    main()
