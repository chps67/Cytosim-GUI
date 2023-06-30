//
//  VParamInterpolationImageView.m
//  Cytosim GUI
//
//  Created by Chris on 20/01/2023.
//

#import "VParamInterpolationImageView.h"


@implementation VParamInterpolationImageView

@synthesize var, leftBoundary, rightBoundary, bottomBoundary, topBoundary, meshSizeValueX, meshSizeValueY;


-(void) awakeFromNib {
    [self setWantsLayer:YES];
}


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    
    // 1st draw the grid and the axes.
    //--------------------------------
    // If there a single value (minX = maxX = minY = maxY), then start at minX /2 and extend to minX + minX/2
    // Otherwise extend/shrink the grid between minX and maxX if they are defined
    
    const NSInteger margin = 5;
    const float epsilon = 1e-4;

    [self.gridLayer removeFromSuperlayer];

    CAShapeLayer* grid = [CAShapeLayer layer];
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathRef immutablePath;
    
    // compute the grid's size
     if (self.var == nil)
        return;

    float dX = var.maxX.floatValue - var.minX.floatValue;
    float dY = var.maxY.floatValue - var.minY.floatValue;
    
    if (dX < epsilon) {
        self.leftBoundary = [NSNumber numberWithFloat:MIN(var.minX.floatValue /2,
                                                          var.minX.floatValue + var.minX.floatValue/2)];
        self.rightBoundary = [NSNumber numberWithFloat:MAX(var.minX.floatValue /2,
                                                           var.minX.floatValue + var.minX.floatValue/2)];
        if ((self.leftBoundary.floatValue == 0) && (self.rightBoundary.floatValue == 0)) {
            self.leftBoundary = @-1;
            self.rightBoundary = @1;
        }
    } else {
        self.leftBoundary = [NSNumber numberWithFloat:var.minX.floatValue];
        self.rightBoundary = [NSNumber numberWithFloat:var.maxX.floatValue];
        
        if ((self.leftBoundary.floatValue == 0) && (self.rightBoundary.floatValue == 0)) {
            self.leftBoundary = @-1;
            self.rightBoundary = @1;
        }
    }
    
    if ( dY < epsilon) {
        self.bottomBoundary = [NSNumber numberWithFloat:MIN(var.minY.floatValue /2,
                                                          var.minY.floatValue + var.minY.floatValue/2)];
        self.topBoundary = [NSNumber numberWithFloat:MAX(var.minY.floatValue /2,
                                                           var.minY.floatValue + var.minY.floatValue/2)];
        if ((self.bottomBoundary.floatValue == 0) && (self.topBoundary.floatValue == 0)) {
            self.bottomBoundary = @-1;
            self.topBoundary = @1;
        }
    } else {
        var.minY = (NSNumber*)var.variationValues.firstObject;
        var.maxY = (NSNumber*)var.variationValues.lastObject;
        self.bottomBoundary = [NSNumber numberWithFloat:var.minY.floatValue];
        self.topBoundary = [NSNumber numberWithFloat:var.maxY.floatValue];
        
        if ((self.bottomBoundary.floatValue == 0) && (self.topBoundary.floatValue == 0)) {
            self.bottomBoundary = @-1;
            self.topBoundary = @1;
        }
    }

    float gSizeX = [self gridSizeX];     // grid Size is always >0 (fabs call inside).
    self.meshSizeValueX = [NSNumber numberWithFloat:gSizeX];
    dX = self.rightBoundary.floatValue - self.leftBoundary.floatValue;
    float numLinesX = fabs(dX) / gSizeX;
    numLinesX = ceil(numLinesX) + 1;
    float viewFactorX = (self.frame.size.width - 2 * margin) / dX;
    
    float gSizeY = [self gridSizeY];     // grid Size is always >0 (fabs call inside).
    self.meshSizeValueY = [NSNumber numberWithFloat:gSizeY];
    dY = self.topBoundary.floatValue - self.bottomBoundary.floatValue;
    float numLinesY = fabs(dY) / gSizeY;
    numLinesY = ceil(numLinesY) + 1;
    float viewFactorY = (self.frame.size.height - 2 * margin) / dY;

    // BEWARE-----------------------------------------------------------------------------------------
    // Sometimes fmod gives weird results for numbers below 1. For example :
    // while it is supposed to send 0 for fmod(0.5, 0.1), it sends 0.1 !!!
    // This is because internal representation of 0.5 is slightly lower than 0.5 or because that
    // of 0.1 is slightly higher than 0.1 (or both). Thus 0.5 cannot hold 5 times 0.1 but a little less
    // and hence the result is the remainder (something that is very close to 0.1).
    // i.e. the division fails to count the exact number of divisors and returns the divisor value
    // SIMPLE WORKAROUND:
    // In case of values < 1.0, premultiply the value by 1/gridSquareSize,
    // find the remainder after division by 1/gridSquareSize and multiply the result by gridSquareSize
    // as fmod now works with values higher than 1, we pass it rounded arguments to get rid of the approximation problem
    //------------------------------------------------------------------------------------------------
    // float offsetX = fabs(fmod(self.leftBoundary.floatValue, gridSquareSize)); // older code (sometimes goes wrong)
    
    float pX, modX, prem, offsetX;
    prem = roundf(1.0 / gSizeX);
    if (self.leftBoundary.floatValue < 1.0) {
        pX = roundf(self.leftBoundary.floatValue * prem);
        modX = fmod(pX, roundf(gSizeX * prem));
        offsetX = modX * gSizeX;
    } else {
        offsetX = fmod(roundf(self.leftBoundary.floatValue), roundf(gSizeX));
    }
    float linePixX = gSizeX * viewFactorX;
    float firstLinePixX = offsetX * viewFactorX;
    
    float pY, modY, offsetY;
    prem = roundf(1.0 / gSizeY);
    if (self.bottomBoundary.floatValue < 1.0) {
        pY = roundf(self.bottomBoundary.floatValue * prem);
        modY = fmod(pY, roundf(gSizeY * prem));
        offsetY = modY * gSizeY;
    } else {
        offsetY = fmod(roundf(self.bottomBoundary.floatValue), roundf(gSizeY));
    }
    float linePixY = gSizeY * viewFactorY;
    float firstLinePixY = offsetY * viewFactorY;
    
    // tells the VParamVariationsManager that the boundaries and the mesh size have been updated
    [[NSNotificationCenter defaultCenter] postNotificationName:@"paramUpdated" object:nil];

    // Add the vertical lines
    for (int h = 0; h < numLinesX; h++) {
        float x = firstLinePixX + h * linePixX;
        if (x <= (self.frame.size.width - margin)) {
            CGRect aRect = CGRectMake(x + margin, margin, 0, self.frame.size.height - 2 * margin);
            CGPathAddRect(path, NULL, aRect);
        }
    }
    // Add the horizontal lines
    for (int v = 0; v < numLinesY; v++) {
        float y = firstLinePixY + v * linePixY;
        if (y <= (self.frame.size.height - margin)) {
            CGRect aRect = CGRectMake(margin, y + margin, self.frame.size.width - 2 * margin, 0 );
            CGPathAddRect(path, NULL, aRect);
        }
    }

    immutablePath = CGPathCreateCopy(path);
    CGPathRelease(path);
    
    grid.path = immutablePath;
    grid.strokeColor = [[NSColor grayColor] CGColor];
    grid.fillColor = [[NSColor clearColor]CGColor];
    grid.lineDashPattern = @[@1, @7];
    [self.layer addSublayer:grid];
    self.gridLayer = grid;
    CGPathRelease(immutablePath);
    
    //----------------------------------------------
    // Draw the interpolated curve
    //----------------------------------------------

    [self.curveLayer removeFromSuperlayer];

    if (var.variationType != randomType) {

        CAShapeLayer* curve = [CAShapeLayer layer];
        path = CGPathCreateMutable();
        const NSInteger numCurvePoints = 50;

        if (var.numberOfValues.integerValue > 1) {
            float xStep = (var.maxX.floatValue - var.minX.floatValue) / (numCurvePoints - 1);
            float x = var.minX.floatValue;
            NSNumber* iPt = [var valueForStep:[NSNumber numberWithFloat:x]];
            CGPoint prevPoint = CGPointMake((x - self.leftBoundary.floatValue) * viewFactorX, (iPt.floatValue- self.bottomBoundary.floatValue) * viewFactorY);
            CGPathMoveToPoint(path, nil, prevPoint.x + margin, prevPoint.y +margin);

            for (NSInteger k = 1; k < numCurvePoints; k++) {
                x += xStep;
                float xPix = fabs(x - self.leftBoundary.floatValue) * viewFactorX;
                iPt = [var valueForStep:[NSNumber numberWithFloat:x]];
                float yPix = fabs(iPt.floatValue - self.bottomBoundary.floatValue) * viewFactorY;
                CGPathAddLineToPoint(path, nil, xPix + margin, yPix + margin);
            }
        }

        immutablePath = CGPathCreateCopy(path);
        CGPathRelease(path);
        curve.path = immutablePath;
        curve.strokeColor = [[NSColor grayColor] CGColor];
        curve.fillColor = [[NSColor clearColor] CGColor];
        [self.layer addSublayer:curve];
        self.curveLayer = curve;
    }

    //----------------------------------------------
    // Draw the points
    //----------------------------------------------

    [self.pointsLayer removeFromSuperlayer];
    CAShapeLayer* points = [CAShapeLayer layer];
    path = CGPathCreateMutable();
    const float pointSize = 4.0;

    if (var.numberOfValues.integerValue >= 2) {
        float xStep = (var.maxX.floatValue - var.minX.floatValue)/(var.numberOfValues.integerValue - 1);
        float x = var.minX.floatValue;

        for (NSInteger k = 0; k < var.variationValues.count; k++) {
            NSNumber* iPt = (NSNumber*)[var.variationValues objectAtIndex:k];
            float xPix = fabs(x - self.leftBoundary.floatValue) * viewFactorX;
            float yPix = fabs(iPt.floatValue - self.bottomBoundary.floatValue) * viewFactorY;
            CGRect point = CGRectMake(xPix + margin - pointSize/2, yPix + margin - pointSize/2, pointSize, pointSize);
            CGPathAddRect(path, nil, point);
            x += xStep;
        }
    }
    else {
        NSNumber* iPt = (NSNumber*)[var.variationValues firstObject];
        if (iPt) {
            float xPix = fabs(iPt.floatValue - self.leftBoundary.floatValue) * viewFactorX;
            CGRect point = CGRectMake(xPix + margin - pointSize/2, xPix +margin - pointSize/2, pointSize, pointSize);
            CGPathAddRect(path, nil, point);
        }
    }


    immutablePath = CGPathCreateCopy(path);
    CGPathRelease(path);
    points.path = immutablePath;
    points.strokeColor = [[NSColor labelColor] CGColor];
    points.fillColor = [[NSColor labelColor]CGColor];
    [self.layer addSublayer:points];
    self.pointsLayer = points;

}

//------------------------------------------------------------------------------------------------
// Tested in "Grid_Size.xlsx" from the Simulations folder
// +++++ beware that arrondi.inf goes to higher values when log10 <0 in the excel file (unlike floor())
//------------------------------------------------------------------------------------------------

//------------------------------------------------------------------------------------------------

-(float) gridSizeX {
    float midX, dX;

    dX = self.rightBoundary.floatValue - self.leftBoundary.floatValue;
    midX = dX/2;
    
    float flog = floor(log10(midX));
    float answer;
    answer = powf(10,flog);
    return fabs(answer);
}

-(float) gridSizeY {
    float midY, dY;

    dY = self.topBoundary.floatValue - self.bottomBoundary.floatValue;
    midY = dY/2;
    
    float flog = floor(log10(midY));
    float answer;
    answer = powf(10,flog);
    return fabs(answer);
}

@end
