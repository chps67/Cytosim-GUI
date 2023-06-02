//
//  VConfigInstance.h
//  Cytosim GUI
//
//  Created by Chris on 18/08/2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class VConfigParameter;

@interface VConfigInstance : NSObject

@property (strong) NSNumber* instanceNumber;
@property (strong) NSString* instanceName;
@property (strong) NSMutableArray* instanceParameters;  // array of VConfigParameters
@property (strong) NSString* instanceCode;
@property (assign) NSRange instanceRange;

-(VConfigParameter*) parameterWithName:(NSString*)name;
-(void) changeParameterNamed:(NSString*)paramName WithValue:(NSNumber*) newValue;
-(void) changeCountWithValue:(NSNumber*) newValue;
-(BOOL) canVary;
-(NSString*) codeFromInstance;
@end

NS_ASSUME_NONNULL_END
