// ============================================================
// FIJI Macro: Lipid Droplet (LD) Quantification
// ============================================================
// Description:
//   Batch quantification of lipid droplets in fluorescence images.
//   Cells are stained with BODIPY 558/568 (lipid droplets, channel C1)
//   and DAPI (nuclei, channel C2).
//
// Input:
//   Multichannel z-stack TIFF files (.tif).
//   Z-stacks must be extracted and saved as individual TIFFs
//   in the input folder before running this macro.
//
// Output (saved to Results folder):
//   MASK_<name>.tif        — binary mask per image
//   overlay_<name>.tif     — max-projection with LD ROIs overlaid
//   RoiSet_<name>.zip      — FIJI ROI set per image
//   _Results.csv           — per-droplet measurements
//   _Summary.csv           — per-image summary table
//   _Analysis details.txt  — log with threshold values and LD counts
//
// Usage:
//   Plugins > Macros > Run... and select this file.
//   Select Input and Results folders when prompted.
// ============================================================

// --- Prompt user to select input and output folders ---
input = getDir("Input folder");
output = getDir("Results folder");

// --- Dialog: choose threshold method and fixed threshold value ---
Dialog.create("Threshold selection");
Dialog.addMessage("How do you want to stablish your threshold?");
Dialog.addChoice("Choose", newArray("Fixed", "Manual"), "Fixed");
// Fixed: applies the value below to all images (fast, reproducible batch mode)
// Manual: pauses on each image for interactive threshold adjustment
Dialog.addNumber("Fixed threshold:", 30);
Dialog.show();

method = Dialog.getChoice();
threshold = Dialog.getNumber();

// --- Initialise file list and counters ---
filelist = getFileList(input);
n = lengthOf(filelist);
tifs = 0;   // counts TIFF files processed
count = 0;  // cumulative LD count across all images

print("Lipid droplet analysis macro\n" + n + " TIFF files found in imput folder\n  " + input + "\n");

// ============================================================
// Main loop: process each TIFF file in the input folder
// ============================================================
for (i = 0; i < n; i++) {

	if (endsWith(filelist[i], ".tif")) {

		tifs = tifs + 1;
		name = File.getNameWithoutExtension(filelist[i]);

		setBatchMode(true);  // suppress display for speed

		// --- Open image and split into individual channel windows ---
		open(input + filelist[i]);
		rename(name);
		run("Split Channels");  // produces C1-<name> (BODIPY) and C2-<name> (DAPI)

		// Discard DAPI channel — not used in LD analysis
		close("C2-" + name);

		// --- Z-projection: maximum intensity ---
		// Collapses the z-stack into a single representative 2D image
		selectImage("C1-" + name);
		run("Z Project...", "projection=[Max Intensity]");

		// --- Background subtraction ---
		// Rolling-ball algorithm (radius = 10 px) removes uneven illumination
		run("Subtract Background...", "rolling=10");

		close("C1-" + name);  // close the original z-stack channel; keep the projection

		// Re-enable display so the threshold tool is visible if needed
		setBatchMode("exit and display");
		rename("MAX_" + name);

		// Set display range for visual inspection (does not affect pixel values)
		setMinAndMax(2, 70);

		// --- Duplicate projection for thresholding (preserve the original for overlay) ---
		run("Duplicate...", "title=[" + name + "]");

		// --- Thresholding ---
		// Otsu auto-threshold is computed first, then overridden based on user choice
		run("Threshold...");
		setAutoThreshold("Otsu dark no-reset stack");

		if (method == "Manual") {
			// Pause and let the user inspect and adjust the lower threshold
			waitForUser("Theshold", "Set lower threshold to remove background");
			getThreshold(lower, upper);
			print(tifs + "- " + name + ": " + lower + ", " + upper);
			setThreshold(lower, 255);

		} else {
			// Apply the fixed threshold value chosen in the dialog
			getThreshold(lower, upper);
			print(tifs + "- " + name + ": " + threshold + ", " + upper);
			setThreshold(threshold, 255);
		}

		// --- Create binary mask ---
		run("Convert to Mask");

		// Watershed: separates touching/overlapping lipid droplets
		// Fill Holes: closes small holes inside detected objects
		run("Watershed");
		run("Fill Holes");

		// --- Measure shape and size descriptors ---
		run("Set Measurements...", "area perimeter shape display redirect=None decimal=6");

		// Analyze Particles:
		//   size=0.10-Infinity  — exclude objects smaller than 0.10 µm² (noise)
		//   display             — add results to Results table
		//   exclude             — exclude particles touching image edges
		//   include             — include holes in particle area
		//   summarize           — add a row to the Summary table
		//   add composite       — add detected particles to ROI Manager
		run("Analyze Particles...", "size=0.10-Infinity display exclude include summarize add composite");

		roiManager("Show All without labels");
		count = count + roiManager("count");
		print("   " + roiManager("count") + " LDs detected");

		// --- Save binary mask ---
		setBatchMode("hide");
		saveAs("Tiff", output + "MASK_" + name + ".tif");
		close("MASK_" + name + ".tif");

		// --- Save overlay image (max-projection + ROI outlines) ---
		selectImage("MAX_" + name);
		run("Enhance Contrast", "saturated=0.01");
		roiManager("Show All without labels");
		setBatchMode("hide");

		if (roiManager("count") != 0) {
			// Overlay ROIs in red and flatten into a single image for saving
			roiManager("Set Color", "red");
			run("Flatten");
			selectImage("MAX_" + name + "-1");
			roiManager("Show All without labels");
			saveAs("Tiff", output + "overlay_" + name + ".tif");

			// Save ROI set as a zip file for later re-loading in ROI Manager
			roiManager("Save", output + "RoiSet_" + name + ".zip");

			close(); close();

			// Reset ROI colour and clear ROI Manager for the next image
			roiManager("Set Color", "yellow");
			roiManager("reset");

		} else {
			// No LDs detected: save overlay without ROIs; skip ROI zip
			saveAs("Tiff", output + "overlay_" + name + ".tif");
			close();
		}

		setBatchMode("exit and display");

	}  // end if .tif

}  // end for loop

// ============================================================
// Save results tables and log
// ============================================================
selectWindow("Summary");
saveAs("Results", output + "_Summary.csv");

selectWindow("Results");
saveAs("Results", output + "_Results.csv");

selectWindow("Log");
saveAs("Text", output + "_Analysis details.txt");

print("\n" + tifs + " images analyzed and a total of " + count + " LDs detected.\nResults stored in\n   " + output);
