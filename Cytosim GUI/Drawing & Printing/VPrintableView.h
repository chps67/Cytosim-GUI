//
//  VPrintableView.h
//  Cytosim GUI
//
//  Created by Chris on 25/10/2022.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface VPrintableView : NSImageView
@property (strong) NSBezierPath* path;
@end

NS_ASSUME_NONNULL_END
