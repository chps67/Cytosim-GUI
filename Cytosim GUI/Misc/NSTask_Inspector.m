//
//  NSControl_Inspector.m
//  Cytosim GUI
//
//  Created by Chris on 26/02/2023.
//

#import "NSTask_Inspector.h"

@implementation NSTask_Inspector

- (instancetype) initWithTask:(NSTask*) aTask
{
    self = [super init];
    if (self) {
        self.iRunning = aTask.isRunning;
        if (! self.iRunning) {
            self.iTerminationStatus = aTask.terminationStatus;
            self.iTerminationReason = aTask.terminationReason;
        }
        self.iArguments = aTask.arguments;
        self.iProcessIdentifier = aTask.processIdentifier;
    }
    return self;
}

@end
