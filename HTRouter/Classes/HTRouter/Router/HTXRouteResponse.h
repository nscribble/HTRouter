//
//  HTXRouteresponse.h
//  HTRouter
//
//  Created by cc on 2018/10/16.
//  Copyright © 2018 Jason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTRouterProtocol.h"

@interface HTXRouteresponse : NSObject <HTRouteResponseProtocol>

+ (instancetype)invalidMatchResponseForRequest:(id<HTRouteRequestProtocol>)request;
+ (instancetype)validMatchResponseWithParameters:(NSDictionary *)parameters request:(id<HTRouteRequestProtocol>)request;

@end
