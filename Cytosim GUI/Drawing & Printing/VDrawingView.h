//
//  VDrawingView.h
//  Cytosim GUI
//
//  Created by Chris on 16/10/2022.
//

#import <Cocoa/Cocoa.h>
#import "NSBezierPath+QuartzUtilities.h"
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

enum tools {
    simul,
    space,
    polygon,
    solid,
    bead,
    cytosim_sphere,
    cytosim_point,
    cytosim_hand,
    cytosim_single,
    cytosim_couple,
    cytosim_fiber,
    cytosim_bundle,
    cytosim_nucleus,
    cytosim_aster,
};

@interface VDrawingView : NSImageView

@property (assign)  NSInteger       currentTool;

@property (assign)  NSPoint         hitPoint;
@property (assign)  NSPoint         prevPoint;
@property (assign)  NSPoint         lastPoint;
@property (assign)  NSColor*        selColor;

@property (strong)  NSBezierPath*   curPath;            // current drawing Path
@property (strong)  NSAffineTransform* zoomTransform;
@property (assign)  NSInteger       handleSize;         // square handle side

@property (assign)  NSPointArray    polygon;            // list of points that describe the current polygon path (curPath)
@property (assign)  NSInteger       numPoints;          // num polygon points
@property (assign)  BOOL            isClosed;           // set to YES if the polygon is terminated
@property (assign)  BOOL            isBuilding;         // set to YES if the user is building the polygon.
@property (assign)  BOOL            dragHandle;         // set to YES if the user is dragging a Handle after built completion.
@property (assign)  NSInteger       draggedHandleIndex; // index of the handle being dragged
@property (assign)  BOOL            dragSelection;      // set to YES if the user is dragging the whole polygon after built completion.

@property (strong)  CAShapeLayer*   gridLayer;
@property (strong)  CAShapeLayer*   axesLayer;
@property (assign)  BOOL            gridVisible;
@property (strong)  CAShapeLayer*   objectLayer;
@property (strong)  CAShapeLayer*   handleLayer;

@property (assign)  float           currentObjectZoom;



-(void) initialize;
-(void) redrawSelection;
-(void) updateGrid;
-(void) resizeBackgroundImage;
-(void) clearAllDrawing;
-(NSString*) polygonToString;
-(void) stringToPolygon:(NSString*) theString;
-(void) scaleObjects;
-(void) doPrint;
-(IBAction) choseNewColor:(id) sender;
@end

NS_ASSUME_NONNULL_END
