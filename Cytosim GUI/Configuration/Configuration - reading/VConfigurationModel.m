//
//  VConfigurationModel.m
//  Cytosim GUI
//
//  Created by Chris on 15/08/2022.
//

#import "VConfigurationModel.h"

// for checking purposes
#import "VAppDelegate.h"
#import "VDocument.h"

@implementation VConfigurationModel

@synthesize hasVariations, modelConfigCode;

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.configString = @"";
        self.trimmedConfigString = @"";
        self.configLines = [NSMutableArray arrayWithCapacity:0];
        self.configObjects = [NSMutableArray arrayWithCapacity:0];
        self.objectNamesSet = [NSMutableSet setWithCapacity:0];
        self.configInstances = [NSMutableArray arrayWithCapacity:0];
        self.variableOutlineItems = [NSMutableArray arrayWithCapacity:0];
        self.hasVariations = NO;
    }
    return self;
}

//======================================================================================

-(void) removeComments {
    
    NSString* uncommentedString = [self.configString copy];
    
    // 1- Discard comment blocks (those of the form  '%{......}' )
    
    // start by extracting all the string matches that start and end with an '{' and an '}', respectively
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\{([^}]+)\\}" options:0 error:nil];
    NSArray *matches = [regex matchesInString:self.configString options:0 range:NSMakeRange(0, self.configString.length)];
    
    for (NSTextCheckingResult* r in matches) {
        
        NSRange matchRange = r.range;
        NSRange extensionRange = NSMakeRange(matchRange.location, 0);
        NSString* extendedString = [self.configString substringWithRange:matchRange];
        NSString* stringExtension = @"";
        
        BOOL stopExpansion = NO;
        BOOL isComment = NO;
        // extend the range upstream until a comment sign or a keyword is found
        while (! stopExpansion) {
            extensionRange.location --;
            if (extensionRange.location < 0)
                break;
            extensionRange.length++;
            stringExtension = [self.configString substringWithRange:extensionRange];
            
            if ([stringExtension hasPrefix:@"%"] || [stringExtension hasPrefix:@"}"]
                || [stringExtension containsString:@"set"]
                || [stringExtension containsString:@"new"]
                || [stringExtension containsString:@"cut"]
                || [stringExtension containsString:@"run"]) {
                stopExpansion = YES;
                isComment = [stringExtension hasPrefix:@"%"];
            }
            if (isComment) {
                matchRange.location = extensionRange.location;
                matchRange.length += extensionRange.length;
                extendedString  = [self.configString substringWithRange:matchRange];
                uncommentedString = [uncommentedString stringByReplacingOccurrencesOfString:extendedString withString:@""];
            }
        }
    }
    
    // 2- discard all the lines that begin by '%'
    NSArray* lines = [uncommentedString componentsSeparatedByString:@"\n"];
    NSMutableArray* mutLines = [NSMutableArray arrayWithArray:lines];
    
    for (NSInteger k = 0; k < mutLines.count; k++) {
        
        NSString* aLine = [mutLines objectAtIndex:k];
        // remove any blank space before a comment '%' sign
        // aLine = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([aLine hasPrefix:@"%"]){
            [mutLines setObject:@"" atIndexedSubscript:k];
        } else {
            if ([aLine containsString:@"%"]) {
                NSRange rightRange = [aLine rangeOfString:@"%"];
                aLine = [aLine substringWithRange:NSMakeRange(0, rightRange.location - 1)];
                [mutLines setObject:aLine atIndexedSubscript:k];
            }
        }
    }
    uncommentedString = [mutLines componentsJoinedByString:@"\n"];
    self.trimmedConfigString = uncommentedString;
}

//======================================================================================

