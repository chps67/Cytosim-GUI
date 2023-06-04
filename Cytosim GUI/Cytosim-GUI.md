
## **General presentation:**

Cytosim-GUI runs on top of François Nedelec's cytoskeleton simulation Cytosim ([https://gitlab.com/f-nedelec/cytosim](https://gitlab.com/f-nedelec/cytosim)) that should be compiled separately (see below). Cytosim is a very powerful set of command line applications that operate on Unix systems through the Terminal. It is not user friendly for unexperienced researchers or newcomers, and may become so complex and so long to learn that it could discourage most of the end users.
Here, we propose an Apple Mac OSX graphic user interface (GUI) that runs the Cytosim command line applications as a standalone application, with complete integration, and a set of smart tools.

## Content:
* Setup and compilation instructions for Cytosim-GUI
* Cytosim-GUI instructions in 10 points
* Polygon design window
* Hints about compiling Cytosim on your mac


### **Setup and compilation**

Once downloaded from GitHub, the project needs minor adjustments to compile with **Apple's XCode** (you should have installed it before) :

Open the "Cytosim GUI.xcodeproj" file and chose "Trust and Open" in the dialog that warns about a project that was downloaded from the internet.

In the project, select the Cytosim-GUI Target
In the "Signing & Capabilities" page set:
	- `Automatically manage signing`
	- Team: `none`
	- Bundle Identifier:  `YOUR_NAME.Cytosim-GUI`
	- Signing Certificate:  `Sign to Run Locally`

In the toolbar of the main window, open the Schemes menu and select "Manage Schemes". In the window that opens click on "Autocreate Schemes Now". The new automatic scheme appears in the list. Select it and click on "Edit". Check that the "Run" configuration displays "Debug" display "Debug" below it. Duplicate this scheme and rename it "Cytosim GUI - release". Set all the appropriate items to "Release" instead of "Debug" under the "Run" and the "Analyze" configurations.

### **Cytosim-GUI instructions in 10 points:**

**1-** Organize your Cytosim command-line application 2D and 3D versions into two folders named "bin2D" and "bin3D". Optionally, Cytosim can be compiled with the `FIBER_HAS_LATTICE` option set to 1. Cytosim-GUI will distinguish these applications if they are located in 2 supplemental folders named "bin2D-latice" and "bin3D-lattice".

**2-** A suggested hierarchy could be : (HOME is the name your Home folder)

	/Users/HOME/Cytosim/Cytosim_Binaries/
	
	contains:
		/Users/HOME/Cytosim/Cytosim_Binaries/bin2D/
		/Users/HOME/Cytosim/Cytosim_Binaries/bin2D-lattice/
	
	and: 
		/Users/HOME/Cytosim/Cytosim_Binaries/bin3D/
		/Users/HOME/Cytosim/Cytosim_Binaries/bin3D-lattice/
	
	The working directory is:
		/Users/HOME/Cytosim/Working_directory/


**3-** Prepare an empty folder of your choice that will function as a working folder for Cytosim-GUI.

**4-** Launch Cytosim-GUI.

**5-** Set up the application through the "Setup" menu or through the "Directory settings" palette. Setting the Binaries folder path and the Work directory path are mandatory.

Chosing the menu item entitled "Set Binaries Directory..." or "Set Working Directory..." opens a dialog where you can type, drag and drop from the finder or select through the standard open panel the directory. Using the Directory settings palette, you may chose a folder or drop it from the finder.

> *The previous steps shoud be done only once at the first launch.*

**6-** Open a configuration file to make a simulation (for examples, pick from the "cym" folder in the cytosim project). A good practice is to copy such file into your working directory together with attached files like a .txt polygon definition for example. Several configuration files can be openend and edited at the same time.

