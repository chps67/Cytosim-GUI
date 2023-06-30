//
//  VCymParameter.h
//  NSOutlineView view-based Implementation
//  The contents is created after reading of .plist files that contain dictionaries, one for the values, the other for the help strings
//  This is the object that will be used to fill one row of the outline View (either root alone, root and parent or child)
//  The data Source will consist of a NSMutableArray of VCymParameter
//  Created by Chris on 06/07/2022.
//

#import <Foundation/Foundation.h>
#import "OrderedDictionary.h"

NS_ASSUME_NONNULL_BEGIN

@interface VCymParameter : NSObject <NSCopying>
    
@property (assign) NSNumber* used;                          // to determine whether to insert or not into a snippet.
@property (copy)   NSString* cymKey;                        // the dictionary's key (a copy of it).
@property (copy)   NSString* _Nullable cymKeyHelpString;    // the cytosim optional help string.
@property (retain) id cymValueObject;                       // the dictionary's object (NSNumber, NSString or a deeper NSDictionary..)
@property (copy)   NSString* cymValueString;                // the dictionary's object converted into a string.
@property (retain) VCymParameter* _Nullable parent;         // parent (for siblings only).
@property (retain) NSMutableArray* _Nullable children;      // siblings. retain as it is a mutable object.

// creation, children extraction and count, parent determination and functions for NSOutlineView display
+ (VCymParameter*)initWithKey:(NSString*)aKey HelpString:(NSString* _Nullable)aHelpStr Value:(id)aValue;
- (NSInteger)numberOfChildren;
- (VCymParameter*)childAtIndex:(NSUInteger)n;
- (VCymParameter*)ancestor;
- (BOOL)isParentObject;
- (void)cymValueFromObject;
- (NSString*)cymParameterToString;  // string extraction for building cytosim configuration file
- (NSString*) trimmedCymKey;        // remove owner's names and return a copy of the cymKey to display to the user
- (NSString*) ownerName;            // send owner's name without changing cymKey

@end

NS_ASSUME_NONNULL_END
