//
//  VModelDrawingView.m
//  Cytosim GUI
//
//  Created by Chris on 18/12/2022.
//

#import "VProteinAssemblyView.h"
#import "VAppDelegate.h"
#import "NSBezierPath+QuartzUtilities.h"
#import "VDocument.h"
#import "VConfigModelCreator.h"
#import "VConfigObject.h"

@implementation VProteinAssemblyView

/*==================================================================================*/

-(void) awakeFromNib {
    
    self.image = nil;
    
    // select default tool
    self.toolButtons = [NSArray arrayWithObjects:self.singleButton,
                        self.coupleButton, self.solidSingleButton, self.fiberCoupleButton, nil]; // tool buttons
    self.toolType = single;
    
    self.drawingPaths = [NSMutableArray arrayWithCapacity:0];
    self.drawingLayers = [NSMutableArray arrayWithCapacity:0];
    self.drawingColors = [NSMutableArray arrayWithCapacity:0];
    self.wantsLayer = YES;
    
    // add grid
    self.gridSquareSize = 40;
    self.numRects = NSMakeSize(floor(self.frame.size.width / self.gridSquareSize),
                                 floor(self.frame.size.height / self.gridSquareSize));
    self.gridLayer = [CAShapeLayer layer];
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathRef immutablePath;
    for (int v = 0; v < self.numRects.height; v++) {
        for (int h = 0; h < self.numRects.width; h++) {
            CGRect aRect = CGRectMake(h * self.gridSquareSize +5 , v * self.gridSquareSize +5,
                                      self.gridSquareSize,self.gridSquareSize);
            CGPathAddRect(path, NULL, aRect);
        }
    }
    
    immutablePath = CGPathCreateCopy(path);
    CGPathRelease(path);
    self.gridLayer.path = immutablePath;
    CGPathRelease(immutablePath);
    
    self.gridLayer.strokeColor = [[NSColor grayColor] CGColor];
    self.gridLayer.fillColor = [[NSColor clearColor]CGColor];
    self.gridLayer.lineDashPattern = @[@1, @7];

    [self.layer addSublayer:self.gridLayer];
    self.selectionLayer = nil;
    
}

/*==================================================================================*/

- (NSColor*) makeFillerWithColor:(NSColor*) color {
    CGFloat red = color.redComponent;
    CGFloat green = color.greenComponent;
    CGFloat blue = color.blueComponent;
    CGFloat alpha = color.alphaComponent * 0.5;
    NSColor* filler = [NSColor colorWithRed:red green:green blue:blue alpha:alpha];
    return filler;
}

/*==================================================================================*/

