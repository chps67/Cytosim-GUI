//
//  VConfigModelCreator.h
//  Cytosim GUI
//
//  Created by Chris on 15/05/2023.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VConfigModelCreator : NSObject

- (IBAction) buildRunLoop:(id) sender;
- (IBAction) buildSpace:(id) sender;
- (IBAction) addCytosimObject:(id) sender;
- (IBAction) buildChimera:(id) sender;
- (IBAction) addChimera:(id) sender;

@end

NS_ASSUME_NONNULL_END
