//
//  AppDelegate.m
//  Cytosim GUI
//
//  Created by Chris on 14/08/2022.
//

#import "VAppDelegate.h"
#import "VDocument.h"
#import "VDocumentController.h"
#import "VConfigObject.h"
#import "VConfigParameter.h"
#import "VCymParameter.h"
#import "VPolygonDrawingView.h"
#import "VModelDrawingView.h"

#import "NSTask_Inspector.h"

@interface VAppDelegate ()

@end

@implementation VAppDelegate

#pragma mark ========== OVERRIDES ==========

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    
    // BEWARE ! IT IS NORMAL TO HAVE A "Unused variable warning" here
    VDocumentController* docCtrl = [[VDocumentController alloc]init];
    // It is not clear why, but this NSDocupentController subclass will actually
    // replace the default controller and prevent do restoration....even though
    // the instance created is not used or stored in an VAppDelegate's variable
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    // Insert code here to initialize your application
    
    self.okForSim = NO;
    self.okForPlay = NO;
    self.okForBatchPlay = NO;
    self.okForLivePlay = NO;
    self.okForReport = NO;
    self.askForDocSavingBeforeRun = YES;

    
    // Read defaults, check and set the URLs accordingly
    NSUserDefaults* def = [NSUserDefaults standardUserDefaults];
    NSURL* tempURL;
    
    //%%%%%%%%%%%%% binaries
    
    @try{
        tempURL = [NSURL fileURLWithPath:[def valueForKey:@"binariesPath"]];
        if ([self checkURLType:tempURL WithExtension:@""] == Directory) {
            self.binariesURL = tempURL;
            self.binariesDirItem.title = self.binariesURL.path;
            self.okForBinDisplay = YES;
            
            self.binPath = self.binariesURL.path;
        }
    }
    @catch (NSException *exception) {
        self.binariesURL = nil;
        self.binariesDirItem.title = @"No Binaries Directory";
        self.okForBinDisplay = NO;

        self.binPath = @"";
    }
    @finally {
        //self.okForSim = (self.binariesURL != nil) && (self.workingURL !=nil);
        //self.okForLivePlay = self.okForSim;
    }
    self.binDirPath.URL = self.binariesURL;

    //%%%%%%%%%%%%% work

    @try {
    tempURL = [NSURL fileURLWithPath:[def valueForKey:@"workDirPath"]];
    if ([self checkURLType:tempURL WithExtension:@""] == Directory) {
        self.workingURL = tempURL;
        self.workingDirItem.title = self.workingURL.path;
        
        self.workPath = self.workingURL.path;
        //self.workingDirItem.enabled = YES;
    }
    }
    @catch (NSException* exception) {
        self.workingURL = nil;
        self.workingDirItem.title = @"No Working Directory";
        
        self.workPath = @"";
    }
    @finally {
        self.okForWorkDisplay = (self.workingURL != nil);
        //self.okForSim = (self.binariesURL != nil) && (self.workingURL !=nil);
        //self.okForLivePlay = self.okForSim;
    }

    self.workDirPath.URL = self.workingURL;

    //%%%%%%%%%%%%% sim

    @try {
        tempURL = [NSURL fileURLWithPath:[def valueForKey:@"simDirPath"]];
        if ([self checkURLType:tempURL WithExtension:@""] == Directory) {
            self.simURL = tempURL;
            self.simDirItem.title = self.simURL.path;
            
            self.simPath = self.simURL.path;
            //self.workingDirItem.enabled = YES;
        }
    }
    @catch (NSException *exception) {
        self.simURL = nil;
        self.simDirItem.title = @"Automatic";
        
        self.simPath = self.simURL.path;
        //self.workingDirItem.enabled = NO;
    }
    @finally {
        self.autoSimDirectory = (self.simURL == nil);
        self.okForPlay = (self.simURL != nil);
        self.okForReport = (self.simURL != nil);
    }

    [self checkSetup];
    self.simDirPath.URL = self.simURL;

    //%%%%%%%%%%%%% variations

    self.varDirPath.URL = self.variationsURL;
    self.varPath = @"";
    
    //§§§§§§§§§§§§§§§§§§§§§§§ Color management for syntax coloring of s
    
    if ([self runInDarkMode]) {
        [self colorsForDarkMode:self];
    } else {
        [self colorsForLightMode:self];
    }

    // read the user's colors set in the previous run if any.
    // Run these functions after setting the default above
    if ([self colorForKey:@"commentsColor"])
        self.commentsColorWell.color = [self colorForKey:@"commentsColor"];
    if ([self colorForKey:@"commandsColor"])
        self.commandsColorWell.color = [self colorForKey:@"commandsColor"];
    if ([self colorForKey:@"objectsColor"])
        self.objectsColorWell.color = [self colorForKey:@"objectsColor"];
    if ([self colorForKey:@"namesColor"])
        self.namesColorWell.color = [self colorForKey:@"namesColor"];
    if ([self colorForKey:@"parametersColor"])
        self.parametersColorWell.color = [self colorForKey:@"parametersColor"];
    if ([self colorForKey:@"numbersColor"])
        self.numbersColorWell.color = [self colorForKey:@"numbersColor"];
    if ([self colorForKey:@"punctuationColor"])
        self.punctuationColorWell.color = [self colorForKey:@"punctuationColor"];

    
    // §§§§§ notification to intercept changes in the activation of documents or in snippetPanel resizing
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(aDocWindowBecameMain:) name:
     NSWindowDidBecomeMainNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(snippetPanelDidResize:) name:
     NSWindowDidResizeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(batchRunFeed:) name:
    @"feedBatchRun" object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(batchPlayFeed:) name:
    @"feedBatchPlay" object:nil];

    // §§§§§§§§  Run parameters and properties
    
    self.folderCreationDate = [NSDate distantPast];
    self.runIn3D = NO;
    self.fibersHaveLattice = NO;
    self.simCounter = 0;
    self.taskInstanceCounter = 0;
    self.activeTaskNumber = 0;
    self.runningTasks = [NSMutableArray arrayWithCapacity:0];
    [self.runningTasksPopUp removeAllItems];
    self.curRunningTask = nil;
    self.batchRun = @NO;
    self.batchPlay = NO;
    self.batchSimWidth = @512;
    self.batchSimHeight = @512;
    self.allowBatchRun = @NO;       // just copied from the VParamVariationsManager's
    self.batchSimURLs = [NSMutableArray arrayWithCapacity:0];
    self.batchPlayURLs = [NSMutableArray arrayWithCapacity:0];
    self.batchSimProgress.minValue = 0.0;
    self.batchSimProgress.maxValue = 100.0;
    self.batchSimProgress.doubleValue = 0.0;

    
    // temporarily set to yes only for debugging raiseMessagePanel, otherwise = no
    self.tasksAreRunning = NO;
    
    // To match all the lauched apps and intercept 'play' application instances
    //self.playInstances = [NSMutableArray arrayWithCapacity:0];
        
    //§§§§§§§§§ config object creator already instatiated in IB
    
    self.configObjectCreator.paramDataSource = [NSMutableArray arrayWithCapacity:0];
    self.configObjectCreator.configObjectsDic = [NSMutableDictionary dictionaryWithCapacity:0];
    [self.configObjectCreator preloadCymObjectFiles];
    
    self.buildCommandPopUp.autoenablesItems = NO;
    self.buildObjectPopUp.autoenablesItems = NO;

    //§§§§§§§§§ initialize drawing window's VPolygonDrawingView
    
    if (self.polygonDrawingWindow) {
        
        NSArray* subViews = self.polygonDrawingWindow.contentView.subviews;
        for (NSView* aView in subViews) {
            if ([aView isMemberOfClass:[NSScrollView class]]) {
                VPolygonDrawingView* dView = (VPolygonDrawingView*)(((NSScrollView*)aView).documentView);
                if ([dView isMemberOfClass:[VPolygonDrawingView class]]) {
                    [dView initialize];
                }
            }
        }
        
        self.polygonZoom = @1.00;
    }
    
    //§§§§§§§§§ initialize drawing window's VModelDrawingView
    
    if (self.modelDesignWindow) {
        
        NSArray* subViews = self.modelDesignWindow.contentView.subviews;
        for (NSView* aView in subViews) {
            if ([aView isMemberOfClass:[NSScrollView class]]) {
                VModelDrawingView* dView = (VModelDrawingView*)(((NSScrollView*)aView).documentView);
                if ([dView isMemberOfClass:[VModelDrawingView class]]) {
                    [dView initialize];
                }
            }
        }
        
        self.polygonZoom = @1.00;
    }

    //§§§§§§§§§ initialize a dictionary from the Tool_Tips.plist file

    NSString *tipsPath = [[NSBundle mainBundle] pathForResource:@"Tool_Tips" ofType:@"plist"];
    NSDictionary* tipsDic = [[NSDictionary alloc]init];
    tipsDic = [NSDictionary dictionaryWithContentsOfFile:tipsPath];
    
    [self installToolTipsFromDitionary:tipsDic intoWindow:self.directorySettingsWindow];
    [self installToolTipsFromDitionary:tipsDic intoWindow:self.runControlWindow];
    [self installToolTipsFromDitionary:tipsDic intoWindow:self.taskMessagePanel];
    [self installToolTipsFromDitionary:tipsDic intoWindow:self.polygonDrawingWindow];
        
    self.colorTitle.hidden = YES;
    self.colorWell.hidden = YES;

//    //§§§§§§§§§ Set icon for files
// ?
    //§§§§§§§§§§§ post a timer for NSWorkspace inspection

//    self.appInspectionTimer = [NSTimer scheduledTimerWithTimeInterval:5 repeats:YES block:^(NSTimer * _Nonnull timer) {
//        if (self.batchPlay) {
//            NSWorkspace* ws = [NSWorkspace sharedWorkspace];
//            NSArray* appsRunning = [[ws runningApplications] copy];
//            for (NSRunningApplication* anApp in appsRunning) {
//                NSInteger appID =  [anApp processIdentifier];
//                NSInteger taskIndex = [self.runningTasksPopUp indexOfSelectedItem];
//                NSNumber* taskID = [self.playInstances objectAtIndex:taskIndex];
//                if (appID == taskID.integerValue) {
//                    NSString* outString = @"found app ID = ";
//                    outString = [outString stringByAppendingString:[NSNumber numberWithInteger:appID].stringValue];
//                    NSLog(@"%@", outString);
//                    [anApp activateWithOptions:NSApplicationActivateAllWindows];
//                    break;
//                }
//            }
//        }
//    }];
}

//-----------------------------------------------------------------------------

- (void) installToolTipsFromDitionary:(NSDictionary*)aDic intoWindow:(NSWindow*) aWindow {
    
    NSArray* subViewsFromWindow = [aWindow.contentView subviews];
    for (NSInteger k = 0; k < subViewsFromWindow.count; k++) {
        NSView* aSubview = [subViewsFromWindow objectAtIndex:k];
        if (aSubview.identifier) {
            if (![aSubview.identifier isEqualToString:@""]) {
                NSString* subID = aSubview.identifier;
                NSString* tip = [aDic objectForKey:subID];
                aSubview.toolTip = [tip copy];
            }
        }
    }
}

//-----------------------------------------------------------------------------

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    
    NSApplicationTerminateReply answer = NSTerminateNow;
    
    if (self.polygonDrawingWindow.documentEdited == YES) {
        if ( ! [self askForSavingPolygon])
            answer = NSTerminateCancel;
    }

    return answer;
}

//-----------------------------------------------------------------------------

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    
    // Insert code here to tear down your application
        
    NSUserDefaults* def = [NSUserDefaults standardUserDefaults];
    [def setValue:self.binariesURL.path forKey:@"binariesPath"];
    [def setValue:self.workingURL.path forKey:@"workDirPath"];
    
    if (self.simURL) {
        [def setValue:self.simURL.path forKey:@"simDirPath"];
    }else {
        [def setValue:@"Automatic" forKey:@"simDirPath"];
    }
    
    // Save the curent color wells colors for syntax colouring
    // As objects can be stored in property lists as NSData, any sRGB color
    // needs to be stored in a NSData first
    
    [self setColor:self.commentsColorWell.color forKey:@"commentsColor"];
    [self setColor:self.commandsColorWell.color forKey:@"commandsColor"];
    [self setColor:self.objectsColorWell.color forKey:@"objectsColor"];
    [self setColor:self.namesColorWell.color forKey:@"namesColor"];
    [self setColor:self.parametersColorWell.color forKey:@"parametersColor"];
    [self setColor:self.numbersColorWell.color forKey:@"numersColor"];
    [self setColor:self.punctuationColorWell.color forKey:@"punctuationColor"];

//    if (self.appInspectionTimer.valid)
//        [self.appInspectionTimer invalidate];
}

//-----------------------------------------------------------------------------

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

//-----------------------------------------------------------------------------

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    return NO;  // do not open an empty document at application startup
}

//-----------------------------------------------------------------------------

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    
    return YES;
}
//----------------------------------------------------------------------------
//-----------------------------------------------------------------------------


#pragma mark ========== NSPathControlDelegate method ==========

// the purpose here is to accept only folders into the NSPathControls, not files

