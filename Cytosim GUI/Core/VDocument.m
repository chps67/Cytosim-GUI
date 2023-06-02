//
//  Document.m
//  Cytosim GUI
//
//  Created by Chris on 14/08/2022.
//

#import "VDocument.h"
#import "VAppDelegate.h"


#define CYTOSIM_COMMAND_TYPE @"command"
#define CYTOSIM_COMMENT_TYPE @"comment"

//@interface VDocument ()
//
//@end

@implementation VDocument

//-----------------------------------------------------------------------------
#pragma mark ______ Overrides _______
//-----------------------------------------------------------------------------

- (instancetype)init {
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
        self.needsColorEdition = NO;
    }
    return self;
}

//-----------------------------------------------------------------------------

+ (BOOL)autosavesInPlace {
    return NO;
}

//-----------------------------------------------------------------------------

+ (BOOL)autosavesDrafts {
    return NO;
}

//-----------------------------------------------------------------------------


- (NSString *)windowNibName {
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"Document";
}


//-----------------------------------------------------------------------------

- (void) awakeFromNib {
    [super awakeFromNib];
    
    
    
    VAppDelegate* del = (VAppDelegate*)(NSApp.delegate);

    if (self.configModel.configString) {
        
        self.configTextView.delegate = self;
                
        NSRange prevRange = NSMakeRange(0, 0);
        self.configTextView.string = self.configModel.configString;
        //[self.configTextView insertText:self.configModel.configString replacementRange: prevRange];
        [self.configTextView scrollRangeToVisible:prevRange];

        // This delegate function is called only after we exit 'awakeFromNib' so
        // call it once to ensure proper text first coloring
//        NSRange wholeRange = {0, self.configTextView.string.length};
//        [self textStorage:self.configTextView.textStorage didProcessEditing:NSTextStorageEditedCharacters range:wholeRange changeInLength:self.configTextView.string.length];

    } else {
        NSString* template = [del.configObjectCreator templateText];
        self.configModel = [[VConfigurationModel alloc]init];
        self.configTextView.delegate = self;
        self.configModel.configString = [NSString stringWithString:template];
        NSRange prevRange = NSMakeRange(0, 0);
        [self.configTextView  insertText:self.configModel.configString replacementRange: prevRange];
//        NSRange wholeRange = {0, self.configTextView.string.length};
//        [self textStorage:self.configTextView.textStorage didProcessEditing:NSTextStorageEditedCharacters range:wholeRange changeInLength:self.configTextView.string.length];
    }
    
    
    [del checkSetup];
    
    // Settings of the NSTextView  defaults
    
    NSString* fontName = @"Monaco";     // alternative = @"Courrier New"
    NSFont* defaultFont = [NSFont fontWithName:fontName size:12];
    
    // N.B. the NSTextView delegate binding is set in IB
    self.configTextView.textStorage.delegate = self;
    [self.configTextView setFont:defaultFont];
    self.configTextView.usesFontPanel = YES; // makes all the NSTextView responsive to the Fomat Menu Items
    self.configTextView.usesFindPanel = YES;
    self.configTextView.usesRuler = NO;
    self.configTextView.allowsUndo = YES;
    self.configTextView.automaticQuoteSubstitutionEnabled = NO;
    self.configTextView.automaticDashSubstitutionEnabled = NO;
    
    self.needsColorEdition = YES;
    if ([del runInDarkMode]) {
        [del colorsForDarkMode:self];
    } else {
        [del colorsForLightMode:self];
    }
    
    // Config file opening happens while the VParamVariationsManager has not been created
    // It's mandatory to wait for the call to awakeFromNib to have it attached from IB.
    // Then, the presence of parameter variations can put the 'canRunSimBatch' flag to YES
    // to control the enabling of the button that runs a batch of Sim calls
    if (self.paramVarMgr) {
        [self.paramVarMgr synchronizeUseBoxes];
        self.paramVarMgr.numSim = [self.paramVarMgr computeNumSimCalls];
        self.paramVarMgr.canRunSimBatch = [NSNumber numberWithBool:[self.paramVarMgr hasVariationsInParameters]];
    }
    
    [self buildNavigationPoUpMenu];
}

