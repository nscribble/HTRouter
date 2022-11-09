//
//  HTXRouteDefinition+JLRParsingSupport.m
//  HTRouter
//
//  Created by cc on 2018/10/19.
//  Copyright © 2018 Jason. All rights reserved.
//

#import "HTXRouteDefinition+JLRParsingSupport.h"
#import "HTParsingUtilities.h"

NSString *const HTRoutePatternKey = @"HTRoutePattern";
NSString *const HTRouteURLKey = @"HTRouteURL";
NSString *const HTRouteSchemeKey = @"HTRouteScheme";
// 注意跟JL的不同，改成了@[]提供多个*位置的参数
NSString *const HTRouteWildcardComponentsKey = @"HTRouteWildcardComponents";
NSString *const HTRoutesGlobalRoutesScheme = @"HTRoutesGlobalRoutesScheme";

@implementation HTXRouteDefinition (JLRParsingSupport)

#pragma mark - Parsing Route Variables

// 已修改原实现（因无法匹配 scheme://*/a/b/c 以*开头的路径参数）
- (NSDictionary <NSString *, NSString *> *)routeVariablesForRequest:(HTXRouterequest *)request {
    NSMutableDictionary *routeVariables = [NSMutableDictionary dictionary];
    
    BOOL isMatch = YES;
    NSString *currentPatternComponent = nil;
    NSInteger matchedIndex = -1;
    NSInteger nonWildcardIndexL = 0;
    
    for (NSInteger rIndex = 0; rIndex < request.pathComponents.count; rIndex++) {
        NSString *requestPathComponent = request.pathComponents[rIndex];
        NSString *patternComponent = nil;
        BOOL isPrePatternWildcard = [currentPatternComponent isEqualToString:@"*"];
        NSInteger pIndex = matchedIndex + 1;
        //isPrePatternWildcard ? index + 1 : index;
        if (pIndex < self.patternPathComponents.count) {
            patternComponent = self.patternPathComponents[pIndex];
        } else {// pattern matched to the end
            isMatch = YES;
            break;
        }
        
        // 参考案例：
        // jiaoyou://love/*/loveview/:topicId/*     requestPathComponent
        // jiaoyou://love/a/b/loveview/123456/x/y   patternComponent
        BOOL isCurrentPatternWildcard = [patternComponent isEqualToString:@"*"];
        if (isCurrentPatternWildcard) {
            nonWildcardIndexL = rIndex - 1;// -1
        }
        
        if (!isCurrentPatternWildcard) {
            if (!isPrePatternWildcard && [patternComponent hasPrefix:@":"]) {// `/*/:param` is invalid
                NSString *variableName = [self routeVariableNameForValue:patternComponent];
                NSString *variableValue = [self routeVariableValueForValue:requestPathComponent];
                
                BOOL decodePlusSymbols = NO;
                variableValue = [HTParsingUtilities variableValueFrom:variableValue decodePlusSymbols:decodePlusSymbols];
                
                routeVariables[variableName] = variableValue;
                matchedIndex ++;// matching URL :Params
            } else if ([patternComponent isEqualToString:requestPathComponent]) {
                if (isPrePatternWildcard) {
                    NSInteger nonWildcardIndexR = rIndex;
                    NSInteger length = nonWildcardIndexR - (nonWildcardIndexL + 1);
                    NSArray *components = [request.pathComponents subarrayWithRange:NSMakeRange(matchedIndex, length)];
                    [self addWildCardComponents:components
                               inRouteVariables:routeVariables];
                    
                    currentPatternComponent = patternComponent;
                }
                
                matchedIndex ++;// matching URL Components
            }
            
            if (!isPrePatternWildcard) {// still matching *
                currentPatternComponent = patternComponent;
            }
            continue;
        } else {// scheme://path/*/a/b/*
            NSAssert(!isPrePatternWildcard, @"/*/*/ is invalid route");
            if (matchedIndex == self.patternPathComponents.count - 1) {//pattern matched to the end
                isMatch = YES;
                NSArray *components = [request.pathComponents subarrayWithRange:NSMakeRange(rIndex, request.pathComponents.count - rIndex)];
                [self addWildCardComponents:components
                           inRouteVariables:routeVariables];
                break;
            } else {
                matchedIndex ++;
                currentPatternComponent = patternComponent;
                continue;
            }
        }
    }
    
    if (!isMatch) {
        routeVariables = nil;
    }
    
    return [routeVariables copy];
}

- (void)addWildCardComponents:(NSArray *)components inRouteVariables:(NSMutableDictionary *)routeVariables {
    NSMutableArray *wildCard = routeVariables[HTRouteWildcardComponentsKey];
    if (!wildCard) {
        wildCard = @[].mutableCopy;
        routeVariables[HTRouteWildcardComponentsKey] = wildCard;
    }
    
    [wildCard addObject:components];
}

- (NSString *)routeVariableNameForValue:(NSString *)value
{
    NSString *name = value;
    
    if (name.length > 1 && [name characterAtIndex:0] == ':') {
        // Strip off the ':' in front of param names
        name = [name substringFromIndex:1];
    }
    
    if (name.length > 1 && [name characterAtIndex:name.length - 1] == '#') {
        // Strip of trailing fragment
        name = [name substringToIndex:name.length - 1];
    }
    
    return name;
}

- (NSString *)routeVariableValueForValue:(NSString *)value
{
    // Remove percent encoding
    NSString *var = [value stringByRemovingPercentEncoding];
    
    if (var.length > 1 && [var characterAtIndex:var.length - 1] == '#') {
        // Strip of trailing fragment
        var = [var substringToIndex:var.length - 1];
    }
    
    return var;
}

#pragma mark - Creating Match Parameters

- (NSDictionary *)matchParametersForRequest:(HTXRouterequest *)request routeVariables:(NSDictionary <NSString *, NSString *> *)routeVariables
{
    NSAssert([routeVariables isKindOfClass:[NSDictionary class]], @" error ");
    
    NSMutableDictionary *matchParams = [NSMutableDictionary dictionary];
    
    // Add the parsed query parameters ('?a=b&c=d'). Also includes fragment.
    BOOL decodePlusSymbols = NO;
    [matchParams addEntriesFromDictionary:[HTParsingUtilities queryParams:request.queryParams decodePlusSymbols:decodePlusSymbols]];
    
    // Add the actual parsed route variables (the items in the route prefixed with ':').
    [matchParams addEntriesFromDictionary:routeVariables];
    
    // Add the additional parameters, if any were specified in the request.
    if (request.config.parameters != nil) {
        [matchParams addEntriesFromDictionary:request.config.parameters];
    }
    
    // Finally, add the base parameters. This is done last so that these cannot be overriden by using the same key in your route or query.
    [matchParams addEntriesFromDictionary:[self defaultMatchParametersForRequest:request]];
    
    return [matchParams copy];
}

- (NSDictionary *)defaultMatchParametersForRequest:(HTXRouterequest *)request
{
    return @{HTRoutePatternKey: self.pattern ?: [NSNull null], HTRouteURLKey: request.URL ?: [NSNull null], HTRouteSchemeKey: self.scheme ?: [NSNull null]};
}

@end
