//
//  VDrawingView.m
//  Cytosim GUI
//
//  Created by Chris on 16/10/2022.
//

#import "VPolygonDrawingView.h"
#import "VAppDelegate.h"
#import "VPrintableView.h"
#import "NSBezierPath+QuartzUtilities.h"

@implementation VPolygonDrawingView

/*==================================================================================*/

- (void)initialize
{
    if (self) {
        self.image = nil;
        self.polygon = (NSPointArray)calloc(3000, sizeof(NSPoint));
        self.numPoints = 0;
        self.handleSize = 6;
        self.selColor = [NSColor redColor];
        self.isClosed = NO;
        self.isBuilding = NO;
        self.curPath = [NSBezierPath bezierPath];
        self.wantsLayer = YES;
        [self addPolygonLayer];
        [self addHandleLayer];
        self.dragHandle = NO;
        self.dragSelection = NO;

        NSRect updtFrame = [self frame];
        NSTrackingArea* trackingArea = [[NSTrackingArea alloc] initWithRect:updtFrame
                        options: (NSTrackingMouseMoved |NSTrackingMouseEnteredAndExited |
                        NSTrackingInVisibleRect | NSTrackingActiveInActiveApp | NSTrackingEnabledDuringMouseDrag)
                        owner:self userInfo:nil];
        [self addTrackingArea:trackingArea];
        
        VAppDelegate* del = (VAppDelegate*)(NSApp.delegate);
        del.polygonScale = @50;            // default = 50 pixels by micron
        del.polygonNumMicrons = @10;       // default = 10 µm i.e 500 pixels wide and high
        [self addGrid:self];
        
        self.currentPolygonZoom = 1.0;
        self.window.documentEdited = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeSelColor) name:NSColorPanelColorDidChangeNotification object:nil];
    }
}

/*==================================================================================*/

-(void) polygonToPath {
    // build the path at the file's scale
    [self.curPath removeAllPoints];
    [self.curPath moveToPoint:self.polygon[0]];
    if (self.numPoints > 1) {
        for (int i=1; i<self.numPoints; i++){
            [self.curPath lineToPoint:self.polygon[i]];
        }
    }
    if (self.isClosed) {
        [self.curPath closePath];
    }
}

/*==================================================================================*/

-(NSString*) polygonToString {
    
    NSString* poly = @"";
    NSString* point = @"";
    VAppDelegate* del = (VAppDelegate*)NSApp.delegate;
    NSInteger halfSize = del.polygonNumMicrons.intValue * del.polygonScale.intValue / 2;

    if (self.numPoints > 0) {
        for (int i = 0; i < self.numPoints; i++){
            point = @"";
            
            float scaledX = (self.polygon[i].x - halfSize)/del.polygonScale.floatValue;
            NSNumber* xf = [NSNumber numberWithFloat:scaledX];
            float scaledY = (self.polygon[i].y - halfSize)/del.polygonScale.floatValue;
            NSNumber* yf = [NSNumber numberWithFloat:scaledY];
            
            point = [point stringByAppendingString:[xf stringValue]];
            point = [point stringByAppendingString:@" "];
            point = [point stringByAppendingString:[yf stringValue]];
            if (i < (self.numPoints -1))
                point = [point stringByAppendingString:@"\n"];
            
            poly = [poly stringByAppendingString:point];
        }
    }

    return poly;
}

/*==================================================================================*/