-(void) addDrawing: (NSInteger)objectType {
    NSPoint orig = [self snapToGrid:self.hitPoint]; // snaps self.hitPoint
    NSRect locLinker, locHand1, locHand2;

    NSBezierPath* newPath = [NSBezierPath bezierPath];
    NSInteger si = 1;
    
    // get top doc's Config Object Symbols
    VAppDelegate* del = (VAppDelegate*)[NSApp delegate];
    VDocument* topDoc = (VDocument*)[del topDoc];
    VConfigModelCreator* creator = topDoc.modelCreator;

    if (objectType == single) {
        
        VConfigObject* newSingle = [creator createSingle];
        
        locLinker = NSMakeRect(orig.x, orig.y + self.gridSquareSize/4, self.gridSquareSize, self.gridSquareSize/2);
        NSPoint locLiM = locLinker.origin;
        locLiM.y += 10; //middle
        [newPath moveToPoint:locLiM];
        [newPath lineToPoint:NSMakePoint(locLiM.x+5,locLiM.y-10)];
        [newPath lineToPoint:NSMakePoint(locLiM.x+15,locLiM.y+10)];
        [newPath lineToPoint:NSMakePoint(locLiM.x+25,locLiM.y-10)];
        [newPath lineToPoint:NSMakePoint(locLiM.x+35,locLiM.y+10)];
        [newPath lineToPoint:NSMakePoint(locLiM.x+40,locLiM.y)];
        newSingle.objPath = [newPath copy];
        newSingle.objColor = self.colorWell.color;
        newSingle.objOrientation = 1; // East
        
        CAShapeLayer* aLayer = [CAShapeLayer layer];
        CGPathRef aCGPath = [newPath quartzPath];
        aLayer.path = aCGPath;
        CGPathRelease(aCGPath);
        aLayer.fillColor = [[NSColor clearColor] CGColor];
        aLayer.strokeColor = [self.colorWell.color CGColor];
        aLayer.lineWidth = 2.0;
        newSingle.objLayer = aLayer;
        [self.layer addSublayer:aLayer];

        [newPath removeAllPoints];
        locHand1 = NSMakeRect(orig.x - self.gridSquareSize, orig.y , self.gridSquareSize, self.gridSquareSize);
        [newPath  appendBezierPathWithOvalInRect:locHand1];
        VConfigObject* newHand = newSingle.children.firstObject;
        newHand.objPath = [newPath copy];
        newHand.objColor = self.colorWell.color;
        // no orientation, a hand is symmetric
        
        CAShapeLayer* bLayer = [CAShapeLayer layer];
        CGPathRef bCGPath = [newPath quartzPath];
        bLayer.path = bCGPath;
        CGPathRelease(bCGPath);
        bLayer.fillColor = [[self makeFillerWithColor:self.colorWell.color] CGColor];
        bLayer.strokeColor = [self.colorWell.color CGColor];
        bLayer.lineWidth = 2.0;
        ((VConfigObject*)newSingle.children.firstObject).objLayer = bLayer;
        [self.layer addSublayer:bLayer];

    }
    [self setNeedsDisplay:YES];
}

/*==================================================================================*/
// deletion of a single:
// removing the single or the hand removes all the single (+ the hand)
// but leaves in place any parent (solid or sphere) without the deleted single in the children array

// deletion of a couple:
// removing the linker or any hand will result in whole couple deletion
// but leaves in place any parent (fiber) without the deleted couple in the children array

-(void) removeObject {
    
    VConfigObject* object = [self selectedObjectAtPoint:self.hitPoint];
    
    VAppDelegate* del = (VAppDelegate*)[NSApp delegate];
    VDocument* topDoc = (VDocument*)[del topDoc];
    VConfigModelCreator* creator = topDoc.modelCreator;
    
    if ([object.objType isEqualToString:@"hand"]) {
        
        VConfigObject* parent = (VConfigObject*)object.parent;
        
        if ([parent.objType isEqualToString:@"single"]) {
            
            if (parent.parent) {    // remove the single from the children of a possible parent like single or sphere
                [parent.parent.children removeObject:parent];   // only removes it from the table - no disposal
                if (parent.parent.children.count == 0) {
                    parent.parent.children = nil;
                }
            }
            [parent.objLayer removeFromSuperlayer];
            [creator.configObjects removeObject:parent]; // only removes it from the table - no disposal
            
            [object.objLayer removeFromSuperlayer];
            [parent.children removeObject:object]; // only removes it from the table - no disposal
        }
        
        if ([parent.objType isEqualToString:@"couple"]) {
            
            NSUInteger index = [parent.children indexOfObject:object];
            VConfigObject* sisterHand = nil;
            (index == 0) ? (sisterHand = [parent.children objectAtIndex:1]) : (sisterHand = [parent.children objectAtIndex:0]);
            
            if (parent.parent) {    // remove the single from the children of a possible mother fiber
                [parent.parent.children removeObject:parent];   // only removes it from the table - no disposal
                if (parent.parent.children.count == 0) {
                    parent.parent.children = nil;
                }
            }
            [parent.objLayer removeFromSuperlayer];
            [creator.configObjects removeObject:parent]; // only removes it from the table - no disposal --> so parent is still accessible within its scope

            [object.objLayer removeFromSuperlayer];
            [parent.children removeObject:object]; // only removes it from the table - no disposal
            [sisterHand.objLayer removeFromSuperlayer];
            [parent.children removeObject:sisterHand]; // only removes it from the table - no disposal

        }
    }
    
    
    if ([object.objType isEqualToString:@"single"]) {
    
        VConfigObject* child = (VConfigObject*)(object.children.firstObject);
        [child.objLayer removeFromSuperlayer];
        [object.children removeObject:child];
        if (object.children.count == 0)
            object.children = nil;
        
        [object.objLayer removeFromSuperlayer];
        
        VConfigObject* parent = (VConfigObject*)object.parent;
        if (parent) {
            [parent.children removeObject:object];
        }
        [creator.configObjects removeObject:object];
    }

    [self.selectionLayer removeFromSuperlayer];
}

