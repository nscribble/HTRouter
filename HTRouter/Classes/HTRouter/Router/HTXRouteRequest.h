//
//  HTXRouterequest.h
//  HTRouter
//
//  Created by cc on 2018/10/16.
//  Copyright © 2018 Jason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTRouterProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface HTXRouterequest : NSObject <HTRouteRequestProtocol>

- (instancetype)initWithURL:(NSURL *)URL configuration:(id<HTRouterConfigurationProtocol>)configuration;

@end

NS_ASSUME_NONNULL_END