- (NSDragOperation)pathControl:(NSPathControl *)pathControl
                  validateDrop:(id<NSDraggingInfo>)info {

    NSInteger answer = NSDragOperationNone;

    NSPasteboard* draggingPasteboard = [NSPasteboard pasteboardWithName:NSPasteboardNameDrag];
    NSArray* classes = @[[NSURL class]];
    NSArray* contents = [draggingPasteboard readObjectsForClasses:classes options:nil];

    NSURL* validURL = (NSURL*)contents.firstObject; // the URL actually has a weird content (File System numbers)
    if (validURL) {
        id res;
        NSError* err;
        [validURL getResourceValue:&res forKey:NSURLIsDirectoryKey error:&err];
        if([(NSNumber*)res boolValue]) {
            answer = NSDragOperationEvery;
        }
    }
    return answer;
    return NSDragOperationEvery;
}

// DO NOT use the acceptDrop method of the delegate as it fails to accept even if it returns YES !
// As setting the validated URL after a drop invokes the NSPathControl action
// this is the right place to update VAppDelegate's URLs

//----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

#pragma mark ========== Doc's methods ==========

-(BOOL) runInDarkMode {
    BOOL answer = NO;
    
    NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
    if ([osxMode isEqualTo:@"Dark"]) {
        answer = YES;
    }
    return answer;
}

-(NSDocument*) topDoc {
    
    NSDocument* sentDoc = nil;
    NSDocument* curDoc = nil;
    NSDocumentController* docController = [NSDocumentController sharedDocumentController];
    
    NSArray* documentList = [docController documents];
    if (documentList) {
        if (documentList.count >0) {
            curDoc = (NSDocument*)[docController currentDocument]; // sends nil when a dialog is open above it
            if (curDoc == nil)
                curDoc = [documentList firstObject];
            if (curDoc) {
                if ([curDoc isKindOfClass:[NSDocument class]])
                    sentDoc = curDoc;
            }
        }
    }
    
    return sentDoc;
}

//-----------------------------------------------------------------------------

-(BOOL) hasTopDoc {
    NSDocument* frontDoc = [self topDoc];
    return frontDoc!= nil;
}

//-----------------------------------------------------------------------------

-(void) aDocWindowBecameMain:(NSNotification*) aNotif {
    NSDocument* mainDoc;
    NSWindow *theWindow = [aNotif object];
    mainDoc = (NSDocument *)[[theWindow windowController] document];
    
    [self updatePalettes:self];
}

//-----------------------------------------------------------------------------

- (IBAction)    showTopDocVariationsWindow:(id)sender {
    VDocument* doc = (VDocument*)[self topDoc];
    [doc showVariationsWindow:self];
}

//-----------------------------------------------------------------------------

-(void) snippetPanelDidResize:(NSNotification*) aNotif {
    
    NSWindow *theWindow = [aNotif object];
    
    if ([theWindow isEqualTo:self.modelDesignWindow]) {
        NSInteger count = -1;
        
        for (int k=0; k<10; k++) {
            if ([theWindow.contentView viewWithTag:k].hidden == NO)
                count++;
        }
        if (count>0){
            [self.configObjectCreator distributeIconsOnLine: 1 reqIcons:self.helpIconsOnFirstLine];
            [self.configObjectCreator distributeIconsOnLine: 2 reqIcons:self.helpIconsOnSecondLine];
        }
    }
}

//-----------------------------------------------------------------------------

-(void) batchRunFeed:(NSNotification*) aNotif {
    
    NSInteger const taskLimit = 4;
    
    if ((self.batchSimURLs.count > 0) && (self.activeTaskNumber < taskLimit)) {
        
        // FIFO mechanism
        NSURL* injectURL = self.batchSimURLs.firstObject;
        NSString* injectFile = injectURL.lastPathComponent;
        //NSLog(@"%@", injectFile);
        [self.batchSimURLs removeObjectAtIndex:0];
        
        // launch sim task at given URL
        self.cymFileURL = [injectURL copy];                         // the full address of the .cym file
        self.simURL =  [injectURL URLByDeletingLastPathComponent];  // the folder that contains the .cym file
        NSButton* senderBtn = [NSButton buttonWithTitle:@"Sim" target:nil action:nil];
        [self launchTask:senderBtn];
        
        if (self.batchSimURLs.count == 1) {
            NSArray* pathComponents = [injectURL pathComponents];
            NSString* docRoot = [self.topDoc.displayName stringByDeletingPathExtension];
            for (NSInteger c=0; c<pathComponents.count; c++) {
                NSString* s = [pathComponents objectAtIndex:c];
                if ([s containsString:docRoot]) {
                    NSString* varPath = @"/";
                    for (NSInteger k = 1; k <= c; k ++) {
                        NSString* f = [pathComponents objectAtIndex:k];
                        varPath = [varPath stringByAppendingString:f];
                        varPath = [varPath stringByAppendingString:@"/"];
                    }
                    self.variationsURL = [NSURL fileURLWithPath:varPath];
                    self.varDirPath.URL = self.variationsURL;
                    break;
                }
            }
        }
        
        // loop up to 'taskLimit' times
        [[NSNotificationCenter defaultCenter] postNotificationName:@"feedBatchRun" object:self];
    }
    
    if (self.activeTaskNumber == 0) {
        self.batchRun = @NO;
        self.okForBatchPlay = YES;
    }
}

//-----------------------------------------------------------------------------

-(void) batchPlayFeed:(NSNotification*) aNotif {
    
    // TASK_LIMIT defined in VAppDelegate.h
    
    if ((self.batchPlayURLs.count > 0) && (self.activeTaskNumber < TASK_LIMIT )) {
        
        // FIFO mechanism
        NSString* injectStr = self.batchPlayURLs.firstObject;
        //NSLog(@"%@", injectStr);
        NSString* temp = [injectStr substringToIndex:injectStr.length-1]; // remove the last '/'
        temp = [temp stringByReplacingOccurrencesOfString:self.variationsURL.path withString:@""];
        temp = [temp stringByReplacingOccurrencesOfString:@"/" withString:@"__"];
        self.varPath = [temp copy];
        [self.batchPlayURLs removeObjectAtIndex:0];
        
        // launch the 'Play' task at given URL
        self.simURL =  [NSURL fileURLWithPath:injectStr];  // the localition of 'objects.cmo' and 'properties.cmo' after a previous 'Sim'
        NSButton* senderBtn = [NSButton buttonWithTitle:@"Play" target:nil action:nil];
        [self launchTask:senderBtn];
        
        // loop up to 'taskLimit' times
        [[NSNotificationCenter defaultCenter] postNotificationName:@"feedBatchPlay" object:self];
    }
        
    if (self.activeTaskNumber == 0) {
        self.batchPlay = NO;
        self.batchRun = @NO;
        self.varPath = @"";
    }
}

//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------

- (IBAction)   updatePalettes:(id)sender {
    
    if (! [self hasTopDoc]){
        self.cymFileURL = nil;
        //self.autoSimDirectory = YES;
    } else {
        VDocument* topDoc = (VDocument*)[self topDoc];
        self.cymFileURL = topDoc.configModel.configURL;
        
        // for debugging
        self.topDocName = topDoc.displayName;
        self.binPath = self.binariesURL.path;
        self.workPath = self.workingURL.path;
        self.simPath = self.simURL.path;
    }
    
    [self checkSetup];
    
    [self refreshMessagePanel];
}

//-----------------------------------------------------------------------------

- (void) defaultColors {
    self.commentsColorWell.color = [self colorForKey:@"commentsColor"];
    self.commandsColorWell.color = [self colorForKey:@"commandsColor"];
    self.objectsColorWell.color = [self colorForKey:@"objectsColor"];
    self.namesColorWell.color = [self colorForKey:@"namesColor"];
    self.parametersColorWell.color = [self colorForKey:@"parametersColor"];
    self.numbersColorWell.color = [self colorForKey:@"numbersColor"];
    self.punctuationColorWell.color = [self colorForKey:@"punctuationColor"];
}

//-----------------------------------------------------------------------------

- (NSColor *)colorForKey:(NSString *)key
{
    NSData  *data;
    NSColor *color;
    NSError* err = nil;
    NSSet* colorClassSet = [NSSet setWithObject:[NSColor class]];
    
    data = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    color= [NSKeyedUnarchiver unarchivedObjectOfClasses:colorClassSet fromData:data error:&err];
    if( ! [color isKindOfClass:[NSColor class]] )
    {
        color = nil;
    }
    return color;
}

//-----------------------------------------------------------------------------

- (void)setColor:(NSColor *)color forKey:(NSString *)key
{
    NSError* err = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:color requiringSecureCoding:YES error:&err];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:key];
}

//-----------------------------------------------------------------------------

- (IBAction) applyAttributesToAllDocs: (id) sender {
    VDocumentController* dCtrl = (VDocumentController*) [NSDocumentController sharedDocumentController];
    for (VDocument* doc in dCtrl.documents) {
        NSString* string = doc.configTextView.textStorage.string;
        NSRange wholeRange =  {0, string.length};
        [doc.configTextView.textStorage edited:NSTextStorageEditedAttributes range:wholeRange changeInLength:0];
    }
}

//-----------------------------------------------------------------------------