-(void) removeBlankLines {
    
    // failed to use a regex to find blank/empty lines so use classical NSString methods
    
    NSString* string = [NSString stringWithString:self.trimmedConfigString];
    
    NSArray* lines = [string componentsSeparatedByString:@"\n"]; // removes \n for each line
    NSMutableArray* mutLines = [NSMutableArray arrayWithArray:lines];
    
    for (NSInteger k=0; k< lines.count; k++){
        NSString* aLine = [lines objectAtIndex:k];
        NSString* temp = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (temp.length == 0)
            [mutLines removeObject:aLine];
    }
    // remove blank spaces
    NSMutableArray* noSpaces = [NSMutableArray arrayWithCapacity:0];
    for (NSString* aLine in mutLines) {
        NSString* temp = [aLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (temp.length < aLine.length) {
            temp = [@[@"\t",temp] componentsJoinedByString:@""];
        }
        [noSpaces addObject:temp];
    }
    string = [noSpaces componentsJoinedByString:@"\n"];
    self.trimmedConfigString = string;
}

//======================================================================================

-(void) splitConfigLines {
    NSArray* lines =  [self.configString componentsSeparatedByString:@"\n"];
    self.configLines = [NSMutableArray arrayWithArray:lines];
}

//======================================================================================

-(NSString*) keyWordString:(NSString*)aString  {
    NSArray* keyWords = [NSArray arrayWithObjects:@"set", @"new", @"run", nil];
    NSString* answer = @"";
    for (NSString* s in keyWords) {
        if ([aString containsString:s]) {
            answer = s;
            break;
        }
    }
    return answer;
}

//======================================================================================

-(NSNumber*) stringIsNumeric:(NSString*)aString {
    NSNumberFormatter* form = [[NSNumberFormatter alloc]init];
    NSLocale* en_loc = [[NSLocale alloc] initWithLocaleIdentifier: @"en"];
    [form setLocale:en_loc];
    NSNumber* num = [form numberFromString:aString];
    return num;
}

//======================================================================================

-(void) extractParametersFromArray:(NSArray*) anArray IntoObject:(VConfigObject*)anObject IntoInstance:(VConfigInstance*)anInstance {

    NSCharacterSet* spaces = [NSCharacterSet whitespaceCharacterSet]; // white spaces and tabulations

    for (NSInteger k = 1; k < anArray.count; k++) {
        
        // skip the first line
        NSString* par = [anArray objectAtIndex:k];
        
        // skip the lines with display parameters
        if (([par containsString:@"="]) &&( ! [par containsString:@"display"])) {
            
            NSArray* members = [par componentsSeparatedByString:@"="];
            
            // make a parameter object
            VConfigParameter* cParam = [[VConfigParameter alloc]init];
            (anObject) ? (cParam.ownerName = anObject.objName) : (cParam.ownerName = anInstance.instanceName);
            cParam.ownerIsInstance = (anInstance != nil);
            cParam.paramName = [members.firstObject stringByTrimmingCharactersInSet:spaces];
            //cParam.instanceCount = [NSNumber numberWithFloat:NAN];

            NSString* value = (NSString*) members.lastObject;
            NSString* name = [cParam.paramName copy];
            cParam.paramStringValue = [members.lastObject stringByTrimmingCharactersInSet:spaces];
            cParam.paramNumValue = [self stringIsNumeric:cParam.paramStringValue];

            if ([value containsString:@","]) {
                NSMutableArray* multiVal = (NSMutableArray*)[value componentsSeparatedByString:@","];
    
                for (NSInteger k = 0; k < multiVal.count; k ++) {
                    VConfigParameter* addParam = [[VConfigParameter alloc]init];
                    (anObject) ? (addParam.ownerName = anObject.objName) : (addParam.ownerName = anInstance.instanceName);
                    NSNumber* ak = [NSNumber numberWithInteger:k];
                    addParam.ownerIsInstance = (anInstance != nil);
                    addParam.paramName = [@[name, @"[", ak.stringValue ,@"]"] componentsJoinedByString:@""];
                    //addParam.instanceCount = [NSNumber numberWithFloat:NAN];
                    NSString* addVal = [[multiVal objectAtIndex:k] stringByTrimmingCharactersInSet:spaces];
                    addParam.paramStringValue = addVal;
                    addParam.paramNumValue = [self stringIsNumeric:addParam.paramStringValue];
                    
                    ([self stringIsNumeric:addVal]) ? (addParam.variations = [[VParameterVariations alloc]initWithValue:addParam.paramNumValue]): (addParam.variations = nil);
                    (anObject) ? ([anObject.objParameters addObject:addParam]) : ([anInstance.instanceParameters addObject:addParam]);
                }
            } else {
                ([self stringIsNumeric:cParam.paramStringValue]) ? (cParam.variations = [[VParameterVariations alloc]initWithValue:cParam.paramNumValue]):(cParam.variations = nil);
                (anObject) ? ([anObject.objParameters addObject:cParam]) : ([anInstance.instanceParameters addObject:cParam]);
            }
        }
    }
}

//======================================================================================

-(NSString*) stringLineContainingWords:(NSArray*) words FromString:(NSString*)src {
    NSArray* allTheLines = [src componentsSeparatedByString:@"\n"];
    NSString* s = @"";
    for (NSString* line in allTheLines) {
        BOOL foundIt = NO;
        for (NSString* word in words) {
            foundIt = [line containsString:word];
            if (!foundIt)
                break;
        }
        // send only the first occurrence that contains all the words
        if (foundIt) {
            s = [line copy];
            break;
        }
    }
    return s;
}

//======================================================================================

-(NSString*) correctCodeForMissingBraces:(NSString*)code {
    NSString* answer = [code copy];
    // the fastest approach is to make fake replacements
    NSUInteger openings = [[NSMutableString stringWithString:code] replaceOccurrencesOfString:@"{" withString:@"{" options:NSLiteralSearch range:NSMakeRange(0, code.length)];
    NSUInteger closings = [[NSMutableString stringWithString:code] replaceOccurrencesOfString:@"}" withString:@"}" options:NSLiteralSearch range:NSMakeRange(0, code.length)];
    if (openings > closings) {
        for (NSInteger k = 0; k< (openings - closings); k++) {
            answer = [answer stringByAppendingString:@"\n}"];
        }
    }
    return answer;
}

//======================================================================================

-(void) extractObjectsAndInstances {

    //-------------------------------------------------------------
    // NEW version  based on the recognition of regular expression
    //-------------------------------------------------------------

    // clear the containers
    [self.configObjects removeAllObjects];
    [self.configInstances removeAllObjects];
    // the next 2 calls also create and update self.trimmedConfigString
    [self removeComments];
    [self removeBlankLines];

    // start by extracting all the string matches that start and end with an '{' and an '}', respectively
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\{([^}]+)\\}" options:0 error:nil];
    NSArray *matches = [regex matchesInString:self.trimmedConfigString options:0 range:NSMakeRange(0, self.trimmedConfigString.length)];

    for (NSTextCheckingResult* r in matches) {
        
        NSRange matchRange = r.range;
        NSString* extendedString = [self.trimmedConfigString substringWithRange:matchRange];
        NSString* objCode = @"";
        
        BOOL stopExpansion = NO;
        // extend the range upstream until a keyword is found
        while (! stopExpansion) {
            matchRange.location --;
            if (matchRange.location < 0)
                break;
            matchRange.length++;
            extendedString  = [self.trimmedConfigString substringWithRange:matchRange];

            stopExpansion = ([extendedString containsString:@"set"])
            || ([extendedString containsString:@"new"])
            || ([extendedString containsString:@"run"])
            || ([extendedString containsString:@"cut"]);
        }

        // when upstream extension is done, get the 1st line and the key words
        NSArray* subLines = [extendedString componentsSeparatedByString:@"\n"];
        NSArray* words = [subLines.firstObject componentsSeparatedByString:@" "];
        objCode = [extendedString copy];    // include the title line

        // create the object or the instance accordingly
        // first extract the objects
        if ([subLines.firstObject containsString:@"set"]) {
            VConfigObject* object = [[VConfigObject alloc]init];
            object.objType = [words objectAtIndex:1];
            object.objName = [words objectAtIndex:2];
            [self.objectNamesSet addObject:object.objName];
            //object.objCode = [objCode copy];
            object.objCode = [self correctCodeForMissingBraces:objCode];
            [self extractParametersFromArray:subLines IntoObject:object IntoInstance:nil];
            // as only one call to 'set objetType objectName' is permitted per file
            // the range can be directly calculated here
            object.objRange = [self.configString rangeOfString:[self stringLineContainingWords:@[@"set", object.objType, object.objName] FromString:self.configString]];
            [self.configObjects addObject:object];
        }

        //b- extract the instances
        if ([subLines.firstObject containsString:@"new"]) {
            NSNumber* num = nil;
            VConfigInstance* instance = [[VConfigInstance alloc]init];
            //instance.instanceCode = [objCode copy];
            instance.instanceCode = [self correctCodeForMissingBraces:objCode];
            if (words.count == 2) {
                num = @1;
                instance.instanceName = [words objectAtIndex:1];
            }
            if (words.count == 3) {
                num= [self stringIsNumeric:[words objectAtIndex:1]];
                instance.instanceName = [words objectAtIndex:2];
            }
            
            if (num != nil) {
                instance.instanceNumber = num;
                NSString* targetStr = @"";
                if ([num.stringValue isEqualToString:@"1"])
                        targetStr = [self stringLineContainingWords:@[@"new", instance.instanceName] FromString:self.configString];
                    else
                        targetStr = [self stringLineContainingWords:@[@"new", num.stringValue, instance.instanceName] FromString:self.configString];
                
                // get the correct range if duplicates
                    // count them
                NSUInteger dupCount = 1;
                for (VConfigInstance* i in self.configInstances){
                    if (([i.instanceName isEqualToString:instance.instanceName]) && ([i.instanceNumber isEqualTo:num])) {
                        dupCount++;
                    }
                }
                    // get the ranges with a regex
                NSRange matchRange = NSMakeRange(0, 0);
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:targetStr options:0 error:nil];
                NSArray *matches = [regex matchesInString:self.configString options:0 range:NSMakeRange(0, self.configString.length)];
                for (NSTextCheckingResult* r in matches) {
                    NSUInteger index = [matches indexOfObject:r] + 1;
                    if (index == dupCount)
                        matchRange = r.range;
                }
                instance.instanceRange = matchRange;
            }
            
            [self extractParametersFromArray:subLines IntoObject:nil IntoInstance:instance];
            [self.configInstances addObject:instance];
        }


    }
}

