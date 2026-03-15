#!/usr/bin/env python3
"""Generate DX Tools app icon - Orange bolt on dark rounded square"""
from PIL import Image, ImageDraw, ImageFont
import os

SIZES = [16, 32, 64, 128, 256, 512, 1024]
OUTPUT_DIR = "DXTools/Assets.xcassets/AppIcon.appiconset"

def generate_icon(size):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Background rounded rect
    margin = int(size * 0.08)
    radius = int(size * 0.22)
    
    # Dark gradient-like background
    for y in range(margin, size - margin):
        t = (y - margin) / (size - 2 * margin)
        r = int(30 + t * 10)
        g = int(30 + t * 8)
        b = int(35 + t * 12)
        draw.line([(margin, y), (size - margin - 1, y)], fill=(r, g, b, 255))
    
    # Draw rounded corners mask
    mask = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=radius,
        fill=255
    )
    img.putalpha(mask)
    
    # Draw bolt symbol ⚡
    cx, cy = size // 2, size // 2
    s = size * 0.30  # bolt scale
    
    # Lightning bolt polygon points
    bolt_points = [
        (cx - s*0.1, cy - s*0.95),   # top
        (cx + s*0.45, cy - s*0.95),   # top right
        (cx + s*0.05, cy - s*0.1),    # middle right
        (cx + s*0.45, cy - s*0.1),    # mid-right extended
        (cx - s*0.15, cy + s*0.95),   # bottom
        (cx - s*0.05, cy + s*0.1),    # middle left  
        (cx - s*0.45, cy + s*0.1),    # mid-left extended
    ]
    
    # Orange gradient bolt
    # Draw filled bolt
    bolt_points_int = [(int(x), int(y)) for x, y in bolt_points]
    
    # Shadow
    shadow_points = [(x+2, y+3) for x, y in bolt_points_int]
    draw.polygon(shadow_points, fill=(0, 0, 0, 80))
    
    # Main bolt - bright orange
    draw.polygon(bolt_points_int, fill=(255, 180, 50, 255))
    
    # Highlight on top half
    highlight_points = bolt_points_int[:4]
    if len(highlight_points) >= 3:
        draw.polygon(highlight_points, fill=(255, 210, 100, 255))
    
    # Re-apply mask
    img.putalpha(mask)
    
    return img

# Generate all sizes
os.makedirs(OUTPUT_DIR, exist_ok=True)

images = []
for size in SIZES:
    icon = generate_icon(size)
    
    if size <= 512:
        # 1x
        filename = f"icon_{size}x{size}.png"
        icon.save(os.path.join(OUTPUT_DIR, filename))
        images.append({"filename": filename, "size": f"{size}x{size}", "scale": "1x"})
    
    # Also save as 2x for half-size
    half = size // 2
    if half in [16, 32, 128, 256, 512]:
        filename = f"icon_{half}x{half}@2x.png"
        icon.save(os.path.join(OUTPUT_DIR, filename))
        images.append({"filename": filename, "size": f"{half}x{half}", "scale": "2x"})

# Write Contents.json
import json
contents = {
    "images": [
        {"filename": img["filename"], "idiom": "mac", "scale": img["scale"], "size": img["size"]}
        for img in sorted(images, key=lambda x: (int(x["size"].split("x")[0]), x["scale"]))
    ],
    "info": {"author": "xcode", "version": 1}
}

with open(os.path.join(OUTPUT_DIR, "Contents.json"), "w") as f:
    json.dump(contents, f, indent=2)

print(f"Generated {len(images)} icon variants")
