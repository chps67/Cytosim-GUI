//
//  NSControl_Inspector.h
//  Cytosim GUI
//
//  Created by Chris on 26/02/2023.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSTask_Inspector : NSTask

@property (assign)  BOOL iRunning;
@property (assign)  double iTerminationStatus;
@property (assign)  float iTerminationReason;
@property (weak)    NSArray* iArguments;
@property (assign)  NSInteger iProcessIdentifier;

- (instancetype) initWithTask:(NSTask*) aTask;

@end
NS_ASSUME_NONNULL_END