/*==================================================================================*/

-(void) rebuildObject:(VConfigObject*) whichObject {
    
    [whichObject.objLayer removeFromSuperlayer];

    CAShapeLayer* aLayer = [CAShapeLayer layer];
    CGPathRef aCGPath = [whichObject.objPath quartzPath];
    aLayer.path = aCGPath;
    CGPathRelease(aCGPath);
    if (! [whichObject.objType isEqualToString: @"single"])
        aLayer.fillColor = [[self makeFillerWithColor:whichObject.objColor] CGColor];
    aLayer.strokeColor = [whichObject.objColor CGColor];
    aLayer.lineWidth = 2.0;

    [self.layer addSublayer:aLayer];
}

/*==================================================================================*/

-(void) mouseDown:(NSEvent *)theEvent {
    
    BOOL alt=NO, shift=NO, dblClick=NO, cmd = NO;
    NSUInteger modifiers =[theEvent modifierFlags];
    shift = (modifiers & NSEventModifierFlagShift) !=0;
    alt = (modifiers & NSEventModifierFlagOption) !=0;
    cmd = (modifiers & NSEventModifierFlagCommand) !=0;
    dblClick = theEvent.clickCount == 2;

    self.hitPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];  // pass nil to convert into window coordinates
    
    // get the path the user clicked in and the corresponding layer
    VConfigObject* hitObj = [self selectedObjectAtPoint:self.hitPoint];
    VAppDelegate* del = (VAppDelegate*)[NSApp delegate];
    VDocument* topDoc = (VDocument*)[del topDoc];
    VConfigModelCreator* creator = topDoc.modelCreator;
    
    if (hitObj) {
        //[del.configObjectCreator writePropToObject:creator.currentObject];
        creator.currentObject = hitObj;
        [self selectObject:creator.currentObject];
        [creator readParametersForObject:creator.currentObject];
        //[del.configObjectCreator readPropFromObject:creator.currentObject];
    }
    
    if (shift) {
        [self addDrawing:self.toolType];
    }
    
    if (alt) {
        [self removeObject];    // at self.hitPoint
    }
    
    [self setNeedsDisplay:YES];
}

/*==================================================================================*/

-(void) selectObject:(VConfigObject*) object {
    
    NSBezierPath* sel = [NSBezierPath bezierPath];
    NSPoint orig = [self snapToGrid:self.hitPoint];
    NSRect selRect = NSMakeRect(orig.x, orig.y, self.gridSquareSize, self.gridSquareSize);
    [sel appendBezierPathWithRoundedRect:selRect xRadius:2 yRadius:2];
    [self.selectionLayer removeFromSuperlayer];
    
    CAShapeLayer* layer = [CAShapeLayer layer];
    CGPathRef path = [sel quartzPath];
    layer.path = path;
    CGPathRelease(path);
    layer.fillColor = [[NSColor clearColor]CGColor];
    layer.lineWidth = 3.0;
    layer.strokeColor = [[NSColor selectedControlColor]CGColor];
    [self.layer addSublayer:layer];
    self.selectionLayer = layer;
    
}

/*==================================================================================*/

- (VConfigObject*) selectedObjectAtPoint:(NSPoint) p {

    VAppDelegate* del = (VAppDelegate*)[NSApp delegate];
    VDocument* topDoc = (VDocument*)[del topDoc];
    VConfigModelCreator* creator = topDoc.modelCreator;
    VConfigObject* target = nil;
    
    // there should be 3 level-deep childhood max.
    for (VConfigObject* object in creator.configObjects) {
        
        if ([object.objPath containsPoint:p]) {
            target = object;
            break;
        }
        if (object.children.count >0) {
            for ( VConfigObject* child in object.children) {
                if ([child.objPath containsPoint:p]) {
                    target = child;
                    break;
                }
                if (child.children.count >0) {
                    for (VConfigObject* gdchild in child.children){
                        if ([gdchild.objPath containsPoint:p]) {
                            target = gdchild;
                            break;
                        }
                    }
                }
            }
        }
    }
    return target;
}