-(IBAction) colorsForDarkMode:(id)sender {
    // built-in default coloring for dark mode (detected in [self applcationDidFinishLaunching:])
    self.commandsColorWell.color = [NSColor colorWithSRGBRed:0.53 green:0.69 blue:0.98 alpha:1.0];
    self.objectsColorWell.color = [NSColor colorWithSRGBRed:0.8 green:0.5 blue:0.33 alpha:1.0];
    self.namesColorWell.color = [NSColor colorWithSRGBRed:0.61 green:0.83 blue:0.59 alpha:1.0];
    self.parametersColorWell.color = [NSColor colorWithSRGBRed:0.81 green:0.81 blue:0.81 alpha:1.0];
    self.numbersColorWell.color = [NSColor colorWithSRGBRed:0.24 green:0.43 blue:0.95 alpha:1.0];
    self.commentsColorWell.color = [NSColor colorWithSRGBRed:166 green:0.39 blue:0.77 alpha:1.0];
    self.punctuationColorWell.color = [NSColor colorWithSRGBRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    
    [self applyAttributesToAllDocs: self];
}

//-----------------------------------------------------------------------------

-(IBAction) colorsForLightMode:(id)sender {
    // built-in default coloring for light mode (detected in [self applcationDidFinishLaunching:])
    self.commandsColorWell.color = [NSColor colorWithSRGBRed:0.12 green:0.70 blue:0.70 alpha:1.0];
    self.objectsColorWell.color = [NSColor colorWithSRGBRed:0.66 green:0.12 blue:0.12 alpha:1.0];
    self.namesColorWell.color = [NSColor colorWithSRGBRed:0.83 green:0.58 blue:0.26 alpha:1.0];
    self.parametersColorWell.color = [NSColor colorWithSRGBRed:0.33 green:0.33 blue:0.33 alpha:1.0];
    self.numbersColorWell.color = [NSColor colorWithSRGBRed:0.24 green:0.43 blue:0.95 alpha:1.0];
    self.commentsColorWell.color = [NSColor colorWithSRGBRed:0.67 green:0.28 blue:0.74 alpha:1.0];
    self.punctuationColorWell.color = [NSColor colorWithSRGBRed:0.60 green:0.60 blue:0.60 alpha:1.0];
    
    [self applyAttributesToAllDocs: self];
}


//-----------------------------------------------------------------------------
#pragma mark ========== Setup methods ==========
//-----------------------------------------------------------------------------

- (IBAction)raiseDirectoryEntry:(id)sender {
    
    NSMenuItem* senderItem = (NSMenuItem*)sender;
    if ([senderItem.title containsString: @"Binaries"]) {
        if (self.binariesURL.path)
            self.directoryEntryField.stringValue = self.binariesURL.path;
        self.directoryEntryType.stringValue = @"Binary files directory";
    }
    if ([senderItem.title containsString: @"Working"]) {
        if (self.workingURL.path)
            self.directoryEntryField.stringValue = self.workingURL.path;
        self.directoryEntryType.stringValue = @"Working directory";
    }
    if ([senderItem.title containsString: @"Use"]) {
        if (self.simURL.path)
            self.directoryEntryField.stringValue = self.simURL.path;
        self.directoryEntryType.stringValue = @"Simulation directory";
    }
    if ([senderItem.title containsString:@"Variations"]) {
        if (self.variationsURL.path)
            self.directoryEntryField.stringValue = self.variationsURL.path;
        self.directoryEntryType.stringValue = @"Parameter variations";
    }
        
    [self.directoryEntryWindow makeKeyAndOrderFront:sender];
}

//-----------------------------------------------------------------------------

- (IBAction)dismissDirectoryEntry:(id)sender {
    [self.directoryEntryWindow orderOut:sender];
}

//-----------------------------------------------------------------------------

- (IBAction)validateDirectoryEntry:(id)sender {
    
    if ([self.directoryEntryType.stringValue containsString:@"Bin"]){
        if ([self.directoryEntryField hasValidDirectory]) {
            self.binariesURL = [NSURL fileURLWithPath: self.directoryEntryField.stringValue];
            self.binariesDirItem.title = self.binariesURL.path;
            self.binPath = self.binariesURL.path;
            self.binDirPath.URL = self.binariesURL;
            self.okForBinDisplay = YES;
        } else {
            self.binariesURL = nil;
            self.binariesDirItem.title = @"No Binaries Directory";
            self.binPath = @"";
            self.binDirPath.URL = nil;
            self.okForBinDisplay = NO;
        }
    }
    
    if ([self.directoryEntryType.stringValue containsString:@"Work"]){
        if ([self.directoryEntryField hasValidDirectory]) {
            self.workingURL = [NSURL fileURLWithPath: self.directoryEntryField.stringValue];
            self.workingDirItem.title = self.workingURL.path;
            self.workPath = self.workingURL.path;
            self.workDirPath.URL = self.workingURL;
            self.okForWorkDisplay = YES;
        } else {
            self.workingURL = nil;
            self.workingDirItem.title = @"No Working Directory";
            self.workPath = @"";
            self.workDirPath.URL = nil;
            self.okForWorkDisplay = NO;
         }
    }
    
    if ([self.directoryEntryType.stringValue containsString:@"Simulation"]){
        if ([self.directoryEntryField hasValidDirectory]) {
            self.simURL = [NSURL fileURLWithPath: self.directoryEntryField.stringValue];
            self.simDirItem.title = self.simURL.path;
            self.simPath = self.simURL.path;
            self.simDirPath.URL = self.simURL;
            // change flag upstream of ::doSetupMenu. Otherwise IB bindings can revert its value !!!!
            self.autoSimDirectory = NO;
            self.okForSimDisplay = YES;
        } else {
            self.simURL = nil;
            self.simDirItem.title = @"Automatic";
            self.simPath = @"";
            // change flag upstream of ::doSetupMenu. Otherwise IB bindings can revert its value !!!!
            self.simDirPath.URL = nil;
            self.autoSimDirectory = YES;
            self.okForSimDisplay = NO;
        }
    }

    if ([self.directoryEntryType.stringValue containsString:@"variations"]){
        if ([self.directoryEntryField hasValidDirectory]) {
            self.variationsURL = [NSURL fileURLWithPath: self.directoryEntryField.stringValue];
            self.variationsDirItem.title = self.variationsURL.path;
            self.varDirPath.URL = self.variationsURL;
            self.autoSimDirectory = NO;
            self.okForSimDisplay = YES;
        } else {
            self.variationsURL = nil;
            self.varDirPath.URL = nil;
            self.variationsDirItem.title = @"No Variations Directory";
        }
    }

    [self.directoryEntryWindow orderOut:sender];
    [self checkSetup];
}

//-----------------------------------------------------------------------------

- (IBAction)choseDirectoryEntry: (id)sender {
    
    NSOpenPanel* theOpenPanel = [NSOpenPanel openPanel];
    theOpenPanel.canChooseDirectories=YES;
    theOpenPanel.canChooseFiles=NO;
    if ([theOpenPanel runModal] == NSModalResponseOK) {
        NSURL* chosenURL = [theOpenPanel URL];
        NSString* displayPath = chosenURL.path;
        // unliked a folder dropped in the VAutoSelectTextfield, the NSOpenPanel sends directory URLs without the final '/' !!
        if (! [displayPath hasSuffix:@"/"])
            displayPath = [displayPath stringByAppendingString:@"/"];
        self.directoryEntryField.stringValue = displayPath;
        [self.directoryEntryField checkURLValidity];
    }
}

//-----------------------------------------------------------------------------
// It is safer not to change any menu enabling or value flag in this function
// as IB bindings rely on the values that are read before this call !!
// To update the values we MUST implement validateMenuItem method from the NSMenuItemValidationProtocol
//-----------------------------------------------------------------------------

- (IBAction) doSetupMenu:(id) sender {
    
    NSMenuItem* senderItem = (NSMenuItem*)sender;
    NSURL* reqURL = nil;
    
    switch (senderItem.tag) {
        
        case 1: // binaries URL
            reqURL = self.binariesURL;
        break;
        
        case 2: // working URL
            reqURL = self.workingURL;
        break;
        
        case 3: // sim URL
            reqURL = self.simURL;
        break;
        
        case 4: // ask for Automatic
            self.simDirItem.title = @"Automatic";
            self.simURL = nil;
            self.simPath = @"";
            self.autoSimDirectory = YES;
        break;
        
        case 5: // ask for existing
            [self raiseDirectoryEntry:sender];
        break;
            
        case 6: // show varaiations directory
            reqURL = self.variationsURL;
            self.okForBatchPlay = YES;
        break;
    }
    
    if (reqURL) {
        NSArray* URLArray = [NSArray arrayWithObject:reqURL];
        NSWorkspace* shWsp = [NSWorkspace sharedWorkspace];
        [shWsp activateFileViewerSelectingURLs:URLArray];
    }
    
    [self checkSetup];
}
//-----------------------------------------------------------------------------

- (IBAction)    doPathControl:(id)sender {
    
    NSPathControl* pC = (NSPathControl*)sender;
    NSString* tit = pC.clickedPathItem.title;
    NSArray* pathComponents = [pC.URL pathComponents];
    NSString* urlPath = [pathComponents componentsJoinedByString:@"/"];
    urlPath = [urlPath stringByReplacingOccurrencesOfString:@"//" withString:@"/"];
    urlPath = [urlPath stringByAppendingString:@"/"];

    if (tit) {
        NSMutableArray* mutComp = [NSMutableArray arrayWithArray:pathComponents];
        NSString *nativeStr = @"", *newPath = @"";
        NSInteger k = 0, m;
        
        for (NSString* s in mutComp) {
            
            // assume the localization of some key folder names could make them different from
            // URL's components, but identical to
            // the native name extracted from the NSPathControl
            // so we need to test both the native and localized names
            // using NSFileManager's displayNameAtPath to get localized name
            
            nativeStr= [nativeStr stringByAppendingString:s];
            NSString* locTit = [[NSFileManager defaultManager] displayNameAtPath:nativeStr];
            
            if (( ! [s isEqualToString:tit]) && ( ! [locTit isEqualToString:tit])) {
                k++;
            } else {
                break;
            }
        }
        
        for (m = 0; m <= k; m++){
            NSString* compo = [mutComp objectAtIndex:m];
            newPath =  [newPath stringByAppendingString:compo];
            if (m > 0) {
                newPath = [newPath stringByAppendingString:@"/"];
            }
        }
        
        NSURL* reqURL = [NSURL fileURLWithPath:newPath];
        NSArray* URLArray = [NSArray arrayWithObject:reqURL];
        NSWorkspace* shWsp = [NSWorkspace sharedWorkspace];
        [shWsp activateFileViewerSelectingURLs:URLArray];
    }
    
    NSURL* newURL = [NSURL fileURLWithPath:urlPath];
    // tit == nil when a dropped URL arrives on the NSPathControl
    if (pC.tag == 0){ // binaries
        self.binariesURL = newURL;
        self.binariesDirItem.title = self.binariesURL.path;
        self.binPath = self.binariesURL.path;
        self.okForBinDisplay = YES;
    }
    if (pC.tag == 1) { // working
        self.workingURL = newURL;
        self.workingDirItem.title = self.workingURL.path;
        self.workPath = self.workingURL.path;
        self.okForWorkDisplay = YES;
    }
    if (pC.tag == 2) { // sim
        self.simURL = newURL;
        self.simDirItem.title = self.simURL.path;
        self.simPath = self.simURL.path;
        self.autoSimDirectory = NO;
        self.okForSimDisplay = YES;
    }
    if (pC.tag == 3){ // variations
        self.variationsURL = newURL;
        self.variationsDirItem.title = self.variationsURL.path;
        self.autoSimDirectory = NO;
        self.okForSimDisplay = YES;
        self.okForBatchPlay = YES;
    }
    [self checkSetup];
}

//-----------------------------------------------------------------------------

- (NSUInteger) checkURLType : (NSURL*)url WithExtension:(NSString*)extension{
    
    NSUInteger uType = UrlNotValid; // see enum urlType
    BOOL isDir = NO;
    BOOL isFile = NO;
    BOOL isFileWithExt = NO;
    
    NSString* fileString = [url lastPathComponent];
    id res;
    NSError* err;
    
    [url getResourceValue:&res forKey:NSURLIsDirectoryKey error:&err];
    isDir = [(NSNumber*)res boolValue];
    
    [url getResourceValue:&res forKey:NSURLIsRegularFileKey error:&err];
    isFile = [(NSNumber*)res boolValue];
    
    if (isFile){
        isFileWithExt = [fileString hasSuffix:extension];
    }
    if (isDir)
        uType = Directory;
    if (isFile)
        uType = File;
    if (isFileWithExt)
        uType = FileWithValidExtension;
    
    return uType;
}

//-----------------------------------------------------------------------------

- (void) checkSetup {
    
    self.okForSim = ((self.binariesURL != nil) && (self.workingURL != nil) && ([self hasTopDoc]));
    self.okForLivePlay = ((self.binariesURL != nil) && (self.workingURL != nil) && ([self hasTopDoc]));
    self.okForPlay = ((self.binariesURL != nil) && (self.workingURL != nil) && (self.simURL != nil));
    self.okForReport = ((self.binariesURL != nil) && (self.workingURL != nil) && (self.simURL != nil));
}

//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
#pragma mark   ========== Run methods ==========
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------
//       Responds to a click in a radio button to change run dimensionality
//-----------------------------------------------------------------------------

-(IBAction) changeDimension:(id)sender {

    NSButton* srcBtn = (NSButton*)sender;
    
    if ([srcBtn isEqualTo: _runIn2DButton])  {
        self.runIn2DButton.state = NSControlStateValueOn;
        self.runIn3DButton.state = NSControlStateValueOff;
        self.runIn3D = NO;
    }
    if ([srcBtn isEqualTo: _runIn3DButton])  {
        self.runIn2DButton.state = NSControlStateValueOff;
        self.runIn3DButton.state = NSControlStateValueOn;
        self.runIn3D = YES;
    }
    if ([srcBtn isEqualTo: _reportIn2DButton])  {
        self.reportIn2DButton.state = NSControlStateValueOn;
        self.reportIn3DButton.state = NSControlStateValueOff;
        self.reportIn3D = NO;
    }
    if ([srcBtn isEqualTo: _reportIn3DButton])  {
        self.reportIn2DButton.state = NSControlStateValueOff;
        self.reportIn3DButton.state = NSControlStateValueOn;
        self.reportIn3D = YES;
    }
}

-(IBAction) changeFiberLattice:(id)sender {
    NSButton* checkBox = (NSButton*)sender;
    (checkBox.state == NSControlStateValueOn) ? (self.fibersHaveLattice = YES) : (self.fibersHaveLattice = NO);
}

//-----------------------------------------------------------------------------
//       Returns current date and hour in a NSString
//-----------------------------------------------------------------------------

-(NSString*) completeDateStringFromDate:(NSDate*)date {

    CFDateRef dat =  (__bridge CFDateRef)date;
    CFDateFormatterRef dateForm = CFDateFormatterCreate(kCFAllocatorDefault,
                    CFLocaleCopyCurrent(),kCFDateFormatterLongStyle, kCFDateFormatterMediumStyle);
    CFStringRef dateString = CFDateFormatterCreateStringWithDate(kCFAllocatorDefault, dateForm, dat);
    return (__bridge NSString*)dateString;
}

-(NSString*) hourStringFromDate:(NSDate*)date {

    CFDateRef dat = (__bridge CFDateRef)date;
    CFDateFormatterRef dateForm = CFDateFormatterCreate(kCFAllocatorDefault,
                    CFLocaleCopyCurrent(),kCFDateFormatterNoStyle, kCFDateFormatterMediumStyle); // No day, just hh:mm:ss
    CFStringRef dateString = CFDateFormatterCreateStringWithDate(kCFAllocatorDefault, dateForm, dat);
    return (__bridge NSString*)dateString;
}

- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval {
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
}

//-----------------------------------------------------------------------------
//       Manages automatic directory creation for calls to 'sim' binary
//-----------------------------------------------------------------------------

- (void) createSimDirectory {

    NSString* answerString = @"";
    self.folderCreationDate = [NSDate now];
    NSString* dateString = [self completeDateStringFromDate:self.folderCreationDate];
    
    NSString* configName = [self.cymFileURL lastPathComponent];
    configName = [configName stringByReplacingOccurrencesOfString:@".cym" withString:@"_"];

    NSString* autoSimDir = [NSString stringWithString:self.workingURL.path];
    autoSimDir = [autoSimDir stringByAppendingString:@"/"];
    autoSimDir = [autoSimDir stringByAppendingString:configName];
    autoSimDir = [autoSimDir stringByAppendingString:@"_Run"];
    NSNumber* simNum = [ NSNumber numberWithInteger:self.simCounter];
    autoSimDir = [autoSimDir stringByAppendingString:simNum.stringValue];
    autoSimDir = [autoSimDir stringByAppendingString:@"_"];
    autoSimDir = [autoSimDir stringByAppendingString:dateString];
    autoSimDir = [autoSimDir stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    autoSimDir = [autoSimDir stringByReplacingOccurrencesOfString:@":" withString:@"_"];

    // create the automatic simulation directory in the Working Directory
    // WARNING THIS DIRECTORY CREATION FAILS IF APP SANDBOXING IS SET !

    NSFileManager* mgr = [NSFileManager defaultManager];
    NSError* err = nil;
    BOOL sdOK = [mgr createDirectoryAtPath:autoSimDir withIntermediateDirectories:NO attributes:nil error:&err];

    if (sdOK) {
        self.simURL = [NSURL fileURLWithPath:autoSimDir];
        answerString = self.simURL.path;
        self.simCounter++;
        
        // to ease "sim" lauching when the configuration files contains ref to other files (with extension ".txt")
        // like a polygon definition file, identify such files and copy them into the newly created directory

        NSError* err =nil;
        NSString* contentString = [NSString stringWithContentsOfURL:self.cymFileURL encoding:NSUTF8StringEncoding error:&err];
        NSArray* lines =  [contentString componentsSeparatedByString:@"\n"];
        for (NSString* l in lines) {
            if ([l containsString:@"file"]) {
                NSRange equal = [l rangeOfString:@"="];
                NSRange fNameRange = equal;
                fNameRange.location++;
                fNameRange.length = l.length - fNameRange.location;
                NSString* fileName = [l substringWithRange:fNameRange];
                fileName = [fileName stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];

                NSURL* fileURL = [self.workingURL URLByAppendingPathComponent:fileName];
                NSURL* dstURL = nil;
                dstURL = [self.simURL URLByAppendingPathComponent:fileName];

                if (! [dstURL isEqualTo:fileURL]) {
                    [mgr copyItemAtURL:fileURL toURL:dstURL error:&err];
                }
            }
        }
    } else {
        self.simURL = nil;
        answerString = @"";
    }
}


//-----------------------------------------------------------------------------
//       Alerts the user if a new simulation data is going to collide with
//       existing files in the sim directory of a previous simulation
//-----------------------------------------------------------------------------

-(BOOL) runAlertForSimulation {
    
    NSAlert* pathAlert = [[NSAlert alloc]init];
    NSImage* theIcon = [NSImage imageNamed:@"CytosimForOSX"];
    pathAlert.icon = theIcon;
    pathAlert.alertStyle = NSAlertStyleWarning;
    NSString* message = self.simURL.path;
    message = [message stringByAppendingString: @"\n\n is defined as the Simulation Directory."];
    message = [message stringByAppendingString: @"\n Continuing will replace its content by a new simulation."];
    message = [message stringByAppendingString: @"\n\n If you cancel, The simulation sirectory will be set to \"Automatic\" and your simulation will be run"];
    [pathAlert setMessageText: message];
    [pathAlert addButtonWithTitle: @"Cancel"]; // 1st button
    [pathAlert addButtonWithTitle: @"Continue Anyway"];  // 2nd nutton
    
    BOOL answer = NO;
    NSModalResponse response = [pathAlert runModal];
    if (response == NSAlertSecondButtonReturn)
        answer = YES;
    return answer;
}


-(BOOL) askForSaving {
    NSAlert* saveAlert = [[NSAlert alloc]init];
    NSImage* theIcon = [NSImage imageNamed:@"CytosimForOSX"];
    saveAlert.icon = theIcon;
    saveAlert.alertStyle = NSAlertStyleWarning;
    NSString* message = @"Do you want to save the configuration file before running ?";
    [saveAlert setMessageText: message];
    [saveAlert addButtonWithTitle: @"Yes save before running"];  // 1st (default) button
    [saveAlert addButtonWithTitle: @"No use the previously saved configuration file"]; // 2nd button

    
    BOOL answer = NO;
    NSModalResponse response = [saveAlert runModal];
    if (response == NSAlertFirstButtonReturn)
        answer = YES;
    return answer;
}

-(BOOL) askForSavingPolygon {
    
    NSAlert* saveAlert = [[NSAlert alloc]init];
    NSImage* theIcon = [NSImage imageNamed:@"CytosimForOSX"];
    saveAlert.icon = theIcon;
    saveAlert.alertStyle = NSAlertStyleWarning;
    NSString* message = @"Do you really want to leave without saving the current polygon ?";
    [saveAlert setMessageText: message];
    [saveAlert addButtonWithTitle: @"Yes"];                     // 1st (default) button
    [saveAlert addButtonWithTitle: @"No don't leave yet"];      // 2nd button

    BOOL answer = NO;
    NSModalResponse response = [saveAlert runModal];
    if (response == NSAlertFirstButtonReturn)
        answer = YES;
    return answer;
}

-(void) forceConfigFileSaving {
    VDocument* topDoc = (VDocument*)[self topDoc];
    if (topDoc.documentEdited) {
        if ([self askForSaving]) {
            [topDoc saveDocument:self];
        }
    }
}

-(NSError*) recordConfigWithName:(NSString*)aName AtURL:(NSURL*)atURL{
    
    VConfigurationModel* model = ((VDocument*)[self topDoc]).configModel;

    // Save a copy of the text in the Sim directory to record the configuration that actually generated the simulation
    NSError* outErr = nil;
    NSString* cymText = model.configString;
    atURL = [atURL URLByAppendingPathComponent:aName];
    [cymText writeToURL: atURL atomically:YES encoding:NSUTF8StringEncoding error:&outErr];
    return outErr;
}

//-----------------------------------------------------------------------------
//       Builds the NSTaks and launches it
//       Several tasks can be run concurently, each one in a separate thread
//       using Apple's Grand Central Dispatch
//-----------------------------------------------------------------------------

-(IBAction) launchTask:(id)sender {

    // To check who called this function
    NSButton* srcBtn = (NSButton*)sender;
    NSString* tit = srcBtn.title;

    if (([tit isEqualToString:@"Sim"]) && (!self.autoSimDirectory)) {
        if (! self.batchRun.boolValue) {
            BOOL goOn = [self runAlertForSimulation];
            if (! goOn) {
                self.autoSimDirButton.state = NSControlStateValueOn;
                self.autoSimDirectory = YES;
                self.simDirPath.enabled = NO;
                [self updatePalettes:self];
            }
        }
    }
    // N.B. checking of path validity is already tested upstream and allows button/menu item enabling.
    
    // If auto creation of a simulation directory then make it now
    // using abolute time as a unique identifier
    // else read directly the path from the sim Directory
    // and also check the validity of the directory upon creation attempt

    if ((self.autoSimDirectory) && ([tit isEqualToString:@"Sim"]) && (!self.batchRun.boolValue))
        [self createSimDirectory];     // sets self.simURL and self.workingURL
    
    if ((self.simURL.path.length >0) || ([tit containsString:@"live"])){

        // variables used to run the task
        NSString*   command = @"";
        NSString*   __block commandOutput;
        NSString*   __block errorOutput;
        NSString*   __block tName;
        BOOL        __block verbose;
        BOOL        __block userStop = NO;

        NSFileHandle* __block curInputHandle;
        NSFileHandle* __block errorFile;
        NSFileHandle* __block outputFile;

        NSArray* taskArguments = nil;

        // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        // this a block to be executed once the task is done
        // As the task is run asynchronously, the output in the Log
        // text field should be called from the main queue.
        // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        void (^taskTerminationHandler)(NSTask* task) = ^(NSTask* task) {
            dispatch_queue_t main = dispatch_get_main_queue();
            dispatch_async(main,
                ^{

                // push info into the Log window before discarding the task
                userStop = self.curRunningTask.stoppedByUser.boolValue;
                NSDate* stopDate = [NSDate now];
                NSString* stopDateString = [self hourStringFromDate:stopDate];
                self.curRunningTask.stopDate = stopDate;
                NSTimeInterval totalTime = [self.curRunningTask totalElapsedTime];
                NSString* s = [NSString  stringWithString:self.curRunningTask.theName];

                NSString* t = [NSString stringWithString:s];
                 t = [t stringByAppendingString:@": Task terminated at "];
                t = [t stringByAppendingString: stopDateString];
                t = [t stringByAppendingString: @"\n    Running time without pauses (hh:mm:ss) "];
                NSString* durationString = [self stringFromTimeInterval:totalTime];
                t = [t stringByAppendingString: durationString];
                t = [t stringByAppendingString: @"\n\n"];
                
                [self appendToLogText:@"---- Task termination ----" WithColor:[NSColor labelColor]];
                [self appendToLogText:t WithColor:[NSColor labelColor]];
                self.batchSimProgress.doubleValue += 1.0;
                
                // manage runningTasks list
                [self.runningTasks removeObject: self.curRunningTask]; // also discards the curRunningTask object
                if (self.runningTasks.count == 0) {
                    self.tasksAreRunning = NO;
                    [self.taskMessagePanel close];
                }
                
                // manage runningTasks PopUp Menu
                [self.runningTasksPopUp removeItemWithTitle:s];
                if (self.runningTasks.count > 0) {
                    self.curRunningTask = self.runningTasks.firstObject;
                    if (self.curRunningTask.theTask.running) {
                        self.curRunningTask.isRunning = @YES;
                        self.curRunningTask.isPaused = @NO;
                        [self.runningTasksPopUp selectItemWithTitle:self.curRunningTask.theName];
                    }
                } else {
                    self.curRunningTask = nil;
                    [self.runningTasksPopUp removeAllItems];
                }

                // Direct errors (if any) to a string in the Log window...
                verbose = YES;  //(self.verboseCheckBox.state == NSControlStateValueOn);
                NSData *errData = [errorFile readDataToEndOfFile];
                [errorFile closeFile];
                if (verbose && !userStop)
                    errorOutput = [[NSString alloc] initWithData: errData encoding: NSUTF8StringEncoding];

                // Direct output (if any) to a string...
                NSData *outData = [outputFile readDataToEndOfFile];
                [outputFile closeFile];
                commandOutput = [[NSString alloc] initWithData: outData encoding: NSUTF8StringEncoding];

                if (errorOutput.length >0)
                    [self appendToLogText:errorOutput WithColor:[NSColor redColor]];

                if (commandOutput.length >0)
                    [self appendToLogText:commandOutput WithColor:[NSColor labelColor]];
                
                self.activeTaskNumber --;
                
                if (self.batchRun.boolValue) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"feedBatchRun" object:self];
                }
                if (self.batchPlay) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"feedBatchPlay" object:self];
                }
                if ([tit isEqualToString:@"Sim"]) {
                    self.simDirPath.URL = self.simURL;
                }
            });
            
            
        };
        // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        //  end of the termination handler
        // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        
        
        // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        // preparation of the actual task lauching
        // Build the command string with common features
        // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        NSString* dimPath = @"";
        
        //(self.runIn3D || self.reportIn3D) ? (dimPath = @"/bin3D/") : (dimPath = @"/bin2D/");
        
        if (self.runIn3D) {
            if (self.fibersHaveLattice) {
                dimPath = @"/bin3D-lattice/";
            } else {
                dimPath = @"/bin3D/";
            }
        } else {
            if (self.fibersHaveLattice) {
                dimPath = @"/bin2D-lattice/";
            } else {
                dimPath = @"/bin2D/";
            }
        }
        
        command = self.binariesURL.path;
        command = [command stringByAppendingString:dimPath];

        if ([tit isEqualToString:@"Sim"]) {

            if (! self.batchRun.boolValue)
                [self forceConfigFileSaving];
            
            command = [command stringByAppendingString:@"sim "];
            command = [command stringByAppendingString:self.cymFileURL.path];
            command = [command stringByAppendingString:@" "];
            command = [command stringByAppendingString:self.simURL.path];

            tName = @"sim_";
        }

        if ([tit containsString:@"Play"]) {

            if (! self.batchPlay) {
                [self forceConfigFileSaving];
                // force a last-minute update of the URL because it failed after a "Save As..." command
                self.cymFileURL = [[self topDoc] fileURL];
            }
            // next build the common play command according to the requested dimension
            command = self.binariesURL.path;
            command = [command stringByAppendingString:dimPath];
            command = [command stringByAppendingString:@"play"];

            // append the live suffix if necessary, then the adress of the .cym file
            
            if ([srcBtn.title containsString:@"live"]) {
                command = [command stringByAppendingString:@" live "];
                command = [command stringByAppendingString:self.cymFileURL.path];
            } else {
                command = [command stringByAppendingString:@" "];
                command = [command stringByAppendingString:self.simURL.path];
            }
            tName = @"play_";
        }

        if ([tit containsString:@"Report"]) {

            command = @"cd ";
            command = [command stringByAppendingString:self.simURL.path];
            command = [command stringByAppendingString:@"; "];

            command = [command stringByAppendingString:self.binariesURL.path];
            command = [command stringByAppendingString:dimPath];
            command = [command stringByAppendingString:@"report "];
            command = [command stringByAppendingString:@" "];
            command = [command stringByAppendingString:self.reportArguments.titleOfSelectedItem];

            command = [command stringByAppendingString:@"> "];  // systematically redirect the output to a file
            NSString* whatFileName = [NSString stringWithString:self.reportArguments.titleOfSelectedItem];
            whatFileName = [whatFileName stringByReplacingOccurrencesOfString:@":" withString:@"_"];
            command = [command stringByAppendingString:whatFileName];
            command = [command stringByAppendingString:@".txt"];
            
            tName = @"report_";
        }
        
        // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        // Actually launch the task in an asynchronous queue
        // This requires the tasks variables: executableURL, arguments,
        // standardInput and standard output to be filled respectively
        // with: the URL , the common command built above, which will rebuild
        // a terminal script, and 3 NSPipes that contain text file references.
        //
        // Any output to the Log window should be called from the main queue
        // (like anything that displays information)
        // %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        taskArguments = [NSArray arrayWithObjects: @"-l", @"-c", command, nil];
                /* the"-l" option might not be required but is not nocive */
        NSURL* taskURL = [NSURL fileURLWithPath:@"bin/bash"];
        NSTask* theTask = [[NSTask alloc]init];

        theTask.executableURL = taskURL;
        
        //************
        theTask.currentDirectoryURL = self.workingURL;
        // setting the currentDirectoryURL will modify this value in the _NSConcreteTask-associated dictionary
        // the default value is the local user directory (/), which works fine with the 'sim' command but is not what we want here.
        // THIS is the CORRECT way to grant access to a polygon file location upon 'play live' (For correct finding of polygons upon lauching
        // the 'sim' command, see in [self createSimDirectory] how to copy  the .txt file into the new directory);
        // instead of sending a "cd " command with the working dir argument as a header of the command that is injected below via 'taskArguments'
        // as a result, the NSTask's suspend and resume methods work fine, while they fail with the "cd " header
        //************
        
        theTask.arguments = taskArguments;

        NSPipe *inputPipe = [NSPipe pipe];
        curInputHandle = inputPipe.fileHandleForWriting;
        theTask.standardInput = inputPipe;

        NSPipe *outputPipe = [NSPipe pipe];
        outputFile = outputPipe.fileHandleForReading;
        theTask.standardOutput = outputPipe;

        NSPipe *errorPipe = [NSPipe pipe];
        errorFile = errorPipe.fileHandleForReading;
        theTask.standardError = errorPipe;

        theTask.terminationHandler = taskTerminationHandler;

        self.taskInstanceCounter++;
        self.activeTaskNumber++;
        
        NSNumber* stiCount = [NSNumber numberWithInteger:self.taskInstanceCounter];
        tName = [tName stringByAppendingString:stiCount.stringValue];
        tName = [tName stringByAppendingString:@"_"];
        
        if (self.batchPlay) {
            tName = [tName stringByAppendingString:self.varPath];
        } else if ([self hasTopDoc]) {
            NSString* temp = [self.cymFileURL.path stringByDeletingPathExtension];
            temp = [temp lastPathComponent];
            tName = [tName stringByAppendingString:temp];
        }
        
        VNamedTask* nTask = [[VNamedTask alloc]init];
        if (nTask) {
            nTask.theTask = theTask;
            nTask.theName = [NSString stringWithString:tName];
            nTask.stoppedByUser = @NO;
        }
        
        //dispatch_queue_t queue = dispatch_queue_create("com.CYTOSIM_GUI_Task", DISPATCH_QUEUE_CONCURRENT); --old version
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        dispatch_queue_t main = dispatch_get_main_queue();

        NSWorkspace* ws = [NSWorkspace sharedWorkspace];
        //NSArray* __block prevAppsRunning = [ws runningApplications];

        dispatch_async(queue,
          ^{
            // Launch the new task and make it the current running task
            NSError* er = nil;
            [theTask launchAndReturnError:&er];
            if (er == 0L) {
                
                //NSTask_Inspector* taskInsp = [[NSTask_Inspector alloc] initWithTask:theTask];
                
                dispatch_async(main,
                    ^{
                    
                    self.curRunningTask = nTask;
                    [self.runningTasks addObject:nTask];
                    NSInteger newIndex = self.runningTasks.count - 1;
                    [self.runningTasksPopUp insertItemWithTitle:nTask.theName atIndex:newIndex]; // add at the bottom of the menu to match the order in self.playInstances
                    if ([nTask.theName hasPrefix:@"sim"])
                        [self recordConfigWithName:[nTask.theName stringByAppendingString:@"_Trace.cym"] AtURL:self.simURL];
                    self.curRunningTask.isRunning = @YES;
                    self.curRunningTask.isPaused = @NO;
                    self.tasksAreRunning = YES;
                    
                    NSDate* nowDate = [NSDate now];
                    if ([nowDate timeIntervalSinceDate: self.folderCreationDate] > 1000)
                        self.curRunningTask.launchDate = nowDate;
                    else
                        self.curRunningTask.launchDate = self.folderCreationDate;
                    
                    NSString* launchString = [self completeDateStringFromDate: self.curRunningTask.launchDate];
                    
                    [self appendToLogText:@"------------------------------------" WithColor:[NSColor labelColor]];
                    [self appendToLogText:launchString WithColor:[NSColor labelColor]];
                    [self appendToLogText: self.curRunningTask.theName WithColor:[NSColor labelColor]];
                    [self appendToLogText:@"------------------------------------" WithColor:[NSColor labelColor]];
                    [self appendToLogText:@"Task launched:" WithColor:[NSColor labelColor]];
                    NSColor *darkGreen  = [NSColor colorWithRed:0.086 green:0.60 blue:0.086 alpha:1.0];
                    [self appendToLogText:taskArguments[2] WithColor:darkGreen]; // displays the 'command' string
                    [self appendToLogText:@"\n" WithColor:[NSColor labelColor]];

                });

            }
            
            // additional adjustment in the interface
            dispatch_async(main,
                ^{
                    //select the last item added (at the bottom of the menu)
                    [self.runningTasksPopUp selectItemWithTitle:nTask.theName];

//                    NSNumber* pID = [NSNumber numberWithInteger:nTask.theTask.processIdentifier];
//                    NSString* tID = @"task ID  = ";
//                    tID = [tID stringByAppendingString:pID.stringValue];
//                    NSLog(@"%@", tID);
//
//                    // beware of storing the pID in the same order as in the NSPopUpButton
//                    [self.playInstances addObject:pID];

               });
          });

    } else {

    }
}