//======================================================================================

// Extracts selectively object and instance parameters that are numeric and
// hence can be set to vary (including instance titles).
// Upon the initial opening of a VDocument, the destination array is self.variableOutlineItems
// and 'keepPreviousVariations' should be set to NO
// When the user updates a VDocument's content, this method is also used but with
// 'keep' set to YES to avoid loosing previous unsaved work

-(void) extractOutlineVariableItems {
    
    [self.variableOutlineItems removeAllObjects];
    
    NSNumberFormatter* form = [[NSNumberFormatter alloc]init];
    NSLocale* en_loc = [[NSLocale alloc] initWithLocaleIdentifier: @"en"];
    [form setLocale:en_loc];
    VOutlineItem *root = nil, *child = nil;
    
    // inject objects that are allowed to vary as root VOutlineItems with variable parameters as children VOutlineItems
    
    for (NSInteger k = 0; k < self.configObjects.count ; k++) {
        
        VConfigObject* obj = [self.configObjects objectAtIndex:k];
        if (obj) {
            if ([obj canVary]) {
                root = [[VOutlineItem alloc] initWithObjectTitle:obj];
                root.children = [NSMutableArray arrayWithCapacity:0];
                root.configParameter.ownerName = @"";
                
                for (VConfigParameter* param in obj.objParameters) {
                    if (param.isNumeric) {
                        VOutlineItem* child = [[VOutlineItem alloc]initWithParameter:param];
                        [root.children addObject:child];
                        child.parent = root;
                        child.configParameter.ownerName = root.configParameter.paramName;
                    }
                }
                [self.variableOutlineItems addObject:root];
            }
        }
    }
    
    // inject instances that are allowed to vary as root VOutlineItems with variable parameters as children VOutlineItems
    
    for (NSInteger k = 0; k< self.configInstances.count; k++) {
        VConfigInstance* inst = [self.configInstances objectAtIndex:k];
        
        if (inst) {
            if ([inst canVary]) {
                root = [[VOutlineItem alloc] initWithInstanceTitle:inst];
                root.children = [NSMutableArray arrayWithCapacity:0];
                root.configParameter.ownerName = @"instance";
                
                for (VConfigParameter* param in inst.instanceParameters) {
                    if (param.isNumeric) {
                        child = [[VOutlineItem alloc]initWithParameter:param];
                        [root.children addObject:child];
                        child.parent = root;
                        child.configParameter.ownerName = root.configParameter.paramName;
                        child.configParameter.instanceCount = [NSNumber numberWithFloat:NAN];
                    }
                }
                [self.variableOutlineItems addObject:root];
            }
        }
    }
    
 }


