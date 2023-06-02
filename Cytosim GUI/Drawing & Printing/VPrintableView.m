//
//  VPrintableView.m
//  Cytosim GUI
//
//  Created by Chris on 25/10/2022.
//

#import "VPrintableView.h"

@implementation VPrintableView

- (void)drawRect:(NSRect)dirtyRect {
    //[super drawRect:dirtyRect];
    
    // Drawing code here.
    [self.path stroke];
}

@end
