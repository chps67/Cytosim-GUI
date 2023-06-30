//
//  VConfigurationModel.h
//  Cytosim GUI
//
//  Created by Chris on 15/08/2022.
//


/*******************************************************************************************************************************************************/
/*******************************************************************************************************************************************************/
// VConfigurationModel stores all the objects that are extracted from the configuration (.cym) text files
// Most of its work is to parse the configuration file to identify cytosim instances and organize them and to extract commands
// This set of operations is not needed to run simulations but is necessary to perform parameter variations
// and to feed the graphical interface of configuration building.
/*******************************************************************************************************************************************************/
/*******************************************************************************************************************************************************/

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
@property (strong) NSMutableArray*  objectMatrix;   // graph of directional relationships between config objects

@property (strong) NSMutableArray*  configInstances;
@property (strong) NSMutableArray*  instanceMatrix; // graph of directional relationships between config instances

@property (strong) NSString*        variableConfigString;
@property (assign) BOOL             hasVariations;
@property (strong) NSMutableArray*  variableOutlineItems;

-(void) splitConfigLines;
-(void) removeComments;
-(void) removeBlankLines;
-(void) extractObjectsAndInstances;

-(void) buildObjectAndInstanceGraphs;

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
