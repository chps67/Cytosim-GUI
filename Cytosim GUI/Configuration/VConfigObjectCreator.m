//
//  VConfigObjectCreator.m
//  Cytosim GUI
//
//  Created by Chris on 30/08/2022.
//

#import "VConfigObjectCreator.h"
//#import "VCymParameter.h"
#import "VAppDelegate.h"
#import "VDocument.h"

@implementation VConfigObjectCreator

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.paramDataSource = [NSMutableArray arrayWithCapacity:0];
        self.readyForCodeInsertion = @NO;
    }
    return self;
}

//-----------------------------------------------------------------------------
#pragma mark ___ .plist FILES READING ___
//-----------------------------------------------------------------------------

-(void) preloadCymObjectFiles {

    [self initializeDataSource:@"simul"];
    [self initializeDataSource:@"space"];
    [self initializeDataSource:@"fiber"];
    [self initializeDataSource:@"bundle"];
    [self initializeDataSource:@"hand"];
    [self initializeDataSource:@"digit"];
    [self initializeDataSource:@"motor"];
    [self initializeDataSource:@"nucleator"];
    [self initializeDataSource:@"tracker"];
    [self initializeDataSource:@"rescuer"];
    [self initializeDataSource:@"cutter"];
    [self initializeDataSource:@"chewer"];
    [self initializeDataSource:@"single"];
    [self initializeDataSource:@"couple"];
    [self initializeDataSource:@"sphere"];
    [self initializeDataSource:@"aster"];

    [self initializeDataSource:@"display_point"];
    [self initializeDataSource:@"display_fiber"];
    [self initializeDataSource:@"display_view"];
    [self initializeDataSource:@"display_world"];
    [self initializeDataSource:@"display_play"];
    
    [self initializeDataSource:@"positioning"];
}

//---------------------------------------------------------------------------------------------
//       Load the content of the .plist files that contain all the Cytosim
//       commands, objects, and parameters names, along with values and help strings
//       extracted or slightly modified/shortened from the comments and docs in the cytosim project
//
//          These files can be easily modified in XCode.
//          They feed the NSOutlineView that appears in the window opened
//          by user action on the "Insert Code" tool in the toolbar.
//          Each NSDictionary (the name of which ends with "DIC" that will
//          be removed upon display) is a title for multiple children variables.
//          For each object file describing the actual parameters, a fully parallel file
//          whose name ends with "_help.plist" stores the help strings that appear
//          close to the list in a wrapping NSTextField
//
//---------------------------------------------------------------------------------------------

- (VCymParameter*) extractParamRecursivelyFromItem:(VCymParameter*)rootParam WithHelpDictionary:(MutableOrderedDictionary*)helpDic {

    VCymParameter* returnParam = nil;

    BOOL hasChildren = [rootParam.cymValueObject isKindOfClass:[NSDictionary class]];

    if (hasChildren) {

        rootParam.children = [NSMutableArray arrayWithCapacity:0];
        OrderedDictionary* dic = (OrderedDictionary*)rootParam.cymValueObject;

//      OrderedDictionary* hDic = [(OrderedDictionary*)helpDic objectForKey:rootParam.cymKey];
//      The instruction above is natural but fails sometimes for obscure reasons
//      that I did not thoroughly explore, and it may return nil
//      It is nicely replaced by the casting of the cymKeyHelpString to an OrderedDictionary :
        OrderedDictionary* hDic = (OrderedDictionary*)rootParam.cymKeyHelpString;

        for (NSInteger index=0; index<dic.count; index++){
            NSString* key = [dic keyAtIndex:index];

            id obj = [dic objectForKey:key];
            NSString* hStr = [hDic objectForKey:key];
            VCymParameter* child = [VCymParameter initWithKey:key HelpString:hStr Value:obj];
            child = [self extractParamRecursivelyFromItem:child WithHelpDictionary:helpDic];
            if (child) {
                [rootParam.children addObject:child];
                child.parent = rootParam;
                returnParam = rootParam;
            }
        }
    } else {
        returnParam = rootParam;
    }
    return returnParam;
}

//-----------------------------------------------------------------------------

