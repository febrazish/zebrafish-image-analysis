Zebrafish image analysis

This script requires ImageJ 1.53t (or later). Go to "Help > Update ImageJ..."
to check your version and update if necessary.

The script uses a plugin that helps Fiji send data to Excel.
You can download/install it in the Fiji menu:
Go to "Help > Update..." to open the ImageJ updater menu.
Fiji might start updating random files. Just OK everything.
Click on "Manage update sites" (bottom left) to open a list of all plugins.
Find the "ResultsToExcel" plugin and check the box to activate it.
Close the plugin list, go back to the updater menu, and click "Apply changes".
Restart Fiji to complete the installation.

Alternatively, a .jar file containing the entire ReadAndWriteExcel plugin
(freely available under the Apache License Version 2.0) can be downloaded
from the zebrafish-image-analysis GitHub repository.
Just place the Read_and_Write_Excel-1.1.7.jar file in the plugins folder 
of the Fiji.app directory and it should work right away.

The script works best when all input images are together in one folder.
Only tif/tiff files and zvi files will be analyzed, other file formats
will be skipped.

The script starts by asking you to select your input folder, and after
that also your preferred output folder (you can also choose to create a
new output folder at thus point). Within the selected output folder,
a sub-folder will be created for every new image that is being analyzed.
ROIs, histograms, and processed images will be stored there.

The Excel plugin creates an Excel file within the output folder that you selected.
Another pop-up windows will appear asking you to name this Excel file. Measurements
and counts will automatically be saved in this one Excel file.
A minor issue: the plugin is a little unpredictable with the titles that it puts
in the first row of each Excel sheet, but the measurements are always saved
in separate sheets that are named to indicate what type of measurement it is.
The images in the input folder are analyzed in alphabetical order, so the results
will also be in that order. The sheet called "Particles" will contain the indexed
list of file names that have been processed.

RUNNING THE SCRIPT
1. On your PC, find Fiji's folder (probably: YOUR PC\users\fiji-win64\Fiji.app)
2. Put the .ijm script file in the macros sub-folder.
3. Open Fiji and install the macro (Plugins > Macros > Install).
4. Run the macro (Plugins > Macros > zebrafish_macro).
Everything else should happen automatically.


A note on the .ijm file names: Fiji will only recognize a macro script if it
is saved in the macros folder with a specific naming format: files have to end
in the .ijm extension, and there should be at least one underscore (_) in the
file name. So, feel free to rename the script file, but just make sure there is
one underscore (or more) underscore in the name.
