//
//  VDrawingGrid.h
//  Cytosim GUI
//
//  Created by Chris on 14/12/2024.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface VDrawingGrid : NSObject

@property (strong)  CAShapeLayer*   gridLayer;
@property (strong)  CAShapeLayer*   axesLayer;
@property (assign)  NSNumber*       gridScale;  // pixels per micron of an elementary square
@property (assign)  NSNumber*       gridSide;   // number of microns wide and high in the whole field

-(void) buildGrid;

@end

NS_ASSUME_NONNULL_END
