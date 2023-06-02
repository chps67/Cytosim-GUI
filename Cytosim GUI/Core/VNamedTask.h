//
//  VNamedTask.h
//  Model class
//  Cytosim For OSX
//
//  Created by Chris on 12/06/2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VNamedTask : NSObject

// The Cocoa task object
@property (retain) NSTask* theTask;

// Since NSTask does not have an encapsulated name, this string should appear
// in the NSPopUpButton that lists all the tasks lauched that are still alive
// and allows to select one of them.
@property (retain) NSString* theName;

// Another important feature is Darwin's process identification
// which is available from NSRunningApplication.
// Hodling a copy of it after each application launching suggests
// that applications with unique IDs (i.e. multiple versions of 'play')
// could be re-ordered programmatically.
// too bad. Fails.
@property (assign) pid_t appProcessID;

// Booleans to control the stop pause and play buttons of
// the control center via IB bindings.
@property (assign) NSNumber* isRunning;
@property (assign) NSNumber* isPaused;

// Boolean to control the 2D vs 3D flag
@property (assign) NSNumber* playIn3D;

// Boolean to record if the task was stopped by the user
// To prevent displaying OpenGL/ Cocoa internal errors in the Log
@property (assign) NSNumber* stoppedByUser;

// time flow variables
@property (assign) NSDate* launchDate;
@property (assign) NSDate* suspensionDate;
@property (assign) NSDate* resumptionDate;
@property (assign) NSDate* stopDate;
@property (assign) NSTimeInterval totalPausedTime;
@property (assign) NSTimeInterval elapsedTime;


// total elapsed time computation
- (void) updateTimeFlow;
- (NSTimeInterval) totalElapsedTime;

@end

NS_ASSUME_NONNULL_END
