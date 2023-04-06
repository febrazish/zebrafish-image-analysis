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

For the script to work, all input images should be in one folder.
Your input folder should contain only zvi or tif image files.

A new folder (Combined_script_output) will be created in the user's
"home directory" (C:\Users\your_username on Windows systems). Within
Combined_script_output, a sub-folder is created for every new image that is
being analyzed. ROIs, histograms, and processed images are stored there.

The Excel plugin will create one Excel file called "zebrafish_script.xlsx"
in the general output folder. Measurement results are automatically saved here.
A minor issue: the plugin is a little unpredictable with the titles that it puts
in the first row of each Excel sheet, but the measurement data is always saved
in the correct sheet and in the correct order. The images in the input folder
are analyzed in alphabetical order, so the results will also be in that order.

RUNNING THE SCRIPT
1. On your PC, find Fiji's folder (probably: YOUR PC\users\fiji-win64\Fiji.app)
2. Put the .ijm script file in the macros sub-folder.
3. Open Fiji and install the macro (Plugins > Macros > Install).
4. Open the first image from your input folder as you normally would.
5. Run the macro (Plugins > Macros > zebrafish_macro).
Everything else should happen automatically.


A note on the .ijm file names: Fiji will only recognize a macro script if it
is saved in the macros folder with a specific naming format: files have to end
in the .ijm extension, and there should be at least one underscore (_) in the
file name. So, feel free to rename the script file, but just make sure there is
one underscore (or more) underscore in the name.