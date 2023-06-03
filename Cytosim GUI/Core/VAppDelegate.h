//
//  AppDelegate.h
//  Cytosim GUI
//
//  Created by Chris on 14/08/2022.
//

#import <Cocoa/Cocoa.h>
#import "VAutoSelectTextField.h"
#import "VNamedTask.h"
#import "VConfigObjectCreator.h"

// GLOBAL variables
//---------------------------------------------
#ifndef TASK_LIMIT
    #define TASK_LIMIT 4
#endif

#ifndef NUM_HELP_IMAGES
    #define NUM_HELP_IMAGES 20
#endif

//---------------------------------------------

@class VPolygonDrawingView;
@class VModelDrawingView;

@interface VAppDelegate : NSObject <NSApplicationDelegate, NSMenuItemValidation, NSPathControlDelegate>

enum urlType {
    UrlNotValid,
    Directory,
    File,
    FileWithValidExtension
};

                // Setup properties ------------

@property (weak)    IBOutlet    NSWindow*               directoryEntryWindow;
@property (weak)    IBOutlet    VAutoSelectTextField*   directoryEntryField;
@property (weak)    IBOutlet    NSTextField*            directoryEntryType;

                // global URLs, shared by all the docs i.e. only in AppDelegate

@property (strong)              NSURL*                  binariesURL;
@property (strong)              NSURL*                  workingURL;

@property (strong)  IBOutlet    NSMenuItem*             binariesDirItem;
@property (strong)  IBOutlet    NSMenuItem*             workingDirItem;

                // document's simulation directory ------

@property (strong)              NSURL*                  simURL;
@property (strong)  IBOutlet    NSMenuItem*             simDirItem;
@property (assign)              BOOL                    autoSimDirectory;
@property (strong)  IBOutlet    NSMenuItem*             autoSimDirItem;
@property (strong)  IBOutlet    NSMenuItem*             useExistingDirItem;

@property (assign)              NSNumber*               batchRun;           // Boolean with IB binding so it is a NSNumber, not a BOOL (bof)
@property (assign)              BOOL                    batchPlay;          // also compatible with IB binding to a view
@property (assign)              NSNumber*               allowBatchRun;      // boolean to control "Run batch" button enabling in the Run panel
@property (assign)              NSNumber*               aDocIsOpen;
@property (strong)              NSURL*                  variationsURL;
@property (strong)  IBOutlet    NSMenuItem*             variationsDirItem;
@property (assign)              NSNumber*               batchSimWidth;
@property (assign)              NSNumber*               batchSimHeight;

@property (assign)              BOOL                    okForSim;
@property (assign)              BOOL                    okForPlay;
@property (assign)              BOOL                    okForBatchPlay;
@property (assign)              BOOL                    okForLivePlay;
@property (assign)              BOOL                    okForReport;
@property (assign)              BOOL                    okForBinDisplay;
@property (assign)              BOOL                    okForWorkDisplay;
@property (assign)              BOOL                    okForSimDisplay;

                // Setup control palette ------------

@property (weak)    IBOutlet    NSPanel*                directorySettingsWindow;
@property (strong)  IBOutlet    NSPathControl*          binDirPath;
@property (strong)  IBOutlet    NSPathControl*          workDirPath;
@property (strong)  IBOutlet    NSPathControl*          simDirPath;
@property (strong)  IBOutlet    NSPathControl*          varDirPath;
@property (strong)  IBOutlet    NSButton*               autoSimDirButton;

                // For debugging panel -------------

@property (strong)              NSString*               topDocName;
@property (strong)              NSString*               binPath;
@property (strong)              NSString*               workPath;
@property (strong)              NSString*               simPath;
@property (strong)              NSString*               varPath;


                // Run properties --------------

@property (weak)    IBOutlet    NSWindow*               runControlWindow;
@property (strong)              NSURL*                  cymFileURL;
@property (assign)              BOOL                    askForDocSavingBeforeRun;

@property (assign)              BOOL                    runIn3D;
@property (strong) IBOutlet     NSButton*               runIn2DButton;
@property (strong) IBOutlet     NSButton*               runIn3DButton;
@property (assign)              BOOL                    fibersHaveLattice;
@property (assign)              NSUInteger              simCounter;
@property (strong)              NSDate*                 folderCreationDate;

@property (strong) IBOutlet     NSButton*               simButton;

@property (strong) IBOutlet     NSButton*               playButton;
@property (strong) IBOutlet     NSButton*               playLiveButton;

@property (strong) IBOutlet     NSButton*               stopButton;
@property (strong) IBOutlet     NSButton*               suspendButton;
@property (strong) IBOutlet     NSButton*               resumeButton;
@property (strong) IBOutlet     NSProgressIndicator*    batchSimProgress;
@property (strong) IBOutlet     NSButton*               stopAllButton;

@property (strong) IBOutlet     NSButton*               runtimeChangeButton;

