//
//  VConfigurationModel.h
//  Cytosim GUI
//
//  Created by Chris on 15/08/2022.
//

#import <Foundation/Foundation.h>
#import "VConfigObject.h"
#import "VConfigInstance.h"
#import "VConfigParameter.h"
#import "VOutlineItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface VConfigurationModel : NSObject

@property (strong) NSURL*           configURL;
@property (strong) NSString*        configString;
@property (strong) NSString*        trimmedConfigString;
@property (strong) NSString*        modelConfigCode;
@property (strong) NSMutableArray*  configLines;
@property (strong) NSMutableArray*  configObjects;
@property (strong) NSMutableSet*    objectNamesSet; // for real-time object names recognition in VDocument's textStorage::didProcessEditing
@property (strong) NSMutableArray*  configInstances;

@property (strong) NSString*        variableConfigString;
@property (assign) BOOL             hasVariations;
@property (strong) NSMutableArray*  variableOutlineItems;

-(void) splitConfigLines;
-(void) removeComments;
-(void) removeBlankLines;
-(void) extractObjectsAndInstances;
-(void) extractOutlineVariableItems;
-(void) reorderOutlineVariableItem:(VOutlineItem*)draggedItem ToPosition:(NSInteger)toPos IntoRootItem:(VOutlineItem*)rootItem;

-(VConfigObject*) objectWithName:(NSString*)name;
-(VConfigInstance*) instanceWithName:(NSString*)name;
-(NSError*) saveVariationData:(NSURL*)atURL;
-(void) openVariationData:(NSURL*)fromURL;

-(void) buildVariableConfigStringWithLabel:(NSString*)label ForPlayInstance:(NSInteger) instanceNum;
-(void) rebuildObjectAndInstanceCodes;
@end

NS_ASSUME_NONNULL_END
