//
//  HTXRouter.m
//  HTRouter
//
//  Created by cc on 2018/10/15.
//  Copyright © 2018 Jason. All rights reserved.
//

#import "HTXRouter.h"
#import "HTXRouteDefinition.h"
#import "HTParsingUtilities.h"
#import "HTXRouteRequest.h"
#import "HTXRouteResponse.h"

#define ST_GUARD_NOT_NIL(arg) \
if (arg == nil) { \
return;\
}

#define __routes__ @"__routes__"

@interface HTXRouter()

@property (nonatomic, assign) BOOL strictlyMatched;
@property (nonatomic, copy) NSString *scheme;
@property (nonatomic, strong) NSMutableDictionary *routePathMapper;

@end

@implementation HTXRouter

@synthesize routeDelegate = _routeDelegate;

#pragma mark - Schemes

+ (instancetype)routerForScheme:(NSString *)scheme {
    HTXRouter *router = [self new];
    router.scheme = scheme;
    router.strictlyMatched = YES;
    
    return router;
}

#pragma mark - Pattern Mapper

- (NSMutableDictionary *)routePathMapper {
    if (!_routePathMapper) {
        _routePathMapper = @{}.mutableCopy;
    }
    
    return _routePathMapper;
}

- (NSMutableDictionary *)_createRouteMapperForPatternComponents:(NSArray *)pathComponents {
    NSMutableDictionary *subRoutes = self.routePathMapper;
    for (NSString *pathComponent in pathComponents) {
        if (![subRoutes objectForKey:pathComponent]) {
            subRoutes[pathComponent] = [[NSMutableDictionary alloc] init];
        }
        subRoutes = subRoutes[pathComponent];
    }
    
    return subRoutes;
}

// 搜索能匹配请求参数的路由定义（目前仅支持 :namedParam及(/optionalParam)
- (NSMutableArray<HTXRouteDefinition *> *)_searchMatchedRoutesForPatternComponents:(NSArray *)pathComponents {
    BOOL supportScalar = YES;
    NSString *currentPart = nil;
    NSMutableArray<HTXRouteDefinition *> *matchedRoutes = @[].mutableCopy;
    
    NSMutableDictionary *subRoutes = self.routePathMapper;
    if (subRoutes[__routes__]) {// for pattern: `scheme://`
        NSArray *routes = subRoutes[__routes__];
        [matchedRoutes addObjectsFromArray:routes];
    }
    
    for (NSString *pathComponent in pathComponents) {
        NSString *part = nil;
        if ([subRoutes objectForKey:pathComponent]) {
            part = pathComponent;
        } else if (supportScalar) {// /path/*/a(/b)/c
            NSArray *keys = [[subRoutes allKeys] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
                if ([evaluatedObject containsString:@"*"]) {
                    return YES;
                }
                if ([evaluatedObject hasPrefix:@":"]) {
                    return YES;
                }
                return NO;
            }]];
            BOOL stop = keys.count <= 0;
            if (!stop) {
                part = keys.firstObject;
            } else if([currentPart isEqualToString:@"*"]) {// 继续匹配
                continue;
            } else {
                break;
            }
        }
        
        subRoutes = subRoutes[part];
        currentPart = part;
        if (subRoutes[__routes__]) {
            NSArray *routes = subRoutes[__routes__];
            [matchedRoutes addObjectsFromArray:routes];
        }
    }
    
    return matchedRoutes;
}

#pragma mark - Registering

- (BOOL)canRouteURL:(nullable NSURL *)URL {// 忽略拦截器
    HTXRouterequest *request = [[HTXRouterequest alloc] initWithURL:URL configuration:nil];
    
    __block BOOL result = NO;
    [self _enumerateOnSearchRoutesForRequest:request handler:^(HTXRouteDefinition *route, BOOL *stop, void (^onCallback)(BOOL lastSuccess)) {
        
        HTXRouteresponse *response = [route routeResponseForRequest:request];
        if (response.isMatched) {
            result = YES;
        }
        
        if (onCallback) {
            onCallback(response.isMatched);
        }
        
        if (result) {
            *stop = YES;
        }
    } execute:NO];
    
    return result;
}

- (id<HTRouteDefinitionProtocol>)addRoute:(NSString *)routePattern
                               definition:(void (^)(id<HTRouteDefinitionProtocol> _Nonnull))definition
                             handlerBlock:(HTRouteHandlerBlock)handlerBlock {
    __weak typeof(self) weakSelf = self;
    return [self addRoute:routePattern definition:definition result:^id<HTRouteDefinitionProtocol>(NSString *pattern) {
        return [[HTXRouteDefinition alloc] initWithScheme:weakSelf.scheme routePattern:pattern handlerBlock:handlerBlock];
    }];
}