-(void) initializeDataSource:(NSString*)cymObjectName {
    
    NSMutableArray* __block tempArray = [NSMutableArray arrayWithCapacity:0];
    NSMutableDictionary* __block tempDic = [NSMutableDictionary dictionaryWithCapacity:0];

    // Read the contents of the cytosim object's .plist file
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:cymObjectName ofType:@"plist"];
    MutableOrderedDictionary* plistObject = [[MutableOrderedDictionary alloc]init];
    plistObject = [MutableOrderedDictionary dictionaryWithContentsOfFile:plistPath];
    
    // Read the contents of the cytosim help strings for object's .plist file
    NSString* cymObjectHelpName = [cymObjectName stringByAppendingString:@"_help"];
    NSString *helpPlistPath = [[NSBundle mainBundle] pathForResource:cymObjectHelpName ofType:@"plist"];
    MutableOrderedDictionary* plistHelpObject = [[MutableOrderedDictionary alloc]init];
    plistHelpObject = [MutableOrderedDictionary dictionaryWithContentsOfFile:helpPlistPath];
    
    // Build the data source

    for (NSInteger index=0; index<plistObject.count; index++){
        NSString* rootKey = [plistObject keyAtIndex:index];
        id obj = [plistObject valueForKey:rootKey];
        VCymParameter* param = [VCymParameter initWithKey:rootKey HelpString:[plistHelpObject valueForKey:rootKey] Value:obj];
        param = [self extractParamRecursivelyFromItem:param WithHelpDictionary:plistHelpObject]; // AppDelegate version
        //[param extractParamRecursivelyWithHelpDictionary:plistHelpObject];
        if (param)
            [tempArray addObject:param];
    }
    tempDic = [NSMutableDictionary dictionaryWithObject:tempArray forKey:cymObjectName];
    [self.configObjectsDic addEntriesFromDictionary: tempDic];
}


#pragma mark --- methods of NSOutlineViewDataSource



- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    NSInteger answer = 0;
    if (item == nil) {
        answer = self.paramDataSource.count;
    } else
        answer = [item numberOfChildren];
    return answer;
}

//-----------------------------------------------------------------------------

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    BOOL answer;
    if (item == nil)
        answer = YES;
    else
        answer = ([item numberOfChildren] != -1);
    return answer;
}

//-----------------------------------------------------------------------------
/*
    N.B. Hereafter, index may represent both the index that scans the dataSource (root items)
    or the index in the children array (if non-nil)
*/

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    
    id answerObj = nil;

    if (item == nil) {
        // called for ALL the root objects (i.e. those without children = not expanded ones in our case)
        answerObj = [self.paramDataSource objectAtIndex:index];
    } else {
        // when a root object has children and is expandable, read the index-th object among the children
        answerObj = [(VCymParameter*)item childAtIndex:index];
    }
    return answerObj;
}

//-----------------------------------------------------------------------------

