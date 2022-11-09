//
//  HTRouter.m
//  HTRouter
//
//  Created by cc on 2018/10/15.
//  Copyright © 2018 Jason. All rights reserved.
//

#import "HTRouter.h"
#import "HTXRouterConfiguration.h"
#import "HTXRouter.h"

static void (^ht_router_logger)(NSString *msg);
void HTRouterLog(NSString *fmt, ...) {
    if (!ht_router_logger) {
        return;
    }
    
    va_list argptr;
    va_start(argptr, fmt);
    NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:argptr];
    va_end(argptr);
    
    if (ht_router_logger) {
        ht_router_logger(msg);
    }
}

#pragma mark - HTRouter

@interface HTRouter ()
<
HTRouteDelegate
>

@property (nonatomic, strong) NSMutableDictionary<NSString *, id<HTRouterProtocol>> *scheme2Routers;
@property (nonatomic, strong) NSMutableArray<id<HTRouteInterceptorProtocol>> *interceptorsM;

@end

@implementation HTRouter

+ (void)initialize {
    [[self defaultRouter] prepare];
}

+ (instancetype)defaultRouter {
    static HTRouter *router = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        router = [self new];
    });
    
    return router;
}


+ (void)setLogger:(void(^)(NSString *msg))blk {
    ht_router_logger = blk;
}

- (NSMutableDictionary<NSString *,id<HTRouterProtocol>> *)scheme2Routers {
    if (!_scheme2Routers) {
        _scheme2Routers = [NSMutableDictionary dictionary];
    }
    
    return _scheme2Routers;
}

- (NSMutableArray<id<HTRouteInterceptorProtocol>> *)interceptorsM {
    if (!_interceptorsM) {
        _interceptorsM = [NSMutableArray array];
    }
    
    return _interceptorsM;
}

#pragma mark - Prepare

- (void)prepare {
    
}

#pragma mark - Override

+ (Class)routerClass {
    return [HTXRouter class];
}

- (void)setRouteDelegateForXRouter:(id<HTRouterProtocol>)xrouter {
    xrouter.routeDelegate = self;
}

#pragma mark - Scheme

- (void)registerScheme:(NSString *)aScheme {
    if (!aScheme.length) {
        return;
    }
    
    NSString *scheme = [aScheme lowercaseString];
    if ([scheme isEqualToString:@"https"]) {
        scheme = @"http";
    }
    id<HTRouterProtocol> router = self.scheme2Routers[scheme];
    if (router) {
        return;
    }
    
    id<HTRouterProtocol> xrouter = [[self.class routerClass] routerForScheme:scheme];
    self.scheme2Routers[scheme] = (id<HTRouterProtocol>)xrouter;
    [self setRouteDelegateForXRouter:xrouter];
}

- (id<HTRouterProtocol>)routerForScheme:(NSString *)aScheme {
    if (!aScheme) {
        return nil;
    }
    
    NSString *scheme = [aScheme lowercaseString];
    if ([scheme isEqualToString:@"https"]) {
        scheme = @"http";
    }
    
    return self.scheme2Routers[scheme];
}

+ (id<HTRouterConfigurationProtocol>)createConfig {
    return [HTXRouterConfiguration createDefaultConfiguration];
}

#pragma mark - HTRouterProtocol

- (BOOL)canRouteURL:(nullable NSURL *)URL {
    id<HTRouterProtocol> router = [self routerForScheme:URL.scheme];
    if (!router) {
        return NO;
    }
    
    return [router canRouteURL:URL];
}

- (id<HTRouteDefinitionProtocol>)addRoute:(NSString *)routePattern handlerBlock:(HTRouteHandlerBlock)handlerBlock {
    return [self addRoute:routePattern definition:NULL handlerBlock:handlerBlock];
}

