//
//  VConfigObject.h
//  Cytosim GUI
//
//  Created by Chris on 18/08/2022.
//

//#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@class VOutlineItem;

NS_ASSUME_NONNULL_BEGIN

@class VConfigParameter;

@interface VConfigObject : NSObject

@property (strong) NSString* objType;
@property (strong) NSString* objName;
@property (strong) NSMutableArray* objParameters;
@property (strong) NSString* objCode;

// only for reading from config files
@property (assign) NSRange objRange;

// for drawing objects
@property (strong) NSBezierPath*    objPath;
@property (strong) CAShapeLayer*    objLayer;
@property (strong) NSColor*         objColor;
@property (assign) NSInteger        objOrientation;    // rotates CW between 0 (north) and 3 (west)

// for referencing siblings and parents
// for example a couple is a parent with 3 children: 2 hands and a linker
@property (strong) VConfigObject*   __nullable parent;
@property (strong) NSMutableArray*  __nullable children;

-(VConfigParameter*) parameterWithName:(NSString*)name;
-(BOOL) canVary;

-(NSString*) codeFromObject;
- (void) changeParameterNamed:(NSString*)paramName WithValue:(NSNumber*) newValue;
- (void) updateWithOutlineItem: (VOutlineItem*) item;
@end

NS_ASSUME_NONNULL_END
