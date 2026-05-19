# K-Means Hardware Accelerator

### A GPU-Inspired Parallel Accelerator for K-Means Image Segmentation on FPGA

[![Verilog](https://img.shields.io/badge/Language-Verilog%20HDL-blue?style=flat-square&logo=v)]()
[![Vivado](https://img.shields.io/badge/Tool-Xilinx%20Vivado%202025-red?style=flat-square)]()
[![Python](https://img.shields.io/badge/Validation-Python%203.x-green?style=flat-square&logo=python)]()
[![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)]()
[![Tests](https://img.shields.io/badge/Tests-39%2F39%20Passed-brightgreen?style=flat-square)]()
[![Delta](https://img.shields.io/badge/HW--SW%20Delta-%CE%94%3D0%20Bit--Identical-brightgreen?style=flat-square)]()

---

## 📌 Project Overview

This project presents the complete design, implementation, and verification of a
**GPU-inspired parallel hardware accelerator** for K-Means image segmentation,
written entirely in **Verilog HDL** and simulated using **Xilinx Vivado 2025**.

The accelerator processes 32×32 RGB images (1024 pixels) across 20 K-Means
iterations to produce a 4-cluster segmented output. Python is used **only** for
data preparation and validation — all clustering logic runs in hardware.

### 🔑 Key Highlights

| Metric | Value |
|---|---|
| Verilog modules designed | 7 |
| Unit test cases | 39 / 39 passed |
| K-Means iterations | 20 |
| Image size | 32×32 pixels (1024 total) |
| Simulation time | ~206 microseconds at 100 MHz |
| Hardware–Python delta | **Δ = 0 (bit-identical)** |
| Vivado cells / nets | 12 cells / 337 nets |
| GitHub | Public — full source code |

---

## 🚀 What Makes This Different

Most published FPGA K-Means designs use:
- **Approximate weighted averaging** instead of exact division
- **HLS auto-generated code** instead of hand-written RTL
- **Random initialisation** that causes cluster death

This project achieves:

✅ **Bit-identical validation** — delta = 0 on all 4 centroids vs Python reference  
✅ **Hand-written RTL Verilog** — explicit control over every register and timing edge  
✅ **K-Means++ initialisation** — prevents cluster death in hardware  
✅ **Empty cluster survival guard** — no centroid collapses to (0,0,0)  
✅ **All bugs documented** — 6 hardware bugs found, root-caused, and fixed  

---

## 🏗️ Architecture

```
pixels.mem (Python-generated)
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│                    kmeans_top.v                             │
│                                                             │
│  pixel_mem.v ──────────────────────────── pixel_r/g/b      │
│  (1024×24-bit BRAM)      │ broadcast to all 4 units        │
│                           │                                 │
│              ┌────────────┼───────────────┐                 │
│              ▼            ▼               ▼        ▼        │
│         dist_unit_0  dist_unit_1  dist_unit_2  dist_unit_3  │
│         (vs C0)      (vs C1)      (vs C2)      (vs C3)      │
│              │            │               │        │        │
│              └────────────┴───────────────┘        │        │
│                        dist0..dist3 [17:0]          │        │
│                           ▼                        │        │
│                    min_finder_k4.v                 │        │
│                    (tournament tree)               │        │
│                           │ cluster_id[1:0]        │        │
│                           ▼                        │        │
│                    accumulator.v ◄─────────────────┘        │
│                    (sum+count+mean)                         │
│                           │ new centroids                   │
│                           ▼                                 │
│                    centroid_regs.v                          │
│                    (K×3 register file)                      │
│                           │ feeds back to dist_units        │
│                                                             │
│          fsm_control.v ── drives all enable signals        │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
Python validate_kmeans.py → delta = 0 ✓
```

### FSM States

```
IDLE → LOAD → COMPUTE → UPDATE → WRITE → CLEAR → DONE
                  ▲                          │
                  └──────────────────────────┘
                         (×20 iterations)
```

---

## 📁 Repository Structure

```
kmeans-hardware-accelerator/
│
├── rtl/                          ← All Verilog design sources
│   ├── dist_unit.v               ← RGB squared Euclidean distance (combinational)
│   ├── min_finder_k4.v           ← 2-level tournament comparator
│   ├── centroid_regs.v           ← K×3 centroid register file
│   ├── accumulator.v             ← Per-cluster sum, count, integer mean
│   ├── pixel_mem.v               ← 1024×24-bit BRAM ($readmemh)
│   ├── fsm_control.v             ← 7-state FSM + pixel counter
│   └── kmeans_top.v              ← Top-level wiring + 3×4:1 write-back mux
│
├── tb/                           ← Vivado simulation testbenches
│   ├── tb_dist_unit.v            ← 5 test cases
│   ├── tb_min_finder_k4.v        ← 6 test cases
│   ├── tb_centroid_regs.v        ← 13 test cases
│   ├── tb_accumulator.v          ← 8 test cases
│   ├── tb_pixel_mem.v            ← 7 test cases
│   └── tb_kmeans_top.v           ← Full system simulation (20 iterations)
│
├── python_model/                 ← Python scripts (data prep + validation only)
│   ├── export_mem.py             ← K-Means++ init + pixels.mem + centroids.mem
│   ├── validate_kmeans.py        ← Compare hardware vs Python centroids
│   ├── kmeans_rgb.py             ← Original RGB K-Means reference
│   └── kmeans_gray.py            ← Original grayscale K-Means reference
│
├── .gitignore                    ← Excludes all Vivado generated files
└── README.md                     ← This file
```

---

## ⚡ Quick Start

### Prerequisites

**Vivado:** Xilinx Vivado 2025.x (xsim simulator)

**Python:**
```bash
pip install numpy opencv-python matplotlib
```

---

### Step 1 — Generate image data (Python)

```bash
cd python_model/
python export_mem.py
# A file picker opens — select any .jpg/.png/.bmp image
# Generates: pixels.mem (1024 pixels) + centroids.mem (4 K-Means++ centroids)
```

Copy both `.mem` files to your Vivado xsim simulation directory:
```
<project>/kmeans_accelerator.sim/sim_1/behav/xsim/pixels.mem
<project>/kmeans_accelerator.sim/sim_1/behav/xsim/centroids.mem
```

---

### Step 2 — Run simulation in Vivado

1. Open Vivado → **New Project** → RTL Project
2. **Add Sources** → add all `.v` files from `rtl/` as **Design Sources**
3. **Add Sources** → add all `.v` files from `tb/` as **Simulation Sources**
4. Right-click `tb_kmeans_top` → **Set as Top** (under Simulation Sources)
5. Run these commands in the Tcl console:
```tcl
set_property file_type SystemVerilog [get_files tb_kmeans_top.v]
set_property top tb_kmeans_top [get_filesets sim_1]
update_compile_order -fileset sim_1
```
6. **Flow → Run Simulation → Run Behavioral Simulation**
7. In the Tcl console:
```tcl
run 300000ns
```

**Expected output:**
```
K-Means Accelerator — Fixed v3
Loading centroids from centroids.mem:
  C0: R=... G=... B=...
  ...
Iter 0 done | C0:xxx C1:xxx C2:xxx C3:xxx px
...
Iter 19 done | ...
DONE — all iterations complete
Total pixels processed: 20480
Final centroids:
  C0: R=187 G=181 B=182
  ...
```

---

### Step 3 — Validate against Python

Update `HARDWARE_CENTROIDS` in `validate_kmeans.py` with the values
printed in the Tcl console, then:

```bash
python validate_kmeans.py
# Select the same image used in Step 1
```

**Expected output:**
```
FINAL CENTROID COMPARISON
C0:  R=187 G=181 B=182  |  R=187 G=181 B=182  delta=0  ✓ MATCH
C1:  R=234 G=164 B= 28  |  R=234 G=164 B= 28  delta=0  ✓ MATCH
C2:  R= 65 G= 65 B= 64  |  R= 65 G= 65 B= 64  delta=0  ✓ MATCH
C3:  R=  9 G= 88 B=226  |  R=  9 G= 88 B=226  delta=0  ✓ MATCH
Total L1 delta: 0
RESULT: Hardware matches Python model — accelerator verified!
```

---

## ✅ Verification Results

### Unit Tests — All 39/39 Passed

| Module | Testbench | Test Cases | Result |
|---|---|---|---|
| `dist_unit.v` | `tb_dist_unit.v` | 5 | ✅ 5/5 |
| `min_finder_k4.v` | `tb_min_finder_k4.v` | 6 | ✅ 6/6 |
| `centroid_regs.v` | `tb_centroid_regs.v` | 13 | ✅ 13/13 |
| `accumulator.v` | `tb_accumulator.v` | 8 | ✅ 8/8 |
| `pixel_mem.v` | `tb_pixel_mem.v` | 7 | ✅ 7/7 |
| **Full system** | `tb_kmeans_top.v` | 20 iters / 20480 px | ✅ DONE |

### Full System Performance

| Parameter | Value |
|---|---|
| Clock | 100 MHz |
| Iterations | 20 |
| Pixels per iteration | 1,024 |
| Total pixel operations | 20,480 |
| Simulation time | 206,245 ns (~206 μs) |
| Hardware–Python delta | **0 (bit-identical)** |

---

## 🔧 Hardware Bug Log

Six non-trivial bugs were found, root-caused, and fixed during development:

| # | Module | Root Cause | Fix |
|---|---|---|---|
| 1 | `dist_unit.v` | Unsigned 8-bit subtraction wraps on negative differences | 9-bit signed expansion before subtract |
| 2 | `fsm_control.v` | Start pulse too short — FSM missed it | Hold start for 4 full clock cycles |
| 3 | `centroid_regs.v` | RST block overwrote centroids loaded from `.mem` | Added `init_load` port; removed centroid reset |
| 4 | `accumulator.v` | Empty cluster → (0,0,0) → permanent collapse | Latch prev centroid + K-Means++ init |
| 5 | `fsm_control.v` | No accumulator clear between iterations | Added dedicated CLEAR state |
| 6 | `fsm_control.v` | `update_en` and `wr_en` overlapped — timing race | Split UPDATE and WRITE into separate states |

---

## 📐 Mathematics

### Distance Metric (dist_unit.v)
```
dist(P, C) = (Rp−Rc)² + (Gp−Gc)² + (Bp−Cb)²

No sqrt needed — comparison only requires relative order.
Worst case: 3 × 255² = 195,075 → fits in 18 bits
```

### Centroid Update (accumulator.v)
```
new_C[k] = floor( sum_RGB[k] / count[k] )

Integer division matches Python int() — enables bit-identical validation.
```

### K-Means++ Seeding (export_mem.py)
```
P(pixel_p) = D(p)² / Σ D(q)²

where D(p) = min distance from p to any already-selected centroid.
Spreads centroids across colour space → prevents cluster death.
```

---

## 📊 Comparison with Related Work

| Feature | Badawi & Bilal 2019 | This Project |
|---|---|---|
| Design tool | Simulink HLS (auto HDL) | **Hand-written RTL Verilog** |
| Centroid update | Weighted avg α=0.999 (approx) | **Integer mean (exact)** |
| Validation | RMSE 4–7 vs Matlab | **Δ=0 bit-identical** |
| Centroid init | Random near 127 | **K-Means++** |
| Cluster death guard | Not mentioned | **Latched prev value** |
| External memory | None | **None (on-chip only)** |
| Platform | Xilinx Zynq-7000 (real board) | Vivado simulation |
| Speed | 26.5 fps Full HD | 206 μs / 1024 px |
| Source code | Simulink (public) | **Verilog (GitHub)** |

---

## 🔮 Future Work

- [ ] Deploy to real Artix-7 FPGA board with XDC constraints file
- [ ] Scale to K=8 or K=16 (extend tournament tree)
- [ ] Support 128×128 or 256×256 images (wider address counter)
- [ ] Add convergence detection (early stop when Δ centroids < threshold)
- [ ] Pipeline dist_unit for higher clock frequency
- [ ] Real-time camera pixel stream input

---

## 📚 References

1. A. Badawi, M. Bilal — *High-Level Synthesis of Online K-Means Clustering Hardware*, Journal of Imaging, MDPI, 2019
2. H. M. Hussain et al. — *A High Speed Configurable FPGA Architecture for K-Means*, NASA/ESA AHS, 2011
3. J. S. S. Kutty et al. — *A High Speed Configurable FPGA Architecture for K-Mean Clustering*, IEEE ISCAS, 2013
4. D. Arthur, S. Vassilvitskii — *K-Means++: The Advantages of Careful Seeding*, ACM-SIAM SODA, 2007
5. M. Zechner, M. Granitzer — *A Parallel Implementation of K-Means Clustering on GPUs*, IEEE ICSC, 2009
6. *KPynq: A Work-Efficient Triangle-Inequality Based K-Means on FPGA*, arXiv:1905.09345, 2019
7. T. Saidani, R. Ghodhbani — *Hardware Acceleration of Video Edge Detection on Xilinx Zynq*, ETASR, 2022

---

## 👤 Author

**Akarshan Ghosh**  




---

## 📄 License

This project is licensed under the MIT License.
Feel free to use, modify, and distribute with attribution.

---

<div align="center">

**⭐ If this project helped you, please give it a star on GitHub ⭐**

*Built with Verilog HDL · Verified with Xilinx Vivado · Validated with Python*

</div>