-(NSView*) outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    
/*
    The checkBox in 'Use' is hidden if the item is expandable
    Otherwise, two text views are used, one with non-editable
    behaviour ('Parameter') as set in IB, and one that is editable ('Value')
*/
    
    NSTableCellView* theCell = nil;
    NSButton* checkButton = nil;
    VCymParameter* param = (VCymParameter*)item;

    if ([tableColumn.title isEqualToString:@"Use"]) {
        theCell = ([outlineView makeViewWithIdentifier:@"MyCheckCellView" owner:self]);
        theCell.hidden = [outlineView isExpandable:item];
        if (! theCell.hidden) {
            NSArray* subs = [theCell subviews];
            checkButton = (NSButton*)(subs.firstObject);
            checkButton.state = (param.used.boolValue == YES)?(NSControlStateValueOn):(NSControlStateValueOff);
        }
    }
    
    // here is where the image that best describes the parameter is chosen
    // in most cases the image name is the same as the parameter name
    // but sometimes a shorter name should be used for loading the image e.g. in cases
    // of parameter declination into X Y or Z for position or for orientation
    // also some parameters with the same name occur in various objects and hence the values they
    // may take also differ. To distinguish between these possibilities, the name of the parameter
    // is followed by the object's name between curly braces as follows: 'parameter {object}'
    // of course this {...} is trimmed at run time (see trimmedName: below)
    // To display the possible choices in the image buttonsbelow the outline view,
    // the corresponding icon names are stored in the help_icon_names.plist
    
    
    if ([tableColumn.title isEqualToString:@"Symbol"]){
        theCell = ([outlineView makeViewWithIdentifier:@"MyImageCellView" owner:self]);
        
        // general case
        NSString* itemName = ((VCymParameter*)item).cymKey;
        
        // special cases
        if (([itemName containsString:@"X"])|| ([itemName containsString:@"Y"])|| ([itemName containsString:@"Z"])) {
            NSCharacterSet* dimSet = [NSCharacterSet characterSetWithCharactersInString:@"XYZ"];
            itemName = [itemName stringByTrimmingCharactersInSet:dimSet];
            itemName = [itemName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }
        // image loading
        NSImage* img = [NSImage imageNamed:itemName];
        if (img) {
            theCell.imageView.image = img;
        } else
            theCell.imageView.image = nil;
    }
    
    if ([tableColumn.title isEqualToString:@"Parameter"]){
        
        theCell = ([outlineView makeViewWithIdentifier:@"MyParameterCellView" owner:self]);
        NSString* cymStr = ((VCymParameter*)item).cymKey;
        
        if ([cymStr containsString:@"DIC"]) {
            NSString* displayString = [NSString stringWithString:((VCymParameter*)item).cymKey];
            NSInteger l = displayString.length;
            displayString = [displayString substringToIndex:l-3];
            theCell.textField.stringValue = displayString;
        } else if ([cymStr containsString:@"{"]) {
            NSString* paramSub = [self trimmedName:cymStr];
            theCell.textField.stringValue = paramSub;
        } else {
            theCell.textField.stringValue = cymStr;
        }
    }
    
    if ([tableColumn.title isEqualToString:@"Value"]) {
        theCell = ([outlineView makeViewWithIdentifier:@"MyValueCellView" owner:self]);
        if ([((VCymParameter*)item) isParentObject]) {
            theCell.textField.stringValue = @"";
        } else {
            theCell.textField.stringValue = ((VCymParameter*)item).cymValueString;
        }
    }
    
    return theCell;
}



//-----------------------------------------------------------------------------
#pragma mark --- methods of NSOutlineViewDelegate
//-----------------------------------------------------------------------------

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    return YES;
}