@property (strong)              VNamedTask*             curRunningTask;
@property (assign)              BOOL                    tasksAreRunning;
@property (strong)              NSMutableArray*         runningTasks;
@property (assign)              NSInteger               taskInstanceCounter;
@property (assign)              NSInteger               activeTaskNumber;
@property (strong) IBOutlet     NSPopUpButton*          runningTasksPopUp;
@property (strong)              NSMutableArray*         batchSimURLs;
@property (strong)              NSMutableArray*         batchPlayURLs;
@property (strong)              NSMutableArray*         playInstances;
//@property (strong)              NSTimer*                appInspectionTimer;

                // messages to running tasks  --------------

@property (strong) IBOutlet     NSPanel*                taskMessagePanel;
@property (strong) IBOutlet     NSPopUpButton*          sendCommandPopup;
@property (strong) IBOutlet     NSPopUpButton*          targetObjectPopup;
@property (strong) IBOutlet     NSPopUpButton*          targetPropertyPopup;
@property (assign)              BOOL                    targetValueControlActive;
@property (strong) IBOutlet     NSSlider*               targetValueSlider;
@property (strong) IBOutlet     NSTextField*            targetValueField;
@property (strong)              NSNumber*               targetValue;
@property (strong) IBOutlet     NSTextField*            minScaleField;
@property (strong) IBOutlet     NSTextField*            maxScaleField;
@property (strong)              NSNumber*               minScaleValue;
@property (strong)              NSNumber*               maxScaleValue;
@property (strong) IBOutlet     NSButton*               linearScaleButton;
@property (strong) IBOutlet     NSButton*               logScaleButton;
@property (strong) IBOutlet     NSTextField*            expressionTextField;
@property (strong) IBOutlet     NSButton*               sendMessageButton;

                    // Log  --------------

@property (strong) IBOutlet     NSTextView*             logTextView;

                    // Analyze properties  --------------

@property (assign)              BOOL                    reportIn3D;
@property (strong) IBOutlet     NSButton*               reportIn2DButton;
@property (strong) IBOutlet     NSButton*               reportIn3DButton;
@property (strong) IBOutlet     NSPopUpButton*          reportArguments;

                    // cym files syntax coloring --------------

@property (strong) IBOutlet     NSPanel*                syntaxColoringPanel;
@property (strong) IBOutlet     NSColorWell*            commandsColorWell;
@property (strong) IBOutlet     NSColorWell*            objectsColorWell;
@property (strong) IBOutlet     NSColorWell*            namesColorWell;
@property (strong) IBOutlet     NSColorWell*            parametersColorWell;
@property (strong) IBOutlet     NSColorWell*            numbersColorWell;
@property (strong) IBOutlet     NSColorWell*            commentsColorWell;
@property (strong) IBOutlet     NSColorWell*            punctuationColorWell;


                    // cym file code insertion --------------

@property (strong) IBOutlet     NSWindow*               modelDesignWindow;
@property (strong) IBOutlet     NSPopUpButton*          buildCommandPopUp;
@property (strong) IBOutlet     NSPopUpButton*          buildObjectPopUp;
@property (strong) IBOutlet     NSTextField*            nameFieldTitle;
@property (strong) IBOutlet     NSTextField*            nameField;
@property (strong) IBOutlet     NSTextField*            numberFieldTitle;
@property (strong) IBOutlet     NSTextField*            numberField;
@property (strong) IBOutlet     NSTextField*            colorTitle;
@property (strong) IBOutlet     NSColorWell*            colorWell;
@property (strong) IBOutlet     NSOutlineView*          paramOutlineView;
@property (strong) IBOutlet     NSTextField*            paramHelpField;
@property (assign)              NSInteger               helpIconsOnFirstLine;
@property (assign)              NSInteger               helpIconsOnSecondLine;

@property (strong) IBOutlet     VConfigObjectCreator*   configObjectCreator;

                    // interactive polygon drawing --------------

@property (strong) IBOutlet     NSWindow*               polygonDrawingWindow;
@property (strong) IBOutlet     VPolygonDrawingView*    polygonDrawingView;

@property (assign)              NSNumber*               xPolygonValue;
@property (assign)              NSNumber*               yPolygonValue;
@property (strong) IBOutlet     NSTextField*            xPolygonValueField;
@property (strong) IBOutlet     NSTextField*            yPolygonValueField;

@property (assign)              NSNumber*               polygonScale;
@property (assign)              NSNumber*               polygonNumMicrons;         // side of a square field
@property (strong) IBOutlet     NSSlider*               polygonScaleSlider;
@property (strong) IBOutlet     NSSlider*               polygonNumMicronsSlider;
@property (strong) IBOutlet     NSTextField*            polygonScaleField;
@property (strong) IBOutlet     NSTextField*            polygonNumMicronsField;

@property (assign) IBOutlet     NSTextField*            polygonZoomTextField;
@property (assign)              NSNumber*               polygonZoom;
@property (strong) IBOutlet     NSSlider*               polygonZoomSlider;

