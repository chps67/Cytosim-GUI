//
//  VDocumentController.m
//  Cytosim GUI
//
//  Created by Chris on 17/08/2022.
//

#import "VDocumentController.h"
#import "VDocument.h"

@implementation VDocumentController

+ (void)restoreWindowWithIdentifier:(NSString *)identifier state:(NSCoder *)state completionHandler:(void (^)(NSWindow *, NSError *))completionHandler
{
    // Don't want automatic document restoration
    completionHandler(nil, [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]);
    
    // If restoration expected then change the above against this one
    // [super restoreWindowWithIdentifier:identifier state:state completionHandler:completionHandler];
}

//-(BOOL) validateToolbarItem:(NSToolbarItem *)toolbarItem {
//    return YES;
//}

@end