- (id<HTRouteDefinitionProtocol>)addRoute:(NSString *)routePattern
                               definition:(void(^)(id<HTRouteDefinitionProtocol>route))definition
                             handlerBlock:(HTRouteHandlerBlock)handlerBlock {
    return [self addRoute:routePattern definition:definition result:^id<HTRouteDefinitionProtocol>(id<HTRouterProtocol> router, NSString *pattern) {
        return [router addRoute:pattern definition:definition handlerBlock:handlerBlock];
    }];
}

- (id<HTRouteDefinitionProtocol>)addRoute:(NSString *)routePattern
                               definition:(void (^)(id<HTRouteDefinitionProtocol> _Nonnull))definition
                              objectBlock:(HTRouteObjectBlock)objectBlock {
    return [self addRoute:routePattern definition:definition result:^id<HTRouteDefinitionProtocol>(id<HTRouterProtocol> router, NSString *pattern) {
        return [router addRoute:pattern definition:definition objectBlock:objectBlock];
    }];
}

- (id<HTRouteDefinitionProtocol>)addRoute:(NSString *)routePattern definition:(void (^)(id<HTRouteDefinitionProtocol> _Nonnull))definition result:(id<HTRouteDefinitionProtocol> (^)(id<HTRouterProtocol> router, NSString *pattern))result {
    if (!result) {
        return nil;
    }
    
    NSString *scheme = [[NSURL URLWithString:routePattern] scheme];
    [self registerScheme:scheme];
    
    // 去除`scheme://`前缀
    NSRange range = [routePattern rangeOfString:@"://" options:NSCaseInsensitiveSearch range:NSMakeRange(0, scheme.length + 3)];
    if (range.location != NSNotFound) {
        NSRange r = NSMakeRange(0, range.location + range.length);
        routePattern = [routePattern stringByReplacingCharactersInRange:r withString:@""];
    }
    
    id<HTRouterProtocol> router = [self routerForScheme:scheme];
    if (!router) {
        return nil;
    }
    
    return result(router, routePattern);
}

- (void)routeURL:(NSURL *)URL configBlock:(id<HTRouterConfigurationProtocol> (^)(void))configuration completion:(HTRouteCompletionBlock _Nullable)completion {
    HTXRouterConfiguration *config = nil;
    if (configuration) {
        config = configuration();
    }
    
    [self routeURL:URL config:config completion:completion];
}

- (void)routeURL:(nullable NSURL *)URL config:(id<HTRouterConfigurationProtocol>)config completion:(HTRouteCompletionBlock _Nullable)completion {
    id<HTRouterProtocol> router = [self routerForScheme:URL.scheme];
    if (!router) {
        return;
    }
    
    [router routeURL:URL configuration:config completion:completion];
}

- (id)requestObjectForURL:(NSURL *)URL configBlock:(id<HTRouterConfigurationProtocol>  _Nonnull (^)(void))configBlock {
    id<HTRouterProtocol> router = [self routerForScheme:URL.scheme];
    if (!router) {
        return nil;
    }
    HTXRouterConfiguration *configuration = nil;
    if (configBlock) {
        configuration = configBlock();
    }
    
    return [router requestObjectForURL:URL configuration:configuration];
}

#pragma mark - <HTRouteDelegate>

- (void)router:(id<HTRouterProtocol>)router didRegisterRoute:(id<HTRouteDefinitionProtocol>)route {
    //HTRouterLog(@"didRegisterRoute: %@", route);
}

- (void)router:(id<HTRouterProtocol>)router willRoute:(id<HTRouteDefinitionProtocol>)route request:(id<HTRouteRequestProtocol>)request callback:(nonnull void (^)(BOOL))callback {
    //HTRouterLog(@"willRoute: %@", request);
    [self interceptRoute:route
                 request:request
                  onPass:^(id<HTRouteRequestProtocol> redirect) {
                      BOOL pass = !redirect || [redirect.URL isEqual:redirect.originalRequest];// 待定可继续路由策略
                      !callback ?: callback(pass);
                      if (!pass) {// 执行redirect
                          [router redirectRouteRequest:redirect completion:NULL];
                      }
                  }
             onInterrupt:^(id<HTRouteRequestProtocol> redirect) {
                 !callback ?: callback(NO);
                 if (redirect) {// 执行redirect
                     [router redirectRouteRequest:redirect completion:NULL];
                 }
             }];
}

