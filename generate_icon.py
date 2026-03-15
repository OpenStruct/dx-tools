#!/usr/bin/env python3
"""Generate DX Tools app icon — Premium 'DX' monogram with gradient background"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os, json, math

SIZES = [16, 32, 64, 128, 256, 512, 1024]
OUTPUT_DIR = "DXTools/Assets.xcassets/AppIcon.appiconset"

def lerp(a, b, t):
    return int(a + (b - a) * t)

def draw_rounded_rect(draw, bbox, radius, fill):
    x0, y0, x1, y1 = bbox
    draw.rounded_rectangle(bbox, radius=radius, fill=fill)

def generate_icon(size):
    # Work at 4x for anti-aliasing, then downscale
    s = size * 4
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    margin = int(s * 0.08)
    radius = int(s * 0.22)
    inner = (margin, margin, s - margin, s - margin)

    # === Background gradient (deep navy to near-black) ===
    for y in range(margin, s - margin):
        t = (y - margin) / (s - 2 * margin)
        r = lerp(20, 12, t)
        g = lerp(22, 14, t)
        b = lerp(35, 22, t)
        draw.line([(margin, y), (s - margin - 1, y)], fill=(r, g, b, 255))

    # === Subtle radial glow in center ===
    glow = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    cx, cy = s // 2, int(s * 0.45)
    glow_radius = int(s * 0.32)
    for i in range(glow_radius, 0, -1):
        alpha = int(35 * (1 - (i / glow_radius) ** 2))
        glow_draw.ellipse(
            [cx - i, cy - i, cx + i, cy + i],
            fill=(100, 140, 255, alpha)
        )
    img = Image.alpha_composite(img, glow)
    draw = ImageDraw.Draw(img)

    # === Draw "DX" text ===
    # Try to find a bold font
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

    # Text shadow/glow
    shadow_layer = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow_layer)
    shadow_draw.text((tx, ty), text, font=font, fill=(80, 140, 255, 120))
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(radius=int(s * 0.025)))
    img = Image.alpha_composite(img, shadow_layer)
    draw = ImageDraw.Draw(img)

    # Main text — gradient from cyan-blue to electric blue
    # Create text mask
    text_mask = Image.new("L", (s, s), 0)
    text_mask_draw = ImageDraw.Draw(text_mask)
    text_mask_draw.text((tx, ty), text, font=font, fill=255)

    # Gradient fill for text
    text_gradient = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    text_grad_draw = ImageDraw.Draw(text_gradient)
    for y in range(s):
        t = y / s
        # Top: bright cyan (#64D2FF) → Bottom: electric blue (#5E5CE6)
        r = lerp(100, 94, t)
        g = lerp(210, 92, t)
        b = lerp(255, 230, t)
        text_grad_draw.line([(0, y), (s - 1, y)], fill=(r, g, b, 255))
    
    text_gradient.putalpha(text_mask)
    img = Image.alpha_composite(img, text_gradient)
    draw = ImageDraw.Draw(img)

    # === Accent line under text ===
    line_y = ty + th + int(s * 0.04)
    line_w = int(tw * 0.8)
    line_x = (s - line_w) // 2
    line_h = max(int(s * 0.012), 2)
    
    # Gradient line
    for x in range(line_w):
        t = x / line_w
        # Gradient from accent blue to cyan
        r = lerp(80, 100, t)
        g = lerp(120, 210, t)
        b = lerp(255, 255, t)
        alpha = int(200 * math.sin(t * math.pi))  # fade edges
        draw.rectangle(
            [line_x + x, line_y, line_x + x, line_y + line_h],
            fill=(r, g, b, alpha)
        )

    # === Small sparkle dots ===
    sparkles = [
        (0.72, 0.28, 3, 180),
        (0.78, 0.33, 2, 120),
        (0.25, 0.70, 2, 100),
    ]
    for sx_pct, sy_pct, sr, sa in sparkles:
        sx_pos = int(s * sx_pct)
        sy_pos = int(s * sy_pct)
        sr_scaled = max(int(s * sr / 400), 1)
        draw.ellipse(
            [sx_pos - sr_scaled, sy_pos - sr_scaled, sx_pos + sr_scaled, sy_pos + sr_scaled],
            fill=(150, 200, 255, sa)
        )

    # === Apply rounded rect mask ===
    mask = Image.new("L", (s, s), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle(inner, radius=radius, fill=255)
    img.putalpha(mask)

    # === Subtle border ===
    border = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    border_draw = ImageDraw.Draw(border)
    border_draw.rounded_rectangle(inner, radius=radius, outline=(255, 255, 255, 20), width=max(int(s * 0.004), 1))
    img = Image.alpha_composite(img, border)

    # Downscale with high-quality resampling
    img = img.resize((size, size), Image.LANCZOS)
    return img

# Generate all sizes
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

# Write Contents.json
contents = {
    "images": [
        {"filename": img["filename"], "idiom": "mac", "scale": img["scale"], "size": img["size"]}
        for img in sorted(images, key=lambda x: (int(x["size"].split("x")[0]), x["scale"]))
    ],
    "info": {"author": "xcode", "version": 1}
}

with open(os.path.join(OUTPUT_DIR, "Contents.json"), "w") as f:
    json.dump(contents, f, indent=2)

print(f"✓ Generated {len(images)} icon variants")
