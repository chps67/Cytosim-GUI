//
//  VParamVariationsTableManager.m
//  Cytosim GUI
//
//  Created by Chris on 19/01/2023.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "VParamVariationsManager.h"

#import "VAppDelegate.h"
#import "VDocument.h"
#import "VConfigurationModel.h"
#import "VConfigObject.h"
#import "VConfigParameter.h"

#import "OrderedDictionary.h"


#define MyPrivateTableViewDataType @"public.text"


@implementation VParamVariationsManager

//-----------------------------------------------------------------------------
#pragma mark ______ Overrides _______
//-----------------------------------------------------------------------------

// BEWARE NOT to initialize controller in awakeFromNib as the method is called several times
// and can preclude upstream handling of non-view members that are set upon file opening for example.
// Instead, override the init method, which is called only once

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.numSim = @1;
        self.canRunSimBatch = @NO;
        
        VAppDelegate* del = (VAppDelegate*)[NSApp delegate];
        del.allowBatchRun = @NO;
    }
    return self;
}

//-----------------------------------------------------------------------------

-(void) awakeFromNib {
    
    NSTrackingArea* trackingArea = [[NSTrackingArea alloc] initWithRect:self.interpolView.frame
                                                                options: (NSTrackingMouseMoved |NSTrackingMouseEnteredAndExited |
                                                                          NSTrackingInVisibleRect | NSTrackingActiveInActiveApp)
                                                                  owner:self userInfo:nil];
    
    [self.interpolView addTrackingArea:trackingArea];
    [self.interpolView registeredDraggedTypes];
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(parameterDidUpdate:)
                                                 name: @"paramUpdated" object:nil];
    
    [self.outlineView registerForDraggedTypes:[NSArray arrayWithObject: MyPrivateTableViewDataType]];

}

//-----------------------------------------------------------------------------

-(void) parameterDidUpdate:(NSNotification*) aNotif {
    self.xOrigin = [self.interpolView.leftBoundary copy];
    self.yOrigin = [self.interpolView.bottomBoundary copy];
    self.xWidth = [self.interpolView.rightBoundary copy];
    self.yHeight = [self.interpolView.topBoundary copy];
    self.meshSizeX = [self.interpolView.meshSizeValueX copy];
    self.meshSizeY = [self.interpolView.meshSizeValueY copy];
}

//-----------------------------------------------------------------------------

- (void) mouseEntered:(NSEvent *)theEvent
{
    NSCursor* curs = [NSCursor crosshairCursor];
    [curs set];
}

//-----------------------------------------------------------------------------

- (void) mouseExited:(NSEvent *)theEvent
{
    NSCursor* curs = [NSCursor arrowCursor];
    [curs set];
    self.curX = [NSNumber numberWithFloat:NAN];
    self.curY = [NSNumber numberWithFloat:NAN];
}

//-----------------------------------------------------------------------------

-(void) mouseMoved:(NSEvent *)event {
    NSPoint movedPoint = [self.interpolView convertPoint:[event locationInWindow] fromView:nil];
    
    const NSInteger margin = 5;
    float dX = self.interpolView.rightBoundary.floatValue - self.interpolView.leftBoundary.floatValue;
    float dY = self.interpolView.topBoundary.floatValue - self.interpolView.bottomBoundary.floatValue;
    NSRect viewFrame = self.interpolView.frame;
    float viewFactorX = (viewFrame.size.width - (2 * margin)) / dX;
    float viewFactorY = (viewFrame.size.height - (2 * margin)) / dY;
    float X = (movedPoint.x - margin) / viewFactorX + self.interpolView.leftBoundary.floatValue;
    float Y = (movedPoint.y - margin) / viewFactorY + self.interpolView.bottomBoundary.floatValue;
    self.curX = [NSNumber numberWithFloat:X];
    self.curY = [NSNumber numberWithFloat:Y];
}

//-----------------------------------------------------------------------------
#pragma mark ______ NSOutlineView data source and delegate methods _______
//-----------------------------------------------------------------------------

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    
    VConfigurationModel* model = self.ownerDoc.configModel;
    
    NSInteger answer = 0;
    if (item == nil) { // This is for displaying only the root items
        // Beware : to display only the expandable items, they all should appear at the top of the NSOutlineDataSource array
        // because cocoa is going to pick 'expandables' items including the first object and then stop
        
        //answer = expandables;
        answer = model.variableOutlineItems.count;
    } else  {   // this is for expanding the root items -> insert 'numberOfChildren' rows
        answer = [item numberOfChildren];
    }
    return answer;
}

//-----------------------------------------------------------------------------

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    BOOL answer = NO;
    if ([item isMemberOfClass:[VOutlineItem class]]) {
        VOutlineItem* oIt = (VOutlineItem*)item;
        answer = oIt.expandable;
    }
    return answer;
}

//-----------------------------------------------------------------------------

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    VConfigurationModel* model = self.ownerDoc.configModel;
    if (item == nil ){
        // called for ALL the root objects (i.e. those without children = not expanded ones in our case)
        return [model.variableOutlineItems objectAtIndex:index];
    } else {
        // when a root object has children and is expandable, read the index-th object among the children
        return [(VOutlineItem*)item childAtIndex:index];
    }
}

