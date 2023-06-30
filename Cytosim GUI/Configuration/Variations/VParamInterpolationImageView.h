//
//  VParamInterpolationImageView.h
//  Cytosim GUI
//
//  Created by Chris on 20/01/2023.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "VParameterVariations.h"

NS_ASSUME_NONNULL_BEGIN


@interface VParamInterpolationImageView : NSImageView

@property (strong)  NSNumber*               leftBoundary;
@property (strong)  NSNumber*               rightBoundary;
@property (strong)  NSNumber*               bottomBoundary;
@property (strong)  NSNumber*               topBoundary;
@property (strong)  NSNumber*               meshSizeValueX;
@property (strong)  NSNumber*               meshSizeValueY;

@property (strong)  VParameterVariations*   var;
@property (strong)  CAShapeLayer*           gridLayer;
@property (strong)  CAShapeLayer*           pointsLayer;
@property (strong)  CAShapeLayer*           curveLayer;

@end

NS_ASSUME_NONNULL_END