//-----------------------------------------------------------------------------

-(void) close {
    [super close];
    [self.variationsWindow close];
    VAppDelegate* del = (VAppDelegate*)(NSApp.delegate);
    [del updatePalettes:self];
    if ( ! [del hasTopDoc])
        del.aDocIsOpen = @NO;
}

//---------------------------------------------------------------------------------------------------
//          READ & WRITE CONFIGURATION FILES
//  The  correct behaviour of the NSDocument (keeping track of the dirty flag .isEdited
//  and updating of the window's title upon Save As... command) is possible
//  only upon the implementation of readFromData and dataOfType methods
//---------------------------------------------------------------------------------------------------

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    
    BOOL answer = NO;
    
    @try {
        
        self.configModel = [[VConfigurationModel alloc]init];
        self.configModel.configString = [[NSString alloc]initWithData:data encoding:NSASCIIStringEncoding];
        self.configModel.configURL = self.fileURL;
        VAppDelegate* del = (VAppDelegate*)(NSApp.delegate);
        del.cymFileURL = self.fileURL;
        
        // perform extraction only once upon file opening
        [self.configModel extractObjectsAndInstances];
        [self.configModel extractOutlineVariableItems];
        
        answer = YES;
        *outError = nil;
        
        NSString* fileString = [self.fileURL.path stringByReplacingOccurrencesOfString:@".cym" withString:@".cymvar"];
        NSURL* varURL = [NSURL fileURLWithPath:fileString]; // DO NOT call URLWithString which gives incomplete NSURL and fails saving
        [varURL checkResourceIsReachableAndReturnError:outError];
        if (*outError == noErr) {
            [self.configModel openVariationData:varURL];
            for (VOutlineItem* root in self.configModel.variableOutlineItems) {
                
                VConfigParameter* param = root.configParameter;
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

                for (VOutlineItem* child in root.children) {
                    
                    VConfigParameter* param = child.configParameter;
                    
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

                }
            }
        }
        
        del.aDocIsOpen = @YES;
        
    } @catch (NSException *exception) {
        answer = NO;
        *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:nil];
    }
    
    return answer;
}

//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    
    NSString *theCym = [self.configTextView string];
    NSData* configData = nil;
    
    @try {
        configData = [theCym dataUsingEncoding:NSASCIIStringEncoding];
        *outError = nil;
        
        // on every successful save operation, update all the objects and instances
        [self.configModel extractObjectsAndInstances];
        
        // but preserve the variation contents as set by the user
        //[self castParametersWithoutVariations];
        
        self.configModel.hasVariations = [self.paramVarMgr hasVariationsInParameters];
        
        if (self.configModel.hasVariations) {
            NSString* docFileString = [self.configModel.configURL.path stringByReplacingOccurrencesOfString:@".cym" withString:@".cymvar"];
            NSURL* varURL = [NSURL fileURLWithPath:docFileString]; // DO NOT call URLWithString which gives incomplete NSURL and fails saving
            *outError = [self.configModel saveVariationData:varURL];
        }

    } @catch (NSException *exception) {
        *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:nil];
    }

    return configData;
}

// Overriding setFileURL ensures to intercept the correct fileURL after the user changed the file's name (saving as...)
// because is called after 'dataOfType'. This will allow to synchronize the doc's URL stored in VApplication (cymFileURL)
- (void)setFileURL:(NSURL *)fileURL {
    [super setFileURL:fileURL];
    
    if (self.configModel)
        self.configModel.configURL = self.fileURL;
    
    VAppDelegate* del = (VAppDelegate*)(NSApp.delegate);
    del.cymFileURL = self.fileURL;
}
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------

- (void) replaceWithText:(NSString*) newText {
    if (self.configModel) {
        NSRange prevRange = NSMakeRange(0, self.configTextView.string.length);
        self.configModel.configString = newText;
        [self.configTextView insertText:self.configModel.configString replacementRange: prevRange];
        [self.configTextView scrollRangeToVisible:NSMakeRange(0,0)];
    }
}

//-----------------------------------------------------------------------------

