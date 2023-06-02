//
//  VConfigObject.h
//  Cytosim GUI
//
//  Created by Chris on 18/08/2022.
//

#import <Foundation/Foundation.h>

@class VOutlineItem;

NS_ASSUME_NONNULL_BEGIN

@class VConfigParameter;

@interface VConfigObject : NSObject

@property (strong) NSString* objType;
@property (strong) NSString* objName;
@property (strong) NSMutableArray* objParameters;
@property (strong) NSString* objCode;
@property (assign) NSRange objRange;


-(VConfigParameter*) parameterWithName:(NSString*)name;
-(BOOL) canVary;

-(NSString*) codeFromObject;
- (void) changeParameterNamed:(NSString*)paramName WithValue:(NSNumber*) newValue;
- (void) updateWithOutlineItem: (VOutlineItem*) item;
@end

NS_ASSUME_NONNULL_END
