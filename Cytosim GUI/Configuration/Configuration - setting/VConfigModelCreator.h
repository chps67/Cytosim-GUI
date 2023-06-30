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

@property (strong)  NSMutableArray* configObjects;
@property (strong)  NSMutableArray* configInstances;

@property (strong) VConfigObject* __nullable currObj;

-(VConfigObject*) createSingle;
-(void) readParametersFromCurrentObject;
-(void) writeParametersToCurrentObject;

@end

NS_ASSUME_NONNULL_END
