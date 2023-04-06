// The zebrafish script

// Performs automated batch analysis of fluorescence microscopy images.
// Only processes images in .tif or .zvi format.
// Requires ImageJ version 1.53t and the "ResultsToExcel" plugin.
// See the README file for details.



// The following lines identify your input image folder and create a new
// a folder (Combined_script_output) in your computer's "home" directory. 
// For Windows users, this is most often in: C:\Users\your_username.
// This folder will later be filled with output sub-folders.

run("Bio-Formats Macro Extensions");
input = getDir("image");
home_directory = getDir("home");
File.makeDirectory(home_directory + "Combined_script_output" + File.separator);
combined_output = home_directory + "Combined_script_output" + File.separator;
close("*");
setBatchMode(true);

// This user-defined function lists all files in the input folder and orders
// them. It then sequentially opens every individual image via Bioformats.
// After opening, it checks the file extension (tif, zvi, or other) and
// categorizes the images accordingly. It creates an output subfolder for
// every image. Any processed images will be saved in this subfolder. 

processFolder(input);

function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		run("Bio-Formats Macro Extensions");
		run("Bio-Formats", "open=[" + input + File.separator + list[i] +"] color_mode=Grayscale view=Hyperstack stack_order=XYCZT");
		if (endsWith(list[i], ".TIF") | endsWith(list[i], ".tif")) {
			File.makeDirectory(combined_output + File.getNameWithoutExtension(Image.title) + "_tif_output" + File.separator);
			output = combined_output + File.getNameWithoutExtension(Image.title) + "_tif_output" + File.separator;
			file_type = "tif_";
			GFP = 1;
			DAPI = 2;
		} else if (endsWith(list[i], ".zvi")) {
			File.makeDirectory(combined_output + File.getNameWithoutExtension(Image.title) + "_zvi_output" + File.separator);
			output = combined_output + File.getNameWithoutExtension(Image.title) + "_zvi_output" + File.separator;
			file_type = "zvi_";
			GFP = 2;
			DAPI = 1;
		} else {
			exit("IK SNAP HET NIET MEER!!");
		}
		processFile(input, output, list[i]);
	}
}


// This function performs the actual image processing on each individual
// image. Using the "ResultsToExcel" plugin, it creates an excel file
// called "zebrafish_script.xlsx" in the combined output folder.
// Measurement results from all images will be saved in this excel file.

