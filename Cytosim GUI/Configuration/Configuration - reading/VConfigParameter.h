//
//  VConfigParameter.h
//  Cytosim GUI
//
//  Created by Chris on 18/08/2022.
//

#import <Foundation/Foundation.h>
#import "VParameterVariations.h"

NS_ASSUME_NONNULL_BEGIN

/*******************************************************************************************************************************************************/
/*******************************************************************************************************************************************************/
// VConfigParameter is not only an internal parameter (between curly braces)
// within the 'set' or 'new' calls of the configuration file.
// It can also represent the data found in the 'set' and 'new' lines themselves (the titles).
// This is necessary i) since these titles have to be displayed in the NSOutlineView controlled by
// the VParamVariationManager and ii) since 'new' titles contain an instance count that could also vary
/*******************************************************************************************************************************************************/
/*******************************************************************************************************************************************************/

@interface VConfigParameter : NSObject <NSCopying>

@property (strong) NSString* ownerName;                 // object or instance name
@property (strong) NSString* ownerType;                 // object's type

@property (assign) BOOL      ownerIsInstance;
@property (strong) NSNumber* instanceCount;              // Only in the case this parameter represents an instance (new ## instanceName)

@property (strong) NSString* paramName;
@property (strong) NSString* paramHelp;
@property (strong) NSString* paramStringValue;
@property (strong) NSNumber* paramNumValue;
@property (assign) NSRange   paramRange;                // the location of the parameter description in the text

@property (strong, nullable) VParameterVariations* variations;    // an object that manages linear and non-linear variations
                                                        // to automatize several consecutive calls to "Sim"


- (instancetype) initWithName:(NSString*) paramName Type:(NSString*)type Value:(NSNumber*)value OwnerName:(NSString*)ownerName Instance:(BOOL)instance InstanceCount:(NSInteger)instanceCount HelpString:(NSString*) help;

- (BOOL) validateDX;                                    // actually varies
- (BOOL) isNumeric;                                     // Tells if the parameter can vary or not
- (void) copyContentsWithoutVariationsFrom:(VConfigParameter*) param;
- (VConfigParameter*) copyVariationIntoParameter;
- (BOOL) isEqualToParameter:(VConfigParameter*)param;
- (void) changeValue:(NSNumber*) newValue;
@end

NS_ASSUME_NONNULL_END
