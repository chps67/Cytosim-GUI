//
//  VDrawingGrid.m
//  Cytosim GUI
//
//  Created by Chris on 14/12/2024.
//

#import "VDrawingGrid.h"

@implementation VDrawingGrid

@synthesize gridScale, gridSide, gridLayer, axesLayer;

-(void) buildGrid {

    //-----  1st compute the grid's size in pixels

    NSInteger numSquares = self.gridSide.intValue;
    NSInteger squareSize = self.gridScale.intValue;
    NSInteger fieldSize = numSquares * squareSize;

    //----- now make the grid in dashed lines
    
    CAShapeLayer* grid = [CAShapeLayer layer];
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathRef immutablePath;
    
    for (int v = 0; v < numSquares; v++) {
        for (int h = 0; h < numSquares; h++) {
            CGRect aRect = CGRectMake(h * squareSize,v * squareSize, squareSize, squareSize);
            CGPathAddRect(path, NULL, aRect);
        }
    }
    
    immutablePath = CGPathCreateCopy(path);
    CGPathRelease(path);
    
    grid.path = immutablePath;
    grid.strokeColor = [[NSColor grayColor] CGColor];
    grid.fillColor = [[NSColor clearColor]CGColor];
    grid.lineDashPattern = @[@1, @7];
    
    self.gridLayer = grid;
    CGPathRelease(immutablePath);
    
    //----- add the axes with plain lines
    
    CAShapeLayer* axes = [CAShapeLayer layer];
    path = CGPathCreateMutable();
    NSInteger halfPos = fieldSize / 2;
    // x axis
    CGPathMoveToPoint(path, nil, 0, halfPos);
    CGPathAddLineToPoint(path, nil, fieldSize, halfPos);
    // y axis
    CGPathMoveToPoint(path, nil, halfPos, 0);
    CGPathAddLineToPoint(path, nil, halfPos, fieldSize);
    immutablePath = CGPathCreateCopy(path);
    CGPathRelease(path);
    axes.path = immutablePath;
    axes.strokeColor = [[NSColor grayColor] CGColor];
    axes.fillColor = [[NSColor clearColor]CGColor];
    axes.lineWidth = 1.5;
    self.axesLayer = axes;
    CGPathRelease(immutablePath);
}


@end