-(void) stringToPolygon:(NSString*) theString {
    
    theString = [self removeComments:theString];
    
    VAppDelegate* del = (VAppDelegate*)NSApp.delegate;
    NSArray* lines = [theString componentsSeparatedByString:@"\n"];
    NSPoint p;
    NSPoint minP = NSZeroPoint, maxP = NSZeroPoint;
    self.numPoints = 0;

    // build polygon backbone, without scaling first....
    NSCharacterSet* tabSet = [NSCharacterSet characterSetWithCharactersInString:@"\t"];
    NSCharacterSet* spcSet = [NSCharacterSet characterSetWithCharactersInString:@" "];

    for (int k=0; k<lines.count; k++) {
        NSString* li = [lines objectAtIndex:k];
        NSArray* coord = [li componentsSeparatedByCharactersInSet:tabSet];
        if (coord.count == 1) {
            coord = [li componentsSeparatedByCharactersInSet:spcSet];
        }
        NSMutableArray* mutCoord = [NSMutableArray arrayWithArray:coord];
        NSMutableArray* trimmedCoord = [NSMutableArray arrayWithCapacity:0];
        for (NSString* s in mutCoord) {
            if (( ! [s isEqualToString:@" "]) && ( ! [s isEqualToString:@"\t"]) && (( ! [s isEqualToString:@""])) )
                [trimmedCoord addObject:s];
        }
        coord = [NSArray arrayWithArray:trimmedCoord];
        if (coord.count == 2) {
            NSString* sX = coord.firstObject;
            NSString* sY = coord.lastObject;
            p.x = [sX floatValue];  // cell coordinates, should be converted into pixel coordinates later
            p.y = [sY floatValue];
            self.polygon[self.numPoints++] = p;
            [self comparePoint:p WithMinPoint:&minP AndMaxPoint:&maxP];
        }
    }
    
    self.isClosed = YES;
    self.isBuilding = NO;

    self.frame = NSMakeRect(0, 0, del.polygonNumMicrons.floatValue * del.polygonScale.floatValue, del.polygonNumMicrons.floatValue * del.polygonScale.floatValue);
    float zeroPos = del.polygonScale.floatValue * del.polygonNumMicrons.floatValue / 2.0;
    for (int k=0; k<lines.count; k++) {
        self.polygon[k].x = (self.polygon[k].x * del.polygonScale.floatValue) + zeroPos;
        self.polygon[k].y = (self.polygon[k].y * del.polygonScale.floatValue) + zeroPos;
    }
    [self polygonToPath];
    [self redrawSelection];
}


-(void) comparePoint: (NSPoint)p WithMinPoint:(NSPoint*) minP AndMaxPoint:(NSPoint*) maxP {
    if (p.x < minP->x)
        minP->x = p.x;
    if (p.y < minP->y)
        minP->y = p.y;
    if (p.x > maxP->x)
        maxP->x = p.x;
    if (p.y > maxP->y)
        maxP->y = p.y;
}

-(NSString*) removeComments:(NSString*) aString {
    
    NSArray* lines = [aString componentsSeparatedByString:@"\n"];
    for (NSString* line in lines) {
        //comments that start with'%'
        if ([line hasPrefix:@"%"]) {
            NSRange lineRange = [aString rangeOfString:line];
            lineRange.length++; // to encompass the \n at the end
            NSString* comment = [aString substringWithRange:lineRange];
            aString = [aString stringByReplacingOccurrencesOfString:comment withString:@""];
        }
    }
    
    return aString;
}

/*==================================================================================*/

-(CGPathRef) makeHandleCGPath {
    int         i, numElements;
    NSInteger   hRadius = self.handleSize/2;
    numElements = (int)[self.curPath elementCount];
    CGPathRef   handles = NULL;
    NSRect      handleRect;
    
    if (numElements > 0) {
        CGMutablePathRef    path = CGPathCreateMutable();
        NSPoint             points[3];

        for (i = 0; i < numElements; i++){
            switch ([self.curPath elementAtIndex:i associatedPoints:points])
            {
                case NSBezierPathElementMoveTo:
                    handleRect = NSMakeRect(points[0].x-hRadius,points[0].y-hRadius,2*hRadius,2*hRadius);
                    CGPathAddRect(path, NULL, handleRect);
                    break;

                case NSBezierPathElementLineTo:
                    handleRect = NSMakeRect(points[0].x-hRadius,points[0].y-hRadius,2*hRadius,2*hRadius);
                    CGPathAddRect(path, NULL, handleRect);
                    break;

                case NSBezierPathElementCurveTo:
                    handleRect = NSMakeRect(points[2].x-hRadius,points[2].y-hRadius,2*hRadius,2*hRadius);
                    CGPathAddRect(path, NULL, handleRect);
                    break;
                
                case NSBezierPathElementClosePath: break;
            }
        }
        handles = CGPathCreateCopy(path);
        CGPathRelease(path);
    }
    return handles;
}

/*==================================================================================*/