-(void) reorderOutlineVariableItem:(VOutlineItem*)draggedItem ToPosition:(NSInteger)toPos IntoRootItem:(VOutlineItem*)rootItem {
    
    NSUInteger index;   // index in the array
    
    if (rootItem == nil) {  //drop between root items
        index = [self.variableOutlineItems indexOfObject:draggedItem];
        if (toPos > index)
            toPos --;
        [self.variableOutlineItems removeObjectAtIndex:index];
        [self.variableOutlineItems insertObject:draggedItem atIndex:toPos];
    } else {                // drop within the rootItem
        index = [rootItem.children indexOfObject:draggedItem];
        if (toPos > index)
            toPos --;
        [rootItem.children removeObjectAtIndex:index];
        [rootItem.children insertObject:draggedItem atIndex:toPos];
    }
}

//-----------------------------------------------------------------------------

-(VConfigObject*) objectWithName:(NSString*)name {
    
    VConfigObject* answer = nil;
    
    for (VConfigObject* obj in self.configObjects) {
        if ([obj.objName isEqualToString:name]){
            answer = obj;
            break;
        }
    }
    return answer;
}

//-----------------------------------------------------------------------------

-(VConfigInstance*) instanceWithName:(NSString*)name {
    VConfigInstance* answer = nil;
    for (VConfigInstance* inst in self.configInstances) {
        if ([inst.instanceName isEqualToString:name]){
            answer = inst;
            break;
        }
    }
    return answer;
}