/*==================================================================================*/

- (void)drawRect:(NSRect)dirtyRect {
    // draws the contour and all the sublayers, so nothing special should be done at this stage
    [super drawRect:dirtyRect];
}

/*==================================================================================*/

// returns the point lying at the bottom-left of the grid square that contains p

- (NSPoint) snapToGrid:(NSPoint)p {
    NSPoint snapPt = p;
    NSInteger sX = round(snapPt.x);
    NSInteger sY = round(snapPt.y);
    NSInteger remX = sX % self.gridSquareSize;
    NSInteger remY = sY % self.gridSquareSize;
    sX = sX - remX + 5;
    if (sX < self.gridSquareSize)
        sX = self.gridSquareSize;
    sY = sY - remY + 5;
    snapPt = NSMakePoint(sX, sY);
    return snapPt;
}

/*==================================================================================*/

-(void) mouseMoved:(NSEvent*) theEvent {
    
//    NSPoint movedPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
//    VAppDelegate* del = (VAppDelegate*)(NSApp.delegate);
}

/*==================================================================================*/

-(void) rightMouseDown:(NSEvent *)event {
    self.hitPoint = [self convertPoint:[event locationInWindow] fromView:nil];  // pass nil to convert into window coordinates
    NSMenu* localMenu = self.proteinsLocalMenu;
    [NSMenu popUpContextMenu:localMenu withEvent:event forView:self];
}

/*==================================================================================*/

-(BOOL) validateMenuItem:(NSMenuItem *)menuItem {
    return YES;
}

- (IBAction) doProteinsMenu:(id)sender {
//    NSMenuItem* item = (NSMenuItem*)sender;
//    float angle= 0.0;
//    ([item.title containsString:@"CCW"]) ? (angle = 90.0) : (angle = -90.0);
//
//    VConfigObject* hitObj = [self selectedObjectAtPoint:self.hitPoint];
//    NSRect aRect = [hitObj.objPath bounds];

    //turn around the middle of the link
    
//    NSPoint aCenter = [self snapToGrid:NSMakePoint(aRect.origin.x + aRect.size.width/2, aRect.origin.y + aRect.size.height/2)];
//    NSAffineTransform* whole = [NSAffineTransform transform];
//    [whole translateXBy:-(aCenter.x) yBy:-(aCenter.y)];
//    NSAffineTransform* rot = [NSAffineTransform transform];
//    [rot rotateByDegrees:angle];    // direct rotation means CCW, so neg signs rotate CW
//    [whole appendTransform:rot];
//    NSAffineTransform* invCentr = [NSAffineTransform transform];
//    [invCentr translateXBy:aCenter.x yBy:aCenter.y ];
//    [whole appendTransform:invCentr];
//
//    NSUInteger index = [self.drawingPaths indexOfObject:hitPath];
//    NSBezierPath* transformedPath = [whole transformBezierPath:hitPath];
//    [self.drawingPaths replaceObjectAtIndex:index withObject:transformedPath];
//
//    [self rebuildObject:transformedPath];
    [self setNeedsDisplay:YES];
}

- (IBAction) doToolButton:(id)sender {
    // state change already happened when this action is called
    NSButton* hit = (NSButton*)sender;
    NSUInteger tag = hit.tag;
    NSInteger state = hit.state;
    
    if (state == NSControlStateValueOn) {
        for (NSButton* btn in self.toolButtons) {
            if (btn.tag != tag) {
                btn.state = NSControlStateValueOff;
            }
        }
    } else {
        for (NSButton* btn in self.toolButtons) {
            if (btn.tag == tag) {
                btn.state = NSControlStateValueOn;
            }
        }
    }
}
@end