-(void) addFloatingPoint:(NSPoint)p {
    // reset the path using poygon points
    [self.curPath removeAllPoints];
    [self polygonToPath];
    // add a point to the path without adding it to the polygon (floating point)
    [self.curPath lineToPoint:p];
}

/*==================================================================================*/

-(void) clearAllDrawing {
    [self.curPath removeAllPoints];
    self.numPoints = 0;
    self.polygon = (NSPointArray)calloc(3000, sizeof(NSPoint));
    self.isClosed = NO;
    self.isBuilding = NO;
    [self redrawSelection];
    
    VAppDelegate* del = (VAppDelegate*)NSApp.delegate;
    del.savePolygonButton.enabled = NO;
    del.clearButton.enabled = NO;
    self.window.documentEdited = NO;
}

/*==================================================================================*/
// scale by a user input zoomFactor with the scaling center being the barycenter of the polygon

-(void) scalePolygon {
    
    VAppDelegate* del = (VAppDelegate*)NSApp.delegate;
    float oldZoomFactor = self.currentPolygonZoom;
    float newZoomFactor = del.polygonZoom.floatValue;
    if (newZoomFactor != 1.0) {
        //float halfPos = del.polygonScale.floatValue * del.polygonNumMicrons.floatValue / 2.0;
        NSPoint baryCenter = NSZeroPoint;
        for (int k=0; k<self.numPoints; k++) {
            baryCenter.x += self.polygon[k].x;
            baryCenter.y += self.polygon[k].y;
        }
        baryCenter.x /= self.numPoints;
        baryCenter.y /= self.numPoints;
        for (int k=0; k<self.numPoints; k++) {
            self.polygon[k].x = ((self.polygon[k].x - baryCenter.x) / oldZoomFactor) + baryCenter.x;
            self.polygon[k].y = ((self.polygon[k].y - baryCenter.y) / oldZoomFactor) + baryCenter.y;
            self.polygon[k].x = ((self.polygon[k].x - baryCenter.x) * newZoomFactor) + baryCenter.x;
            self.polygon[k].y = ((self.polygon[k].y - baryCenter.y) * newZoomFactor) + baryCenter.y;
        }
        self.currentPolygonZoom = newZoomFactor;
        del.polygonZoom = [NSNumber numberWithFloat:newZoomFactor];
    }
    [self polygonToPath];
    [self redrawSelection];
}

/*==================================================================================*/

-(void) addPolygonLayer {
    self.polygonLayer = [CAShapeLayer layer];
    self.polygonLayer.lineWidth = 1.0;
    self.polygonLayer.lineCap = kCALineCapRound;
    self.polygonLayer.strokeColor = [self.selColor CGColor];
    self.polygonLayer.fillColor = [[NSColor clearColor] CGColor];
    self.polygonLayer.lineDashPattern = @[@11, @4];
    [self.layer addSublayer:self.polygonLayer];
    [self animatePolygonLayer];
}

/*==================================================================================*/

-(void) animatePolygonLayer {
    
    // create animation for the layer
    CABasicAnimation *dashAnimation;
    dashAnimation = [CABasicAnimation animationWithKeyPath:@"lineDashPhase"];
    dashAnimation.fromValue = @0.0f;
    dashAnimation.toValue = @15.0f;
    dashAnimation.duration = 0.75f;
    dashAnimation.repeatCount = HUGE_VALF;
    [self.polygonLayer addAnimation:dashAnimation forKey:@"marching_ants"];
}

/*==================================================================================*/

-(void) addHandleLayer {
    self.handleLayer = [CAShapeLayer layer];
    self.handleLayer.lineWidth = 1.0;
    self.handleLayer.strokeColor = [self.selColor CGColor];
    self.handleLayer.fillColor = [[NSColor clearColor] CGColor];
    [self.layer addSublayer:self.handleLayer];
}

/*==================================================================================*/

