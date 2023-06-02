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

@interface VPolygonDrawingView : NSImageView


@property (assign)  NSPoint         hitPoint;
@property (assign)  NSPoint         prevPoint;
@property (assign)  NSPoint         lastPoint;
@property (assign)  NSColor*        selColor;

@property (strong)  NSBezierPath*   curPath;            // current polygon Path
@property (strong)  NSAffineTransform* zoomTransform;
@property (assign)  NSInteger       handleSize;         // square handle side

@property (assign)  NSPointArray    polygon;            // list of points that describe the current path (curPath)
@property (assign)  NSInteger       numPoints;          // num polygon points
@property (assign)  BOOL            isClosed;           // set to YES if the polygon is terminated
@property (assign)  BOOL            isBuilding;         // set to YES if the user is building the polygon.
@property (assign)  BOOL            dragHandle;         // set to YES if the user is dragging a Handle after built completion.
@property (assign)  NSInteger       draggedHandleIndex; // index of the handle being dragged
@property (assign)  BOOL            dragSelection;      // set to YES if the user is dragging the whole polygon after built completion.

@property (strong)  CAShapeLayer*   gridLayer;
@property (strong)  CAShapeLayer*   axesLayer;
@property (assign)  BOOL            gridVisible;
@property (strong)  CAShapeLayer*   polygonLayer;
@property (strong)  CAShapeLayer*   handleLayer;

@property (assign)  float           currentPolygonZoom;



-(void) initialize;
-(void) redrawSelection;
-(void) updateGrid;
-(void) resizeBackgroundImage;
-(void) clearAllDrawing;
-(NSString*) polygonToString;
-(void) stringToPolygon:(NSString*) theString;
-(void) scalePolygon;
-(void) doPrint;
-(IBAction) changeColor:(id)sender;
@end

NS_ASSUME_NONNULL_END