- (NSPrintOperation *)printOperationWithSettings:(NSDictionary<NSPrintInfoAttributeKey,id> *)printSettings error:(NSError *__autoreleasing  _Nullable *)outError {
    NSPrintOperation* printOp =  ([NSPrintOperation printOperationWithView:self.configTextView]);
    return printOp;
}

- (void)document:(NSDocument *)document didPrint:(BOOL)didPrintSuccessfull {
    VAppDelegate* del = (VAppDelegate*)(NSApp.delegate);
    if ([del runInDarkMode]) {
        [del colorsForDarkMode:self];
        self.configTextView.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
    }
    //[del defaultColors];
}

- (IBAction) printConfigurationFile: (id)sender {
    VAppDelegate* del = (VAppDelegate*)(NSApp.delegate);
    if ([del runInDarkMode]) {
        [del colorsForLightMode:self];
        self.configTextView.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    }
    [self printDocumentWithSettings:self.printInfo.dictionary showPrintPanel:YES delegate:self didPrintSelector:@selector(document:didPrint:) contextInfo:nil];
}


//-----------------------------------------------------------------------------
#pragma mark ______ Syntax Coloring _______
//-----------------------------------------------------------------------------

/*
 Code by 'Holex' from https://stackoverflow.com/questions/8533691/how-to-get-all-nsrange-of-a-particular-character-in-a-nsstring
*/

- (BOOL)highlightString:(NSString *)string inText:(NSMutableAttributedString *)attributedString withColour:(NSColor*)color {
    NSError *error;
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:string options:NSRegularExpressionIgnoreMetacharacters error:&error];
    if (error == nil) {
        [regexp enumerateMatchesInString:attributedString.string options:NSMatchingReportProgress range:NSMakeRange(0, attributedString.string.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            if (result.numberOfRanges > 0) {
                for (int i = 0; i < result.numberOfRanges; i++) {
                    [attributedString addAttribute:NSForegroundColorAttributeName value:color range:[result rangeAtIndex:i]];
                }
            }
        }];
        return TRUE;
    } else {
        return FALSE;
    }
}

//-----------------------------------------------------------------------------

- (NSString*) stringAfterString:(NSString*)string InString:(NSString*)wholeString {
    NSString* answerString = nil;
    NSRange range = [wholeString rangeOfString:string];
    if (range.location != NSNotFound) {
        range.location += range.length; // not +1 as the spaces are already included at the end of the NSSet's names
        NSString* rightString = [wholeString substringFromIndex:range.location];
        NSArray* rightWords = [rightString componentsSeparatedByString:@" "];
        answerString = rightWords.firstObject;
    }
    return answerString;
}

//-----------------------------------------------------------------------------

- (IBAction) choseTextColors: (id) sender {
    VAppDelegate* del = (VAppDelegate*)NSApp.delegate;
    [del.syntaxColoringPanel orderFront:self];
}


//-----------------------------------------------------------------------------
#pragma mark --- NSTextView NSTextStorageDelegate and NSTextDelegate methods
//-----------------------------------------------------------------------------

//- (void)textDidChange:(NSNotification *)notification {
//   // NSLog(@"called after the text actually changed");
//}
//
//- (void)textStorage:(NSTextStorage *)textStorage willProcessEditing:(NSTextStorageEditActions)editedMask range:(NSRange)editedRange changeInLength:(NSInteger)delta {
//
//    NSLog(@"called BEFORE the text actually changed");
//}
//
//- (void)processEditing {
//    NSLog(@"called when?");
//}

