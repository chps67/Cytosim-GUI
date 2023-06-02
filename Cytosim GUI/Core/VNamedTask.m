//
//  VNamedTask.m
//  Cytosim For OSX
//
//  Created by Chris on 12/06/2022.
//

#import "VNamedTask.h"

@implementation VNamedTask

@synthesize theTask, theName, isRunning, isPaused, stoppedByUser,
            launchDate, suspensionDate, resumptionDate, stopDate, totalPausedTime, elapsedTime;


// init
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.launchDate = [NSDate date];
        self.suspensionDate = [NSDate date];
        self.resumptionDate = [NSDate date];
        self.stopDate = [NSDate date];
        self.totalPausedTime = 0.0;
        self.elapsedTime = 0.0;
    }
    return self;
}

- (void) updateTimeFlow {
    self.totalPausedTime += [self.resumptionDate timeIntervalSinceDate: self.suspensionDate];
}

- (NSTimeInterval) totalElapsedTime {
    self.elapsedTime = [self.stopDate timeIntervalSinceDate:self.launchDate];
    self.elapsedTime -= self.totalPausedTime;
    return self.elapsedTime;
}

@end