//-----------------------------------------------------------------------------

-(NSError*) saveVariationData:(NSURL*)atURL {
    // Build variations text
    
    NSError* outErr = nil;
    
    NSString* varText = nil;
    NSString* s = atURL.lastPathComponent;
    varText = [@[@"% ", s, @"\n"] componentsJoinedByString:@" "];
    
    for (VOutlineItem* root in self.variableOutlineItems) {
        
        VConfigParameter* rp = root.configParameter;
        if (rp.validateDX) {
            NSString* var = [self stringWithVariation:rp];
            varText = [varText stringByAppendingString:var];
        }
        
        for (VOutlineItem* child in root.children) {
            VConfigParameter* cp = child.configParameter;
            if (cp.validateDX) {
                NSString* vac = [self stringWithVariation:cp];
                varText = [varText stringByAppendingString:vac];
            }
        }
    }
    varText = [varText substringToIndex:varText.length-1];
    [varText writeToURL: atURL atomically:YES encoding:NSUTF8StringEncoding error:&outErr];
    return outErr;
}

//-----------------------------------------------------------------------------

- (NSString*) stringWithVariation:(VConfigParameter*)par {
    NSString* answer = @"";

    NSNumber *varType = [NSNumber numberWithInteger:par.variations.variationType];
    NSArray *parData = [NSArray arrayWithObjects:par.variations.active, par.ownerName, par.paramName, par.variations.numberOfValues, par.variations.minX, par.variations.maxX, varType, par.variations.p1, par.variations.p2, par.variations.p3, par.variations.p4, nil];
    answer = [parData componentsJoinedByString:@", "];
    answer = [answer stringByAppendingString:@"\n"];
    return answer;
}
//-----------------------------------------------------------------------------

