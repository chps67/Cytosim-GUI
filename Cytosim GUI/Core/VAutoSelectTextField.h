//
//  VAutoSelectTextField.h
//  Cytosim For OSX
//
//  Created by Chris on 26/06/2022.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface VAutoSelectTextField : NSTextField <NSDraggingDestination>

@property (assign) BOOL hasValidURL;
@property (assign) BOOL hasValidFile;
@property (assign) NSString* validFileExtension;
@property (assign) BOOL hasFileWithValidExtension;
@property (assign) BOOL hasValidDirectory;

- (void) checkURLValidity;
- (void) grantURLAccessToSandBox;
- (void) denyURLAccessToSandBox;

@end

NS_ASSUME_NONNULL_END