//-----------------------------------------------------------------------------
- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    
    VAppDelegate* del = (VAppDelegate*)NSApp.delegate;

    del.paramHelpField.stringValue = @"";
    
    // do not use the notification sent because it only contains in .object the outlined view that was selected
    NSInteger selIndex = [del.paramOutlineView selectedRow];
    VCymParameter* selParam = [del.paramOutlineView itemAtRow:selIndex];
    
    if (([selParam.cymKey containsString:@"color"]) && (![selParam.cymKey containsString:@"coloring"])) {
        del.colorTitle.hidden = NO;
        del.colorWell.hidden = NO;
    } else {
        del.colorTitle.hidden = YES;
        del.colorWell.hidden = YES;
    }
    
    if ((! [selParam isParentObject]) && (selParam.cymKeyHelpString.length > 0)) {
        del.paramHelpField.stringValue = selParam.cymKeyHelpString;
        
        //hide all help images and legends
        for (int k = 1; k <= (2 * NUM_HELP_IMAGES); k += 2){
            NSButton* iView = [del.modelDesignWindow.contentView viewWithTag: k];
            NSTextField* fView = [del.modelDesignWindow.contentView viewWithTag: k+1];
            iView.hidden = YES;
            fView.hidden = YES;
        }
        
        NSString *helpIconsPath = [[NSBundle mainBundle] pathForResource:@"help_icon_names" ofType:@"plist"];
        MutableOrderedDictionary* helpIconsDictionary = [[MutableOrderedDictionary alloc]init];
        helpIconsDictionary = [MutableOrderedDictionary dictionaryWithContentsOfFile:helpIconsPath];
        
        // build the full name
        NSString* keyWithObject = selParam.cymKey;
        if (! [selParam.cymKey containsString:@"{"]) {
            keyWithObject =  [@[selParam.cymKey, @" {", del.buildObjectPopUp.title , @"}"] componentsJoinedByString:@""];
        }
        
        OrderedDictionary* iconsDic = [helpIconsDictionary valueForKey:keyWithObject]; //selParam.cymKey];
        
        if (iconsDic) {
            
            NSImage* img = nil;
            NSInteger numIcons = iconsDic.count;
            NSInteger topIcons = numIcons;
            NSInteger bottomIcons = 0;
            
            if (numIcons > 11) {
                if (numIcons % 2 == 0) {
                    topIcons = numIcons / 2;
                }
                else {
                    topIcons = (numIcons / 2) + 1;
                }
                bottomIcons = numIcons - topIcons;
            }
            
            NSInteger keyIndex = 0;
            
            for (int k = 1; k <= (topIcons * 2); k += 2){
                
                NSButton* iView = [del.modelDesignWindow.contentView viewWithTag: k];
                NSTextField* fView = [del.modelDesignWindow.contentView viewWithTag: k+1];
            
                NSString* aKey = [iconsDic keyAtIndex:keyIndex++];
                img = [NSImage imageNamed:aKey];
                iView.image = img;
                iView.hidden = NO;
                // remove any object name enclosed by curly brackets
                NSString* nameStr = [NSString stringWithString:aKey];
                if ([aKey containsString:@"{"])
                    nameStr = [self trimmedName:nameStr];
                fView.stringValue = [NSString stringWithString:nameStr];
                fView.hidden = NO;
            }
            
            for (int k = 1 + NUM_HELP_IMAGES ; k <= ((bottomIcons * 2) + NUM_HELP_IMAGES) ; k += 2){
                
                NSButton* iView = [del.modelDesignWindow.contentView viewWithTag: k];
                NSTextField* fView = [del.modelDesignWindow.contentView viewWithTag: k+1];
            
                NSString* aKey = [iconsDic keyAtIndex:keyIndex++];
                img = [NSImage imageNamed:aKey];
                iView.image = img;
                iView.hidden = NO;
                // remove any object name enclosed by curly brackets
                NSString* nameStr = [NSString stringWithString:aKey];
                if ([aKey containsString:@"{"])
                    nameStr = [self trimmedName:nameStr];
                fView.stringValue = [NSString stringWithString:nameStr];
                fView.hidden = NO;
            }

            [self distributeIconsOnLine:1 reqIcons:topIcons];
            [self distributeIconsOnLine:2 reqIcons:bottomIcons];
            
            // for later reuse upon window resizing
            del.helpIconsOnFirstLine = topIcons;
            del.helpIconsOnSecondLine = bottomIcons;

        }
        
    }
}

//---------------------------------------------------------------------------------
#pragma mark Object's methods
//---------------------------------------------------------------------------------

- (NSString*)trimmedName: (NSString*) aName {
    NSArray* components = [aName componentsSeparatedByString:@" "];
    NSString* cleanName = [NSString stringWithString:[components firstObject]];
    return cleanName;
}

//---------------------------------------------------------------------------------