function processFile(input, output, file) {
	selectWindow(Image.title);
	id_Original = getImageID();
	baseName = File.getNameWithoutExtension(Image.title);
	if (nSlices > 2) {
		Stack.setChannel(1);
		run("Delete Slice", "delete=channel");
	}
	selectImage(id_Original);
	Stack.setChannel(GFP);
	run("Green");
	Stack.setChannel(DAPI);
	run("Blue");
	Stack.setDisplayMode("composite");
	saveAs("Tiff", output + baseName + "_composite");
	run("Set Measurements...", "mean redirect=None decimal=2");
	selectImage(id_Original);
	Stack.setChannel(DAPI);
	run("Duplicate...", "title=DAPI_" + baseName);
	id_DAPI = getImageID();
	run("Duplicate...", "duplicate");
	id_DAPIduplicate = getImageID();
	selectImage(id_DAPIduplicate);
	run("Measure");
	run("Read and Write Excel", "no_count_column stack_results file=[" + combined_output + "zebrafish_script.xlsx] sheet=" + file_type + "DAPI_MGV");
	run("Clear Results");
	selectImage(id_DAPIduplicate);
	run("Histogram");
	saveAs("Tiff", output + "Histogram of DAPI_" + Image.title);
	selectImage(id_Original);
	Stack.setChannel(GFP);
	run("Duplicate...", "title=GFP_" + baseName);
	id_GFP = getImageID();
	selectImage(id_GFP);
	run("Measure");
	run("Read and Write Excel", "no_count_column stack_results file=[" + combined_output + "zebrafish_script.xlsx] sheet=" + file_type + "GFP_MGV");
	run("Clear Results");
	selectImage(id_GFP);
	run("Histogram");
	saveAs("Tiff", output + "Histogram of GFP_" + Image.title);
	selectImage(id_GFP);
	run("Duplicate...", "title=autoBG_" + baseName);
	run("Subtract Background...", "rolling=15");
	id_AutoGFP = getImageID();
	saveAs("Tiff", output + "AutoBG_" + Image.title);
	selectImage(id_DAPIduplicate);
	setAutoThreshold("Default dark");
	run("Threshold...");
	setAutoThreshold("Huang dark");
	setOption("BlackBackground", true);
	run("Convert to Mask");
	saveAs("Tiff", output + "Huang_" + Image.title);
	run("Open");
	run("Close-");
	run("Watershed");
	run("Voronoi");
	run("Color Balance...");
	setMinAndMax(0, 0);
	call("ij.ImagePlus.setDefault16bitRange", 12);
	run("Apply LUT");
	run("Close");
	id_VoroOriginal = getImageID();
	run("Duplicate...", "title=Voronoi_" + baseName);
	id_VoroDuplicate = getImageID();
	selectImage(id_VoroOriginal);
	saveAs("Tiff", output + "Voronoi_" + Image.title);
	selectImage(id_AutoGFP);
	run("Duplicate...", "title=analyzeParticles_" + baseName);
	id_Particles = getImageID();
	setAutoThreshold("MaxEntropy dark");
	setOption("BlackBackground", true);
	run("Convert to Mask");
	run("Analyze Particles...", "minimum=1 maximum=999999 bins=20 show=Overlay clear record");
	for (i=0; i<nResults; i++) {
		x = getResult('XStart', i);
		y = getResult('YStart', i);
		doWand(x,y);
		roiManager("add");
	}
	particle_rois = roiManager("count");
	parts_array = newArray(particle_rois);
	for (i=0; i<parts_array.length; i++) {
		parts_array[i] = i;
	}
	roiManager("Show None");
	selectImage(id_Particles);
	saveAs("Tiff", output + Image.title);
	selectImage(id_Particles);
	roiManager("select", parts_array);
	roiManager("XOR");
	roiManager("add");
	roiManager("select", particle_rois);
	partsRoiIndex = roiManager("index");
	roiManager("Select", partsRoiIndex);
	roiManager("rename", "Particles_" + baseName);
	roiManager("save selected", output + "Particle_selection" + baseName + ".roi");
	roiManager("select", parts_array);
	roiManager("Delete");
	roiManager("Select", 0);
	particlesIndex = roiManager("index");
	run("Enlarge...", "enlarge=5 pixel");
	roiManager("add");
	roiManager("select", (particlesIndex + 1));
	intermedRoiIndex = roiManager("index");
	roiManager("rename", "IntermediateSelection_" + baseName);
	roiManager("save selected", output + "IntermediateSelection_" + baseName + ".roi");
	selectImage(id_Original);
	roiManager("Select", intermedRoiIndex);
	roiManager("Update");
	roiManager("select", intermedRoiIndex);
	roiManager("rename", "FinalSelection_" + baseName);
	FinalRoiIndex = roiManager("index");
	run("Set Measurements...", "area mean redirect=None decimal=2");
	selectImage(id_GFP);
	roiManager("select", FinalRoiIndex);
	roiManager("measure");
	run("Read and Write Excel", "no_count_column stack_results file=[" + combined_output + "zebrafish_script.xlsx] sheet=" + file_type + "ROI_area_MGV");
	run("Clear Results");
	selectImage(id_VoroDuplicate);
	roiManager("select", FinalRoiIndex);
	run("Make Inverse");
	run("Clear", "slice");
	run("Select None");
	saveAs("Tiff", output + "Bounded_Voronoi_" + Image.title);
	selectImage(id_VoroDuplicate);
	run("Select None");
	run("Create Selection");
	roiManager("Add");
	roiManager("select", (FinalRoiIndex + 1));
	VoroRoiIndex = roiManager("index");
	roiManager("rename", "VoronoiSelection_" + baseName);
	roiManager("save selected", output + "VoronoiSelection_" + baseName + ".roi");
	run("Select None");
	run("Set Measurements...", "redirect=None decimal=2");
	selectImage(id_DAPI);
	roiManager("select", FinalRoiIndex);
	run("Find Maxima...", "prominence=10 output=Count");
	run("Read and Write Excel", "no_count_column stack_results file=[" + combined_output + "zebrafish_script.xlsx] sheet=" + file_type + "Maxima");
	run("Clear Results");
	selectImage(id_Particles);
	roiManager("select", FinalRoiIndex);
	run("Make Inverse");
	run("Clear", "slice");
	run("Select None");
	roiManager("select", VoroRoiIndex);
	run("Clear", "slice");
	run("Select None");
	setBackgroundColor(0, 0, 0);
	run("Analyze Particles...", "size=10-999999 include summarize");
	Table.rename("Summary", "Results");
	run("Read and Write Excel", "no_count_column stack_results file=[" + combined_output + "zebrafish_script.xlsx] sheet=" + file_type + "Particles");
	run("Clear Results");
	close("*");
	roiManager("reset");
}







