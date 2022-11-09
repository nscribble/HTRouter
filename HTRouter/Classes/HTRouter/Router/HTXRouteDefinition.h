//
//  HTXRouteDefinition.h
//  HTRouter
//
//  Created by cc on 2018/10/16.
//  Copyright © 2018 Jason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTRouterProtocol.h"
#import "HTXRouteRequest.h"
#import "HTXRouteResponse.h"

@interface HTXRouteDefinition : NSObject <HTRouteDefinitionProtocol>

@property (nonatomic, assign, readonly) NSUInteger routeHash;

- (HTXRouteresponse *)routeResponseForRequest:(HTXRouterequest *)request;

- (void)markAsSubroute:(HTXRouteDefinition *)route;

@end