-(NSButton*) checkBoxAtRow:(NSInteger) aRow {
    
    NSButton* check = nil;
    VAppDelegate* del = (VAppDelegate*)NSApp.delegate;
    NSInteger useColIndex = [del.paramOutlineView columnWithIdentifier:@"Use"];
    NSTableCellView* aCellView = [del.paramOutlineView viewAtColumn:useColIndex row:aRow makeIfNecessary:YES];
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

//---------------------------------------------------------------------------------

-(BOOL) boxesAreChecked {
    
    VAppDelegate* del = (VAppDelegate*)NSApp.delegate;
    NSInteger n = del.paramOutlineView.numberOfRows;
    BOOL foundOne = NO;
    for (NSInteger k=0; k<n ; k++) {
        NSButton* rowCheckBox = [self checkBoxAtRow:k];
        if (rowCheckBox) {
            if (rowCheckBox.state == NSControlStateValueOn) {
                foundOne = YES;
                break;
            }
        }
    }
    return foundOne;
}

//---------------------------------------------------------------------------------

- (void) distributeIconsOnLine:(NSInteger)lineNumber reqIcons:(NSInteger)iconsPerLine {
    
    if (iconsPerLine == 0)
        return;
    
    VAppDelegate* del = (VAppDelegate*)NSApp.delegate;
    NSInteger deltaX = 0, dx2 = 0;
    NSInteger k = 0;

    for (NSInteger tag = 1 + (lineNumber - 1) * NUM_HELP_IMAGES ; tag < lineNumber * NUM_HELP_IMAGES ; tag += 2) {
        NSButton* iView = [del.modelDesignWindow.contentView viewWithTag: tag];
        NSTextField* fView = [del.modelDesignWindow.contentView viewWithTag: tag + 1];
        NSRect R = iView.superview.frame;
        // Half of the deltaX is set as a margin before the first image view and implicitely,
        //  the same half will remain after the last image View...
        deltaX = (NSInteger)R.size.width / (iconsPerLine);
        dx2 = deltaX / 2;
        
        if (iView.hidden == NO) {
            
            NSRect newFrameI = iView.frame;
            newFrameI.origin.x = dx2 + (k * deltaX) - (iView.frame.size.width / 2.0);
            iView.frame = newFrameI;
            
            [fView sizeToFit];
            [fView setAlignment:NSTextAlignmentCenter];
            NSRect newFrameF = fView.frame;
            newFrameF.origin.x = dx2 + (k * deltaX) - (fView.frame.size.width / 2.0);
            fView.frame = newFrameF;

            k++;
        }
    }
}

//---------------------------------------------------------------------------------

- (IBAction) choseHelpIconValue: (id) sender {
    
    VAppDelegate* del = (VAppDelegate*)NSApp.delegate;
    NSButton* iView = (NSButton*)sender;
    NSInteger senderTag = iView.tag + 1;

    NSString* chosenValue = [(NSTextField*)[del.modelDesignWindow.contentView viewWithTag: senderTag] stringValue];
    
    NSInteger selIndex = [del.paramOutlineView selectedRow];
    VCymParameter* selParam = [del.paramOutlineView itemAtRow:selIndex];
    selParam.cymValueObject = [NSString stringWithString:chosenValue];
    selParam.cymValueString = chosenValue;
    
    [del.paramOutlineView reloadItem:[del.paramOutlineView itemAtRow:selIndex]];
}

//-----------------------------------------------------------------------------

-(IBAction) changeUseInOutline:(id)sender {
    
    VAppDelegate* del = (VAppDelegate*)NSApp.delegate;
    
    NSButton* checkBox = (NSButton*)sender;
    NSInteger row = [del.paramOutlineView rowForView:checkBox];
    VCymParameter* targetParam = [del.paramOutlineView itemAtRow:row];
    BOOL status = (checkBox.state == NSControlStateValueOn);
    NSUInteger cbState = checkBox.state;
    targetParam.used = [NSNumber numberWithBool:status];
    
    if ([targetParam.cymKey containsString:@"X"]){
        VCymParameter* YParam = [del.paramOutlineView itemAtRow:row+1];
        NSButton* YBtn = [self checkBoxAtRow:row+1];
        YBtn.state = cbState;
        YParam.used = [NSNumber numberWithBool:status];
        
        VCymParameter* ZParam = [del.paramOutlineView itemAtRow:row+2];
        NSButton* ZBtn = [self checkBoxAtRow:row+2];
        ZBtn.state = cbState;
        ZParam.used = [NSNumber numberWithBool:status];
    }
    if ([targetParam.cymKey containsString:@"Y"]){
        VCymParameter* XParam = [del.paramOutlineView itemAtRow:row-1];
        XParam.used = [NSNumber numberWithBool:status];
        NSButton* XBtn = [self checkBoxAtRow:row-1];
        XBtn.state = cbState;
        
        VCymParameter* ZParam = [del.paramOutlineView itemAtRow:row+1];
        ZParam.used = [NSNumber numberWithBool:status];
        NSButton* ZBtn = [self checkBoxAtRow:row+1];
        ZBtn.state = cbState;
    }
    if ([targetParam.cymKey containsString:@"Z"]){
        VCymParameter* XParam = [del.paramOutlineView itemAtRow:row-2];
        XParam.used = [NSNumber numberWithBool:status];
        NSButton* XBtn = [self checkBoxAtRow:row-2];
        XBtn.state = cbState;
        
        VCymParameter* YParam = [del.paramOutlineView itemAtRow:row-1];
        YParam.used = [NSNumber numberWithBool:status];
        NSButton* YBtn = [self checkBoxAtRow:row-1];
        YBtn.state = cbState;
    }
    if ([targetParam.cymKey containsString:@"plus"]){
        VCymParameter* PlusParam = [del.paramOutlineView itemAtRow:row+1];
        PlusParam.used = [NSNumber numberWithBool:status];
        NSButton* PlusBtn = [self checkBoxAtRow:row+1];
        PlusBtn.state = cbState;
    }
    if ([targetParam.cymKey containsString:@"minus"]){
        VCymParameter* MinusParam = [del.paramOutlineView itemAtRow:row-1];
        MinusParam.used = [NSNumber numberWithBool:status];
        NSButton* MinusBtn = [self checkBoxAtRow:row-1];
        MinusBtn.state = cbState;
    }
    
    [self updateAllowCodeInsertion:self];
}

//-----------------------------------------------------------------------------
-(IBAction) updateAllowCodeInsertion: (id) sender {

    VAppDelegate* del = (VAppDelegate*)NSApp.delegate;
    BOOL nameOK =  ( [del.buildCommandPopUp.selectedItem.title isEqualToString:@"set"] && (del.nameField.stringValue.length > 0));
    BOOL numOK =  ( [del.buildCommandPopUp.selectedItem.title isEqualToString:@"new"] && (del.nameField.stringValue.length > 0) && (del.numberField.stringValue.length > 0));
    BOOL okForInsertion = ([self boxesAreChecked] && (nameOK || numOK));
    self.readyForCodeInsertion = [NSNumber numberWithBool:okForInsertion];
}

//-----------------------------------------------------------------------------

-(IBAction) changeParameterValueInOutline:(id)sender {
    
    VAppDelegate* del = (VAppDelegate*)NSApp.delegate;

    NSString* newValue = ((NSTextField*)sender).stringValue;
    // value edition functions only when a row is selected
    NSInteger selIndex = [del.paramOutlineView selectedRow];
    VCymParameter* selParam = [del.paramOutlineView itemAtRow:selIndex];

    if ([selParam.cymValueObject isKindOfClass:[NSNumber class]]) {
        selParam.cymValueObject = [NSNumber numberWithFloat:((NSTextField*)sender).floatValue];
    }
    if ([selParam.cymValueObject isKindOfClass:[NSString class]]) {
        selParam.cymValueObject = [NSString stringWithString:newValue];
    }
    selParam.cymValueString = newValue;
}

//-----------------------------------------------------------------------------

- (IBAction) changeParameterColor: (id) sender {
    
    VAppDelegate* del = (VAppDelegate*)NSApp.delegate;
    NSInteger selIndex = [del.paramOutlineView selectedRow];
    VCymParameter* selParam = [del.paramOutlineView itemAtRow:selIndex];
    NSColor* chosenColor = del.colorWell.color;
    CGFloat* c = malloc(sizeof(CGFloat) * 4);
    [chosenColor getComponents:c];
    NSString* colorStr = @"(";
    for (NSInteger k = 0; k < 4; k++) {
        NSNumber* cN = [NSNumber numberWithDouble: c[k]];
        NSNumberFormatter *nF = [[NSNumberFormatter alloc]init];
        [nF setFormat:@"##0.## "];
        nF.localizesFormat = NO;
        NSString* cNs = [nF stringFromNumber:cN];
        if ([cNs containsString:@","]) {
            cNs = [cNs stringByReplacingOccurrencesOfString:@"," withString:@"."];
        }
        colorStr = [colorStr stringByAppendingString:cNs];
    }
    colorStr = [colorStr stringByAppendingString:@")"];
    selParam.cymValueString = colorStr;
    [del.paramOutlineView reloadData];
    NSIndexSet* index = [NSIndexSet indexSetWithIndex:selIndex];
    [del.paramOutlineView selectRowIndexes:index byExtendingSelection:NO];
}

//-----------------------------------------------------------------------------

-(NSString*) templateText {
    
    NSString* comment1 = @"%{\n  Insert your entitlements and comments here...\n\n  Replace the terms in CAPITALS in the template if you know what you are doing.\n  For more control, replace each configuration element and/or add new ones using the configuration snippets window.\n}\n\n";
    NSString* simul = @"set simul SIMUL_NAME\n{\n    PARAMETERS AND VALUES\n}\n\n";
    NSString* space = @"set space SPACE_NAME\n{\n    PARAMETERS AND VALUES\n}\n\n";
    NSString* space2 = @"new SPACE_NAME\n{\n    PARAMETERS AND VALUES\n}\n\n";
    NSString* obj1 = @"set OBJECT_TYPE OBJECT_NAME\n{\n    PARAMETERS AND VALUES\n}\n\n";
    NSString* obj2 = @"new NUMBER_OF_OBJECTS OBJECT_NAME\n{\n    PARAMETERS AND VALUES\n}\n\n";
    NSString* run = @"run STEPS SIMUL_NAME\n{\n    PARAMETERS AND VALUES\n}\n\n";
    NSString* s = [@[comment1, simul, space, space2, obj1, obj2, run] componentsJoinedByString:@""];

//    NSString* s = @"";
    return s;
}

//-----------------------------------------------------------------------------

-(NSString*) extractParameterList {
    
    NSString* result = @"";
    NSMutableArray* displayElements = [NSMutableArray arrayWithCapacity:0];
    NSInteger nonDisplayParamCount = 0;
    
    for (VCymParameter* param in self.paramDataSource) {
        NSString* temp = @"";
        NSString* spc = @"    ";
        
        if (param.children) {
            // DEPTH LEVEL 1
            for (VCymParameter* child in param.children) {
                
                if (child.used.boolValue == YES) {
                    
                    // go upward in the parent object chain to detect a 'display' parameter
                    VCymParameter* parent = child.parent;

                    if ([parent.cymKey containsString:@"display"]) {
                        [displayElements addObject:child];
                    } else {
                        NSString* cleanKey = [child.cymKey copy];
                        cleanKey = [self trimmedName:cleanKey]; // suppress "{...}"
                        temp = [@[@"\t", cleanKey, @" = ", child.cymValueString,@"\n"] componentsJoinedByString:@""];
                        nonDisplayParamCount ++;
                        result = [result stringByAppendingString:temp];
                    }
                } else {
                    if (child.children) {
                        // DEPTH LEVEL 2
                        for (NSInteger k = 0; k< child.children.count; k++) {
                            
                            VCymParameter* subChild = [child.children objectAtIndex:k];
                            
                            if (subChild.used.boolValue == YES) {
                                VCymParameter* agecanonix = [subChild ancestor];
                                if ([agecanonix.cymKey containsString:@"display"]) {
                                    [displayElements addObject:subChild];
                                } else {
                                    NSString* cleanKey = [subChild.cymKey copy];
                                    NSCharacterSet* dimSet = [NSCharacterSet characterSetWithCharactersInString:@"XYZ"];
                                    BOOL hasX = [cleanKey containsString:@"X"];
                                    
                                    if (hasX) {
                                        cleanKey = [cleanKey stringByTrimmingCharactersInSet:dimSet];
                                        cleanKey = [cleanKey substringToIndex:cleanKey.length-1];
                                    }
                                    temp = [@[@"\t", cleanKey, @" = ", subChild.cymValueString,@"\n"] componentsJoinedByString:@""];
                                    if (hasX){
                                        // X
                                        temp = [temp substringToIndex:temp.length-1];
                                        // Y
                                        VCymParameter* nextChild = [child.children objectAtIndex: ++k];
                                        temp = [temp stringByAppendingString:@" "];
                                        temp = [temp stringByAppendingString:nextChild.cymValueString];
                                        // Z
                                        nextChild = [child.children objectAtIndex: ++k];
                                        temp = [temp stringByAppendingString:@" "];
                                        temp = [temp stringByAppendingString:nextChild.cymValueString];
                                        temp = [temp stringByAppendingString:@"\n"];
                                        result = [result stringByAppendingString:temp];
                                    } else {
                                        result = [result stringByAppendingString:temp];
                                        result = [result stringByAppendingString:@"\n"];
                                    }
                                    nonDisplayParamCount ++;
                                }
                            } else {
                                if (subChild.children) {
                                    // DEPTH LEVEL 3 (has only plus and minus end parameters)
                                    for (NSInteger k = 0; k< subChild.children.count; k++) {
                                        VCymParameter* grandChild = [subChild.children objectAtIndex:k];
                                        if (grandChild.used.boolValue == YES) {
                                            
                                            NSString* p = grandChild.cymKey;
                                            BOOL aggregate = [p containsString:@"minus"];
                                            p = [self trimmedName:p]; // suppress "{minus or plus end}"
                                            NSString* v = grandChild.cymValueString;
                                            if (! aggregate) {
                                                temp = [temp stringByAppendingString:[@[@"\t", p, @" = ", v, @"\n"] componentsJoinedByString:@""]];
                                            } else {
                                                temp = [temp stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n"]];
                                                temp = [temp stringByAppendingString:[@[@", ", v, @"\n"] componentsJoinedByString:@""]];
                                            }
                                            result = [temp copy];
                                        }
                                    }
                                }
                            }
                        } // for
                    } // if
                } // else
            } // for
        } else {
            if (param.used.boolValue == YES) {
                temp = [@[spc, param.cymKey, @" = ", param.cymValueString, @"\n"] componentsJoinedByString:@""];
                result = [result stringByAppendingString:temp];
            }
        }
    }
    
    if (nonDisplayParamCount > 0) {
        if (displayElements.count >0) {
            NSMutableArray* displayParams = [NSMutableArray arrayWithCapacity:0];
            NSString* temp = @"";
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
    } else {
        if (displayElements.count >0) {
            NSString* temp = @"display\n";
            for (VCymParameter* param in displayElements) {
                NSString* p = param.cymKey;
                BOOL aggregate = [p containsString:@"minus"];
                p = [self trimmedName:p]; // suppress "{minus or plus end}"
                NSString* v = param.cymValueString;
                if (! aggregate) {
                    temp = [temp stringByAppendingString:[@[@"\t", p, @" = ", v, @"\n"] componentsJoinedByString:@""]];
                } else {
                    temp = [temp stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\n"]];
                    temp = [temp stringByAppendingString:[@[@", ", v, @"\n"] componentsJoinedByString:@""]];
                }
            }
            result = [temp copy];
        }
    }
    return result;
}

//-----------------------------------------------------------------------------

-(NSString*) buildSnippet {
    
    VAppDelegate* del = (VAppDelegate*)NSApp.delegate;

    NSString* result = @"";
    NSString* command = del.buildCommandPopUp.title;
    NSString* object = del.buildObjectPopUp.title;
    NSString* objName = del.nameField.stringValue;
    
    if ([command isEqualToString:@"set"]) {
        
        NSString* content = [self extractParameterList];
        NSArray* pListLines = [content componentsSeparatedByString:@"\n"];
        NSMutableArray* pListLinesMut = [NSMutableArray arrayWithArray:pListLines];
        
        if ([pListLinesMut.firstObject isEqualToString:@"display"]) {
            [pListLinesMut removeObjectAtIndex:0];
            object = del.nameField.stringValue;
            objName = @"display";
            content = [pListLinesMut componentsJoinedByString:@"\n"];
        }
        
        NSString* opening = [@[command, object, objName] componentsJoinedByString:@" "];
        opening = [opening stringByAppendingString:@"\n{\n"];
        NSString* closing = @"}\n";
        
        result = [@[opening, content, closing] componentsJoinedByString:@""];
    }
    
    if ([command isEqualToString:@"new"]) {
        NSString* opening = [@[command, del.numberField.stringValue, objName] componentsJoinedByString:@" "];
        opening = [opening stringByAppendingString:@"\n{\n"];
        NSString* closing = @"}\n";
        NSString* content = [self extractParameterList];
        result = [@[opening, content, closing] componentsJoinedByString:@""];
    }
    return result;
}

//-----------------------------------------------------------------------------

-(IBAction) insertCode:(id)sender {
    // insert at caret location or replace selected text
    
    VAppDelegate* del = (VAppDelegate*)NSApp.delegate;
    VDocument* topDoc = (VDocument*)[del topDoc];

    NSString* s = [self buildSnippet];
    NSRange replaced = [[[topDoc.configTextView selectedRanges] firstObject]rangeValue];
    [topDoc.configTextView insertText:s replacementRange:replaced];
}

@end
