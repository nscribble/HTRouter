//
//  HTXRouteDefinition+JLRParsingSupport.h
//  HTRouter
//
//  Created by cc on 2018/10/19.
//  Copyright © 2018 Jason. All rights reserved.
//

#import "HTXRouteDefinition.h"

extern NSString *const HTRoutePatternKey;
extern NSString *const HTRouteURLKey;
extern NSString *const HTRouteSchemeKey;
extern NSString *const HTRouteWildcardComponentsKey;
extern NSString *const HTRoutesGlobalRoutesScheme;

@class HTXRouterequest;
@interface HTXRouteDefinition (JLRParsingSupport)

- (NSDictionary *)defaultMatchParametersForRequest:(HTXRouterequest *)request;
- (NSDictionary *)matchParametersForRequest:(HTXRouterequest *)request routeVariables:(NSDictionary <NSString *, NSString *> *)routeVariables;
- (NSString *)routeVariableValueForValue:(NSString *)value;
- (NSString *)routeVariableNameForValue:(NSString *)value;
- (NSDictionary <NSString *, NSString *> *)routeVariablesForRequest:(HTXRouterequest *)request;

@end