//-----------------------------------------------------------------------------
//       Control over task running (tasks should be running to be stopped,
//          they do not respond to stop button action in they are in pause)
//-----------------------------------------------------------------------------

-(IBAction) stopTask:(id)sender {
    
    if (self.curRunningTask  != nil) {
        
        if (self.curRunningTask.theTask.isRunning) {
            
            [self.curRunningTask.theTask terminate]; // Generates an openGL error output in the Log of the app
            self.curRunningTask.isRunning = @YES;
            self.curRunningTask.isPaused = @NO;
            self.curRunningTask.stoppedByUser = @YES;
            
            // Log output management is processed by [self launchTask:] in the task termination handler block
        }
    }
}

//-----------------------------------------------------------------------------

-(IBAction) suspendTask:(id)sender {
    
    if (self.curRunningTask  != nil) {
         
        // Operate actual task suspension
        
        BOOL success = [self.curRunningTask.theTask suspend];
        if (success) {
            //BOOL checkRun = self.curRunningTask.theTask.running;
            self.curRunningTask.isRunning = @NO;
            self.curRunningTask.isPaused = @YES;
            
            NSDate* suspDate = [NSDate now];
            self.curRunningTask.suspensionDate = suspDate;
            NSString* message = self.curRunningTask.theName;
            message = [message stringByAppendingString:@" suspended at "];
            message = [message stringByAppendingString:[self hourStringFromDate:suspDate]];
            [self appendToLogText: message  WithColor:[NSColor labelColor]];
        }
    }
}

