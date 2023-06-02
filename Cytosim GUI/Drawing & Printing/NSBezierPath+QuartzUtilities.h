//
//  NSBezierPath+QuartzUtilities.h
//  BitMap_Editor
//
//  Created by Chris on 19/01/2020.
//  Copyright © 2020 Chris. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBezierPath (QuartzUtilities)

-(CGPathRef)quartzPath;
+(NSBezierPath *)bezierPathWithCGPath:(CGPathRef)cgPath; //prefixed as Apple may add bezierPathWithCGPath: method someday
-(NSPointArray) polygonWithBezierPath:(int*)numPoints;
-(BOOL) isClosed;
-(NSBezierPath*)copyPath;
@end

NS_ASSUME_NONNULL_END