-(void) openVariationData:(NSURL*)fromURL {
    
    NSMutableArray* items = self.variableOutlineItems;
    
    NSString* varString = [NSString stringWithContentsOfURL:fromURL encoding:NSASCIIStringEncoding error:nil];
    NSArray* lines = [varString componentsSeparatedByString:@"\n"];
    
    for (NSString* line in lines) {
        
        if ( ! [[line substringWithRange:NSMakeRange(0, 1)] isEqualTo:@"%"]) {
            
            NSArray* vars = [line componentsSeparatedByString:@", "];
            
            NSString* active = [vars objectAtIndex:0];
            NSString* ownerObject = [vars objectAtIndex:1];
            NSString* paramName = [vars objectAtIndex:2];
            NSString* numVal = [vars objectAtIndex:3];
            NSString* minX = [vars objectAtIndex:4];
            NSString* maxX = [vars objectAtIndex:5];
            NSString* varType = [vars objectAtIndex:6];
            NSString* p1 = [vars objectAtIndex:7];
            NSString* p2 = [vars objectAtIndex:8];
            NSString* p3 = [vars objectAtIndex:9];
            NSString* p4 = [vars objectAtIndex:10];
            
            for (VOutlineItem* root in items) {
                VConfigParameter* p = root.configParameter;
                if (([p.ownerName isEqualToString:ownerObject]) && ([p.paramName isEqualToString:paramName])) {
                    p.variations.active = [NSNumber numberWithBool:active.boolValue];
                    p.variations.variationType = varType.integerValue;
                    p.variations.numberOfValues = [NSNumber numberWithInteger:numVal.integerValue];
                    p.variations.minX = [NSNumber numberWithFloat:minX.floatValue];
                    p.variations.maxX = [NSNumber numberWithFloat:maxX.floatValue];
                    p.variations.p1 = [NSNumber numberWithFloat:p1.floatValue];
                    p.variations.p2 = [NSNumber numberWithFloat:p2.floatValue];
                    p.variations.p3 = [NSNumber numberWithFloat:p3.floatValue];
                    p.variations.p4 = [NSNumber numberWithFloat:p4.floatValue];
                }
                
                for (VOutlineItem* child in root.children) {
                    VConfigParameter* q = child.configParameter;
                    if (([q.ownerName isEqualToString:ownerObject]) && ([q.paramName isEqualToString:paramName])) {
                        q.variations.active = [NSNumber numberWithBool:active.boolValue];
                        q.variations.variationType = varType.integerValue;
                        q.variations.numberOfValues = [NSNumber numberWithInteger:numVal.integerValue];
                        q.variations.minX = [NSNumber numberWithFloat:minX.floatValue];
                        q.variations.maxX = [NSNumber numberWithFloat:maxX.floatValue];
                        q.variations.p1 = [NSNumber numberWithFloat:p1.floatValue];
                        q.variations.p2 = [NSNumber numberWithFloat:p2.floatValue];
                        q.variations.p3 = [NSNumber numberWithFloat:p3.floatValue];
                        q.variations.p4 = [NSNumber numberWithFloat:p4.floatValue];
                    }
                }
            }
        }
    }
}

//-----------------------------------------------------------------------------

