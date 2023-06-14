//
//  VModelDrawingView.m
//  Cytosim GUI
//
//  Created by Chris on 18/12/2022.
//

#import "VProteinAssemblyView.h"
#import "VAppDelegate.h"

@implementation VProteinAssemblyView

/*==================================================================================*/

- (void)initialize
{
    if (self) {
        self.image = nil;
    }
}

/*==================================================================================*/

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

/*==================================================================================*/

-(void) mouseMoved:(NSEvent*) theEvent {
    
    NSPoint movedPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    VAppDelegate* del = (VAppDelegate*)(NSApp.delegate);
}

-(void) rightMouseDown:(NSEvent *)event {
    VAppDelegate* del = (VAppDelegate*)(NSApp.delegate);
    NSMenu* localMenu = [del objectLocalMenu];
    [NSMenu popUpContextMenu:localMenu withEvent:event forView:self];
}

/*==================================================================================*/


@end