- (id<HTRouteDefinitionProtocol>)addRoute:(NSString *)routePattern
                               definition:(void (^)(id<HTRouteDefinitionProtocol> _Nonnull))definition
                              objectBlock:(HTRouteObjectBlock)objectBlock {
    __weak typeof(self) weakSelf = self;
    return [self addRoute:routePattern definition:definition result:^id<HTRouteDefinitionProtocol>(NSString *pattern) {
        return [[HTXRouteDefinition alloc] initWithScheme:weakSelf.scheme routePattern:pattern objectBlock:objectBlock];
    }];
}

- (id<HTRouteDefinitionProtocol>)addRoute:(NSString *)routePattern
                               definition:(void (^)(id<HTRouteDefinitionProtocol> _Nonnull))definition
                                   result:(id<HTRouteDefinitionProtocol> (^)(NSString *pattern))result {
    if (!result) {
        return nil;
    }
    
    HTXRouteDefinition *route = result(routePattern);
    !definition ?: definition(route);
    if (![routePattern containsString:@"("]) {
        [self _registerRoute:route];
    }
    [route markAsSubroute:route];
    
    // /path(/optional1)(/optional1)展开
    NSArray <NSString *> *optionalRoutePatterns = [HTParsingUtilities expandOptionalRoutePatternsForPattern:routePattern];
    __block HTXRouteDefinition *subroute = nil;
    if (optionalRoutePatterns.count > 0) {
        [optionalRoutePatterns enumerateObjectsUsingBlock:^(NSString * _Nonnull pattern, NSUInteger idx, BOOL * _Nonnull stop) {
            HTXRouteDefinition *optional = result(pattern);
            !definition ?: definition(optional);
            [self _registerRoute:optional];
            [optional markAsSubroute:route];
            
            if (!subroute) {
                subroute = optional;//
            }
        }];
    }
    
    return route;
}
- (void)_registerRoute:(HTXRouteDefinition *)route {
    ST_GUARD_NOT_NIL(route);
    
    NSMutableDictionary *routeMapper = [self _createRouteMapperForPatternComponents:route.patternPathComponents];
    NSMutableArray *handlers = routeMapper[__routes__];
    if (!handlers) {
        routeMapper[__routes__] = @[].mutableCopy;
        handlers = routeMapper[__routes__];
    }
    if (route) {
        [handlers addObject:route];
    }
    
    if ([self.routeDelegate respondsToSelector:@selector(router:didRegisterRoute:)]) {
        [self.routeDelegate router:self didRegisterRoute:route];
    }
}

- (void)_unregisterRoute:(HTXRouteDefinition *)route {
    ST_GUARD_NOT_NIL(route);
    
    NSMutableDictionary *routeMapper = [self _createRouteMapperForPatternComponents:route.patternPathComponents];
    NSMutableArray *handlers = routeMapper[__routes__];
    if (!handlers) {
        return;
    }
    [handlers removeObject:route];
    
    if ([self.routeDelegate respondsToSelector:@selector(router:didUnRegisterRoute:)]) {
        [self.routeDelegate router:self didUnRegisterRoute:route];
    }
}

#pragma mark - Routing

- (void)routeURL:(NSURL *)URL configuration:(id<HTRouterConfigurationProtocol>)configuration completion:(HTRouteCompletionBlock)completion {
    if (!URL) {
        return;
    }
    
    HTXRouterequest *request = [[HTXRouterequest alloc] initWithURL:URL configuration:configuration];
    [self _routeRequest:request completion:completion];
}

- (id)requestObjectForURL:(NSURL *)URL configuration:(id<HTRouterConfigurationProtocol>)configuration {
    if (!URL) {
        return nil;
    }
    
    __block id resultObject = nil;
    HTXRouterequest *request = [[HTXRouterequest alloc] initWithURL:URL configuration:configuration];
    [self _enumerateOnSearchRoutesForRequest:request handler:^(HTXRouteDefinition *route, BOOL *stop, void (^onCallback)(BOOL lastSuccess)) {//TODO: 修改为HTRouteRespCode
        HTXRouteresponse *response = [route routeResponseForRequest:request];
        if (!response.isMatched) {
            return ;
        }
        
        __block BOOL success = YES;
        success &= [route executeWithResponse:response callback:^(BOOL rs) {
            //success = rs;
        }];
        
        if (success) {
            resultObject = response.resultObject;
            *stop = YES;
        }
        
        if (onCallback) {
            onCallback(success);
        }
    } execute:YES];
    
    return resultObject;
}

- (void)redirectRouteRequest:(id<HTRouteRequestProtocol>)request completion:(HTRouteCompletionBlock)completion {
    [self _routeRequest:request completion:completion];
}

- (void)_routeRequest:(id<HTRouteRequestProtocol>)request completion:(HTRouteCompletionBlock)completion {
    // TODO: Interceptor是否修改为在searchRoutes之前进行？
    [self _enumerateOnSearchRoutesForRequest:request handler:^(HTXRouteDefinition *route, BOOL *stop, void (^onCallback)(BOOL lastSuccess)) {
        if ([self.routeDelegate respondsToSelector:@selector(router:willRoute:request:callback:)]) {
            [self.routeDelegate router:self willRoute:route request:request callback:^(BOOL pass) {
                BOOL result = !pass ? NO : [self _executeRoute:route request:request completion:completion];// 执行路由
                if (onCallback) {
                    onCallback(result);
                }
            }];
        } else {
            BOOL result = [self _executeRoute:route request:request completion:completion];
            if (onCallback) {
                onCallback(result);
            }
        }
    } execute:YES];
}