//-----------------------------------------------------------------------------

-(NSView*) outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
   
    NSTableCellView* theCell = nil;
    NSButton* checkButton = nil;
    VOutlineItem* oIt = (VOutlineItem*)item;
    NSNumberFormatter* form = [[NSNumberFormatter alloc]init];
    NSLocale* en_loc = [[NSLocale alloc] initWithLocaleIdentifier: @"en"];
    [form setLocale:en_loc];

    if ([tableColumn.identifier isEqualToString:@"Use"]) {
        theCell = ([outlineView makeViewWithIdentifier:@"Use_view" owner:self]);
        NSArray* subs = [theCell subviews];
        checkButton = (NSButton*)(subs.firstObject);
        if (oIt.expandable == YES) {
            NSNumber* num = [form numberFromString:oIt.configParameter.instanceCount.stringValue];
            if ((num == nil) || (num.integerValue == 0)) {   // the parameter value is only numeric
                checkButton.hidden = YES;
            } else {
                checkButton.hidden = NO;
            }
        } else {
            checkButton.hidden = NO;
            if (oIt.configParameter.variations.active.boolValue == YES) {
                checkButton.state = NSControlStateValueOn;
            } else {
                checkButton.state = NSControlStateValueOff;
            }
        }
    }
    
    if ([tableColumn.identifier isEqualToString:@"Object"]){
        theCell = ([outlineView makeViewWithIdentifier:@"Object_view" owner:self]);
        theCell.textField.stringValue = [oIt.configParameter.ownerType copy];
    }
    if ([tableColumn.identifier isEqualToString:@"Instances"]){
        theCell = ([outlineView makeViewWithIdentifier:@"Instances_view" owner:self]);
        if (oIt.configParameter.ownerIsInstance) {
            theCell.textField.stringValue = [self numericString:[oIt.configParameter.instanceCount.stringValue copy]];
        } else {
            theCell.textField.stringValue = @"";
        }
    }
    if ([tableColumn.identifier isEqualToString:@"Name"]){
        theCell = ([outlineView makeViewWithIdentifier:@"Name_view" owner:self]);
        theCell.textField.stringValue = [oIt.configParameter.paramName copy];
    }
    if ([tableColumn.identifier isEqualToString:@"MinX"]){
        theCell = ([outlineView makeViewWithIdentifier:@"MinX_view" owner:self]);
        theCell.textField.stringValue = [self numericString:[oIt.configParameter.variations.minX.stringValue copy]];
    }
    if ([tableColumn.identifier isEqualToString:@"MaxX"]){
        theCell = ([outlineView makeViewWithIdentifier:@"MaxX_view" owner:self]);
        theCell.textField.stringValue = [self numericString:[oIt.configParameter.variations.maxX.stringValue copy]];
    }
    if ([tableColumn.identifier isEqualToString:@"MinY"]){
        theCell = ([outlineView makeViewWithIdentifier:@"MinY_view" owner:self]);
        theCell.textField.stringValue = [self numericString:[oIt.configParameter.variations.minY.stringValue copy]];
    }
    if ([tableColumn.identifier isEqualToString:@"MaxY"]){
        theCell = ([outlineView makeViewWithIdentifier:@"MaxY_view" owner:self]);
        theCell.textField.stringValue = [self numericString:[oIt.configParameter.variations.maxY.stringValue copy]];
    }

    if (oIt.configParameter.validateDX)
        theCell.textField.textColor = NSColor.systemBrownColor;
    else
        theCell.textField.textColor = NSColor.controlTextColor;

    return theCell;
}

//-----------------------------------------------------------------------------
// tests if a string holds numeric data
//-----------------------------------------------------------------------------

- (NSString*) numericString:(NSString*)sourceStr {
    
    NSString* outStr = @"";
    NSNumberFormatter* form = [[NSNumberFormatter alloc]init];
    NSLocale* en_loc = [[NSLocale alloc] initWithLocaleIdentifier: @"en"];
    [form setLocale:en_loc];

    NSNumber* num = [form numberFromString:sourceStr];
    if ((num != nil) && (![num.stringValue isEqualToString:@"nan"])) {
        outStr = num.stringValue;
    }
    return outStr;
}

//-----------------------------------------------------------------------------

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    
    VOutlineItem* oIt = (VOutlineItem*)item;
    NSNumberFormatter* form = [[NSNumberFormatter alloc]init];
    NSLocale* en_loc = [[NSLocale alloc] initWithLocaleIdentifier: @"en"];
    [form setLocale:en_loc];
    BOOL answer = NO;
    
    if (oIt.expandable == YES) {
        NSNumber* num = [form numberFromString:oIt.configParameter.instanceCount.stringValue];
        if (num) {   // the parameter value is only numeric
            if (num.integerValue > 0)
                answer = YES;
        }
    } else {
        answer = YES;
    }

    return answer;
}