//-----------------------------------------------------------------------------

-(IBAction) resumeTask:(id)sender {
    
    if (self.curRunningTask  != nil) {
        if (self.curRunningTask.isRunning.boolValue == NO) {
            
            [self.curRunningTask.theTask resume];
            self.curRunningTask.isRunning = @YES;
            self.curRunningTask.isPaused = @NO;
            
            NSDate* resumDate = [NSDate now];
            self.curRunningTask.resumptionDate = resumDate;
            // now that the task is resumed, compute time spent in pause
            [self.curRunningTask updateTimeFlow];
            
            NSString* message = self.curRunningTask.theName;
            message = [message stringByAppendingString:@" resumed at "];
            message = [message stringByAppendingString:[self hourStringFromDate:resumDate]];
            [self appendToLogText: message  WithColor:[NSColor labelColor]];
        }
    }
}

//-----------------------------------------------------------------------------

- (IBAction)    stopAllTasks:(id)sender {
    
    [self.batchSimURLs removeAllObjects];
    [self.batchPlayURLs removeAllObjects];
    
    for (VNamedTask* task in self.runningTasks) {
        self.curRunningTask = task;
        [self stopTask:self];
    }
    
    self.batchRun = @NO;
    self.batchPlay = NO;
    self.batchSimProgress.maxValue = 100.0;
    self.batchSimProgress.doubleValue = 0.0;
}


//-----------------------------------------------------------------------------
//       Select the target task from the NSPopUpButton
//       if several tasks are running concurrently. Otherwise
//       only the current task appears in the PopUp
//-----------------------------------------------------------------------------

-(IBAction) changeCurRunningTask:(id)sender {
    NSPopUpButton* list = (NSPopUpButton*)sender;
    NSString* tName = list.selectedItem.title;

    for (id obj in self.runningTasks) {
        VNamedTask* nTask = (VNamedTask*)obj;
        BOOL match = [nTask.theName isEqualToString:tName];
        if (match) {
            
            self.curRunningTask = nTask;
            
            // Now extract the last component of the tName,
            // match with a Document's name, and select the corresponding window.
            // This is required because refreshMessagePanel operates with objects
            // of the front doc (configuration file)...
            
            NSArray* compo = [tName componentsSeparatedByString:@"_"];
            NSString* coreName = (NSString*)compo.lastObject;
            NSDocumentController* docController = [NSDocumentController sharedDocumentController];
            NSArray* documentList = [docController documents];
            VDocument* topDoc = nil;
            
            for (NSDocument* aDoc in documentList) {
                if ([aDoc.displayName containsString:coreName]) {
                    topDoc = (VDocument*)aDoc;
                    break;
                }
            }
            if (topDoc) {
                NSArray* wControllers = [topDoc windowControllers];
                NSWindowController* ctrl = wControllers.firstObject;
                if (ctrl)
                    [ctrl.window makeKeyAndOrderFront:self];
            }
            
            [self refreshMessagePanel];
            
            // Once this is done, there may be several instances of the same app that run in parallel.
            // This is not relevant for "sim" or "report", which both work in the background, but
            // it is important to put the appropriate "play" app at the top before sending any message to it.
            // Re-rordering instances of "play" apps involves the observer timer that runs in the background
            // and an instance of NSRunningApplication...
            
//            NSWorkspace* ws = [NSWorkspace sharedWorkspace];
//            NSArray* appsRunning = [[ws runningApplications] copy];
//            for (NSRunningApplication* anApp in appsRunning) {
//                NSInteger appID =  [anApp processIdentifier];
//                NSInteger taskIndex = [self.runningTasksPopUp indexOfSelectedItem];
//                NSNumber* taskID = [self.playInstances objectAtIndex:taskIndex];
//                if (appID == taskID.integerValue) {
//                    NSString* outString = @"found app ID = ";
//                    outString = [outString stringByAppendingString:[NSNumber numberWithInteger:appID].stringValue];
//                    NSLog(@"%@", outString);
//                    [anApp activateWithOptions:NSApplicationActivateAllWindows]; // ID matching is OK but this has NO EFFECT on a command line app
//                    break;
//                }
//            }
            
        }
    }
}

//-----------------------------------------------------------------------------
//       Run tasks from the Menu Items
//-----------------------------------------------------------------------------

- (IBAction) runMenu:(id) sender {
    
    NSString* tit = ((NSMenuItem*)sender).title;
    
    if ([tit containsString:@"2D"])
        self.runIn3D = NO;
    if ([tit containsString:@"3D"])
        self.runIn3D = YES;
    
    NSMenuItem* tempItem = [[NSMenuItem alloc]init];
    
    if ([tit containsString:@"Simulation"])
        tempItem.title = @"Sim";

    if ([tit containsString:@"From Simulation"])
        tempItem.title = @"Play";

    if ([tit containsString:@"Live"])
        tempItem.title = @"Play live";
    
    [self launchTask:tempItem];
}

//-----------------------------------------------------------------------------

- (IBAction)    batchSim:(id)sender {
    
    if ([self hasTopDoc]) {
        VDocument* doc = (VDocument*)self.topDoc;
        VParamVariationsManager* mgr = doc.paramVarMgr;
        [mgr runSimBatch:self];
    }
}

//-----------------------------------------------------------------------------