@property (strong) IBOutlet     NSButton*               openBackgroundImageButton;
@property (strong) IBOutlet     NSButton*               clearBackgroundButton;
@property (strong) IBOutlet     NSButton*               polygonBackTransparencyCheckBox;

@property (strong) IBOutlet     NSButton*               clearButton;
@property (strong) IBOutlet     NSButton*               openPolygonButton;
@property (strong) IBOutlet     NSButton*               savePolygonButton;

                    // interactive model drawing --------------

@property (strong) IBOutlet     VModelDrawingView*      modelDrawingView;
@property (strong) IBOutlet     NSImageView*            modelSimulationIcon;
@property (assign)              NSNumber*               xModelValue;
@property (assign)              NSNumber*               yModelValue;
@property (strong) IBOutlet     NSTextField*            xModelValueField;
@property (strong) IBOutlet     NSTextField*            yModelValueField;
@property (assign)              NSNumber*               modelScale;
@property (assign)              NSNumber*               modelNumMicrons;         // side of a square field
@property (strong) IBOutlet     NSSlider*               modelScaleSlider;
@property (strong) IBOutlet     NSSlider*               modelNumMicronsSlider;
@property (strong) IBOutlet     NSTextField*            modelScaleField;
@property (strong) IBOutlet     NSTextField*            modelNumMicronsField;



@property (strong)              NSDictionary*           toolTipsDictionary;

                    // Setup Methods --------------

- (BOOL)        runInDarkMode;
- (IBAction)    raiseDirectoryEntry:(id)sender;
- (IBAction)    dismissDirectoryEntry:(id)sender;
- (IBAction)    validateDirectoryEntry:(id)sender;
- (IBAction)    choseDirectoryEntry: (id)sender;
- (IBAction)    doSetupMenu:(id) sender;
- (IBAction)    doPathControl:(id)sender;
- (void)        checkSetup;
- (IBAction)    updatePalettes:(id)sender;
- (void)        defaultColors;
- (IBAction)    colorsForDarkMode:(id)sender;
- (IBAction)    colorsForLightMode:(id)sender;

                    // Run Methods --------------

- (IBAction)    changeDimension:(id)sender;
- (IBAction)    changeFiberLattice:(id)sender;
- (NSDocument*) topDoc;
- (BOOL)        hasTopDoc;
- (void)        aDocWindowBecameMain:(NSNotification*) aNotif;
- (IBAction)    runMenu:(id) sender;
- (IBAction)    showTopDocVariationsWindow:(id)sender;

- (NSString*)   completeDateStringFromDate:(NSDate*)date;
- (void)        createSimDirectory;

- (IBAction)    launchTask:(id)sender;
- (IBAction)    stopTask:(id)sender;
- (IBAction)    suspendTask:(id)sender;
- (IBAction)    resumeTask:(id)sender;
- (IBAction)    changeCurRunningTask:(id)sender;
- (IBAction)    stopAllTasks:(id)sender;
- (IBAction)    batchSim:(id)sender;
- (IBAction)    batchPlay:(id)sender;
- (IBAction)    batchNextGroup:(id)sender;

- (IBAction)    toggleBatchRunView:(id)sender;

                    //Send messages ---------------

- (IBAction)    changeCommand:(id)sender;
- (IBAction)    changeObject:(id)sender;
- (IBAction)    changeParameter:(id)sender;
- (IBAction)    changeParameterValue:(id)sender;
- (IBAction)    sendMessageToRunningTask: (id)sender;

                    // Analyze Methods --------------

- (IBAction)    analyzeMenu:(id)sender;

                    // Edit Configuration File ------

- (IBAction)    blockComment:(id)sender;
- (IBAction)    shiftRight:(id)sender;
- (IBAction)    shiftLeft:(id)sender;
- (IBAction)    insertCodeSnippet:(id)sender;

                    // PlaceHolder --------------

-(IBAction)     placeHolder:(id)sender;

                    // Polygon Drawing ----------

-(IBAction)     chosePolygonScale:(id)sender;
-(IBAction)     chosePolygonNumMicrons:(id)sender;
-(IBAction)     changePolygonZoom:(id)sender;
-(IBAction)     togglePolygonTransparency:(id)sender;
-(IBAction)     clearPolygonBackgroundImage: (id) sender;
-(IBAction)     openPolygonFile: (id) sender;
-(IBAction)     savePolygonFile: (id) sender;
-(IBAction)     printPolygon: (id) sender;

                    // Model Drawing ----------

-(IBAction)     choseModelScale:(id)sender;
-(IBAction)     choseModelNumMicrons:(id)sender;
-(IBAction)     makeConfigurationFromModel:(id)sender;
-(IBAction)     modelInsertSimulation:(id)sender;
-(IBAction)     modelInsertSpace:(id)sender;
-(IBAction)     modelInsertFiber:(id)sender;
-(IBAction)     modelInsertChimericProtein:(id)sender;


                    // Code Snippet Insertion ------

-(IBAction)     choseCommandAndObjectCombination:(id)sender;

@end
