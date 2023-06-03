
## **General presentation:**

Cytosim-GUI runs on top of François Nedelec's cytsokeleton simulation Cytosim that should be compiled separately (see below). Cytosim is a very powerful set of command line applications that operate on Unix systems through the Terminal. It is not user friendly for unexperienced researchers or newcomers, and may become so complex and so long to learn that it could discourage most of the end users.
Here, we propose an Apple Mac OSX graphic user interface (GUI) that runs the Cytosim command line applications as a standalone application, with complete integration, and a set of smart tools.

## **Setup and compilation**

Once downloaded from GitHub, the project needs minor adjustments to compile with XCode (you should have installed it before) :

In the project, select the Cytosim-GUI Target
In the "Signing & Capabilities" page set:
	- Automatically manage signing
	- Team: none
	- Bundle Identifier:  Chris.Cytosim-GUI
	- Signing Certificate:  Sign to Run Locally

In the toolbar of the main window, open the Schemes menu and select "Manage Schemes". In the window that opens click on "Autocreate Schemes Now". The new automatic scheme appears in the list. Select it and click on "Edit". Check that the "Run" configuration displays "Debug" display "Debug" below it. Duplicate this scheme and rename it "Cytosim GUI - release". Set all the appropriate items to "Release" instead of "Debug" under the "Run" and the "Analyze" configurations.

## **Cytosim-GUI instructions in 10 points:**

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
