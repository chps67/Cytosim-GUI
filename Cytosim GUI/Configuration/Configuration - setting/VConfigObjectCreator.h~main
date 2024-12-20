//
//  VConfigObjectCreator.h
//  Cytosim GUI
//
//  Created by Chris on 30/08/2022.
//

#import <Cocoa/Cocoa.h>

#import "VCymParameter.h"
#import "VConfigObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface VConfigObjectCreator : NSObject <NSOutlineViewDataSource, NSOutlineViewDelegate>

// a mutable dic that contains the config object parameters arrays read from the .plist files
@property (strong) NSMutableDictionary* configObjectsDic;

// the current array to be displayed in the NSOutlineView, picked into the 'configObjectsDic' dictionary
@property (strong) NSMutableArray* paramDataSource;

@property (assign) NSNumber* readyForCodeInsertion;   // boolean to control the enabling of the 'Insert code' button


- (void) preloadCymObjectFiles;
- (void) initializeDataSource:(NSString*)cymObjectName;
- (void) distributeIconsOnLine:(NSInteger)lineNumber reqIcons:(NSInteger)iconsPerLine;
- (IBAction) choseHelpIconValue: (id) sender;
- (IBAction) changeParameterColor: (id) sender;
- (NSString*) templateText;

- (void) readPropFromObject:(VConfigObject*)object;
- (void) writePropToObject:(VConfigObject*)object;
@end

NS_ASSUME_NONNULL_END