* The configration file (.cym extension) is displayed with default syntax coloring that you can change (click in the Syntax Color tool from the document's window top bar). Also you can change the font or print the document contents by clicking the "Fonts" and "Print" tools. To navigate the .cym file content, chose an item in the "Display object" menu. For  better reactivity in syntax coloring, changes you make to the text should be parsed manually (Parse tool) to feed this menu.

* To comment or uncomment lines, end of lines or even blocks of text, select the text you want to operate on and click the "Block (Un)Comment" tool at the top of the window.  
* To indent or de-indent text, select a block of text and click the "Shift right" or "Shift left" tool.
* Configuration file content has to comply with Cytosim syntax. To help in building a new configuration, a graphical design tool is also under development (Model tool; unfinished).   
* You can make Cytosim-GUI automatically manage parameter variations (Variations tool). Variations are set as a series of y values computed from an interval of x values with linear or non-linear models. The graph in the variations window shows the interpolated values. To actually set a parameter to vary, check the "Use it" button in the outline view. The variations are recorded in a .cymvar file created when the configuration file is saved. Running "Sim" variations is commanded from the "Batch run" section (that can be unfolded by pressing the down arrow button) of the "Run Control" palette. Set the desired window size before depressing the "Sim batch" button. For optimal performance, only 4 simulations will be run in parallel at a time. Simulation results are targeted to specific subfolders of the batch folder hierarchy created in the Working directory. The results can be displayed (4 by 4) by Cytosim's Play applications when clicking on "Show variations". 

**7-** You can chose to run the simulation in several ways, from the "Run control" palette or from the "Run" menu. Launching any type of simulation will operate on the top configuration window. Selecting the menu items requires that the top configuration window is activated. 

Depending on the configuration file, first select if you will run the 2D or the 3D version of Cytosim's Play application. Checking the Lattice button will select the appropriate version. 

**NB:** *You may launch concurently as many simulations as you want. All the instances will appear in the "Running Task" PopUp menu of the "Run Control" palette. You can suspend, resume or stop the task selected in this menu using the neighbor buttons.*

You may chose among three types of run:

* "Play live" (command-L key equivalent) will operate in real time without recording any file. During the run, you can control the Cytosim's Play application via a local menu (right-click) or via the keyboard. For convenience, a window that recapitulates all the commands can be opened via the "Play help..." button in the "Run Control" palette.
* "Sim" with the "Auto" button checked in the "Directory settings" palette (or selected in the Setup menu) will automatically create a new folder in the working directory. This folder is named after your configuration file and also comprises the run number, the date and time of creation. The simulation folder will contain the "objects.cmo" and "properties.cmo" created for this run, plus a copy of the configuration file with a "_Trace" suffix added. Simulations launched this way operate completely in the background. 
* To play the results or to extract measurements of a prior simulation ("Play from Sim Dir" or "Analyze" menu or palette), uncheck the "Auto" button in the "Directory settings" palette or chose " Use the directory of a previous simulation" from the Simulation Directory submenu.

**8-** Messages can be sent to the simulation objects during a "Play live" operation. Open the "Message to Running Task" palette (click on the "Message to task..." button in the "Run Control"). There, chose the command, the object and the property you want to target and adjust its value (use the slider or type directly the wanted value in the adjacent text field).

**9-** All the simulations/play operations are logged in the "Log" window. Its content can be saved as a .txt file. All the text that appears in green can be copied and pasted in the Terminal application to run Cytosim in the command line mode. Be aware that ending a task with the stop button of the "Run Control" palette will not display Cytosim's warnings in the Log window. Conversely, stopping an operation with the Cytosim's command will result in red-colored text output if errors or warning are raised.

**10-** Configuration files may need a .txt file that describes the points of a polygon. Such file is named explicitely in the configuration file and should be located in the same folder as the configuration file to run properly. A graphic editor for designing such files is included under the item "Show drawing window" in the "Window" menu.

### Polygon design window

In Cytosim, polygons are designed by a list of xy coordinates saved in a text (.txt) file separate from the configuration (.cym) file. In Cytosim-GUI, drawing such polygons at the right scale (with or without a template image) and their export in .txt files is made easy with the polygon design tool.

* The window can display or not a model image as a template to follow manually when building the polygon. To open a new image, click the "Open background" button at the bottom left. The image is automatically scaled and centered on the grid's origin (0,0) but it keeps the same size ratio as the original. To dim the image and facilitate polygon seeing, click the "Transparent" checkbox at the top right of the window. To remove the background image, click the "Clear background" button. To hide or show the grid, operate on the "Show/Hide Grid" tool in the window's toolbar.
* Below the toobar, the box entitled "Grid" controls the global size and scale of the grid. 1 square = 1µm. Whatever the changes you make, when adjusting the sliders, the origin (0,0) always remains at the center of the window. Just move the polygon globally to shift the coordinates (click inside a closed polygon and drag the mouse). The location of the mouse (either clicked or not) is displayed in µm units at the x and y coordinates.
* The "Polygon zoom" slider scales the polygon coordinates respective to its barycentre, not to the point (0,0) of the grid. Note that part of a polygon may lie outside of the grid. This does not preclude correct coordinates saving.
* The default color for drawing polygons is red, but you may change it via the "Color" tool.
* Mouse and keyboard control of polygon building are as follows:
	* click in the window : add a new handle
	* release mouse button while building a polygon shows the last segment linked to the mouse cursor
	* click inside and drag it to move a handle
	* double clicking when adding a point automatically adds it and closes the polygon (no open polygons allowed)
	* shift-click in a handle adds a point at the middle of the segment comprised between the click and the previous handle
	* alt/option-click in a handle removes it.
	* click and drag inside a closed polygon moves it around to follow the mouse
	* zoom in or out without changing the scale of the polygon or that of the grid using two fingers on a trackpad. 
* Print a polygon in black and white, without the handles and the marching ants by clicking on the "Print" tool. The full grid size covers the page width.
* Save a polygon to disk by clicking on the "Save" button
* A click in the "Clear" botton erases the polygon without warning (sorry for that, undo/redo is not implemented yet)
* Closing the "Drawing window" does not erase the polygon (it will appear the same way when you re-open the window), but trying to quit Cytosim GUI will give you a chance to save any unsaved polygon or to resign saving.

### Hints about Cytosim compilation on your mac

*Preliminary remark 1: The support of OpenGL libraries was dropped by Apple some years ago when they introduced Metal, but it is still present and effective for Intel Macs and also for Apple's Silicon chips (ARM64 architecture). OpenGL is mandatory to compile Cytosim applications and libraries (not to build and run Cytosim GUI).*

*Preliminary remark 2: Some parts below are quite technical but are the exact transcription of what I had to do to correctly compile Cytosim's command line applications with XCode*

####How to compile Cytosim using XCode:
* Make sure you have XCode and the appropriate XCode development tools installed


* Download a "cytosim-master" archive from the Cytosim site on GitLab and uncompress it


* The "cytosim-master" folder that is extracted contains an XCode project entitled cytosim.xcodeproj. Open it and chose "Trust and Open" in the dialog that warns about a project that was downloaded from the internet.

* Cleaning of the project
	* Some releases of the cytosim.xcodeproj (like the one I downloaded as of Dec 5th 2022 to write this step by step guide) miss files in the project although they are present among the distributed source files and need some further cleaning to be properly compiled. In my case, the files named `"display.h" , "display.cc" and "display_prop.h"` were not correctly attached to the project. After finding them (in the src/disp/ directory of the cytosim-master folder you just dowloaded) a drag and drop to the list of files to the left panel of the XCode window should fix the problem.
	* Also, two frameworks were not correctly configured in the project: OpenGL and GLUT, which appeared twice with one GLUT sample in red (meaning the file is not found).  Select the red GLUT.framework and discard it by typing a backspace. Select the remaining GLUT.framework and make sure in the right panel of XCode (target membership) that all the items called `"play", "test_glapp", "test_rasterizer" and "test_grid"` are checked otherwise the framework will not be linked with the products. Proceed in a similar way with the OpenGL.framework, but to identify the one you should discard, check the directory locations first by right-cliking on each and selecting "Show in Finder".  Keep the one that is not located in /System/Library/Frameworks/ and again, check the "Target Membership" on the right, the same as for the GLUT.framework.
	* Apple also dropped some years ago the GNU's OpenMP library. As it is required for speeding up Cytosim runs in optimizing the use of up to 4 processor cores in parallel, you should download and install it as indicated here (files and instructions come from [https://mac.r-project.org/openmp/](https://mac.r-project.org/openmp/)). You should collect several files first : the headers "omp.h", "ompt.h" and "omp-tools.h" should be located into the directory /usr/local/include/; the dynamic library "libomp.dylib" should be located into /usr/local/lib/. To do this operation easily from the Mac's Finder, type shift-command-G and type the appropriate directory path you want to go to. /usr/local/include/ and /usr/local/lib/ should then be added to the cytosim.xcodeproj for the project to know where to search. To do that, select the "cytosim" project item at the top, in the left panel of the XCode window, then in the middle panel, select "sim" under TARGETS. At the top-right of the main panel, enter "search" in the filter field. It should go to "Search Paths". There, double-click in the right half of the row entitled "Header Search Paths" and a PopUp window will open. Click on the (+) sign and enter "usr/local/include/" in the field that appears (see the figure). Proceed the same way with "Library search paths" and enter "/usr/local/lib/". Repeat the setting of the search paths for the other targets: "play", "sieve", "frametool" and "report". Also add "/Library/Frameworks/" to the "Framework Search Paths" of the same targets. Finally, add the "libomp.dylib" to the project (drag and drop into the lib folder of the project).
* At last, your project should allow the building of the applications now. You should compile at least 2 versions of the Cytosim (2D and 3D). A 1D version is also permitted by Cytosim, but not supported by Cytosim-GUI. The 2 or 3 dimensions flavour is controlled by the value of a global variable called DIM, which is defined in a file named dim.h (located in src/math/dim.h). The default dimension value is 2 (#define DIM 2). You can switch to the 3D version by setting #define DIM 3. For each dimension, you will also need to build two versions of the applications depending on the value (0 or 1) of the flag `FIBER_HAS_LATTICE` located in sim/Fibers/fiber.h. 
* To make a flavour of Cytosim's command line applications, chose "Archive" in the "Product" menu of XCode. In the window that opens, click on "Distribute App", then chose "Copy App" and select the distination with the Save dialog that appears. As the name of the apps are always the same (in 2D, 3D, with of without lattice support), store them immediately in the appropriate folders as recommended above.
* Your mac is expected to complain when each command line app will be launched for the first time. To fix this issue, open the System preferences application and go to the Confidentiality and Security part. There, in the Security part, you should find a place to override the finder's security warning message and allow the app to be launched. This operation has to be renewed for each app and flavour.




