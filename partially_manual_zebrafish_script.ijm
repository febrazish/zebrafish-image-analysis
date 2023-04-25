// THE ZEBRAFISH SCRIPT (SEMI-AUTOMATIC, USER INPUT REQUIRED)

// PERFORMS AUTOMATED BATCH ANALYSIS OF FLUORESCENCE MICROSCOPY IMAGES.
// ONLY PROCESSES IMAGES IN .TIF OR .ZVI FORMAT.
// REQUIRES IMAGEJ VERSION 1.53T AND THE "RESULTSTOEXCEL" PLUGIN.
// SEE THE README FILE FOR MORE INSTRUCTIONS.

// THE FOLLOWING LINES IDENTIFY YOUR INPUT IMAGE FOLDER AND CREATE A NEW
// A FOLDER (COMBINED_SCRIPT_OUTPUT) IN YOUR COMPUTER'S "HOME" DIRECTORY. 
// ON WINDOWS PCS, THIS IS MOST OFTEN IN: C:\USERS\YOUR_USERNAME.
// THIS FOLDER WILL LATER BE FILLED WITH OUTPUT SUB-FOLDERS.

run("Bio-Formats Macro Extensions");
input = getDirectory("Show me the zebrafish folder ");
home_directory = getDir("home");
File.makeDirectory(home_directory + "combined_script_output" + File.separator);
combined_output = home_directory + "combined_script_output" + File.separator;
setBatchMode(true);

// BELOW IS THE FIRST OF THREE USER-DEFINED FUNCTIONS.
// THIS FUNCTION LISTS ALL FILES IN THE INPUT FOLDER AND ORDERS THEM.
// IT THEN SEQUENTIALLY OPENS EVERY INDIVIDUAL IMAGE VIA BIOFORMATS.
// AFTER OPENING, IT CHECKS THE FILE EXTENSION (TIF, ZVI, FOLDER, OR OTHER) AND
// CATEGORIZES THE IMAGES ACCORDINGLY. IT CREATES AN OUTPUT SUBFOLDER FOR
// EVERY IMAGE. ANY PROCESSED IMAGES WILL BE SAVED IN THIS SUBFOLDER. 

processFolder(input);

function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < 5; i++) {
		run("Bio-Formats Macro Extensions");
		run("Bio-Formats", "open=[" + input + File.separator + list[i] +"] color_mode=Grayscale view=Hyperstack stack_order=XYCZT");
		showProgress(i+1, list.length);
		if (endsWith(list[i], ".TIF") | endsWith(list[i], ".tif")) {
			File.makeDirectory(combined_output + File.getNameWithoutExtension(Image.title) + "_tif_output" + File.separator);
			output = combined_output + File.getNameWithoutExtension(Image.title) + "_tif_output" + File.separator;
			file_type = "tif_";
			GFP = 2;
			DAPI = 1;
			processFile(input, output, list[i]);
		} else if (endsWith(list[i], ".zvi")) {
			File.makeDirectory(combined_output + File.getNameWithoutExtension(Image.title) + "_zvi_output" + File.separator);
			output = combined_output + File.getNameWithoutExtension(Image.title) + "_zvi_output" + File.separator;
			file_type = "zvi_";
			GFP = 2;
			DAPI = 1;
		} else if (File.isDirectory(list[i])) {
			print("It seems like " + list[i] + " is just a folder.");
		} else {
			print("I don't know which file type" + list[i] + " is, so I'll just move on.");
		}
	}
}

