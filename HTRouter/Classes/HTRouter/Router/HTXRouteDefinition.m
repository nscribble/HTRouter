//
//  HTXRouteDefinition.m
//  HTRouter
//
//  Created by cc on 2018/10/16.
//  Copyright © 2018 Jason. All rights reserved.
//

#import "HTXRouteDefinition.h"
#import "HTXRouteDefinition+JLRParsingSupport.h"

@interface HTXRouteDefinition()

@property (nonatomic, assign, readwrite) NSUInteger routeHash;

@end

@implementation HTXRouteDefinition

@synthesize matchMode = _matchMode;
@synthesize continueNext = _continueNext;
@synthesize priority = _priority;
@synthesize scheme = _scheme;
@synthesize pattern = _pattern;
@synthesize patternPathComponents = _patternPathComponents;
@synthesize handlerBlock = _handlerBlock;
@synthesize objectBlock = _objectBlock;
@synthesize skipInterception = _skipInterception;

#pragma mark - Public

- (instancetype)initWithScheme:(NSString *)scheme routePattern:(NSString *)pattern handlerBlock:(HTRouteHandlerBlock)handlerBlock {
    if (self = [self initWithScheme:scheme routePattern:pattern]) {
        _handlerBlock = [handlerBlock copy];
    }
    return self;
}

- (instancetype)initWithScheme:(NSString *)scheme routePattern:(NSString *)pattern objectBlock:(HTRouteObjectBlock)objectBlock {
    if (self = [self initWithScheme:scheme routePattern:pattern]) {
        _objectBlock = [objectBlock copy];
    }
    return self;
}

- (instancetype)initWithScheme:(NSString *)scheme routePattern:(NSString *)pattern {
    if (self = [super init]) {
        _scheme = scheme;
        _priority = HTRoutePriorityDefault;
        _pattern = [pattern stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
        _patternPathComponents = [[_pattern componentsSeparatedByString:@"/"] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString * _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            return evaluatedObject.length > 0;
        }]];
    }
    return self;
}

- (HTXRouteresponse *)routeResponseForRequest:(HTXRouterequest *)request {
    // 是否匹配、匹配参数、query参数等
    BOOL fallback = NO;
    if (request.pathComponents.count != self.patternPathComponents.count) {
        BOOL patternContainsWildcard = [self.patternPathComponents containsObject:@"*"];
        
        if (!patternContainsWildcard) {
            HTRouteMatchMode matchMode = (request.config && request.config.matchMode) ? (self.matchMode & request.config.matchMode) : self.matchMode;
            BOOL canFallback = (matchMode & HTRouteMatchFallback) != 0;
            if (!canFallback || ![self shouldFallbackForRequest:request]) {
                return [HTXRouteresponse invalidMatchResponseForRequest:request];
            }
            else {
                fallback = YES;
                HTRouterLog(@"fallback of not strictly matched");
            }
        }
    }
    
    NSDictionary *routeVariables = [self routeVariablesForRequest:request];
    
    if (routeVariables != nil) {
        // It's a match, set up the param dictionary and create a valid match response
        NSDictionary *matchParams = [self matchParametersForRequest:request routeVariables:routeVariables];
        HTXRouteresponse *response = [HTXRouteresponse validMatchResponseWithParameters:matchParams request:request];
        response.isFallback = fallback;
        return response;
    } else {
        // nil variables indicates no match, so return an invalid match response
        return [HTXRouteresponse invalidMatchResponseForRequest:request];
    }
    
    return nil;
}

- (BOOL)shouldFallbackForRequest:(HTXRouterequest *)request {
    NSArray *patternPathComponents = self.patternPathComponents;
    NSArray *requestPathComponents = request.pathComponents;
    if (patternPathComponents.count > requestPathComponents.count) {
        return NO;
    }
    
    NSString *part;
    NSInteger matchIndexMax = NSNotFound;
    NSInteger MAX_INDEX = requestPathComponents.count;
    for (NSInteger index = 0; index < MAX_INDEX; index ++) {
        if (index >= patternPathComponents.count) {
            if (patternPathComponents.count == 0) {
                matchIndexMax = 0;
            }
            break;
        }
        NSString *patternPart = patternPathComponents[index];
        NSString *requestPart = requestPathComponents[index];
        if ([patternPart isEqualToString:requestPart] ||
            [patternPart hasPrefix:@":"] ||
            [patternPart isEqualToString:@"*"]) {
            part = patternPart;
            matchIndexMax = index;
            continue;
        } else if ([part isEqualToString:@"*"]) {
            continue;
        }
        break;
    }
    
    return matchIndexMax >= (NSInteger)patternPathComponents.count - 1;
}

- (BOOL)executeWithResponse:(HTXRouteresponse *)response callback:(nonnull HTRouteCompletionBlock)callback {
    if (!response) {
        return NO;
    }
    
    if (self.handlerBlock) {
        self.handlerBlock(self, response, callback);
    }
    else if (self.objectBlock) {
        id object = self.objectBlock(self, response);
        response.resultObject = object;
    } else {
        return NO;
    }
    
    return YES;
}

- (void)markAsSubroute:(HTXRouteDefinition *)route {
    self.routeHash = route.hash;
}


#pragma mark - Override

- (NSUInteger)hash {
    return self.pattern.hash ^ @(self.priority).hash ^ self.scheme.hash ^ self.patternPathComponents.hash;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@:<scheme: %@, pattern: %@, priority:%@", [super description], self.scheme, self.pattern, @(self.priority)];
}

@end