-(void) showGrid {
    
    VAppDelegate* del = (VAppDelegate*)(NSApp.delegate);

    //-----  1st resize the frame of the drawing view to make it fit the fieldSize and scale values

    NSInteger numSquares = del.polygonNumMicrons.intValue;
    NSInteger fieldSize = numSquares * del.polygonScale.intValue;
    self.frame = NSMakeRect(0, 0, fieldSize, fieldSize);
    
    //----- now make the grid in dashed lines
    
    CAShapeLayer* grid = [CAShapeLayer layer];
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathRef immutablePath;
    
    for (int v = 0; v < numSquares; v++) {
        for (int h = 0; h < numSquares; h++) {
            CGRect aRect = CGRectMake(h * del.polygonScale.intValue,v * del.polygonScale.intValue,
                                      del.polygonScale.intValue, del.polygonScale.intValue);
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

/*==================================================================================*/
// to forward a color change

-(void) changeSelColor {
    self.selColor = [[NSColorPanel sharedColorPanel] color];
    [self redrawSelection];
}

-(void) rebuildPolygonLayer {
    [self.polygonLayer removeFromSuperlayer];
    [self addPolygonLayer];
    CGPathRef path = [self.curPath quartzPath];
    self.polygonLayer.path = path;
    CGPathRelease(path);
    
    [self.handleLayer removeFromSuperlayer];
    [self addHandleLayer];
    path = [self makeHandleCGPath];
    self.handleLayer.path = path;
    CGPathRelease(path);
}

/*==================================================================================*/

-(void) resizeBackgroundImage {
    if (self.image){
        NSSize imgSize = self.image.size;
        NSSize newSize = self.frame.size;
        float xRatio = newSize.width/imgSize.width;
        float yRatio = newSize.height/imgSize.height;
        float newRatio = MIN(xRatio, yRatio);
        imgSize.width *= newRatio;
        imgSize.height *=newRatio;
        self.image.size = imgSize;
        [self setNeedsDisplay:YES];
    }
}

/*==================================================================================*/

-(void) doPrint {
    //[self print:self];    // this one only prints the background image, not the layers, which is not what we want here
    
    // as there is no way to print directly from a CALayer, create an offscreen VPrintableView and draw the polygon into it
    // then force display and just call print from the new view...
    
    VPrintableView* pView = [[VPrintableView alloc]initWithFrame:self.frame];
    pView.path = [NSBezierPath bezierPath];
    [pView.path moveToPoint:self.polygon[0]];
    if (self.numPoints > 1) {
        for (int i=1; i<self.numPoints; i++){
            [pView.path lineToPoint:self.polygon[i]];
        }
    }
    if (self.isClosed) {
        [pView.path closePath];
    }
    pView.path.lineWidth = 1.0;
    [pView display];
    
    [pView print:self];
}

/*==================================================================================*/

-(IBAction) choseNewColor:(id)sender {
    NSColorPanel* theColors = [NSColorPanel sharedColorPanel];
    [theColors makeKeyAndOrderFront:self];
}

/*==================================================================================*/

-(void) redrawSelection {
    [self rebuildPolygonLayer];

    // Surprisingly using the layers from the calls below loses the animation !
    // so replace by integral polygon rebuilding and animation is OK now
    // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    CGPathRef path = [self.curPath quartzPath];
//    self.polygonLayer.path = path;
//    CGPathRelease(path);
//    CGPathRef handles = [self makeHandleCGPath];
//    self.handleLayer.path = handles;
//    CGPathRelease(handles);
}

/*==================================================================================*/

- (void)drawRect:(NSRect)dirtyRect {
    
    //[super drawRect:dirtyRect];
    
    // Drawing code here.
    VAppDelegate* del = (VAppDelegate*)NSApp.delegate;
    NSInteger halfSize = del.polygonNumMicrons.intValue * del.polygonScale.intValue / 2;
    float dx = halfSize - self.image.size.width/2;
    float dy = halfSize - self.image.size.height/2;

    NSRect dstRect = NSMakeRect(dx,dy,self.image.size.width, self.image.size.height);
    NSRect imgRect = NSMakeRect(0,0,self.image.size.width, self.image.size.height);
    float frac = 0.25;
    if (del.polygonBackTransparencyCheckBox.state == NSControlStateValueOff)
        frac = 1.0;
    [self.image drawInRect:dstRect fromRect:imgRect operation:NSCompositingOperationSourceOver fraction:frac];
    [self redrawSelection];
}

/*==================================================================================*/

-(NSRect) handleRectAtIndex:(NSInteger)index {
    NSInteger   h = self.handleSize/2;
    NSRect      handleRect;
    NSPoint     points[3];
    
    switch ([self.curPath elementAtIndex:index associatedPoints:points]) {
        case NSBezierPathElementMoveTo:
            handleRect = NSMakeRect(points[0].x-h,points[0].y-h,2*h,2*h);
            break;

        case NSBezierPathElementLineTo:
            handleRect = NSMakeRect(points[0].x-h,points[0].y-h,2*h,2*h);
            break;

        case NSBezierPathElementCurveTo:
            handleRect = NSMakeRect(points[2].x-h,points[2].y-h,2*h,2*h);
            break;
        
        case NSBezierPathElementClosePath:
            handleRect = NSZeroRect;
            break;
    }
    return handleRect;
}

/*==================================================================================*/

-(NSInteger) indexOfHandleContainingPoint:(NSPoint)p {
    NSInteger   answer =-1;
    int         i, numElements;
    
    numElements = (int)[self.curPath elementCount];
    
    for (i=0; i<numElements; i++) {
        if (NSPointInRect(p, [self handleRectAtIndex:i])) {
            answer = i;
            break;
        }
    }
    return answer;
}

/*==================================================================================*/

-(void) mouseDown:(NSEvent *)theEvent {
    
    BOOL alt=NO, shift=NO, dblClick=NO, cmd = NO;
    NSUInteger modifiers =[theEvent modifierFlags];
    shift = (modifiers & NSEventModifierFlagShift) !=0;
    alt = (modifiers & NSEventModifierFlagOption) !=0;
    cmd = (modifiers & NSEventModifierFlagCommand) !=0;
    dblClick = theEvent.clickCount == 2;
    VAppDelegate* del = (VAppDelegate*)NSApp.delegate;


    self.hitPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];  // pass nil to convert into window coordinates

    if (dblClick){
        // terminate a polygon by closing it
        if (! self.isClosed) {
            self.isClosed = YES;
            [self polygonToPath];
            [self redrawSelection];
            self.isBuilding = NO;
            del.savePolygonButton.enabled = YES;
        }
        return;
    }
    
    if (!self.isBuilding && (CGPathContainsPoint(self.handleLayer.path, NULL, self.hitPoint, NO))) {
        
        ////  click into a handle after a polygon is built
        NSInteger targetHandle = [self indexOfHandleContainingPoint: self.hitPoint];
        
        if (alt) {
            
            // to remove a handle
            for (int i = 0; i < self.numPoints; i++) {
                if (i >= targetHandle){
                    self.polygon[i] = self.polygon[i+1];
                }
            }
            self.numPoints--;
            [self polygonToPath];
            [self redrawSelection];
            
        } else if (shift) {
            
            // to insert a handle
            if (targetHandle == 0) targetHandle = 1;
            for (int i=0; i< (self.numPoints+1); i++) {
                if (i == targetHandle) {
                        // get the present coordinates of the target point and the one before in the list
                    NSPoint p1 = self.polygon[i];
                    NSPoint p2 = self.polygon[i-1];
                        // make room in the list, starting by the end of it
                    for (NSInteger j = self.numPoints; j >= i; j--) {
                        self.polygon[j] = self.polygon[j-1];
                    }
                        // insert the new point
                    self.polygon[i] = NSMakePoint((p1.x + p2.x) / 2, (p1.y + p2.y) / 2);
                }
            }
            self.numPoints++;
            [self polygonToPath];
            [self redrawSelection];
        } else {
            
            // no insertion, no deletion, then drag the handle
            self.dragHandle = YES;
            self.draggedHandleIndex = targetHandle;
            
        }
        
    } else {
        
        if (! self.isClosed) {
            
            // add a new point to the existing polygon
            self.polygon[self.numPoints++] = self.hitPoint;
            //self.polygon[self.numPoints++] = NSMakePoint(px,py);
            
            self.isBuilding = YES;
            self.window.documentEdited = YES;
            
            del.clearButton.enabled = YES;

            [self polygonToPath];
            [self redrawSelection];
            CABasicAnimation* ants = (CABasicAnimation*)[self.polygonLayer animationForKey:@"marching_ants"];
            if (ants) {
                [self.polygonLayer addAnimation:ants forKey:nil];
            }

        } else if (CGPathContainsPoint(self.polygonLayer.path, NULL, self.hitPoint, NO)) {
            
            self.dragSelection = YES;
            
        }
    }
    
}

/*==================================================================================*/

- (void) mouseUp:(NSEvent *)theEvent {
    
    BOOL alt=NO, shift=NO, cmd = NO;
    NSUInteger modifiers =[theEvent modifierFlags];
    shift = (modifiers & NSEventModifierFlagShift) !=0;
    alt = (modifiers & NSEventModifierFlagOption) !=0;
    cmd = (modifiers & NSEventModifierFlagCommand) !=0;

    //NSPoint upPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    if (self.dragHandle == YES)
        self.dragHandle = NO;
    if (self.dragSelection == YES)
        self.dragSelection = NO;
}

/*==================================================================================*/

-(void) mouseMoved:(NSEvent*) theEvent {
    
    NSPoint movedPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    VAppDelegate* del = (VAppDelegate*)(NSApp.delegate);

    NSInteger halfSize = del.polygonNumMicrons.intValue * del.polygonScale.intValue / 2;
    float newX = (floor(movedPoint.x) - halfSize)/del.polygonScale.floatValue;
    float newY = (floor(movedPoint.y) - halfSize)/del.polygonScale.floatValue;
    del.xPolygonValue = [NSNumber numberWithFloat: newX];
    del.yPolygonValue = [NSNumber numberWithFloat: newY];
    
    if (self.isBuilding && ! self.isClosed) {
        [self addFloatingPoint:movedPoint];
        [self redrawSelection];
    } else {
        if  ((CGPathContainsPoint(self.polygonLayer.path, NULL, movedPoint, NO)) ||
             (CGPathContainsPoint(self.handleLayer.path, NULL, movedPoint, NO))) {
            NSCursor* curs = [NSCursor arrowCursor];
            [curs set];
        } else {
            NSCursor* curs = [NSCursor crosshairCursor];
            [curs set];
        }
    }
}

/*==================================================================================*/

- (void) mouseDragged:(NSEvent *)theEvent {
    
    NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];

    VAppDelegate* del = (VAppDelegate*)(NSApp.delegate);
    NSInteger halfSize = del.polygonNumMicrons.intValue * del.polygonScale.intValue / 2;
    float newX = (floor(point.x) - halfSize)/del.polygonScale.floatValue;
    float newY = (floor(point.y) - halfSize)/del.polygonScale.floatValue;
    del.xPolygonValue = [NSNumber numberWithFloat: newX];
    del.yPolygonValue = [NSNumber numberWithFloat: newY];

    if (self.dragHandle){
        self.polygon[self.draggedHandleIndex] = point;
        [self polygonToPath];
        [self redrawSelection];
    }
    
    if (self.dragSelection) {
        float dx = point.x-self.hitPoint.x;
        float dy = point.y-self.hitPoint.y;
        
        long n = self.numPoints;
        for (int i=0; i<n; i++){
            self.polygon[i].x += dx;
            self.polygon[i].y += dy;
        }
        [self polygonToPath];
        [self redrawSelection];
        self.hitPoint = point;
    }
    
    self.window.documentEdited = YES;

}

/*==================================================================================*/

- (void) mouseEntered:(NSEvent *)theEvent
{
    NSCursor* curs = [NSCursor crosshairCursor];
    [curs set];
}

/*==================================================================================*/

- (void) mouseExited:(NSEvent *)theEvent
{
    NSCursor* curs = [NSCursor arrowCursor];
    [curs set];
}

/*==================================================================================*/

- (void)magnifyWithEvent:(NSEvent *)event {
    
    VAppDelegate* del = (VAppDelegate*)NSApp.delegate;

    NSScrollView* scrl = nil;
    NSView* encloser = [[self superview]superview];
    if ([encloser isMemberOfClass:[NSScrollView class]])
        scrl = (NSScrollView*)encloser;
    if (scrl) {
        float zoomFactor = scrl.magnification + event.magnification;
        NSInteger halfSize = del.polygonNumMicrons.intValue * del.polygonScale.intValue / 2;
        NSPoint center = NSMakePoint(halfSize, halfSize);
        [(NSScrollView*)scrl setMagnification:zoomFactor centeredAtPoint:center];
    }

    [self polygonToPath];
    [self redrawSelection];
}

@end