// THIS FUNCTION PERFORMS THE ACTUAL IMAGE PROCESSING ON EACH INDIVIDUAL
// IMAGE. USING THE "RESULTSTOEXCEL" PLUGIN, IT CREATES AN EXCEL FILE
// CALLED "ZEBRAFISH_SCRIPT.XLSX" IN THE COMBINED OUTPUT FOLDER.
// MEASUREMENT RESULTS FROM ALL IMAGES WILL BE SAVED IN THIS EXCEL FILE.

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
	// DAPI THRESHOLD (HUANG), WATERSHED AND VORONOI //
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
	// GFP THRESHOLD (MAXENTROPY) AND ANALYZE PARTICLES //
	selectImage(id_AutoGFP);
	run("Duplicate...", "title=MaxEntropy_" + baseName);
	id_MaxEntropy = getImageID();
	setAutoThreshold("MaxEntropy dark");
	setOption("BlackBackground", true);
	run("Convert to Mask");
	selectImage(id_Original);
	// DIALOG BOX PAUSING THE SCRIPT FOR MANUAL ROI SELECTION //
	roiSelectionDialogWindow();
	// CONTINUING ANALYSIS USING THE MANUAL SELECTION //
	roiManager("add");
	roiManager("select", 0);
	roiManager("rename", "ManualSelection_" + baseName);
	roiManager("save selected", output + "ManualSelection_" + baseName + ".roi");
	ManualRoiIndex = roiManager("index");
	setBatchMode("hide");
	// MEASUREMENTS AND VORONOI ROI SELECTION //
	run("Set Measurements...", "area mean redirect=None decimal=2");
	selectImage(id_GFP);
	roiManager("select", ManualRoiIndex);
	roiManager("measure");
	run("Read and Write Excel", "no_count_column stack_results file=[" + combined_output + "zebrafish_script.xlsx] sheet=" + file_type + "ROI_area_MGV");
	run("Clear Results");
	selectImage(id_VoroDuplicate);
	roiManager("select", ManualRoiIndex);
	run("Make Inverse");
	run("Clear", "slice");
	run("Select None");
	saveAs("Tiff", output + "Bounded_Voronoi_" + Image.title);
	selectImage(id_VoroDuplicate);
	run("Select None");
	run("Create Selection");
	roiManager("Add");
	roiManager("select", (ManualRoiIndex + 1));
	VoroRoiIndex = roiManager("index");
	roiManager("rename", "VoronoiSelection_" + baseName);
	roiManager("save selected", output + "VoronoiSelection_" + baseName + ".roi");
	run("Select None");
	run("Set Measurements...", "redirect=None decimal=2");
	selectImage(id_DAPI);
	roiManager("select", ManualRoiIndex);
	run("Find Maxima...", "prominence=10 output=Count");
	run("Read and Write Excel", "no_count_column stack_results file=[" + combined_output + "zebrafish_script.xlsx] sheet=" + file_type + "Maxima");
	run("Clear Results");
	// DAPI-GFP OVERLAYS AND PARTICLE COUNTING //
	run("Set Measurements...", "  redirect=None decimal=0");
	selectImage(id_MaxEntropy);
	roiManager("select", ManualRoiIndex);
	run("Make Inverse");
	run("Clear", "slice");
	run("Select None");
	roiManager("select", ManualRoiIndex);
	Overlay.addSelection("blue", 1);
	roiManager("select", VoroRoiIndex);
	Overlay.addSelection("blue", 1);
	Overlay.flatten;
	saveAs("Tiff", output + "MaxEntropy_" + baseName + "-1");
	setBatchMode("show");
	roiManager("Show None");
	setTool("multipoint");
	waitForUser("Time to count!\n"
	 +" \n"
	 +"Feel free to use the multi-\n"
	 +"point tool that I've selected\n"
	 +"          for you         \n"
	 +" \n");
	run("Measure");
	run("Input/Output...", "jpeg=100 gif=-1 file=.csv copy_row save_row");
	Table.deleteColumn("Y");
	setResult("X", nResults, nResults);
	Table.deleteRows(0, nResults-2);
	Table.renameColumn("X", "Manual_particle_count");
	Table.update;
	run("Read and Write Excel", "no_count_column stack_results file=[" + combined_output + "zebrafish_script.xlsx] sheet=" + file_type + "Multi-point_tool_counts");
	setBatchMode("hide");
	run("Input/Output...", "jpeg=100 gif=-1 file=.csv copy_row save_column save_row");
	run("Clear Results");
	close("*");
	roiManager("reset");
}

function roiSelectionDialogWindow() {
	if (nImages > 0) {
		imageList = newArray(nImages);
		for (i = 0; i < nImages; i++) {
			selectImage(i+1);
			imageList[i] = getTitle();
		}
		imageList = Array.sort(imageList);
		Dialog.create("Please Select An Image");
		Dialog.addMessage("Choose the image you want to use for drawing a manual ROI selection.");
		Dialog.addChoice("Image:", imageList);
		Dialog.show();
		chosenImage = Dialog.getChoice();// Retrieve the user's image of choice
		selectWindow(chosenImage);// Bring the chosen image to the front
		setBatchMode("show");
		setTool("freehand");// Pre-select the freehand selection tool (can be changed or left out entirely)
		waitForUser("ROI Selection", "Draw an ROI selection. Click OK to continue.");// Display window and wait for user to make a selection
	} else if (nImages == 0) {
		showMessage("No Open Images", "There are no images. Something probably went wrong.");
	}
}







