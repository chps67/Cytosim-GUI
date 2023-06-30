//
//  VConfigModelCreator.h
//  Cytosim GUI
//
//  Created by Chris on 15/05/2023.
//

#import <Foundation/Foundation.h>
#import "VConfigObject.h"
#import "VConfigInstance.h"

NS_ASSUME_NONNULL_BEGIN

@interface VConfigModelCreator : NSObject

@property (weak)    VConfigObject*  currentObject;
@property (weak)    VConfigInstance* currentInstance;
@property (strong)  NSMutableArray* configObjects;
@property (strong)  NSMutableArray* configInstances;

-(VConfigObject*) createSingle;
-(void) readParametersForObject:(VConfigObject*)object;
-(void) writeParametersForObject:(VConfigObject*)object;

@end

NS_ASSUME_NONNULL_END
