//
//  VConfigModelCreator.h
//  Cytosim GUI
//
//  Created by Chris on 15/05/2023.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VConfigModelCreator : NSObject

- (IBAction) buildSpace:(id) sender;
- (IBAction) buildFiber:(id) sender;
- (IBAction) buildProtein:(id) sender;
- (IBAction) buildEvent:(id) sender;
- (IBAction) buildField:(id) sender;
- (IBAction) buildRunLoop:(id) sender;


@end

NS_ASSUME_NONNULL_END