- (IBAction) batchPlay:(id)sender {
    
    NSURL *directoryURL = self.variationsURL;
    NSArray *keys = [NSArray arrayWithObjects:
        NSURLIsDirectoryKey, NSURLIsPackageKey, NSURLLocalizedNameKey, nil];
     
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager]
                                         enumeratorAtURL:directoryURL
                                         includingPropertiesForKeys:keys
                                         options:(NSDirectoryEnumerationSkipsPackageDescendants |
                                                  NSDirectoryEnumerationSkipsHiddenFiles)
                                         errorHandler:^(NSURL *url, NSError *error) {
                                             // Handle the error.
                                             // Return YES if the enumeration should continue after the error.
                                             return YES;
                                         }];
     
    for (NSURL *url in enumerator) {
        // Error checking is omitted for clarity.
        NSNumber *isOKforPlay = nil;
        [url getResourceValue:&isOKforPlay forKey:NSURLIsRegularFileKey error:NULL];
        if ([isOKforPlay boolValue]) {
            NSString* urlStr = [[url URLByDeletingLastPathComponent]path];
            urlStr = [urlStr stringByAppendingString:@"/"];
            BOOL found = NO;
            for (NSString* s in self.batchPlayURLs) {
                if([urlStr isEqualToString:s]){
                    found = YES;
                    break;
                }
            }
            if (! found)
                [self.batchPlayURLs addObject:urlStr];
            found = NO;
        }
    }
    
    
    self.batchSimProgress.maxValue = self.batchPlayURLs.count;
    self.batchPlay = YES;
    self.batchRun = @YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"feedBatchPlay" object:self];
 
}

//-----------------------------------------------------------------------------

- (IBAction)    batchNextGroup:(id)sender {
    
    // remove the current running tasks, not the ones in the queue
    
    for (VNamedTask* task in self.runningTasks) {
        self.curRunningTask = task;
        [self stopTask:self];
    }
}

//-----------------------------------------------------------------------------

- (IBAction)    toggleBatchRunView:(id)sender {
    
    NSInteger deltaHeight = 100;
    NSButton* disclosureBtn = (NSButton*)sender;
    NSRect wFrame = self.runControlWindow.frame;
    
    if (disclosureBtn.state == NSControlStateValueOn) {
        wFrame.size.height += deltaHeight;
        wFrame.origin.y -= deltaHeight;
    } else {
        wFrame.size.height -= deltaHeight;
        wFrame.origin.y += deltaHeight;
    }
    [self.runControlWindow setFrame:wFrame display:YES];

}

//-----------------------------------------------------------------------------
#pragma mark ========== Messages to running tasks ==========
//-----------------------------------------------------------------------------
//       Manage runtime changes modifications and message sending with "Sim"
//-----------------------------------------------------------------------------


- (IBAction) raiseMessagePanel: (id)sender {
    
    [NSApp activateIgnoringOtherApps:YES];
    [self.taskMessagePanel orderFront:self];
    [self refreshMessagePanel];
 }

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

-(void) refreshMessagePanel {
    
    [self.targetObjectPopup removeAllItems];
    [self.targetPropertyPopup removeAllItems];

    VDocument* doc = (VDocument*)[self topDoc];
    if (doc == nil) {
        self.targetValueControlActive = NO;
        self.expressionTextField.stringValue = @"";
        return;
    }

    for (VConfigObject* obj in doc.configModel.configObjects) {
        // add the object's name
        [self.targetObjectPopup addItemWithTitle:obj.objName];
    }
    // take the current object and put its parameters in the appropriate PopUpButton
    NSString* selObjName = self.targetObjectPopup.selectedItem.title;
    VConfigObject* currentObj = nil;
    if (selObjName) {
        currentObj = [doc.configModel objectWithName:selObjName];
        for (VConfigParameter* par in currentObj.objParameters) {
            [self.targetPropertyPopup addItemWithTitle:par.paramName];
        }
    }
    // idem. take the current parameter and put its value into the value field, slider etc...
    NSString* paramName = self.targetPropertyPopup.selectedItem.title;
    if (paramName) {
        VConfigParameter* currentPar = [currentObj parameterWithName:paramName];
        float val = currentPar.paramNumValue.floatValue;
        if ( val != -1000) {
            // set only the NSNumber values as the fields and slider are bound to them via IB
            self.targetValue = @(val);
            self.minScaleValue = @(val/2.0);
            self.maxScaleValue = @(val*2.0);
            self.targetValueControlActive = YES;
        } else {
            self.targetValueControlActive = NO;
        }
        [self buildAndDisplayCommandString];
    }
}

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

- (void) buildAndDisplayCommandString {
    
    VDocument* doc = (VDocument*)[self topDoc];
    
    NSString* selObjName = self.targetObjectPopup.selectedItem.title;
    VConfigObject* currentObj = [doc.configModel objectWithName:selObjName];
    NSString* paramName = self.targetPropertyPopup.selectedItem.title;
    VConfigParameter* currentPar = [currentObj parameterWithName:paramName];

    
    // Build the expected command string from the controller panel
    NSString* str = @"";
    str = [str stringByAppendingString:self.sendCommandPopup.titleOfSelectedItem];
    str = [str stringByAppendingString:@" "];
    
    str = [str stringByAppendingString:self.targetObjectPopup.titleOfSelectedItem];
    str = [str stringByAppendingString:@" { "];
    
    str = [str stringByAppendingString:self.targetPropertyPopup.titleOfSelectedItem];
    str = [str stringByAppendingString:@"="];

    float val = currentPar.paramNumValue.floatValue;
    if ( val != -1000) {
        str = [str stringByAppendingString:self.targetValue.stringValue];
        str = [str stringByAppendingString:@"%f"];
        str = [str stringByAppendingString:@" }\n"];
    } else {
        str = [str stringByAppendingString:currentPar.paramStringValue];
        str = [str stringByAppendingString:@"%s"];
        str = [str stringByAppendingString:@" }\n"];
    }
    
    
    // display in the text field so that the user can modify it
    self.expressionTextField.stringValue = str;
}

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

- (IBAction) changeCommand:(id)sender {
    
    VDocument* doc = (VDocument*)[self topDoc];
    if (doc == nil) {
        self.targetValueControlActive = NO;
        self.expressionTextField.stringValue = @"";
        return;
    }
    [self buildAndDisplayCommandString];
}

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

- (IBAction) changeObject:(id)sender {
    
    VDocument* doc = (VDocument*)[self topDoc];
    if (doc == nil) {
        self.targetValueControlActive = NO;
        self.expressionTextField.stringValue = @"";
        return;
    }

    // take the current object and put it's parameters in the appropriate PopUpButton
    NSString* selObjName = self.targetObjectPopup.selectedItem.title;
    VConfigObject* currentObj = [doc.configModel objectWithName:selObjName];

    [self.targetPropertyPopup removeAllItems];
    for (VConfigParameter* par in currentObj.objParameters) {
        [self.targetPropertyPopup addItemWithTitle:par.paramName];
    }

    NSString* paramName = self.targetPropertyPopup.selectedItem.title;
    VConfigParameter* currentPar = [currentObj parameterWithName:paramName];
    float val = currentPar.paramNumValue.floatValue;
    if ( val != -1000) {
        // set only the NSNumber values as the fields and slider are bound to them via IB
        // The actual value will always be located half-way between the min and the max
        self.targetValue = @(val);
        self.minScaleValue = @(val/2.0);
        self.maxScaleValue = @(val*1.5);
        self.targetValueControlActive = YES;
    } else {
        self.targetValueControlActive = NO;
    }
    [self buildAndDisplayCommandString];

}

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

- (IBAction) changeParameter:(id)sender {
    
    VDocument* doc = (VDocument*)[self topDoc];
    if (doc == nil) {
        self.targetValueControlActive = NO;
        self.expressionTextField.stringValue = @"";
        return;
    }

    // take the current object and put it's parameters in the appropriate PopUpButton
    NSString* selObjName = self.targetObjectPopup.selectedItem.title;
    VConfigObject* currentObj = [doc.configModel objectWithName:selObjName];

    NSString* paramName = self.targetPropertyPopup.selectedItem.title;
    VConfigParameter* currentPar = [currentObj parameterWithName:paramName];
    float val = currentPar.paramNumValue.floatValue;
    if ( val != -1000) {
        // set only the NSNumber values as the fields and slider are bound to them via IB
        // The actual value will always be located half-way between the min and the max
        self.targetValue = @(val);
        self.minScaleValue = @(val/2.0);
        self.maxScaleValue = @(val*1.5);
        self.targetValueControlActive = YES;
    } else {
        self.targetValueControlActive = NO;
    }
    
    [self buildAndDisplayCommandString];
}

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

- (IBAction) changeParameterValue:(id)sender {
    
    if ([sender isKindOfClass:[NSSlider class]]) {
        self.targetValue = @(((NSSlider*)sender).floatValue);
    }
    if ([sender isKindOfClass:[NSTextField class]]) {
        self.targetValue = @(((NSTextField*)sender).floatValue);
    }
    float val = self.targetValue.floatValue;
    self.minScaleValue = @(val/2.0);
    self.maxScaleValue = @(val*1.5);
    
    [self buildAndDisplayCommandString];
}

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

-(IBAction) changeValueScale:(id)sender {
    
    NSButton* srcBtn = (NSButton*)sender;
    NSString* tit = srcBtn.title;
    
    if ([tit containsString:@"Linear"])  {
        self.linearScaleButton.state = NSControlStateValueOn;
        self.logScaleButton.state = NSControlStateValueOff;
        [self convertToLinearScale];
    }
    if ([tit containsString:@"log"])  {
        self.linearScaleButton.state = NSControlStateValueOff;
        self.logScaleButton.state = NSControlStateValueOn;
        [self convertToLogScale];
    }
}

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

-(IBAction) changeMinMaxSliderValue:(id)sender {
    
    if ([sender isEqualTo:self.minScaleField]) {
        self.minScaleValue = @(self.minScaleField.floatValue);
    }
    if ([sender isEqualTo:self.maxScaleField]) {
        self.maxScaleValue = @(self.maxScaleField.floatValue);
    }
}

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

-(void) convertToLogScale {
    self.targetValue = @(log10(self.targetValue.floatValue));
    if (self.minScaleValue.floatValue == 0.0){
        self.minScaleValue = @(0.001);
    }
    self.minScaleValue = @(log10(self.minScaleValue.floatValue));
    self.maxScaleValue = @(log10(self.maxScaleValue.floatValue));
}

-(void) convertToLinearScale {
    self.targetValue = @(pow(10,self.targetValue.floatValue));
    self.minScaleValue = @(pow(10,self.minScaleValue.floatValue));
    self.maxScaleValue = @(pow(10,self.maxScaleValue.floatValue));
}

//-----------------------------------------------------------------------------

-(void) activateAppWithPID:(NSNumber*) pidNum {
    
    NSPipe* inputPipe = (NSPipe*)self.curRunningTask.theTask.standardInput;
    NSFileHandle* inputHandle = inputPipe.fileHandleForWriting;
    NSData* data = nil;
    NSString* sID = pidNum.stringValue;
    NSArray* msgParts = [NSArray arrayWithObjects:@"osascript -e \"tell application \"System Events\"\n",
                         @"set frontmost of the first process whose unix id is ", sID, @" to true\n", @"end tell\n", @"\"", nil ];
    
    NSString* message = [msgParts componentsJoinedByString:@""];
    NSError* err = nil;
    data = [message dataUsingEncoding:NSUTF8StringEncoding];
    [inputHandle writeData:data error:&err];
}

//-----------------------------------------------------------------------------

-(IBAction) sendMessageToRunningTask:(id)sender {
    
    // Standard Input of control characters (those displayed with the help command / the command key equivalents of OpenGL menus)
    // does nothing because key strokes are managed directly by openGL in the 'play' application
    
    NSPipe* inputPipe = (NSPipe*)self.curRunningTask.theTask.standardInput;
    NSFileHandle* inputHandle = inputPipe.fileHandleForWriting;
    NSData* data = nil;
    
    // This is not used here but the pipe can also send multiple commands in a single line like this:
    // str = @"change microtubule { rigidity=0.0%f } change microtubule { segmentation=0.25%f }\n";
    
    NSString* str = self.expressionTextField.stringValue;
    data = [str dataUsingEncoding:NSUTF8StringEncoding];
    NSError* err = nil;
    [inputHandle writeData:data error:&err];
    
    if (err == nil) {
        // Apple recommends to close the inputHandle once used, but this prevents from getting the task's standard input
        // for another message, because it cannot be re-opened or replaced once the task is running
        // [inputHandle closeFile];
        
        // unlike file closure, here we synchronize the inputHandle content.
        // This function generates an error "-[NSConcreteFileHandle synchronizeFile]: Operation not supported" that corresponds to NSPOSIXErrorDomain code = 45, which looks like a disk error. Yet the function works fine so far, so keep it ....!!!!
        [inputHandle synchronizeAndReturnError:&err];
        if (err) {
            //NSLog(@"Disk Error ? = POSIX code 45");
        }

        // record the new values into the proper object's' parameter
        NSString* objName = @"";
        NSString* paramName = @"";
        NSString* paramValueString = @"";
        
        objName = self.targetObjectPopup.selectedItem.title;
        paramName = self.targetPropertyPopup.selectedItem.title;
        paramValueString = self.targetValueField.stringValue;
        
        NSCharacterSet* digits = [NSCharacterSet characterSetWithCharactersInString:@"0.123456789"];
        NSRange digitRange = [paramValueString rangeOfCharacterFromSet:digits];
        BOOL isNumber = (digitRange.location != NSNotFound);
        
        VDocument* doc = (VDocument*)[self topDoc];
        VConfigObject* obj = [doc.configModel objectWithName:objName];
        VConfigParameter* par = [obj parameterWithName:paramName];
        if (isNumber) {
            par.paramNumValue = self.targetValue;
            par.paramStringValue = @"";
        } else {
            par.paramStringValue = paramValueString;
            par.paramNumValue = @(-1000);
        }

        // now keep track of the change made in the log text.
        if (objName) {
            NSString* newLine = [@[objName, paramName, @"=", paramValueString, @"\n"] componentsJoinedByString:@" "];
            NSDate* msgDate = [NSDate now];
            NSString* msgString = [self hourStringFromDate:msgDate];
            msgString = [@[msgString, newLine] componentsJoinedByString:@"    "];
            [self appendToLogText:msgString WithColor:[NSColor labelColor]];
        }
    }
}



