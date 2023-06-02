//
//  NSBezierPath+QuartzUtilities.m
//  BitMap_Editor
//
//  Created by Chris on 19/01/2020.
//  Copyright © 2020 Chris. All rights reserved.
//

#import "NSBezierPath+QuartzUtilities.h"

@implementation NSBezierPath (QuartzUtilities)

//====================================================================================================================

// from apple sample code

- (CGPathRef) quartzPath {
    
    int                 i, numElements;
    CGPathRef           immutablePath = NULL;
    
    numElements = (int)[self elementCount];
    if (numElements > 0)
    {
        NSPoint             points[3];
        BOOL                didClosePath = YES;
        CGMutablePathRef    path = CGPathCreateMutable();

        for (i = 0; i < numElements; i++)
        {
            switch ([self elementAtIndex:i associatedPoints:points])
            {
                case NSBezierPathElementMoveTo:
                    CGPathMoveToPoint(path, NULL, points[0].x, points[0].y);
                    break;
 
                case NSBezierPathElementLineTo:
                    CGPathAddLineToPoint(path, NULL, points[0].x, points[0].y);
                    didClosePath = NO;
                    break;
 
                case NSBezierPathElementCurveTo:
                    CGPathAddCurveToPoint(path, NULL, points[0].x, points[0].y,
                                        points[1].x, points[1].y,
                                        points[2].x, points[2].y);
                    didClosePath = NO;
                    break;
 
                case NSBezierPathElementClosePath:
                    CGPathCloseSubpath(path);
                    didClosePath = YES;
                    break;
            }
        }
        immutablePath = CGPathCreateCopy(path);
        CGPathRelease(path);
    }
    return immutablePath;
}

//====================================================================================================================

// From Bob Ueland (found on stackoverflow)

+ (NSBezierPath *) bezierPathWithCGPath:(CGPathRef)cgPath {
    NSBezierPath *bezierPath = [NSBezierPath bezierPath];
    CGPathApply(cgPath, (__bridge void *)bezierPath, CGPathCallback);
    return bezierPath;
}

static void CGPathCallback(void *info, const CGPathElement *element) {
    NSBezierPath *bezierPath = (__bridge NSBezierPath *)info;
    CGPoint *points = element->points;
    switch(element->type) {
        case kCGPathElementMoveToPoint: [bezierPath moveToPoint:points[0]]; break;
        case kCGPathElementAddLineToPoint: [bezierPath lineToPoint:points[0]]; break;
        case kCGPathElementAddQuadCurveToPoint: {
            NSPoint qp0 = bezierPath.currentPoint, qp1 = points[0], qp2 = points[1], cp1, cp2;
            CGFloat m = (2.0 / 3.0);
            cp1.x = (qp0.x + ((qp1.x - qp0.x) * m));
            cp1.y = (qp0.y + ((qp1.y - qp0.y) * m));
            cp2.x = (qp2.x + ((qp1.x - qp2.x) * m));
            cp2.y = (qp2.y + ((qp1.y - qp2.y) * m));
            [bezierPath curveToPoint:qp2 controlPoint1:cp1 controlPoint2:cp2];
            break;
        }
        case kCGPathElementAddCurveToPoint: [bezierPath curveToPoint:points[2] controlPoint1:points[0] controlPoint2:points[1]]; break;
        case kCGPathElementCloseSubpath: [bezierPath closePath]; break;
    }
}

//====================================================================================================================

-(NSPointArray) polygonWithBezierPath:(int*)numPoints {
    NSPoint         points[3];
    NSPointArray    poly = nil;
    int             numElements = (int)[self elementCount];
    
    if (numElements > 0) {
        poly = (NSPointArray)calloc(numElements, sizeof(NSPoint));

        for (int i = 0; i < numElements; i++) {
           
           switch ([self elementAtIndex:i associatedPoints:points]) {
            case NSBezierPathElementMoveTo:
                break;

            case NSBezierPathElementLineTo:
                poly[i] = points[0];
                break;
               
           case NSBezierPathElementCurveTo:
               poly[i] = points[2];
               break;
               
           case NSBezierPathElementClosePath:
               break;
           }
        }
    }
    *numPoints = numElements;
    return poly;
}

//====================================================================================================================

-(BOOL) isClosed {
    int  numElements = (int)[self elementCount];
    NSBezierPathElement command;
    BOOL foundClosed = NO;
    for (int i=0; i<numElements; i++) {
        command = [self elementAtIndex:i];
        if (command == NSBezierPathElementClosePath) {
            foundClosed = YES;
            break;
        }
    }
    return foundClosed;
}

//====================================================================================================================

-(NSBezierPath*)copyPath {
    NSBezierPath* newPath = [NSBezierPath bezierPath];
    return newPath;
}

@end
