//
//  VConfigTextView.m
//  Cytosim GUI
//
//  Created by Chris on 07/02/2023.
//

#import "VConfigTextView.h"
#import "VAppDelegate.h"
#import "VDocument.h"

@implementation VConfigTextView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

-(void) didChangeText {
    
    [super didChangeText];

//    VAppDelegate* del = (VAppDelegate*)[NSApp delegate];
//    VDocument* doc = (VDocument*)[del topDoc];
//
//    // Re-extract text contents into the configModel
//    // Re-extract text contents into the configModel
//    [doc.configModel extractObjects];
//    [doc.configModel extractInstances];
//    [doc.configModel extractVariationSuitableParams];
//
//    // Then ensure that any change in par   ameter value will be directly cast
//    // to parameter variations
//    if (doc.variationsWindow.visible) {
//       [doc.paramVarMgr.tableView reloadData];
//       [doc.paramVarMgr.interpolView setNeedsDisplay:YES];
//    }

}
@end