- (void)textStorage:(NSTextStorage *)textStorage didProcessEditing:(NSTextStorageEditActions)editedMask range:(NSRange)editedRange changeInLength:(NSInteger)delta {
    
    if (! self.needsColorEdition)
        return;
    
    NSString*       tx = @"";   // text that sits between a command and the next '{'

    NSString*       com = @"";
    NSString*       obj = @"";

    NSScanner*      scanner = [NSScanner scannerWithString:textStorage.string];
    NSRange         fullRange, comRange, objRange, txRange;
    NSUInteger      startLoc, endLoc;
    NSUInteger      aLoc;
    VAppDelegate*   del = (VAppDelegate*)NSApp.delegate;

    NSArray*        commands = [NSArray arrayWithObjects:@"set", @"change", @"new", @"add", @"delete", @"mark",
                                  @"run", @"read", @"include", @"cut", @"report", @"import", @"export", @"call",
                                  @"repeat", @"for", @"restart", @"dump", @"save", nil];

    NSArray*        objects = [NSArray arrayWithObjects:@"simul", @"space", @"fiber", @"hand", @"single", @"couple",
                                @"bundle", @"aster", @"solid", @"bead", @"sphere", nil];

    // reset all text attributes to parameters' color
    fullRange = NSMakeRange(0, textStorage.string.length);
    [textStorage addAttribute:NSForegroundColorAttributeName value:del.parametersColorWell.color range:fullRange];

    // commands, objects and object names
    for (NSString* command in commands) {

        while([scanner scanUpToString:command intoString:nil]) {

            if (!scanner.isAtEnd) {
                comRange.location = scanner.scanLocation;
                comRange.length = command.length;
                NSString *upStr = @"", *downStr = @"";
                NSRange aRange = NSMakeRange(comRange.location -1, 1);
                upStr = [textStorage.string substringWithRange:aRange];
                aRange = NSMakeRange(comRange.location+comRange.length, 1);
                downStr = [textStorage.string substringWithRange:aRange];

                if (([downStr isEqualToString:@" "])) {
                    [textStorage addAttribute:NSForegroundColorAttributeName value:del.commandsColorWell.color range:comRange];
                    downStr = @"";
                }

                while ([scanner scanUpToString:@"{" intoString:nil]) {
                    if (!scanner.isAtEnd) {
                        endLoc = scanner.scanLocation;
                        txRange.location = comRange.location + comRange.length;
                        txRange.length = endLoc - txRange.location;
                        tx = [textStorage.string substringWithRange:txRange];
                        NSMutableArray* words = (NSMutableArray*)[tx componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        [words removeObject:@""];
                        NSString* lastWord = words.lastObject;
                        aRange = [tx rangeOfString:lastWord];
                        aRange.location += txRange.location;
                        [textStorage addAttribute:NSForegroundColorAttributeName value:del.namesColorWell.color range:aRange];

                        for (NSString* o in objects) {
                            if ([tx containsString:o]) {
                                objRange = [tx rangeOfString:o];
                                objRange.location += txRange.location;
                                objRange.length = o.length;
                                [textStorage addAttribute:NSForegroundColorAttributeName value:del.objectsColorWell.color range:objRange];
                            }
                        }
                    }
                }
            }
        }
        scanner.scanLocation = 0;
        tx = @"";
    }

    // digits & numbers
    NSCharacterSet* numSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789.-+"];
    while ([scanner scanUpToCharactersFromSet:numSet intoString:nil]) {
        if (!scanner.isAtEnd) {
            startLoc = scanner.scanLocation;
            while ([scanner scanCharactersFromSet:numSet intoString:nil]) {
                NSUInteger endLoc = scanner.scanLocation;
                txRange.location = startLoc;
                txRange.length = endLoc-startLoc;
                [textStorage addAttribute:NSForegroundColorAttributeName value:del.numbersColorWell.color range:txRange];
            }
        }
    }
    scanner.scanLocation = 0;
    
    // punctuation
    NSCharacterSet* puncSet = [NSCharacterSet characterSetWithCharactersInString:@",(;){}"];
    while ([scanner scanUpToCharactersFromSet:puncSet intoString:nil]) {
        if (!scanner.isAtEnd) {
            startLoc = scanner.scanLocation;
            while ([scanner scanCharactersFromSet:puncSet intoString:nil]) {
                endLoc = scanner.scanLocation;
                txRange.location = startLoc;
                txRange.length = endLoc-startLoc;
                [textStorage addAttribute:NSForegroundColorAttributeName value:del.punctuationColorWell.color range:txRange];
            }
        }
    }
    scanner.scanLocation = 0;

    // comments
    NSString* aLine;
    txRange.location = 0;
    txRange.length = 0;
    
    while ([scanner scanUpToString:@"\n" intoString:&aLine]) {
        
        if (!scanner.isAtEnd) {
            
            startLoc = scanner.scanLocation;
            
            if ([aLine hasPrefix:@"%"]) {
                startLoc -= aLine.length;
                endLoc = startLoc+aLine.length;
                
                if ([aLine containsString:@"{"]) {
                    if ([scanner scanUpToString:@"}" intoString:nil]){
                        if (!scanner.isAtEnd) {
                            endLoc = scanner.scanLocation + 1;
                        }
                    }
                }
                txRange = NSMakeRange(startLoc, endLoc-startLoc);
                
            } else if (([aLine containsString:@"%"]) && (![aLine hasPrefix:@"%"])){
                NSRange startRange = [aLine rangeOfString:@"%"];
                NSString* subS = [aLine substringFromIndex:startRange.location];
                txRange = [textStorage.string rangeOfString:subS];
            }
        }
        [textStorage addAttribute:NSForegroundColorAttributeName value:del.commentsColorWell.color range:txRange];
    }


    // The following call will completely reset the variations by re-casting the content of the modified .cym file (takes too much time ?)
    // A Parse tool has been added in the toolbar to force extraction manually.
//    [self parseAgain:self];
//    [self.configModel extractOutlineVariableItems];

    // Finally, ensure that any change in parameter value will be directly cast
    // to the parameter variations' window
    if (self.variationsWindow.visible) {
        [self.paramVarMgr.outlineView reloadData];
        [self.paramVarMgr.interpolView setNeedsDisplay:YES];
    }
}


//-----------------------------------------------------------------------------
#pragma mark ______ Document methods _______
//-----------------------------------------------------------------------------


-(NSRange) extendTextViewSelectionRangeToWholeLines {
    
    NSRange selectedRange = [[[self.configTextView selectedRanges] firstObject]rangeValue];
    NSUInteger sStart = selectedRange.location;
    NSUInteger sEnd = selectedRange.location + selectedRange.length;
    NSString* wholeText = self.configTextView.string;

    if ((self.configTextView.string.length >0) && (selectedRange.length>0)) {

        // extend the selection range to whole lines
        
        NSArray* wholeLines = [wholeText componentsSeparatedByString:@"\n"];
        NSUInteger lStart = 0, lEnd = 0, delta = 0;
        
        for (NSString* line in wholeLines) {
            
            // here do NOT make use of [NSString rangeOfString:] because of weird results with  '{', '}' or with empty lines
            // So computing the locations and lengths manually if much safer.
            // Also, add #1 to each line to take into acount the '\n' at the end of a line into a line's length
            NSRange lineRange = NSMakeRange(lEnd, line.length+1);
            lStart = lineRange.location;
            lEnd = lStart + lineRange.length;
            
            
            if ((sStart > lStart) && (sStart < lEnd)) {
                delta = selectedRange.location - lStart;
                selectedRange.location = lStart;
                selectedRange.length += delta;
            }
            
            if ((sEnd < lEnd) && (sEnd > lineRange.location)) {
                delta = lEnd - sEnd;
                selectedRange.length += delta;
            }
        }
        
        NSString* selectedText = [wholeText substringWithRange:selectedRange];
        if ( ! [selectedText hasSuffix:@"\n"])
            selectedRange.length += 1;
    }
    return selectedRange;
}

//-----------------------------------------------------------------------------

-(IBAction) blockComment:(id)sender {
 
    //extend the actual text selection to whole lines
    NSRange wholeLinesRange = [self extendTextViewSelectionRangeToWholeLines];
    self.configTextView.selectedRange = wholeLinesRange;

    // get the selected text and insert the short string "% " in front of each line
    
    NSString* selText = [self.configTextView.string substringWithRange:wholeLinesRange];
    NSMutableArray* lines = (NSMutableArray*)[selText componentsSeparatedByString:@"\n"];
    if ([lines.lastObject isEqualToString:@""])
        [lines removeLastObject];
    
    NSString* newText = @"";
    NSString* newLine = @"";
    BOOL isAlreadyCommented = YES;
    
    for (NSString* line in lines) {
        isAlreadyCommented = [line hasPrefix:@"%"];
        if ( ! isAlreadyCommented)
            break;
    }
    
    NSMutableArray* linesCopy = [NSMutableArray arrayWithCapacity:0];
    if (isAlreadyCommented) {
        for (NSString* line in lines) {
            if ([line hasPrefix:@"% "])
                newLine = [[line copy] stringByReplacingOccurrencesOfString:@"% " withString:@""];
            else
                newLine = [[line copy] stringByReplacingOccurrencesOfString:@"%" withString:@""];
            newLine = [newLine stringByAppendingString:@"\n"];
            [linesCopy addObject:newLine];
        }
    } else {
        for (NSString* line in lines){
            newLine = [@[@"% ", line] componentsJoinedByString:@""];
            newLine = [newLine stringByAppendingString:@"\n"];
            [linesCopy addObject:newLine];
        }
    }
    for (NSString* s in linesCopy) {
        newText = [newText stringByAppendingString:s];
    }
    
    // insert the modified text by replacing the old text
    [self.configTextView insertText:newText replacementRange:wholeLinesRange];
    
    NSRange newRange = [self.configTextView.string rangeOfString:newText];
    self.configTextView.selectedRange = newRange;
}

//-----------------------------------------------------------------------------

- (IBAction) indentSelection:(id)sender {
    //extend the actual text selection to whole lines
    NSRange wholeLinesRange = [self extendTextViewSelectionRangeToWholeLines];
    self.configTextView.selectedRange = wholeLinesRange;

    // get the selected text and insert the short string "% " in front of each line
    
    NSString* selText = [self.configTextView.string substringWithRange:wholeLinesRange];
    NSArray* lines = [selText componentsSeparatedByString:@"\n"];
    NSString* newText = @"";
    
    for (NSString* line in lines) {
        if ( ! [line isEqualToString:@""] ) {
            NSString* newLine = @"    ";
            newLine = [newLine stringByAppendingString:line];
            if ( ! [line hasSuffix:@"\n"])
                newLine = [newLine stringByAppendingString:@"\n"]; // the lines do not contain a CR
            newText = [newText stringByAppendingString:newLine];
        }
    }

    // insert the modified text by replacing the old text
    [self.configTextView insertText:newText replacementRange:wholeLinesRange];
    NSRange newRange = [self.configTextView.string rangeOfString:newText];
    self.configTextView.selectedRange = newRange;
}

//-----------------------------------------------------------------------------

- (IBAction) deIndentSelection:(id)sender {
    
    //extend the actual text selection to whole lines
    NSRange wholeLinesRange = [self extendTextViewSelectionRangeToWholeLines];
    self.configTextView.selectedRange = wholeLinesRange;

    // get the selected text and insert the short string "% " in front of each line
    
    NSString* selText = [self.configTextView.string substringWithRange:wholeLinesRange];
    NSArray* lines = [selText componentsSeparatedByString:@"\n"];
    NSString* newText = @"";
    
    for (NSString* line in lines) {
        NSString* newLine;
        if (line.length >= 4) {
            NSRange newLineRange = NSMakeRange(0,line.length);
            if ([line hasPrefix:@"    "])
                newLineRange = NSMakeRange(4,line.length-4);
            newLine = [line substringWithRange:newLineRange];
            newLine = [newLine stringByAppendingString:@"\n"];
            newText = [newText stringByAppendingString:newLine];
        } else if ( ! [line isEqualToString:@""]){
            newLine = [line stringByAppendingString:@"\n"];
            newText = [newText stringByAppendingString:newLine];
        }
    }

    // insert the modified text by replacing the old text
    [self.configTextView insertText:newText replacementRange:wholeLinesRange];
    NSRange newRange = [self.configTextView.string rangeOfString:newText];
    self.configTextView.selectedRange = newRange;
}


- (IBAction) openModelBuilder: (id) sender {
    VAppDelegate* del = (VAppDelegate*)NSApp.delegate;
    [del.modelDesignWindow orderFront:self];
}

- (IBAction) showVariationsWindow: (id) sender {
    
    [self.variationsWindow makeKeyAndOrderFront:nil];
    [self.paramVarMgr synchronizeUseBoxes];
}

- (NSString*) removeSpacesAtTheEndOfString:(NSString*) s {
    for (NSInteger k = s.length - 1; k > 0; k --) {
        NSString *theCharacter = [NSString stringWithFormat:@"%c", [s characterAtIndex:k]];
        if ([theCharacter isEqualToString:@" "]) {
            s = [s substringWithRange:NSMakeRange(0, s.length - 1)];
        } else {
            break;
        }
    }
    return s;
}

//---------------------------------------------------------------------------------

- (IBAction) goToObjectItem:(id)sender {
    NSPopUpButton* btn = (NSPopUpButton*)sender;
    NSInteger tag = btn.selectedItem.tag;
    NSRange targetRange = {0,0};
    
    NSInteger objCount = self.configModel.configObjects.count;
    if (tag < objCount) {
        targetRange = ((VConfigObject*)[self.configModel.configObjects objectAtIndex:tag]).objRange;
    } else {
        tag -= objCount;
        targetRange = ((VConfigInstance*)[self.configModel.configInstances objectAtIndex:tag]).instanceRange;
    }
    //[self.configTextView scrollRangeToVisible:targetRange]; // positions the range in the middle of the window --> bad
    [self scrollRangeToTop:targetRange];
}

//---------------------------------------------------------------------------------

-(void) scrollRangeToTop:(NSRange) aRange {
    
    NSRange glyphRange = [self.configTextView.layoutManager glyphRangeForCharacterRange:aRange actualCharacterRange:nil];
    NSRect rect = [self.configTextView.layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:self.configTextView.textContainer];
    NSPoint topText = self.configTextView.textContainerOrigin;
    NSPoint contentOffset = CGPointMake(0, topText.y + rect.origin.y);
    NSView* cv = self.configTextView.superview;
    if ([cv isMemberOfClass:[NSClipView class]]) {
        NSClipView* clip = (NSClipView*)cv;
        [clip scrollToPoint:contentOffset];
    }
}

- (IBAction) parseAgain:(id)sender {
    // Update the model's configString to cast the change
    self.configModel.configString = [NSString stringWithString:self.configTextView.textStorage.string];
    //    // Re-extract text contents into the configModel
    [self.configModel extractObjectsAndInstances];
    [self.configModel extractOutlineVariableItems];
    [self buildNavigationPoUpMenu];
}

//-----------------------------------------------------------------------------

-(void) buildNavigationPoUpMenu {
    // build navigation PopUp menu
    // BEWARE: NSPopUpButton item insertion automatically removes duplicates !
    // this is why it is mandatory to add a different prefix to each item's title.
    
    [self.objectsButton removeAllItems];
    self.objectsButton.autoenablesItems = NO; // also set in IB... !
    
    [self.objectsButton addItemWithTitle:@"--- set --------------------------"];
    self.objectsButton.lastItem.tag = -1;
    self.objectsButton.lastItem.enabled = NO;
    
    NSInteger k = 0;
    for (VConfigObject* obj in self.configModel.configObjects) {
        [self.objectsButton addItemWithTitle:[@[obj.objType, obj.objName] componentsJoinedByString:@" :: "]];
        self.objectsButton.lastItem.tag = k;
        k++;
    }
    
    [self.objectsButton addItemWithTitle:@"--- new --------------------------"];
    self.objectsButton.lastItem.tag = -1;
    self.objectsButton.lastItem.enabled = NO;

    NSString* instanceString = @"";
    for (VConfigInstance* inst in self.configModel.configInstances) {
        
        NSString* appendix = @"";
        if ([instanceString containsString:inst.instanceName]) {
            NSUInteger occ =  [[NSMutableString stringWithString:instanceString] replaceOccurrencesOfString:inst.instanceName withString:inst.instanceName options:NSLiteralSearch range:NSMakeRange(0, instanceString.length)];
            if (occ > 0){
                NSString* occS = [NSNumber numberWithInteger:occ].stringValue;
                appendix = [@[@" (",occS,@")"]componentsJoinedByString:@""];
            }
        }
        NSString* dupName = [inst.instanceName stringByAppendingString:appendix];
        [self.objectsButton addItemWithTitle:[@[inst.instanceNumber.stringValue, dupName] componentsJoinedByString:@" :: "]];
        instanceString = [instanceString stringByAppendingString:[@[inst.instanceName, @"\n"]componentsJoinedByString:@""]];
        self.objectsButton.lastItem.tag = k;
        k++;
    }
    
    [self.objectsButton selectItemWithTag:0];
}


@end