// do the real route jobs
- (BOOL)_executeRoute:(id<HTRouteDefinitionProtocol>)route request:(id<HTRouteRequestProtocol>)request completion:(HTRouteCompletionBlock)completion{
    BOOL result = NO;
    HTXRouteresponse *response = [route routeResponseForRequest:request];
    if (!response.isMatched) {
        return NO;
    }
    
    __block BOOL success = YES;
    success &= [route executeWithResponse:response callback:^(BOOL rs) {
        //success = rs;// TODO: 路由定义中的业务层可控制是否成功回调
    }];
    result |= success;
    
    if (result && [self.routeDelegate respondsToSelector:@selector(router:didRoute:response:)]) {
        [self.routeDelegate router:self didRoute:route response:response];
    }
    
    if (completion) {
        completion(success);
    }
    
    return result;
}

// search and enumerate all the matched routes for the request
- (void)_enumerateOnSearchRoutesForRequest:(HTXRouterequest *)request handler:(void (^)(HTXRouteDefinition *definition, BOOL *stop, void (^onCallback)(BOOL lastSuccess)))handler execute:(BOOL)execute {
    NSURL *URL = request.URL;
    NSURLComponents *URLComponents = [NSURLComponents componentsWithString:URL.absoluteString];
    NSArray *pathComponents = [HTParsingUtilities extractPathComponentsForURLComponents:URLComponents];
    
    NSMutableArray<HTXRouteDefinition *> *routes = [self _searchMatchedRoutesForPatternComponents:pathComponents];
    if (routes.count <= 0) {
        if (execute && [self.routeDelegate respondsToSelector:@selector(router:didFailedToRoute:)]) {
            [self.routeDelegate router:self didFailedToRoute:request];
        }
        return;
    }
    
    // sort matched routes
    if (routes.count > 1) {
        NSSortDescriptor *sortPriority = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(priority)) ascending:NO];
        NSSortDescriptor *sortMatchLevel = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(pattern)) ascending:NO comparator:^NSComparisonResult(NSString *  _Nonnull obj1, NSString *  _Nonnull obj2) {
            if (obj1.length < obj2.length) {
                return NSOrderedAscending;
            } else if (obj1.length > obj2.length) {
                return NSOrderedDescending;
            }
            return NSOrderedSame;
        }];
        
        HTRoutePreferOption reqOption = request.config ? request.config.preferOption : HTRoutePreferPriority;
        BOOL preferPriority = (reqOption & HTRoutePreferPriority) != 0;
        [routes sortUsingDescriptors:preferPriority ? @[sortPriority, sortMatchLevel] : @[sortMatchLevel, sortPriority]];
    }
    
    NSMutableDictionary *routedRoutes = @{}.mutableCopy;
    [self _enumerateOnRoutes:routes request:request handler:handler routedHashes:routedRoutes execute:execute];
}

- (void)_enumerateOnRoutes:(NSArray *)routes request:(HTXRouterequest *)request handler:(void (^)(HTXRouteDefinition *definition, BOOL *stop, void (^onCallback)(BOOL lastSuccess)))handler routedHashes:(NSMutableDictionary *)routedHashes execute:(BOOL)execute{
    if (routes.count <= 0) {
        return;
    }
    
    HTXRouteDefinition *route = routes.firstObject;
    
    if (routedHashes[@(route.routeHash)]) {// for the 'same' route definition
        return ;
    }
    routedHashes[@(route.routeHash)] = @(1);
    
    __block BOOL atLeastOneSuccess = NO;
    BOOL isTheLastOne = routes.count == 1;
    if (handler) {
        BOOL callerStop = NO;
        handler(route, &callerStop, ^(BOOL lastSuccess) {// callback
            atLeastOneSuccess |= lastSuccess;
            
            if ((!route.continueNext || isTheLastOne) && !atLeastOneSuccess) {
                if (execute) {
                    if ([self.routeDelegate respondsToSelector:@selector(router:didFailedToRoute:)]) {
                        [self.routeDelegate router:self didFailedToRoute:request];
                    }
                }
                else {
                    HTRouterLog(@"Can Not Route Request: %@", request);
                }
            }
            
            if (route.continueNext && !isTheLastOne && !callerStop) {
                NSMutableArray *nextRoutes = [routes mutableCopy];
                [nextRoutes removeObjectAtIndex:0];
                
                [self _enumerateOnRoutes:nextRoutes
                                 request:request
                                 handler:handler
                            routedHashes:routedHashes
                                 execute:execute];
            }
        });
    }
    
}

@end
