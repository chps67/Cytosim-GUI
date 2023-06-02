//
//  VModelDrawingView.h
//  Cytosim GUI
//
//  Created by Chris on 18/12/2022.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface VModelDrawingView : NSImageView

@property (strong)  CAShapeLayer*   gridLayer;
@property (strong)  CAShapeLayer*   axesLayer;
@property (assign)  BOOL            gridVisible;

-(void) initialize;
-(void) updateGrid;

@end

NS_ASSUME_NONNULL_END