#pragma mark ========== Log content management ==========


//-----------------------------------------------------------------------------
//       Updates the Log text field
//-----------------------------------------------------------------------------

-(void) appendToLogText:(NSString*) aText WithColor:(NSColor*)reqColor {
    
    // compute the present text length and add and empty selection range at the end
    NSInteger presentLength = self.logTextView.string.length;
    NSRange range = NSMakeRange(presentLength, 0);
    [self.logTextView setSelectedRange:range];

    // add an end of line and insert colored text according to reqColor
    aText = [aText stringByAppendingString:@"\n"];
    NSDictionary* attrib = [NSDictionary dictionaryWithObject:reqColor forKey:NSForegroundColorAttributeName];
    NSAttributedString* attText = [[NSAttributedString alloc]initWithString:aText attributes:attrib];
    [self.logTextView insertText:attText replacementRange:range];
}

//-----------------------------------------------------------------------------

-(IBAction) clearLog:(id)sender {
    self.logTextView.string = @"";
}

//-----------------------------------------------------------------------------

-(IBAction) saveLog:(id)sender {
    
    NSString *theLog = [self.logTextView string];
    NSURL * theLogURL;
//    NSArray* allowedType = [NSArray arrayWithObject:@"txt"];
    NSSavePanel* theSavePanel = [NSSavePanel savePanel];
//    theSavePanel.allowedContentTypes = allowedType;
    [theSavePanel setTitle:@"Save Log file"];
    [theSavePanel setPrompt:@"Save"];
    
    if ([theSavePanel runModal] == NSModalResponseOK) {
        NSError* err =nil;
        theLogURL = [theSavePanel URL];
        [theLog writeToURL: theLogURL atomically:YES encoding:NSUTF8StringEncoding error:&err];
        if (err){
            NSLog(@"error upon file saving");
        }
    }
}

//-----------------------------------------------------------------------------
#pragma mark   ========== Edition methods ==========
//-----------------------------------------------------------------------------

- (IBAction) analyzeMenu:(id)sender {
    
}

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

- (IBAction) blockComment:(id)sender {
    VDocument* doc = (VDocument*)[self topDoc];
    [doc blockComment:sender];
}

//-----------------------------------------------------------------------------

- (IBAction) shiftRight:(id)sender{
    VDocument* doc = (VDocument*)[self topDoc];
    [doc indentSelection:sender];
}

//-----------------------------------------------------------------------------

- (IBAction) shiftLeft:(id)sender {
    VDocument* doc = (VDocument*)[self topDoc];
    [doc deIndentSelection:sender];
}

//-----------------------------------------------------------------------------

- (IBAction) insertCodeSnippet:(id)sender {
    VDocument* doc = (VDocument*)[self topDoc];
    [doc openModelBuilder:self];
}

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

-(IBAction) placeHolder:(id)sender {
    
}


//-----------------------------------------------------------------------------
#pragma mark ========== Code snippet creation ==========
//-----------------------------------------------------------------------------


-(IBAction) choseCommandAndObjectCombination:(id)sender {

    // as 2 senders should be combined, get the titles directly from the NSPopUpButtons references in AppDelegate
    NSString* whichObject = self.buildObjectPopUp.title;
    NSString* whichCommand = self.buildCommandPopUp.title;
    
    for (int k = 1; k <= (2 * NUM_HELP_IMAGES); k += 2){
        NSButton* iView = [self.modelDesignWindow.contentView viewWithTag: k];
        NSTextField* fView = [self.modelDesignWindow.contentView viewWithTag: k+1];
        iView.hidden = YES;
        fView.hidden = YES;
    }

    // then adapt enabled items and select the permitted one
    // Disabling an item works only if the NSPopUpButon.autoenableItems is set to NO at startup
    if ([whichObject isEqualToString:@"simul"]) {
        [self.buildCommandPopUp itemWithTitle:@"new"].enabled = NO;
        [self.buildCommandPopUp itemWithTitle:@"run"].enabled = YES;
        if ([self.buildCommandPopUp.selectedItem.title isEqualToString:@"new"])
            [self.buildCommandPopUp selectItemWithTitle:@"run"];
    } else {
        [self.buildCommandPopUp itemWithTitle:@"new"].enabled = YES;
        [self.buildCommandPopUp itemWithTitle:@"run"].enabled = NO;
        if ([self.buildCommandPopUp.selectedItem.title isEqualToString:@"run"])
            [self.buildCommandPopUp selectItemWithTitle:@"new"];
    }
    
    if ((whichCommand.length == 0) || (whichObject.length == 0))
        return;
        
    NSArray *srcArray, *displayArray;
    NSMutableArray* targetArray = [NSMutableArray arrayWithCapacity:0];
    BOOL childrenExpansion = NO;
    
    NSArray* tempArray = (NSArray*)[self.configObjectCreator.configObjectsDic objectForKey:whichObject];

    if ([whichCommand containsString:whichCommand]) {
        NSEnumerator* en = tempArray.objectEnumerator;
        VCymParameter* p;
        while (p = [en nextObject]) {
            if ([p.cymKey containsString:whichCommand]) {
                [targetArray addObject:p];
            }
        }
        srcArray = [NSArray arrayWithArray:targetArray];
    }

    [self.configObjectCreator.paramDataSource removeAllObjects];
    [self.configObjectCreator.paramDataSource addObjectsFromArray:srcArray];     // original objects (not copies)

    // Add display parameters in case of 'set' command
    if ([whichCommand containsString:@"set"]) {
        
        if ([whichObject containsString:@"simul"]) {
            displayArray = [self.configObjectCreator.configObjectsDic objectForKey:@"display_view"];
            [self.configObjectCreator.paramDataSource addObjectsFromArray:displayArray]; // original objects (not copies)
            displayArray = [self.configObjectCreator.configObjectsDic objectForKey:@"display_play"];
            [self.configObjectCreator.paramDataSource addObjectsFromArray:displayArray]; // original objects (not copies)
        }
        
        if ([whichObject containsString:@"space"]) {
            displayArray = (NSArray*)[self.configObjectCreator.configObjectsDic objectForKey:@"display_world"];
            [self.configObjectCreator.paramDataSource addObjectsFromArray:displayArray]; // original objects (not copies)
        }
        
        NSMutableSet* handSet = [NSMutableSet setWithObjects: @"digit", @"motor", @"nucleator", @"rescuer", @"tracker",nil];
        if ([handSet containsObject:whichObject]) {
            displayArray = (NSArray*)[self.configObjectCreator.configObjectsDic objectForKey:@"hand"];
            [self.configObjectCreator.paramDataSource addObjectsFromArray:displayArray]; // original objects (not copies)
            displayArray = (NSArray*)[self.configObjectCreator.configObjectsDic objectForKey:@"display_point"];
            [self.configObjectCreator.paramDataSource addObjectsFromArray:displayArray]; // original objects (not copies)
            displayArray = (NSArray*)[self.configObjectCreator.configObjectsDic objectForKey:@"positioning"];
            [self.configObjectCreator.paramDataSource addObjectsFromArray:displayArray]; //
        }
        [handSet addObject:@"hand"];
        if (([handSet containsObject:whichObject]) ||
            ([whichObject containsString:@"solid"]) ||
            ([whichObject containsString:@"bead"])) {
            if (([whichObject containsString:@"solid"]) ||
                ([whichObject containsString:@"bead"])) {
                displayArray = (NSArray*)[self.configObjectCreator.configObjectsDic objectForKey:@"positioning"];
                [self.configObjectCreator.paramDataSource addObjectsFromArray:displayArray];
            }
        }
        
        if (([whichObject containsString:@"single"]) ||
            ([whichObject containsString:@"couple"])){
            displayArray = (NSArray*)[self.configObjectCreator.configObjectsDic objectForKey:@"display_point"];
            [self.configObjectCreator.paramDataSource addObjectsFromArray:displayArray]; // original objects (not copies)
            displayArray = (NSArray*)[self.configObjectCreator.configObjectsDic objectForKey:@"positioning"];
            [self.configObjectCreator.paramDataSource addObjectsFromArray:displayArray]; // original objects (not copies)
        }
        
        if (([whichObject containsString:@"fiber"]) ||
            ([whichObject containsString:@"bundle"])){
            displayArray = (NSArray*)[self.configObjectCreator.configObjectsDic objectForKey:@"display_fiber"];
            [self.configObjectCreator.paramDataSource addObjectsFromArray:displayArray]; // original objects (not copies)
            displayArray = (NSArray*)[self.configObjectCreator.configObjectsDic objectForKey:@"positioning"];
            [self.configObjectCreator.paramDataSource addObjectsFromArray:displayArray]; // original objects (not copies)
        }
        
        self.numberField.enabled = NO;
        self.numberFieldTitle.hidden = YES;
        self.colorWell.hidden = YES;
        self.colorTitle.hidden = YES;
    }
    if ([whichCommand containsString:@"new"]) {
        self.numberField.enabled = YES;
        self.numberFieldTitle.hidden = NO;
    }

    [self.paramOutlineView reloadData];
    
    // expand the cym object chosen and all its children, but not the display dictionaries
    [self.paramOutlineView expandItem:(VCymParameter*)srcArray.firstObject expandChildren:childrenExpansion];
    
    self.paramHelpField.stringValue = @""; // as no parameter is selected upon reloading
}

//-----------------------------------------------------------------------------

-(IBAction) resetObject:(id)sender {
//    [self preloadCymObjectFiles];
    [self.configObjectCreator preloadCymObjectFiles];
    [self choseCommandAndObjectCombination:self.buildObjectPopUp];
}

//-----------------------------------------------------------------------------

-(IBAction) insertTemplate:(id)sender{
    NSString* comment1 = @"%{\n  Insert your entitlements and comments here...\n\n  Replace the terms in CAPITALS in the template if you know what you are doing.\n  For more control, replace each configuration element and/or add new ones using the configuration snippets window.\n}\n\n";
    NSString* simul = @"set simul SIMUL_NAME\n{\n    PARAMETERS AND VALUES\n}\n\n";
    NSString* space = @"set space SPACE_NAME\n{\n    PARAMETERS AND VALUES\n}\n\n";
    NSString* space2 = @"new SPACE_NAME\n{\n    PARAMETERS AND VALUES\n}\n\n";
    NSString* obj1 = @"set OBJECT_TYPE OBJECT_NAME\n{\n    PARAMETERS AND VALUES\n}\n\n";
    NSString* obj2 = @"new NUMBER_OF_OBJECTS OBJECT_NAME\n{\n    PARAMETERS AND VALUES\n}\n\n";
    NSString* run = @"run STEPS SIMUL_NAME\n{\n    PARAMETERS AND VALUES\n}\n\n";
    NSString* s = [@[comment1, simul, space, space2, obj1, obj2, run] componentsJoinedByString:@""];

    VDocument* doc = (VDocument*)[self topDoc];
    [doc replaceWithText:s];
}

//-----------------------------------------------------------------------------

-(NSString*) extractParameterListFromSource {
    
    NSString* result = @"";
    NSMutableArray* displayElements = [NSMutableArray arrayWithCapacity:0];
    
    for (VCymParameter* param in self.configObjectCreator.paramDataSource) {
        NSString* temp = @"";
        NSString* spc = @"    ";
        
        if (param.children) {
            
            for (VCymParameter* child in param.children) {
                
                if (child.used.boolValue == YES) {
                    
                    // go upward in the parent object chain to detect a 'display' parameter
                    VCymParameter* parent = child.parent;

                    if ([parent.cymKey containsString:@"display"]) {
                        [displayElements addObject:child];
                    } else {
                        temp = [@[spc, child.cymKey, @" = ", child.cymValueString, @"\n"] componentsJoinedByString:@""];
                        result = [result stringByAppendingString:temp];
                    }
                } else {
                    
                    if (child.children) {
                        for (VCymParameter* subChild in child.children) {
                            if (subChild.used.boolValue == YES) {
                                VCymParameter* agecanonix = [subChild ancestor];
                                if ([agecanonix.cymKey containsString:@"display"]) {
                                    [displayElements addObject:subChild];
                                } else {
                                    temp = [@[spc, subChild.cymKey, @" = ", subChild.cymValueString, @"\n"] componentsJoinedByString:@""];
                                    result = [result stringByAppendingString:temp];
                                }
                            }
                        }
                    }
                    
                } // else
            }
        } else {
            if (param.used.boolValue == YES) {
                temp = [@[spc, param.cymKey, @" = ", param.cymValueString, @"\n"] componentsJoinedByString:@""];
                result = [result stringByAppendingString:temp];
            }
        }
        if (displayElements.count >0) {
            NSMutableArray* displayParams = [NSMutableArray arrayWithCapacity:0];
            for (VCymParameter* param in displayElements) {
                NSString* p = param.cymKey;
                NSString* v = param.cymValueString;
                temp = [@[p,@"=",v,@"; "] componentsJoinedByString:@""];
                [displayParams addObject:temp];
            }
            result = [result stringByAppendingString: @"    display = ( "];
            for (NSInteger k=0; k<displayParams.count; k++){
                result = [result stringByAppendingString:[displayParams objectAtIndex:k]];
            }
            result = [result stringByAppendingString:@")\n"];
        }
    }
    return result;
}