//-----------------------------------------------------------------------------

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    
    NSInteger row = self.outlineView.selectedRow;
    
    // do NOT select empty rows (fix console error)
    if (row < 0)
        return;
    
    self.currentItem = (VOutlineItem*)[self.outlineView itemAtRow:row];
    
    // update the manager's check flags for each parameter
    [self checkBoxForItem:self.currentItem];
    [self synchronizeUseBoxes];
    
    // display the original or the interpolated values in the image view
    self.interpolView.var = self.currentItem.configParameter.variations;
    [self.interpolView setNeedsDisplay:YES];
}

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

- (IBAction) refreshOutline:(id)sender {
    
    NSAlert* reloadAlert = [[NSAlert alloc]init];
    NSImage* theIcon = [NSImage imageNamed:@"CytosimForOSX"];
    reloadAlert.icon = theIcon;
    reloadAlert.alertStyle = NSAlertStyleWarning;
    NSString* message = @"Do you really want to reload all the data from the configuration (.cym) file ? \n All the variations will be lost. \n Saving your .cym file will record only new modifications. ";
    [reloadAlert setMessageText: message];
    [reloadAlert addButtonWithTitle: @"No"];  // 1st (default) button
    [reloadAlert addButtonWithTitle: @"Yes"]; // 2nd button
    
    NSModalResponse response = [reloadAlert runModal];
    if (response == NSAlertSecondButtonReturn) {
        //NSControl_Inspector* ctrl_Insp = [[NSControl_Inspector alloc] initWithControl: self.runBatchButton];
        VConfigurationModel* model = self.ownerDoc.configModel;
        [model extractObjectsAndInstances];
        [model extractOutlineVariableItems];
        [self.outlineView reloadData];
    }
}
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

-(NSButton*) checkBoxForItem:(id)item {
    
    NSButton* check = nil;
    
    NSInteger targetRow = [self.outlineView rowForItem:item];
    NSInteger useColIndex = [self.outlineView columnWithIdentifier:@"Use"];
    NSTableCellView* aCellView = [self.outlineView viewAtColumn:useColIndex row:targetRow makeIfNecessary:YES];
    if (aCellView) {
        NSArray* subs = aCellView.subviews;
        if (subs) {
            NSView* firstView = (NSView*)subs.firstObject;
            if (firstView) {
                if ([firstView isKindOfClass:[NSButton class]]) {
                    check = (NSButton*)firstView;
                }
            }
        }
    }
    return check;
}

//-----------------------------------------------------------------------------

-(void) synchronizeUseBoxes {
    
    NSButton* useBox = nil;
    
    for (NSInteger row = 0; row < [self.outlineView numberOfRows]; row++) {
        VOutlineItem* root = (VOutlineItem*)[self.outlineView itemAtRow:row];
        if (root.configParameter.isNumeric) {
            
            useBox = [self checkBoxForItem:root];
            if ((root.configParameter.variations.active.boolValue == YES) || (root.configParameter.validateDX)) {
                useBox.enabled = YES;
                (root.configParameter.variations.active.boolValue == YES) ? (useBox.state = NSControlStateValueOn) : (useBox.state = NSControlStateValueOff);
            }
            
            if ([self.outlineView isItemExpanded:root]) {
                
                for (NSInteger childIndex = 0; childIndex < root.children.count; childIndex++) {
                    VOutlineItem* child = (VOutlineItem*)[root.children objectAtIndex:childIndex];
                    if (child.configParameter.isNumeric) {
                        useBox = [self checkBoxForItem:child];
                        if ((child.configParameter.variations.active.boolValue) || (child.configParameter.validateDX)) {
                            useBox.enabled = YES;
                            (child.configParameter.variations.active.boolValue == YES) ? (useBox.state = NSControlStateValueOn) : (useBox.state = NSControlStateValueOff);
                        }
                    }
                }
                
            }
        }
    }
}

- (void)outlineViewItemDidCollapse:(NSNotification *)notification {
    
    [self synchronizeUseBoxes];
}

//-----------------------------------------------------------------------------

- (void)outlineViewItemDidExpand:(NSNotification *)notification {
    
    [self synchronizeUseBoxes];
}

//-----------------------------------------------------------------------------

- (BOOL) hasVariationsInParameters {
    BOOL answer = NO;
    
    VConfigurationModel* model = self.ownerDoc.configModel;

    for (VOutlineItem* root in model.variableOutlineItems) {
        if (root.configParameter.validateDX){
            answer = YES;
            break;
        }
        for (VOutlineItem* child in root.children) {
            if (child.configParameter.validateDX) {
                answer = YES;
                break;
            }
        }
    }
    return answer;
}

//-----------------------------------------------------------------------------
#pragma mark ______ Internal methods for outlineView _______
//-----------------------------------------------------------------------------

- (void) outlineEnableUseCheckBox:(BOOL)enable ForItem:(VOutlineItem*)item {

    NSButton* checkBox = [self checkBoxForItem:item];
    checkBox.enabled = enable;
    //[self synchronizeUseBoxes];
}

