//
//  VAutoSelectTextField.m
//  Cytosim For OSX
//
//  Created by Chris on 26/06/2022.
//

#import "VAutoSelectTextField.h"

@implementation VAutoSelectTextField

@synthesize hasValidURL, hasValidFile, hasValidDirectory, hasFileWithValidExtension, validFileExtension ;

// This NSTextField Subclass overrides two functions :
// - mouseDown to select directly all the content upon a click
// - textDidChange to fill the textField with the dropped URL and select it all.
// - awakeFromNib to register for file types upon drag and drop (required to fire draggingEntered)
// - draggingEntered which makes the target text field the window's first reponder


- (void)awakeFromNib {
    [self registerForDraggedTypes:@[NSPasteboardTypeString, NSPasteboardTypeURL, NSPasteboardTypeFileURL]];
    self.validFileExtension = @"cym"; // optionally the field can test if the URL is a file with valid extension
}

//-----------------------------------------------------------------------------

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    [self.window makeFirstResponder:self];
    return [super draggingEntered:sender];
}

//-----------------------------------------------------------------------------

- (void)mouseDown:(NSEvent *)theEvent
{
    [[self currentEditor] selectAll:nil];
}

//-----------------------------------------------------------------------------

-(void) textDidChange:(NSNotification *)notification {
 
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];

    // 1st check if the present text in the field is a valid URL
    NSString* fieldContents = self.stringValue;
    NSURL* validURL = [NSURL fileURLWithPath:fieldContents];
    // if the URL is not valid, do not replace with pasteboard contents because the user is editing the field...
    if (! validURL) {
        [nc postNotificationName:@"noURL" object:self];
        [self checkURLValidity];
        return;
    }

    // It's impossible to override NSTextField's drag and drop methods (never called)
    // So let's work it out  by replacing the field contents with the URL's path
    // contained in the dragging pasteboard
    
    NSPasteboard* draggingPasteboard = [NSPasteboard pasteboardWithName:NSPasteboardNameDrag];
    NSArray* classes = @[[NSURL class]];
    NSArray* contents = [draggingPasteboard readObjectsForClasses:classes options:nil];

    validURL = (NSURL*)contents.firstObject; // the URL actually has a weird content (File System numbers)
    if (validURL) {
        NSString* path = [validURL path];
        self.stringValue = path;
        [[self currentEditor] selectAll:nil];
        
        // post a notification to the notification center when the content is a valid URL
        // this will be read by the text field owner when the text changes
        // It gives the opportunity to take specific actions
        [nc postNotificationName:@"containsURL" object:self];
        
        // alternative for FILES
        // store URL validity into the hasValidURL property that can be used
        // to set IB bindings
        [self checkURLValidity];
    }
}

//-----------------------------------------------------------------------------

- (void) checkURLValidity {
    
    self.hasFileWithValidExtension = NO;
    self.hasValidDirectory = NO;
    self.hasValidFile = NO;
    NSURL* theURL = [NSURL fileURLWithPath:self.stringValue];
    self.hasValidURL = theURL.isFileURL;
    
    if (self.hasValidURL) {
        NSString* fileString = [theURL lastPathComponent];
        id res;
        NSError* err;
        self.hasFileWithValidExtension = [fileString hasSuffix:self.validFileExtension];
        [theURL getResourceValue:&res forKey:NSURLIsDirectoryKey error:&err];
        self.hasValidDirectory = [(NSNumber*)res boolValue];
        [theURL getResourceValue:&res forKey:NSURLIsRegularFileKey error:&err];
        self.hasValidFile = [(NSNumber*)res boolValue];
    }
}

//-----------------------------------------------------------------------------

- (void) grantURLAccessToSandBox {
    if (self.hasValidURL){
        NSURL* theURL = [NSURL fileURLWithPath:self.stringValue];
        [theURL startAccessingSecurityScopedResource];
    }
}

//-----------------------------------------------------------------------------

- (void) denyURLAccessToSandBox {
    if (self.hasValidURL){
        NSURL* theURL = [NSURL fileURLWithPath:self.stringValue];
        [theURL stopAccessingSecurityScopedResource];
    }
}

@end