//-----------------------------------------------------------------------------

-(NSString*) buildSnippet {
    
    NSString* result = @"";
    NSString* command = self.buildCommandPopUp.title;
    NSString* object = self.buildObjectPopUp.title;
    NSString* objName = self.nameField.stringValue;
    
    if ([command isEqualToString:@"set"]) {
        
        NSString* opening = [@[command, object, objName] componentsJoinedByString:@" "];
        opening = [opening stringByAppendingString:@"\n{\n"];
        NSString* closing = @"}\n";
        
        NSString* content = [self extractParameterListFromSource];
        
        result = [@[opening, content, closing] componentsJoinedByString:@""];
    }
    return result;
}

//-----------------------------------------------------------------------------

-(IBAction) insertSnippet:(id)sender {
    // insert at caret location or replace selected text
    NSString* s = [self buildSnippet];
    VDocument* doc = (VDocument*)[self topDoc];
    [doc replaceWithText:s];
}

//-----------------------------------------------------------------------------
#pragma mark  ========== Polygon Drawing Window  ==========
//-----------------------------------------------------------------------------

-(IBAction) chosePolygonScale:(id)sender {
    
    NSInteger remainder = self.polygonScaleSlider.intValue % 10;
    NSInteger newValue = self.polygonScaleSlider.intValue;
    if (remainder >0)
        newValue += (10 - remainder);
    self.polygonScaleSlider.integerValue = newValue;
    self.polygonScale  = [NSNumber numberWithInteger:newValue];
    
    [self.polygonDrawingView updateGrid];
}

//-----------------------------------------------------------------------------

-(IBAction) chosePolygonNumMicrons:(id)sender {
    NSInteger remainder = self.polygonNumMicronsSlider.intValue % 2;
    NSInteger newValue = self.polygonNumMicronsSlider.intValue;
    if (remainder >0)
        newValue ++;
    self.polygonNumMicronsSlider.integerValue = newValue;
    self.polygonNumMicrons  = [NSNumber numberWithInteger:newValue];
    
    [self.polygonDrawingView updateGrid];
    [self.polygonDrawingView resizeBackgroundImage];
}


-(IBAction) changePolygonZoom:(id)sender {
    self.polygonZoom = [NSNumber numberWithFloat:(self.polygonZoomSlider.integerValue/10.0)];
    [self.polygonDrawingView scalePolygon];
}

//-----------------------------------------------------------------------------

-(IBAction) clearPolygon: (id) sender {
    [self.polygonDrawingView clearAllDrawing];
    self.clearButton.enabled = NO;
    self.savePolygonButton.enabled = NO;
}

//-----------------------------------------------------------------------------

-(IBAction) openPolygonBackgroundImage: (id) sender {
    
    NSOpenPanel* theOpenPanel = [NSOpenPanel openPanel];
    NSURL * theURL;
    
    NSArray* allowedTypes = [NSImage imageTypes];
    // remove the types that generate an error !
    NSMutableArray* mutTypes = [NSMutableArray arrayWithArray:allowedTypes];
    [mutTypes removeObject:@"com.apple.atx"];
    [mutTypes removeObject:@"com.microsoft.cur"];
    allowedTypes = [NSArray arrayWithArray:mutTypes];
    
    [theOpenPanel setAllowedFileTypes:allowedTypes];
    
    if ([theOpenPanel runModal] == NSModalResponseOK) {
        theURL = [theOpenPanel URL];
        NSImage* openImage = [[NSImage alloc]initWithContentsOfURL:theURL];
        if (openImage) {
            
            self.polygonDrawingView.image = openImage;
            
            // manage image resizing to fit the present grid's frame
            NSSize imgSize = openImage.size;
            float widerDim = MAX(imgSize.width, imgSize.height);
            float viewSize = self.polygonDrawingView.frame.size.width; // square grid so width = height
            float zFact = viewSize /widerDim;
            NSSize newSize = NSMakeSize(imgSize.width * zFact, imgSize.height * zFact);
            openImage.size = newSize;
            self.clearBackgroundButton.enabled = YES;
        }
    }
}

//-----------------------------------------------------------------------------

-(IBAction) clearPolygonBackgroundImage: (id) sender {
    self.polygonDrawingView.image = nil;
    [self.polygonDrawingView setNeedsDisplay:YES];
    self.clearBackgroundButton.enabled = NO;
}

//-----------------------------------------------------------------------------

-(IBAction) togglePolygonTransparency:(id)sender {
    [self.polygonDrawingView setNeedsDisplay:YES];
}

//-----------------------------------------------------------------------------

-(IBAction) openPolygonFile: (id) sender {
        
    NSOpenPanel* theOpenPanel = [NSOpenPanel openPanel];
    NSURL * theURL;
    NSArray* allowedType = [NSArray arrayWithObject:@"txt"];
    [theOpenPanel setAllowedFileTypes:allowedType];
    NSString* polyString = @"";
    
    if ([theOpenPanel runModal] == NSModalResponseOK) {
        theURL = [theOpenPanel URL];
        polyString = [NSString stringWithContentsOfURL:theURL encoding:NSASCIIStringEncoding error:nil];
        [self.polygonDrawingView stringToPolygon:polyString];
        self.polygonZoom = [NSNumber numberWithFloat:1.0];
        self.clearButton.enabled = YES;
        self.savePolygonButton.enabled = YES;
    }
}

//-----------------------------------------------------------------------------

-(IBAction) savePolygonFile: (id) sender {
    
    NSString* thePoly = [self.polygonDrawingView polygonToString];
    
    NSURL * theURL;
    NSSavePanel* theSavePanel = [NSSavePanel savePanel];
    NSArray* allowedType = [NSArray arrayWithObject:@"txt"];
    [theSavePanel setAllowedFileTypes:allowedType];
    [theSavePanel setTitle:@"Save polygon file"];
    [theSavePanel setPrompt:@"Save"];
    
    if ([theSavePanel runModal] == NSModalResponseOK) {
        NSError* err =nil;
        theURL = [theSavePanel URL];
        [thePoly writeToURL: theURL atomically:YES encoding:NSUTF8StringEncoding error:&err];
        self.polygonDrawingWindow.documentEdited = NO;

        if (err){
            NSLog(@"error upon file saving");
        }
    }

}
//-----------------------------------------------------------------------------

-(IBAction) printPolygon: (id) sender {
    [self.polygonDrawingView doPrint];
}

//-----------------------------------------------------------------------------
#pragma mark  ========== Model Drawing Window  ==========
//-----------------------------------------------------------------------------


-(IBAction) choseModelScale:(id)sender {
    NSInteger remainder = self.modelScaleSlider.intValue % 10;
    NSInteger newValue = self.modelScaleSlider.intValue;
    if (remainder >0)
        newValue += (10 - remainder);
    self.modelScaleSlider.integerValue = newValue;
    self.modelScale  = [NSNumber numberWithInteger:newValue];
    
    [self.modelDrawingView updateGrid];
}

-(IBAction) choseModelNumMicrons:(id)sender {
    NSInteger remainder = self.modelNumMicronsSlider.intValue % 2;
    NSInteger newValue = self.modelNumMicronsSlider.intValue;
    if (remainder >0)
        newValue ++;
    self.modelNumMicronsSlider.integerValue = newValue;
    self.modelNumMicrons  = [NSNumber numberWithInteger:newValue];
    
    [self.modelDrawingView updateGrid];
}

-(IBAction) makeConfigurationFromModel:(id)sender {
    
}

-(IBAction) defineModelParameterValue:(id)sender {
    
}

-(IBAction) defineModelInstanceName:(id)sender {
    
}

-(IBAction) defineModelInstanceNumber:(id)sender {
    
}

-(IBAction) defineModelInstanceRandom:(id)sender {
    
}

-(IBAction) defineModelInstanceLineColor:(id)sender {
    
}

-(IBAction) defineModelInstanceFillColor:(id)sender {
    
}

-(IBAction) modelInsertSimulation:(id)sender {
    
    for (int k = 1; k <= (2 * NUM_HELP_IMAGES); k += 2){
        NSButton* iView = [self.modelDesignWindow.contentView viewWithTag: k];
        NSTextField* fView = [self.modelDesignWindow.contentView viewWithTag: k+1];
        iView.hidden = YES;
        fView.hidden = YES;
    }

    NSString* whichObject = @"simul";
    NSString* whichCommand = @"set";
    NSMutableArray* targetArray = [NSMutableArray arrayWithCapacity:0];
    NSArray* srcArray, *displayArray;
    BOOL childrenExpansion = NO;

    NSArray* tempArray = (NSArray*)[self.configObjectCreator.configObjectsDic objectForKey:whichObject];
    NSEnumerator* en = tempArray.objectEnumerator;
    VCymParameter* p;
    while (p = [en nextObject]) {
        if ([p.cymKey containsString:whichCommand]) {
            [targetArray addObject:p];
        }
    }
    srcArray = [NSArray arrayWithArray:targetArray];
    [self.configObjectCreator.paramDataSource removeAllObjects];
    [self.configObjectCreator.paramDataSource addObjectsFromArray:srcArray];     // add original objects (not copies)
    
    displayArray = [self.configObjectCreator.configObjectsDic objectForKey:@"display_view"];
    [self.configObjectCreator.paramDataSource addObjectsFromArray:displayArray]; // original objects (not copies)
    displayArray = [self.configObjectCreator.configObjectsDic objectForKey:@"display_play"];
    [self.configObjectCreator.paramDataSource addObjectsFromArray:displayArray]; // original objects (not copies)

    [self.paramOutlineView reloadData];
    // expand the cym object chosen and all its children, but not the display dictionaries
    [self.paramOutlineView expandItem:(VCymParameter*)srcArray.firstObject expandChildren:childrenExpansion];
    self.paramHelpField.stringValue = @""; // as no parameter is selected upon reloading
    
    self.modelSimulationIcon.hidden = NO;
}


-(IBAction) modelInsertSpace:(id)sender {
    
}

-(IBAction) modelInsertFiber:(id)sender {
    
}

-(IBAction) modelInsertCrosslinker:(id)sender {
    
}

-(IBAction) modelInsertNucleator:(id)sender {
    
}

-(IBAction) modelInsertMotor:(id)sender {
    
}

-(IBAction) modelInsertChimericProtein:(id)sender {
    
}


//-----------------------------------------------------------------------------
#pragma mark ============= NSMenuItemValidation Protocol =====================
//-----------------------------------------------------------------------------


-(BOOL) validateMenuItem:(NSMenuItem *)menuItem {
    
    // activate by default, only manage deactivations ....
    // Meaning of tag values: the digit of tens denotes the menu, that of units denotes the items
    
    BOOL answer = YES;

//// Setup menu
    
    ////      go to explicit bin directory
    if (menuItem.tag == 1)
        answer =  (self.binariesURL != nil);

    ////      go to explicit working directory
    if (menuItem.tag == 2)
        answer =  (self.workingURL != nil);
    
    ////      go to explicit  sim directory
    if (menuItem.tag == 3) {
        answer =  (self.simURL != nil);
    }

    ////      chose automatic sim directory
    if (menuItem.tag == 4) {
        menuItem.state = self.autoSimDirectory;
        answer =  ! self.autoSimDirectory;
    }
    
    ////      chose explicit a new sim directory
    //    if (menuItem.tag == 5) {
    //        menuItem.state = ! self.autoSimDirectory;
    //        answer = self.autoSimDirectory;
    //    }

//// Run menu

    ////      run sim in 2D (11) or 3D (12)
    if ((menuItem.tag == 11) || (menuItem.tag == 12)) {
        answer = self.okForSim;
    }
    
    ////      run play from sim directory
    if ((menuItem.tag == 13)) {
        answer = self.okForPlay;
    }
    
    ////      run play live
    if ((menuItem.tag == 14)) {
        answer = self.okForLivePlay;
    }

//// Analyze menu

    ////      Report item
    if ((menuItem.tag == 21)) {
        answer = self.okForReport;
    }
    
    ////      insert code snippet
    if ((menuItem.tag == 31)) {
        VDocument* doc = (VDocument*)[self topDoc];
        answer = (doc != nil);
    }
 
    return answer;
}

@end
