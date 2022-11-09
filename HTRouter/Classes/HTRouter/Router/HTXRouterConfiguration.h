//
//  HTXRouterConfiguration.h
//  HTRouter
//
//  Created by cc on 2018/10/16.
//  Copyright © 2018 Jason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTRouterProtocol.h"

@interface HTXRouterConfiguration : NSObject <HTRouterConfigurationProtocol>

+ (instancetype)createDefaultConfiguration;

@end