- (void)router:(id<HTRouterProtocol>)router didRoute:(id<HTRouteDefinitionProtocol>)route response:(nonnull id<HTRouteResponseProtocol>)response {
    HTRouterLog(@"didRoute: %@, response: %@", route, response);
}

- (void)router:(id<HTRouterProtocol>)router didFailedToRoute:(id<HTRouteRequestProtocol>)request {
    HTRouterLog(@"didFailedToRoute: %@", request);
    if (self.onFallback) {
        self.onFallback(request);
    }
}

- (void)router:(id<HTRouterProtocol>)router didUnRegisterRoute:(id<HTRouteDefinitionProtocol>)route {
    
}

#pragma mark - Interceptor

- (void)addInterceptor:(id<HTRouteInterceptorProtocol>)interceptor {
    if (!interceptor || ![interceptor conformsToProtocol:@protocol(HTRouteInterceptorProtocol)]) {
        return;
    }
    
    if (![self.interceptorsM containsObject:interceptor]) {
        [self.interceptorsM addObject:interceptor];
    }
}

- (NSArray<id<HTRouteInterceptorProtocol>> *)sortedInterceptors {
    NSArray<id<HTRouteInterceptorProtocol>> *interceptors = [self.interceptorsM copy];
    interceptors = [interceptors sortedArrayUsingComparator:^NSComparisonResult(id<HTRouteInterceptorProtocol>  _Nonnull obj1, id<HTRouteInterceptorProtocol>  _Nonnull obj2) {
        return (obj1.interceptorLevel == obj2.interceptorLevel) ? NSOrderedSame :
        (obj1.interceptorLevel > obj2.interceptorLevel ? NSOrderedDescending : NSOrderedAscending);
    }];
    
    return interceptors;
}

// 路由拦截与重定向
- (void)interceptRoute:(id<HTRouteDefinitionProtocol>)route
               request:(id<HTRouteRequestProtocol>)request
                onPass:(void (^)(id<HTRouteRequestProtocol> redirect))onPass
           onInterrupt:(void (^)(id<HTRouteRequestProtocol> redirect))onInterrupt {
    NSArray<id<HTRouteInterceptorProtocol>> *interceptors = [self sortedInterceptors];
    [self intercepts:interceptors
               route:route
             request:request
              onPass:onPass
         onInterrupt:onInterrupt];
}

- (void)intercepts:(NSArray<id<HTRouteInterceptorProtocol>> *)interceptors
             route:(id<HTRouteDefinitionProtocol>)route
           request:(id<HTRouteRequestProtocol>)request
            onPass:(void (^)(id<HTRouteRequestProtocol> redirect))onPass
       onInterrupt:(void (^)(id<HTRouteRequestProtocol> redirect))onInterupt {
    if (route.skipInterception) {
        !onPass ?: onPass(nil);
        return;
    }
    if (interceptors.count <= 0) {
        !onPass ?: onPass( request.originalRequest ? request : nil );
        return;
    }
    
    id<HTRouteInterceptorProtocol> interceptor = interceptors.firstObject;
    [interceptor onRoute:route request:request result:^(BOOL pass, id<HTRouteRequestProtocol>  _Nullable redirectRequest) {
        if (pass) {
            if (interceptors.count == 1) {// all passed
                !onPass ?: onPass(redirectRequest);
            } else {
                id<HTRouteRequestProtocol> nextRequest = redirectRequest ?: request;
                NSMutableArray *nextInterceptors = [interceptors mutableCopy];
                [nextInterceptors removeObjectAtIndex:0];
                
                // intercept on the remaining interceptors
                [self intercepts:nextInterceptors
                           route:route
                         request:nextRequest
                          onPass:onPass
                     onInterrupt:onInterupt];
            }
        } else {
            !onInterupt ?: onInterupt(redirectRequest);
        }
    }];
}

@end
