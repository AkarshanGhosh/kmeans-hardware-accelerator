import cv2
import numpy as np
from tkinter import Tk, filedialog

# ── File picker (same style as your existing scripts) ──
Tk().withdraw()
print("Select your image...")

file_path = filedialog.askopenfilename(
    title="Select Image for K-Means Hardware",
    filetypes=[("Image Files", "*.jpg *.jpeg *.png *.bmp")]
)

if not file_path:
    print("No file selected!")
    exit()

# ── Load and prepare (exactly as your Python baseline) ──
image = cv2.imread(file_path)
image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
image = cv2.resize(image, (32, 32))
pixels = image.reshape(-1, 3)          # (1024, 3)

print(f"Image loaded: {file_path}")
print(f"Pixel array shape: {pixels.shape}")

# ── Export pixels.mem ──
with open("pixels.mem", "w") as f:
    for r, g, b in pixels:
        f.write(f"{r:02X}{g:02X}{b:02X}\n")
print("pixels.mem written —", len(pixels), "pixels")

# ── Export centroids.mem (K=4 random picks) ──
K = 4
indices = np.random.choice(len(pixels), K, replace=False)
centroids = pixels[indices]

with open("centroids.mem", "w") as f:
    for r, g, b in centroids:
        f.write(f"{r:02X}{g:02X}{b:02X}\n")
print("centroids.mem written —", K, "centroids")

# ── Print preview so you can sanity check ──
print("\nInitial centroids chosen:")
for i, (r, g, b) in enumerate(centroids):
    print(f"  C{i}: R={r:3d}  G={g:3d}  B={b:3d}  →  hex {r:02X}{g:02X}{b:02X}")

print("\nFirst 5 pixels preview:")
for i, (r, g, b) in enumerate(pixels[:5]):
    print(f"  P{i}: R={r:3d}  G={g:3d}  B={b:3d}  →  hex {r:02X}{g:02X}{b:02X}")

print("\nDone. Copy pixels.mem and centroids.mem into your Vivado project folder.")