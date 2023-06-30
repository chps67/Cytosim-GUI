//
//  VParameterVariations.h
//  Cytosim GUI
//
//  Created by Chris on 12/01/2023.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

enum varTypes {
    randomType,         // uniform random
    linearType,         // p1*x+p2
    logType,            // p1*log(x)+p2
    exponentialType,    // p1*exp(p2*x)+p3
    sqrtType,           // p1*sqrt(x)+p2
    quadraticType,      // p1*x^2+p2*x+p3
    cubicType           // p1*x^3+p2*x^2+p3*x+p4
};

@interface VParameterVariations : NSObject <NSCopying>

@property (strong) NSNumber*        active;
@property (assign) NSInteger        variationType;     // one of the varTypes above

@property (strong) NSNumber*        p1;                // param value
@property (strong) NSNumber*        p2;
@property (strong) NSNumber*        p3;
@property (strong) NSNumber*        p4;

@property (strong) NSNumber*        numberOfValues;    // number of values to be interpolated
@property (strong) NSNumber*        minX;              // the interval of x values
@property (strong) NSNumber*        maxX;
@property (strong) NSNumber*        minY;               // start Y (interpolated) value
@property (strong) NSNumber*        maxY;               // end  Y (interpolated) values
@property (strong) NSMutableArray*  variationValues;    // array of all the Y (interpolated) values




-(instancetype) initWithValue:(NSNumber*) value;  // copies the value given in the configuration file into the variations array
-(void)         collectValues;
-(NSNumber*)    valueForStep:(NSNumber* )x;

@end

NS_ASSUME_NONNULL_END
