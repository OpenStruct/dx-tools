#!/usr/bin/env python3
"""Generate DX Tools app icon — Premium 'DX' monogram with orange gradient on dark background"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os, json, math

SIZES = [16, 32, 64, 128, 256, 512, 1024]
OUTPUT_DIR = "DXTools/Assets.xcassets/AppIcon.appiconset"

def lerp(a, b, t):
    return int(a + (b - a) * t)

def generate_icon(size):
    s = size * 4
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    margin = int(s * 0.08)
    radius = int(s * 0.22)
    inner = (margin, margin, s - margin, s - margin)

    # === Background gradient (deep warm dark) ===
    for y in range(margin, s - margin):
        t = (y - margin) / (s - 2 * margin)
        r = lerp(24, 14, t)
        g = lerp(20, 12, t)
        b = lerp(22, 14, t)
        draw.line([(margin, y), (s - margin - 1, y)], fill=(r, g, b, 255))

    # === Subtle radial glow in center (warm orange) ===
    glow = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    cx, cy = s // 2, int(s * 0.45)
    glow_radius = int(s * 0.32)
    for i in range(glow_radius, 0, -1):
        alpha = int(30 * (1 - (i / glow_radius) ** 2))
        glow_draw.ellipse(
            [cx - i, cy - i, cx + i, cy + i],
            fill=(255, 140, 66, alpha)
        )
    img = Image.alpha_composite(img, glow)
    draw = ImageDraw.Draw(img)

    # === Draw "DX" text ===
    font_paths = [
        "/System/Library/Fonts/SFCompact.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/Library/Fonts/SF-Pro-Display-Bold.otf",
        "/System/Library/Fonts/SFNS.ttf",
    ]
    
    font_size = int(s * 0.38)
    font = None
    for fp in font_paths:
        if os.path.exists(fp):
            try:
                font = ImageFont.truetype(fp, font_size)
                break
            except:
                pass
    if font is None:
        font = ImageFont.load_default()

    text = "DX"
    bbox_text = draw.textbbox((0, 0), text, font=font)
    tw = bbox_text[2] - bbox_text[0]
    th = bbox_text[3] - bbox_text[1]
    tx = (s - tw) // 2 - bbox_text[0]
    ty = (s - th) // 2 - bbox_text[1] - int(s * 0.01)

    # Text shadow/glow (warm orange)
    shadow_layer = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow_layer)
    shadow_draw.text((tx, ty), text, font=font, fill=(255, 120, 40, 120))
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(radius=int(s * 0.025)))
    img = Image.alpha_composite(img, shadow_layer)
    draw = ImageDraw.Draw(img)

    # Text mask
    text_mask = Image.new("L", (s, s), 0)
    text_mask_draw = ImageDraw.Draw(text_mask)
    text_mask_draw.text((tx, ty), text, font=font, fill=255)

    # Gradient fill — top: bright orange (#FFB060) → bottom: deep orange (#FF6B2C)
    text_gradient = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    text_grad_draw = ImageDraw.Draw(text_gradient)
    for y in range(s):
        t = y / s
        r = lerp(255, 255, t)
        g = lerp(190, 100, t)
        b = lerp(100, 44, t)
        text_grad_draw.line([(0, y), (s - 1, y)], fill=(r, g, b, 255))
    
    text_gradient.putalpha(text_mask)
    img = Image.alpha_composite(img, text_gradient)
    draw = ImageDraw.Draw(img)

    # === Accent line under text ===
    line_y = ty + th + int(s * 0.04)
    line_w = int(tw * 0.8)
    line_x = (s - line_w) // 2
    line_h = max(int(s * 0.012), 2)
    
    for x in range(line_w):
        t = x / line_w
        r = lerp(255, 255, t)
        g = lerp(140, 180, t)
        b = lerp(66, 100, t)
        alpha = int(200 * math.sin(t * math.pi))
        draw.rectangle(
            [line_x + x, line_y, line_x + x, line_y + line_h],
            fill=(r, g, b, alpha)
        )

    # === Small sparkle dots ===
    sparkles = [
        (0.72, 0.28, 3, 160),
        (0.78, 0.33, 2, 100),
        (0.25, 0.70, 2, 80),
    ]
    for sx_pct, sy_pct, sr, sa in sparkles:
        sx_pos = int(s * sx_pct)
        sy_pos = int(s * sy_pct)
        sr_scaled = max(int(s * sr / 400), 1)
        draw.ellipse(
            [sx_pos - sr_scaled, sy_pos - sr_scaled, sx_pos + sr_scaled, sy_pos + sr_scaled],
            fill=(255, 200, 150, sa)
        )

    # === Apply rounded rect mask ===
    mask = Image.new("L", (s, s), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle(inner, radius=radius, fill=255)
    img.putalpha(mask)

    # === Subtle border ===
    border = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    border_draw = ImageDraw.Draw(border)
    border_draw.rounded_rectangle(inner, radius=radius, outline=(255, 255, 255, 18), width=max(int(s * 0.004), 1))
    img = Image.alpha_composite(img, border)

    img = img.resize((size, size), Image.LANCZOS)
    return img

os.makedirs(OUTPUT_DIR, exist_ok=True)

images = []
for size in SIZES:
    icon = generate_icon(size)

    if size <= 512:
        filename = f"icon_{size}x{size}.png"
        icon.save(os.path.join(OUTPUT_DIR, filename))
        images.append({"filename": filename, "size": f"{size}x{size}", "scale": "1x"})

    half = size // 2
    if half in [16, 32, 128, 256, 512]:
        filename = f"icon_{half}x{half}@2x.png"
        icon.save(os.path.join(OUTPUT_DIR, filename))
        images.append({"filename": filename, "size": f"{half}x{half}", "scale": "2x"})

contents = {
    "images": [
        {"filename": img["filename"], "idiom": "mac", "scale": img["scale"], "size": img["size"]}
        for img in sorted(images, key=lambda x: (int(x["size"].split("x")[0]), x["scale"]))
    ],
    "info": {"author": "xcode", "version": 1}
}

with open(os.path.join(OUTPUT_DIR, "Contents.json"), "w") as f:
    json.dump(contents, f, indent=2)

print(f"✓ Generated {len(images)} icon variants (orange)")
