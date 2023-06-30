//
//  VModelDrawingView.h
//  Cytosim GUI
//
//  Created by Chris on 18/12/2022.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface VProteinAssemblyView : NSImageView <NSMenuItemValidation>

enum objectType {
    single,
    couple,
    solid_backbone,
    fiber_backbone
};

@property (assign) NSPoint          hitPoint;
@property (assign) NSPoint          prevPoint;
@property (assign) NSPoint          lastPoint;

@property (assign) NSUInteger       gridSquareSize;
@property (assign) NSSize           numRects;

@property (strong) NSMutableArray*  drawingPaths;     // storage of drawing NSBezierPaths for grpahical parts
@property (strong) NSMutableArray*  drawingLayers;    // keep one layer per object
@property (strong) NSMutableArray*  drawingColors;    // with its color
@property (strong) CAShapeLayer*    curDrawingLayer;
@property (strong) NSColor*         curColor;

@property (strong) CAShapeLayer*    gridLayer;
@property (strong) CAShapeLayer*    __nullable selectionLayer;

@property (strong) IBOutlet         NSMenu*    proteinsLocalMenu;
@property (strong) IBOutlet         NSButton*  singleButton;
@property (strong) IBOutlet         NSButton*  coupleButton;
@property (strong) IBOutlet         NSButton*  solidSingleButton;
@property (strong) IBOutlet         NSButton*  fiberCoupleButton;
@property (strong)                  NSArray*   toolButtons;
@property (strong) IBOutlet         NSColorWell* colorWell;

@property (assign) NSInteger        toolType;

- (IBAction) doProteinsMenu:(id)sender;
- (IBAction) doToolButton:(id)sender;
@end

NS_ASSUME_NONNULL_END
