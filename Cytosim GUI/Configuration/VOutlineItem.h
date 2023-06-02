//
//  VOutlineItem.h
//  Cytosim GUI
//
//  Created by Chris on 27/02/2023.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class VConfigObject;
@class VConfigInstance;
@class VConfigParameter;
@class VConfigurationModel;

@interface VOutlineItem : NSObject

// NSOutline properties (mandatory)
@property (assign) BOOL                             expandable;
@property (retain) VOutlineItem*        _Nullable   parent;         // Parent (for siblings only).
@property (retain) NSMutableArray*      _Nullable   children;       // Siblings. Although items are retained elsewhere,
                                                                    // set .children with a retain attribute  as it is a mutable object.

// The actual parameter object with its own variations
@property (strong) VConfigParameter*                configParameter; // default getter and setter 




// object's methods
- (instancetype) initWithInstanceTitle:(VConfigInstance*)inst;
- (instancetype) initWithObjectTitle:(VConfigObject*)object;
- (instancetype) initWithParameter:(VConfigParameter*)param;

// NSOutlineView mandatory methods
- (NSInteger) numberOfChildren;
- (VOutlineItem*) childAtIndex:(NSUInteger)n;
- (VOutlineItem*) ancestor;
- (BOOL) isParentObject;

@end

NS_ASSUME_NONNULL_END