-(void) buildVariableConfigStringWithLabel:(NSString*)label ForPlayInstance:(NSInteger) instanceNum {
    
    self.variableConfigString = @"";
    NSString* simulName = @"";
    VAppDelegate* del = (VAppDelegate*)NSApp.delegate;
    VConfigObject *disPlay = nil, *batchDisplayObject = nil;
    
    for (VConfigObject* obj in self.configObjects) {
        if ([obj.objName isEqualToString:@"display"]) {
            disPlay = obj;
        } else {
            if ([obj.objType isEqualToString:@"simul"])
                simulName = [obj.objName copy];
            
            NSString* oCode = obj.objCode;
            oCode = [oCode stringByAppendingString:@"\n"];
            self.variableConfigString = [self.variableConfigString stringByAppendingString:oCode];
        }
    }
    if (disPlay) {
        if ([disPlay.objName isEqualToString:@"display"]) {
            NSInteger playMarginX = 10, playMarginY = 80;
            NSInteger rowSize = TASK_LIMIT/2;
            NSInteger playRow, playColumn;
            (instanceNum < rowSize) ? (playRow = 0) : (playRow = 1);
            playColumn = instanceNum - (playRow * rowSize);
            NSInteger playPosX = playColumn * (playMarginX + del.batchSimWidth.integerValue);
            // the origin for OpenGL locations is at the top left....
            NSInteger playPosY = playRow * (playMarginY + del.batchSimHeight.integerValue);
            
            batchDisplayObject = [[VConfigObject alloc]init];
            batchDisplayObject.objType = disPlay.objType;
            batchDisplayObject.objName= disPlay.objName;
            NSString* labelStr = [@[@"\tlabel = (", label, @")\n"] componentsJoinedByString:@""];
            NSString* winSizeStr = [@[@"\twindow_size = ", del.batchSimWidth.stringValue, @", ", del.batchSimHeight.stringValue, @"\n"]              componentsJoinedByString:@""];
            NSString* winPosStr = [@[@"\twindow_position = ", [NSNumber numberWithInteger:playPosX].stringValue, @", ", [NSNumber numberWithInteger:playPosY].stringValue, @"\n" ] componentsJoinedByString:@""];
            NSString* loopStr = @"\tloop = 1\n";
            //VConfigObject* displayObject = [self aggregateObject:disPlay AndObject:batchDisplayObject];
            NSString* newCode = [@[@"set ",batchDisplayObject.objType,@" ", batchDisplayObject.objName,@"\n", @"{\n",
                                     labelStr, winSizeStr, winPosStr, loopStr, @"}\n\n"] componentsJoinedByString:@""];
            self.variableConfigString = [self.variableConfigString stringByAppendingString:newCode];
        }
    }
    
    for (VConfigInstance* inst in self.configInstances) {
        NSString* iCode = inst.instanceCode;
        iCode = [iCode stringByAppendingString:@"\n"];
        self.variableConfigString = [self.variableConfigString stringByAppendingString:iCode];
    }
        
    // copy the 'run' code
    NSRange runRange = [self.trimmedConfigString rangeOfString:@"run"];
    NSInteger fullLength = self.trimmedConfigString.length;
    runRange.length = fullLength - runRange.location;
    NSString* runCode = [self.trimmedConfigString substringWithRange:runRange];
    self.variableConfigString = [self.variableConfigString stringByAppendingString:@"\n"];
    self.variableConfigString = [self.variableConfigString stringByAppendingString:runCode];
    //NSBeep();
}

//-----------------------------------------------------------------------------

- (VConfigObject*) aggregateObject:(VConfigObject*)obj1 AndObject:(VConfigObject*)obj2 {
    
    VConfigObject* aggrObject = nil;
    
    if (obj1.objType == obj2.objType) {
        
        if ([obj1.objName isEqualToString:obj2.objName]) {
            
            NSMutableArray* obj1Params = obj1.objParameters;
            NSMutableArray* obj2Params = obj2.objParameters;
            NSMutableArray* aggrParams = [NSMutableArray arrayWithCapacity:0];
            [aggrParams addObjectsFromArray:obj1Params];
            [aggrParams addObjectsFromArray:obj2Params];
            
            aggrObject = [[VConfigObject alloc]init];
            aggrObject.objType = obj1.objType;
            aggrObject.objName = obj1.objName;
            aggrObject.objParameters = aggrParams;
            aggrObject.objCode = [aggrObject codeFromObject];
        }
    }
    return aggrObject;
}


//-----------------------------------------------------------------------------

-(void) rebuildObjectAndInstanceCodes {
    for (VConfigObject* obj in self.configObjects) {
        obj.objCode = [obj codeFromObject];
    }
    for (VConfigInstance* inst in self.configInstances) {
        inst.instanceCode = [inst codeFromInstance];
    }
}


//-----------------------------------------------------------------------------

-(void) moveObjectsOfArray:(NSMutableArray*) array FromRow:(NSInteger) fromRow ToRow:(NSInteger)toRow {
    id object = [array objectAtIndex:fromRow];
    [array removeObjectAtIndex:fromRow];
    [array insertObject:object atIndex:toRow];
}

//-----------------------------------------------------------------------------

@end
