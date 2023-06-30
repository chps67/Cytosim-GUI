//
//  VModelDrawingView.m
//  Cytosim GUI
//
//  Created by Chris on 18/12/2022.
//

#import "VModelDrawingView.h"
#import "VAppDelegate.h"

@implementation VModelDrawingView

/*==================================================================================*/

- (void)initialize
{
    if (self) {
        self.image = nil;
        self.wantsLayer = YES;

        NSRect updtFrame = [self frame];
        NSTrackingArea* trackingArea = [[NSTrackingArea alloc] initWithRect:updtFrame
                        options: (NSTrackingMouseMoved |NSTrackingMouseEnteredAndExited |
                        NSTrackingInVisibleRect | NSTrackingActiveInActiveApp | NSTrackingEnabledDuringMouseDrag)
                        owner:self userInfo:nil];
        [self addTrackingArea:trackingArea];
        
        VAppDelegate* del = (VAppDelegate*)(NSApp.delegate);
        del.modelScale = @50;            // default = 50 pixels by micron
        del.modelNumMicrons = @10;       // default = 10 µm i.e 500 pixels wide and high
        [self addGrid:self];
        
        self.window.documentEdited = NO;
    }
}

/*==================================================================================*/

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

/*==================================================================================*/

-(void) mouseMoved:(NSEvent*) theEvent {
    
    NSPoint movedPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    VAppDelegate* del = (VAppDelegate*)(NSApp.delegate);

    NSInteger halfSize = del.modelNumMicrons.intValue * del.modelScale.intValue / 2;
    float newX = (floor(movedPoint.x) - halfSize)/del.modelScale.floatValue;
    float newY = (floor(movedPoint.y) - halfSize)/del.modelScale.floatValue;
    del.xModelValue = [NSNumber numberWithFloat: newX];
    del.yModelValue = [NSNumber numberWithFloat: newY];
}

/*==================================================================================*/

-(void) showGrid {
    
    VAppDelegate* del = (VAppDelegate*)(NSApp.delegate);

    //-----  1st resize the frame of the drawing view to make it fit the fieldSize and scale values

    NSInteger numSquares = del.modelNumMicrons.intValue;
    NSInteger fieldSize = numSquares * del.modelScale.intValue;
    self.frame = NSMakeRect(0, 0, fieldSize, fieldSize);
    
    //----- now make the grid in dashed lines
    
    CAShapeLayer* grid = [CAShapeLayer layer];
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathRef immutablePath;
    
    for (int v = 0; v < numSquares; v++) {
        for (int h = 0; h < numSquares; h++) {
            CGRect aRect = CGRectMake(h * del.modelScale.intValue,v * del.modelScale.intValue,
                                      del.modelScale.intValue, del.modelScale.intValue);
            CGPathAddRect(path, NULL, aRect);
        }
    }
    
    immutablePath = CGPathCreateCopy(path);
    CGPathRelease(path);
    
    grid.path = immutablePath;
    grid.strokeColor = [[NSColor grayColor] CGColor];
    grid.fillColor = [[NSColor clearColor]CGColor];
    grid.lineDashPattern = @[@1, @7];
    
    self.gridVisible = YES;
    [self.layer addSublayer:grid];
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
    [self.layer addSublayer:axes];
    self.axesLayer = axes;
    CGPathRelease(immutablePath);
    
}

/*==================================================================================*/

-(void) removeGrid {
    [self.gridLayer removeFromSuperlayer];
    [self.axesLayer removeFromSuperlayer];
    self.gridVisible = NO;
}

/*==================================================================================*/

-(IBAction) addGrid: (id)sender {

    if (! self.gridVisible) {
        [self showGrid];
        return;
    } else {
        [self removeGrid];
    }
}

-(void) updateGrid {
    [self removeGrid];
    [self showGrid];
}

@end
