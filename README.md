# FIJI Macro – Lipid Droplet Quantification

Batch analysis of lipid droplets (LDs) in fluorescence microscopy images using **BODIPY 558/568** (C1) and **DAPI** (C2) staining from z-stack acquisitions.

---

## Overview

This macro processes multichannel z-stack TIFF files to detect and quantify lipid droplets. For each image it:

1. Splits channels and discards the DAPI channel (C2)
2. Creates a maximum-intensity Z-projection of the BODIPY channel (C1)
3. Subtracts background (rolling-ball, radius = 10 px)
4. Applies a threshold (Otsu auto or user-defined fixed/manual) to create a binary mask
5. Separates touching droplets with a Watershed transform and fills holes
6. Runs **Analyze Particles** to measure area, perimeter, and shape descriptors for each LD
7. Saves per-image outputs (mask, overlay with ROIs, ROI set) and global summary tables

---

## Requirements

- [FIJI](https://fiji.sc/) (ImageJ2 distribution) — any recent version
- No additional plugins required; all functions are built into FIJI

---

## Input Data Preparation

> **Important:** Z-stack images must be **extracted and saved as individual TIFF files** in the input folder before running the macro. The macro does not split z-stacks from multi-series files.

Expected file format:
- Multichannel TIFF (`.tif`)
- **C1** = BODIPY 558/568 (lipid droplets)
- **C2** = DAPI (nuclei) — used only as reference; not analysed

---

## Usage

1. Open FIJI
2. Go to **Plugins → Macros → Run…** and select `LD_analysis.ijm`  
   *(or drag-and-drop the `.ijm` file onto the FIJI toolbar)*
3. When prompted, select:
   - **Input folder** — folder containing your `.tif` files
   - **Results folder** — folder where outputs will be saved
4. In the **Threshold selection** dialog, choose:
   - `Fixed` — uses the fixed threshold value specified in the dialog (default: 30). Recommended for consistent batch processing
   - `Manual` — pauses on each image so you can adjust the lower threshold interactively using the Threshold tool

---

## Parameters

| Parameter | Default | Description |
|---|---|---|
| Threshold method | `Fixed` | `Fixed` (automated batch) or `Manual` (per-image review) |
| Fixed threshold | `30` | Lower threshold value applied to the background-subtracted max-projection |
| Background subtraction radius | `10 px` | Rolling-ball radius for background subtraction |
| Particle minimum size | `0.10 µm²` | Minimum LD area for Analyze Particles (excludes noise) |
| Display range | `2 – 70` | Min/max intensity for overlay visualisation only |

---

## Outputs

All files are saved to the **Results folder** you select at run time.

| File | Description |
|---|---|
| `MASK_<name>.tif` | Binary mask after thresholding, watershed, and fill holes |
| `overlay_<name>.tif` | Max-projection with detected LD ROIs overlaid in red |
| `RoiSet_<name>.zip` | FIJI ROI set for each image (re-openable in ROI Manager) |
| `_Results.csv` | Per-droplet measurements (area, perimeter, circularity, etc.) |
| `_Summary.csv` | Per-image summary (count, total area, etc.) |
| `_Analysis details.txt` | Log file with threshold values and LD counts per image |

---

## Measured Parameters

Measurements are set to: **Area**, **Perimeter**, **Shape descriptors** (circularity, aspect ratio, roundness, solidity).

These can be modified in the macro by editing the `Set Measurements` line.

---

## Notes and Tips

- **Threshold choice:** The Otsu auto-threshold is computed first and displayed; the fixed or manual value then overrides the lower bound. Inspect a representative image before running a full batch to validate the default value of 30.
- **Batch mode:** The macro uses FIJI's batch mode for speed. Images are not displayed during processing except when `Manual` thresholding is selected.
- **ROI colours:** ROIs are shown in red on the overlay image and reset to yellow in the ROI Manager after saving.
- **Empty images:** Images where no particles are detected are still saved (overlay without ROIs); no ROI zip is created for those.

---

## Citation / Acknowledgements

If you use this macro in a publication, please cite the FIJI platform:

> Schindelin, J. et al. (2012). Fiji: an open-source platform for biological-image analysis. *Nature Methods*, 9(7), 676–682. https://doi.org/10.1038/nmeth.2019

---

## License

This macro is released under the [MIT License](LICENSE). You are free to use, modify, and distribute it with attribution.