//-----------------------------------------------------------------------------

- (IBAction) useOutlineItemVariation:(id)sender {
    NSButton* checkBox = (NSButton*)sender;
    
    // This is mandatory since a click in the checkbox does NOT select the row.
    // i.e. the user may check a row while another one is actually selected
    NSInteger targetRow = [self.outlineView rowForView:checkBox];
    VConfigParameter* targetParam = ((VOutlineItem*)[self.outlineView itemAtRow:targetRow]).configParameter;
    
    BOOL status = (checkBox.state == NSControlStateValueOn);
    
    // set variations according to the checkbox status
    if (targetParam) {
        targetParam.variations.active = [NSNumber numberWithBool: status];
    }
    // then compute the number of expected vars by scanning all the parameters
    self.numSim = [[self computeNumSimCalls] copy];
    if (! self.ownerDoc.documentEdited)
        [self.ownerDoc updateChangeCount:NSChangeDone];

}

//-------------------------------------------------------------------------------------
// BEWARE - IB trick - the connection below is OK with the built-in NSTextField in the
// NSTableCellView but by default it will not allow editing.
// This should be modified in IB by changing the items of at least one menu:
//
// • Behavior SHOULD be set to 'Editable' instead of default 'None'
// • Action  is OPTIONAL. It is set by default to 'Send on end editing', which looks OK
//       as the action is called upon striking tab or return keys.
//-------------------------------------------------------------------------------------



- (IBAction) editOutlineCellValue:(id)sender {
    
    VOutlineItem* oIt = nil;
    
    if ([sender isMemberOfClass:[NSTextField class]]) {
        
        if (self.outlineView.selectedRow < 0)
            return;
        else {
            oIt = self.currentItem;
        }
        
        NSTextField* editedField = (NSTextField*)sender;
        NSString* cellValueStr = editedField.stringValue;
        
        NSView* superView = [sender superview];
        NSString* superID = superView.identifier;
        
        NSNumberFormatter* form = [[NSNumberFormatter alloc]init];
        NSLocale* en_loc = [[NSLocale alloc] initWithLocaleIdentifier: @"en"];
        [form setLocale:en_loc];
        NSNumber* num = [form numberFromString:cellValueStr];
        
        if (num != nil) {   // the parameter value is only numeric
            
            if ([superID isEqualToString:@"MinX_view"]) {
                oIt.configParameter.variations.minX = num;
            }
            if ([superID isEqualToString:@"MaxX_view"]) {
                oIt.configParameter.variations.maxX = num;
            }

            if (oIt.configParameter.validateDX) {
                [self applyOutlineItemVariationChange];
                [self outlineEnableUseCheckBox:YES ForItem:self.currentItem];
            } else {
                [self outlineEnableUseCheckBox:NO ForItem:self.currentItem];
            }
        }
    }
}

//-----------------------------------------------------------------------------

- (void) applyOutlineItemVariationChange {
    
    VConfigParameter* param = self.currentItem.configParameter;
    
    if  (param.validateDX) {
        
        if (param.variations.numberOfValues.integerValue == 1)
            param.variations.numberOfValues = @2;
        
        // compute all the main, intermediate and max values
        // and store them into variations.variationValues
        // ALSO the new parameter variations directly modify the paramSuitableForVariations table of the config model
        [param.variations collectValues];

        // round the number of instances
        if (param.ownerIsInstance) {
            if ([param.ownerName isEqualToString:@"instance"]) {
                for (NSInteger k = 0; k < param.variations.variationValues.count; k++) {
                    NSNumber* n = [param.variations.variationValues objectAtIndex:k];
                    if ([n.stringValue containsString:@"."]) {
                        NSInteger roundedValue = n.integerValue;
                        NSNumber* nn = [NSNumber numberWithInteger:roundedValue];
                        [param.variations.variationValues replaceObjectAtIndex:k withObject:nn];
                    }
                }
            }
        }
        
        // update the table AND the interpolation view
        self.interpolView.var = param.variations;
        [self.interpolView setNeedsDisplay:YES];
        [self.outlineView reloadData];
        
        if (! self.ownerDoc.documentEdited)
            [self.ownerDoc updateChangeCount:NSChangeDone];
    }
}


//-----------------------------------------------------------------------------
#pragma mark ......................... Drag and Drop
//-----------------------------------------------------------------------------

// The pasterboard item with a unique identifier = the # of the selected row or -1 if none is seleceted
- (id <NSPasteboardWriting>)outlineView:(NSOutlineView *)outlineView pasteboardWriterForItem:(id)item {
    NSPasteboardItem *pboardItem = nil;
    NSInteger selRow = outlineView.selectedRow;
    NSString *identifier = [NSString stringWithFormat:@"%ld", selRow];
    pboardItem = [[NSPasteboardItem alloc] init];
    [pboardItem setString:identifier forType:MyPrivateTableViewDataType];
    return pboardItem;
}

// First, this is where we identify the dragged item.
- (void)outlineView:(NSOutlineView *)outlineView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forItems:(NSArray *)draggedItems {
    self.currentItem = (VOutlineItem*)draggedItems.firstObject;
}

