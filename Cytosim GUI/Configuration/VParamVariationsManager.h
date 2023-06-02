//
//  VParamVariationsTableManager.h
//  Cytosim GUI
//
//  Created by Chris on 19/01/2023.
//

#import <Foundation/Foundation.h>
#import "VParamInterpolationImageView.h"
#import "VConfigParameter.h"
#import "VOutlineItem.h"


NS_ASSUME_NONNULL_BEGIN

@class VDocument;

@interface VParamVariationsManager : NSObject <NSTableViewDataSource, NSTableViewDelegate,
                                    NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (strong) IBOutlet NSWindow*                       ownerWindow;
@property (strong) IBOutlet VDocument*                      ownerDoc;

@property (strong) IBOutlet  NSOutlineView*                 outlineView;
@property (strong, nullable) VOutlineItem*                  currentItem;    // the variable to be displayed in outlineView

@property (strong) NSNumber*                                canRunSimBatch; // BOOL bound to the "Run Sim Batch" button in IB

// IB-bound numbers
@property (strong) NSNumber*                                curX;
@property (strong) NSNumber*                                curY;
@property (strong) NSNumber*                                xOrigin;
@property (strong) NSNumber*                                yOrigin;
@property (strong) NSNumber*                                xWidth;
@property (strong) NSNumber*                                yHeight;
@property (strong) NSNumber*                                meshSizeX;
@property (strong) NSNumber*                                meshSizeY;

@property (strong) NSNumber*                                numSim;             // total number of simulations generated

// batch run of Sim command interface
@property (strong) IBOutlet NSButton*                       runBatchButton;
@property (strong) IBOutlet VParamInterpolationImageView*   interpolView;

- (IBAction) useOutlineItemVariation:(id)sender;
- (IBAction) editOutlineCellValue:(id)sender;
- (void) applyOutlineItemVariationChange;
- (void) outlineEnableUseCheckBox:(BOOL)enable ForItem:(VOutlineItem*)item;
- (IBAction) refreshOutline:(id)sender;
- (void) synchronizeUseBoxes;
- (NSButton*) checkBoxForItem:(id)item ;
- (IBAction) editParameterValues:(id)sender;
- (BOOL) hasVariationsInParameters;
- (void) applyVariationChange;
- (NSNumber*) computeNumSimCalls;
- (IBAction) runSimBatch:(id)sender;


@end

NS_ASSUME_NONNULL_END