// This is where we accept the future drop to operate, as represented with the mobile blue pin symbol that follows the mouse
// the only drag mode allowed is a move mode (no copy or anything else)
// Here we get the destination item position as the # of the crack line between items
// 0 means before the first item, 1 between the 1st and the 2nd etc...
-(NSDragOperation) outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
    
    NSDragOperation theDrop = NSDragOperationNone;
    
    // validate the drop only if a child object is deposited within the same child object
    if (item) {
        VOutlineItem* dstItem = (VOutlineItem*)item;
        NSInteger srcLevel = [outlineView levelForItem:self.currentItem];
        NSInteger dstLevel = [outlineView levelForItem:dstItem];
        if ((srcLevel == 1) && (dstLevel == 0)) {
            VOutlineItem* srcParent = self.currentItem.parent;
            if ([dstItem isEqualTo:srcParent]) {
                theDrop = NSDragOperationMove;
            }
        }
    } else {
        if (index >=0) { // movement between root objects
            theDrop = NSDragOperationMove;
        }
    }
    return theDrop;
}

// final drop acceptance and item or children reordering into the data source.
// the index means the same as in the above function
-(BOOL) outlineView:(NSOutlineView *)outlineView acceptDrop:(id<NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index {
    BOOL answer = NO;
    VConfigurationModel* model = self.ownerDoc.configModel;
    [model reorderOutlineVariableItem:self.currentItem ToPosition:index IntoRootItem:item];
    [outlineView reloadData];
    [self synchronizeUseBoxes];
    return answer;
}

// end the dragging session by resetting the currentItem
-(void) outlineView:(NSOutlineView *)outlineView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation {
    self.currentItem = nil;
}

//-----------------------------------------------------------------------------
#pragma mark ______ Change interpolation parameters _______
//-----------------------------------------------------------------------------

- (IBAction) editParameterValues:(id)sender {
    [self synchronizeUseBoxes];
    [self applyVariationChange];
    [self computeNumSimCalls];
}

//-----------------------------------------------------------------------------

- (void) applyVariationChange {
    
    if  (self.currentItem.configParameter.validateDX) {
        
        if (self.currentItem.configParameter.variations.numberOfValues.integerValue < 2) {
            self.currentItem.configParameter.variations.minX = [NSNumber numberWithFloat:NAN];
            self.currentItem.configParameter.variations.maxX = [NSNumber numberWithFloat:NAN];
            self.currentItem.configParameter.variations.minY = [self.currentItem.configParameter.paramNumValue copy];
            self.currentItem.configParameter.variations.maxY = [self.currentItem.configParameter.paramNumValue copy];
            [self.currentItem.configParameter.variations.variationValues removeAllObjects];
            [self.currentItem.configParameter.variations.variationValues addObject:self.currentItem.configParameter.paramNumValue];
        }
        
        // compute all the main, intermediate and max values
        // and store them into variations.variationValues
        // ALSO the new parameter variations directly modify the paramSuitableForVariations table of the config model
        [self.currentItem.configParameter.variations collectValues];
        
        // update the table AND the interpolation view
        self.interpolView.var = self.currentItem.configParameter.variations;
        [self.interpolView setNeedsDisplay:YES];
        [self.outlineView reloadData];
        
        
        if (! self.ownerDoc.documentEdited)
            [self.ownerDoc updateChangeCount:NSChangeDone];

    }
}

//-----------------------------------------------------------------------------
#pragma mark ______ Batch of Sim runs _______
//-----------------------------------------------------------------------------


- (NSNumber*) computeNumSimCalls {
    
    VConfigurationModel* model = self.ownerDoc.configModel;
    NSMutableArray* params = model.variableOutlineItems;
    NSNumber* answer = @1;
    VAppDelegate* del = (VAppDelegate*)[NSApp delegate];


    for (VOutlineItem* root in params) {
        if (root.configParameter.variations.active.boolValue == YES) {
            answer = [NSNumber numberWithInteger: answer.integerValue * root.configParameter.variations.numberOfValues.integerValue];
        }
        for (VOutlineItem* child in root.children) {
            if (child.configParameter.variations.active.boolValue == YES) {
                answer = [NSNumber numberWithInteger: answer.integerValue * child.configParameter.variations.numberOfValues.integerValue];
            }
        }
    }
    
    if (answer.integerValue > 1) {
        self.canRunSimBatch = @YES;
        del.allowBatchRun = @YES;
    }
    else {
        self.canRunSimBatch = @NO;
        del.allowBatchRun = @NO;
    }
    
    return answer;
}

//-----------------------------------------------------------------------------

-(NSError*) saveConfigWithVarName:(NSString*)aName AtURL:(NSURL*)atURL WithComment:(NSString*)comment{
    
    VConfigurationModel* model = self.ownerDoc.configModel;

    // Save variations text
    NSError* outErr = nil;
    NSString* varText = model.variableConfigString;
    NSString* commentedText = [comment stringByAppendingString:varText];
    atURL = [atURL URLByAppendingPathComponent:aName];
    [commentedText writeToURL: atURL atomically:YES encoding:NSUTF8StringEncoding error:&outErr];
    return outErr;
}


//-----------------------------------------------------------------------------

- (IBAction) runSimBatch:(id)sender {
 
    VAppDelegate* del = (VAppDelegate*)[NSApp delegate];
    VDocument* doc = self.ownerDoc;
    NSString* docTitle = doc.displayName;
    docTitle = [docTitle stringByDeletingPathExtension];
    VConfigurationModel* model = doc.configModel;
    
    NSURL* savedSimURL = [del.simURL copy];
    NSURL* savedCymFileURL = [del.cymFileURL copy];

    
    del.batchRun = @YES;
    [del.batchSimURLs removeAllObjects];
    del.batchSimProgress.minValue = 0.0;
    del.batchSimProgress.maxValue = self.numSim.doubleValue;
    del.batchSimProgress.doubleValue = 0.0;


    // When a variation is evidenced
    // store the configObject / configInstance and subsequently parameters with each of the variations
    // into a sub-array called levelArray.
    // Then, add this levelArray into the final 'parameterVariations' array
    //
    
    NSMutableArray* parameterVariations = [NSMutableArray arrayWithCapacity:0];
    
    for (VOutlineItem* root in model.variableOutlineItems) {
        if (root.configParameter.ownerIsInstance) {
            if ((root.configParameter.validateDX) && (root.configParameter.variations.active.boolValue == YES)) {
                
                // for each root found :
                // 1- extract the correct instance, which will ease code re-building
                // 2- store it into a levelArray in location 0
                // 3- then store one parameter per instance number variation in the same levelArray
                // 4- store levelArray as an object into the parameterVariations array.
                NSMutableArray* levelArray = [NSMutableArray arrayWithCapacity:0];
                VConfigInstance* inst = [model instanceWithName:root.configParameter.paramName];
                if (inst) {
                    [levelArray addObject:inst];
                    for (NSNumber* var in root.configParameter.variations.variationValues) {
                        VConfigParameter* aParam = [[VConfigParameter alloc]init];
                        [aParam copyContentsWithoutVariationsFrom:root.configParameter]; // copies the instanceNumber property too
                        aParam.paramNumValue = [var copy];
                        aParam.paramStringValue = var.stringValue;
                        [levelArray addObject:aParam];
                    }
                    [parameterVariations addObject:levelArray];
                }
            }
        }
        
        for (VOutlineItem* child in root.children) {
            if ((child.configParameter.validateDX) && (child.configParameter.variations.active.boolValue == YES)) {
                
                // for each child found :
                // 1- extract the correct object or instance, which will ease code re-building
                // 2- store it into a levelArray in location 0
                // 3- store one parameter per variation after this object/instance in the same levelArray
                // 4- store levelArray as an object into the parameterVariations array.
                NSMutableArray* levelArray = [NSMutableArray arrayWithCapacity:0];
                id genericObject = nil;
                if (child.configParameter.ownerIsInstance) {
                    genericObject = [model instanceWithName:root.configParameter.paramName];
                    VConfigInstance* inst = (VConfigInstance*)genericObject;
                    if (inst)
                        [levelArray addObject:inst];
                } else {
                    genericObject = [model objectWithName:child.configParameter.ownerName];
                    VConfigObject* obj = (VConfigObject*)genericObject;
                    if (obj)
                        [levelArray addObject:obj];
                }
                if (levelArray.count >0) {
                    for (NSNumber* var in child.configParameter.variations.variationValues) {
                        VConfigParameter* aParam = [[VConfigParameter alloc]init];
                        [aParam copyContentsWithoutVariationsFrom:child.configParameter];
                        aParam.paramNumValue = [var copy];
                        aParam.paramStringValue = var.stringValue;
                        [levelArray addObject:aParam];
                    }
                    [parameterVariations addObject:levelArray];
                }
            }
        }
    }
    
    // Here, we build an array that will contains all the combinations of the numbers of indexes
    // We also chose to move to C arrays to avoid back and forth conversions between NSNumbers and NSIntegers
    //
    // In the example of 3 nested loops (n = 3 levels) with 3,4 and 2 values, respectively,
    // the index space is explored using a single i which should  start by level 3 (starts at 1 and decreases down to 0)
    // while i >= 0 continue to decrement i
    // we should build 3x4x2 = 24 indexes stored in an array.
    // This array contains virtual strides of 3 values each (the indexes for each of the 3 levels)
    // 0,0,0  0,0,1     0,1,0  0,1,1     0,2,0  0,2,1     0,3,0  0,3,1
    // 1,0,0  1,0,1     1,1,0  1,1,1     1,2,0  1,2,1     1,3,0  1,3,1
    // 2,0,0  2,0,1     2,1,0  2,1,1     2,2,0  2,2,1     2,3,0  2,3,1
    //
    // To adapt to variable number of levels and to variable number of variations for each level
    // use a single for loop that goes through all the solutions.
    // This is really a tricky code but it works fine and is soooo compact !
    
    NSInteger numLevels = parameterVariations.count;
    NSInteger maxIndexes[numLevels];
    NSInteger totalCombi = 1;
    for (NSInteger k = 0; k < numLevels; k++) {
        NSArray* levelArray = (NSArray*)[parameterVariations objectAtIndex:k];
        maxIndexes[k] = levelArray.count - 1 ;
        totalCombi *= maxIndexes[k];
    }
    

    // declare an array of integers to store the output indexes
    NSInteger outputIndexes[totalCombi*numLevels];
    for (NSInteger k=0; k<(totalCombi*numLevels); k++)
        outputIndexes[k] = 0;
    
    // declare an array of integers to store the indexes of each level during the loop
    NSInteger i[numLevels];
    for (NSInteger level=0; level<numLevels; level++)
        i[level] = 0;
    
    NSInteger changeStep = 1;       // the number of index repeats before incrementation is the product of the maxIndexes of all the levels on the right
    NSInteger changeIndex = 0;      // when the changeIndex reaches change, then increment the index. Use this sub index and not the % operator
                                    // because 0 % x is also 0 and we don't want to increment i[level] at the first occurrence of a 0
                                    // see the file "combinations.xlsx" in the project's folder for a simple simulation with the above example
    
    for (NSInteger level=numLevels-1; level>=0; level--) {                      // loop down through the levels
        // calculate how many times an index should be repeated before changing
        (level == numLevels-1) ? (changeStep = 1) : (changeStep *= maxIndexes[level+1]);
        NSInteger levelLimit = maxIndexes[level]-1;

        for (NSInteger k=0; k<totalCombi; k++) {                                // loop over the multi-index unique solutions
            NSInteger offset = k*numLevels + level;                             // offset in the outputIndex array
            if (changeIndex++ >= changeStep-1) {                                // sub changeStep counter
                outputIndexes[offset] = i[level]++;                             // set and increase the value at offset at every step
                changeIndex = 0;
            } else {
                outputIndexes[offset] = i[level];
            }
            if (i[level] > levelLimit)
                i[level] = 0;
        }
    }
 
    // reset i[level] to 0
    for (NSInteger level=0; level<numLevels; level++)
        i[level] = 0;

    // Create all the appropriate folders within the expected hierarchy
    NSString* rootPath = del.workingURL.path;
    
    NSString* cymName = [del.cymFileURL lastPathComponent];
    cymName = [cymName stringByReplacingOccurrencesOfString:@".cym" withString:@"_"];
    NSDate* creation = [NSDate now];
    NSString* dateString = [del completeDateStringFromDate:creation];
    dateString = [dateString stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    dateString = [dateString stringByReplacingOccurrencesOfString:@":" withString:@"_"];
    rootPath = [[NSArray arrayWithObjects:rootPath,@"/", cymName, @"variations_",dateString,@"/", nil] componentsJoinedByString:@""];
    
    NSString* genObjName = @"";
    NSString* varDirPath = @"";
    NSString* varString = @"";
    NSString* directories = @"";
    NSString* comment = @"";
    NSString* label = @"";
    
    NSMutableArray* genObjects = [NSMutableArray arrayWithCapacity:0];
    
    for (NSInteger k= 0; k< totalCombi*numLevels ; k++){
        
        NSInteger level = k % numLevels;
        NSInteger playInstance = (k/numLevels) % TASK_LIMIT;    // defined in VAppDelegate.h
        
        if (level < numLevels) {
            NSArray* levelArray = [parameterVariations objectAtIndex:level];
            id genericObject = levelArray.firstObject;
            [genObjects addObject:genericObject];
            
            VConfigObject* obj = nil;
            VConfigInstance* inst = nil;
            genObjName = @"";
            if ([genericObject isMemberOfClass:[VConfigObject class]]) {
                obj = (VConfigObject*)genericObject;
                genObjName = obj.objName;
            } else {
                inst = (VConfigInstance*)genericObject;
                genObjName = inst.instanceName;
            }
            
            NSInteger index = outputIndexes[k];
            VConfigParameter* par = [levelArray objectAtIndex:index+1];
            NSString* pName = par.paramName;
            if ((par.ownerIsInstance) && ([par.ownerName isEqualToString:@"instance"]))
                pName = @"instance";
        
            NSString* newVar = [[NSArray arrayWithObjects:genObjName,pName,par.paramStringValue,nil] componentsJoinedByString:@"_"];
            NSString* newComment = [@[@"% ", newVar, @"\n"]componentsJoinedByString:@""];
            comment = [comment stringByAppendingString:newComment];
            label = [label stringByAppendingString:[[NSArray arrayWithObjects:pName,par.paramStringValue,nil] componentsJoinedByString:@"_"]];
            label = [label stringByAppendingString:@" "];
            varString = [varString stringByAppendingString:newVar];
            varString = [varString stringByAppendingString:@"/"];
        }
        
        if (level == numLevels -1){
            
            // make the directory with intermediates
            
            varDirPath = [rootPath stringByAppendingString:varString];
            directories = [directories stringByAppendingString:varDirPath];
            directories = [directories stringByAppendingString:@"\n"];
            NSFileManager* fMgr = [NSFileManager defaultManager];
            NSError* err = nil;
            BOOL sdOK = [fMgr createDirectoryAtPath:varDirPath withIntermediateDirectories:YES attributes:nil error:&err];
            
            // build the object's or instance's code, then assemble a config file and save it
            // for this the simples way is to split varString into an array of strings separated by slashes
            // then to edit the object's code and to save it into the model's object and instance codes
            // this way there will be mismatches between object's/instance's contents and codes
            // but once all the files will be created and saved, re-extract the codes from all the objects.
            
            if (sdOK) {
                NSString* varStringShort = [varString substringToIndex:varString.length -1];
                NSArray* variationStrings = [varStringShort componentsSeparatedByString:@"/"];
                
                for (NSInteger vs=0; vs < variationStrings.count; vs++) {
                    
                    NSString* s = [variationStrings objectAtIndex:vs];
                    NSArray* paramComponents = [s componentsSeparatedByString:@"_"];
                    NSString* parComponentName = [paramComponents objectAtIndex:1];         // name is at index #1
                    NSString* parComponentValueString = [paramComponents objectAtIndex:2];  // value is at index #2

                    id genObj = [genObjects objectAtIndex:vs];
                    if ([genObj isMemberOfClass:[VConfigObject class]]) {
                        genObjName = ((VConfigObject*)genObj).objName;
                        [((VConfigObject*)genObj) changeParameterNamed:parComponentName WithValue:[NSNumber numberWithFloat:parComponentValueString.floatValue]];
                        ((VConfigObject*)genObj).objCode = [((VConfigObject*)genObj) codeFromObject];
                    } else {
                        genObjName = ((VConfigInstance*)genObj).instanceName;
                        if ([parComponentName isEqualToString:@"instance"]) {
                            ((VConfigInstance*)genObj).instanceNumber = [NSNumber numberWithFloat:parComponentValueString.floatValue];
                        } else {
                            [((VConfigInstance*)genObj) changeParameterNamed:parComponentName WithValue:[NSNumber numberWithFloat:parComponentValueString.floatValue]];
                        }
                        ((VConfigInstance*)genObj).instanceCode = [((VConfigInstance*)genObj) codeFromInstance];
                    }
                }
                [genObjects removeAllObjects];
            }
            else {
                NSDictionary *errorDictionary = @{ NSLocalizedDescriptionKey : @"error in creating variation folder"};
                err = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:errorDictionary];
                [self raiseFileMgrAlert:err];
                return;
            }
            
            [model buildVariableConfigStringWithLabel:label ForPlayInstance:playInstance];
            
            
            varString = [varString stringByReplacingOccurrencesOfString:@"/" withString:@"__"];
            varString = [varString substringToIndex:varString.length-2]; // remove to  2 last underscores
            NSString* varConfigFileName = [@[docTitle,@"__",varString, @".cym"] componentsJoinedByString:@""];
            del.simURL = [NSURL fileURLWithPath:varDirPath];
            comment = [comment stringByAppendingString:@"\n\n"];
            err = [self saveConfigWithVarName:varConfigFileName AtURL:del.simURL WithComment:comment]; // pass the folder's URL
            if (err != nil) {
                [self raiseFileMgrAlert:err];
                return;
            }
            NSString* fullVarPath = [del.simURL.path copy];
            fullVarPath = [fullVarPath stringByAppendingString:@"/"];
            fullVarPath = [fullVarPath stringByAppendingString:varConfigFileName];
            [del.batchSimURLs addObject:[NSURL fileURLWithPath:fullVarPath]];

            // reset the variation string and directory path
            varString = @"";
            varDirPath = @"";
            comment = @"";
            label = @"";

        }
    }
    
    // do some cleaning upon exit
    
    [model rebuildObjectAndInstanceCodes];
    
    // Do not reset batchRun here, it will be set to NO upon AppDelegate's batchFeedRun completion
    //del.batchRun = @NO;
    
    del.simURL = [savedSimURL copy];
    del.simPath = del.simURL.path;
    del.cymFileURL =  [savedCymFileURL copy]; //doc.fileURL;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"feedBatchRun" object:self];
}

//-----------------------------------------------------------------------------

-(void) raiseFileMgrAlert:(NSError*) error {
    
    NSAlert* fMgrAlert = [[NSAlert alloc]init];
    NSImage* theIcon = [NSImage imageNamed:@"CytosimForOSX"];
    fMgrAlert.icon = theIcon;
    fMgrAlert.alertStyle = NSAlertStyleInformational;
    NSString* message = @"An error occurred while saving a file\n";
    message = [message stringByAppendingString:error.description];
    [fMgrAlert setMessageText: message];
    [fMgrAlert addButtonWithTitle: @"OK"];  // 1st (default) button
    
    [fMgrAlert runModal];    // do nothing special here so don't use the NSModalResponse returned by runModal
}

//-----------------------------------------------------------------------------

@end
