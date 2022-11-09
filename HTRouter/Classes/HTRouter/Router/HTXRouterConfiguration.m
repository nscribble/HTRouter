//
//  HTXRouterConfiguration.m
//  HTRouter
//
//  Created by cc on 2018/10/16.
//  Copyright © 2018 Jason. All rights reserved.
//

#import "HTXRouterConfiguration.h"

@interface HTXRouterConfiguration ()

@property (nonatomic, assign) HTRoutePreferOption preferOption;
@property (nonatomic, assign) HTRouteMatchMode matchMode;
@property (nonatomic, assign) HTRouteTransitionType transitionType;
@property (nonatomic, strong, readwrite) NSMutableDictionary *parametersM;
@property (nonatomic, strong, readwrite) NSMutableArray<id<HTRouteInterceptorProtocol>> *interceptorsM;

@end

@implementation HTXRouterConfiguration

- (NSString *)description {
    return [NSString stringWithFormat:@"%@, prefer: %@, match:%@, transition:%@", [super description], @(self.preferOption), @(self.matchMode), @(self.transitionType)];
}

+ (instancetype)createDefaultConfiguration {
    HTXRouterConfiguration *config = [self new];
    config.transitionType = HTRouteTransitionPush;
    config.parametersM = @{}.mutableCopy;
    
    return config;
}

- (NSDictionary<NSString *,id> *)parameters {
    return self.parametersM;// [self.parametersM copy];
}

- (NSArray *)interceptors {
    return [self.interceptorsM sortedArrayUsingComparator:^NSComparisonResult(id<HTRouteInterceptorProtocol>  _Nonnull obj1, id<HTRouteInterceptorProtocol>  _Nonnull obj2) {
        if (obj1.interceptorLevel > obj2.interceptorLevel) {
            return NSOrderedDescending;
        } else if (obj1.interceptorLevel < obj2.interceptorLevel) {
            return NSOrderedAscending;
        }
        return NSOrderedSame;
    }];
}

- (NSMutableArray *)interceptorsM {
    if (!_interceptorsM) {
        _interceptorsM = @[].mutableCopy;
    }
    
    return _interceptorsM;
}

- (id<HTRouterConfigurationProtocol>  _Nonnull (^)(HTRouteMatchMode))match {
    return ^(HTRouteMatchMode mode) {
        self.matchMode = mode;
        return self;
    };
}

- (id<HTRouterConfigurationProtocol>  _Nonnull (^)(NSDictionary * _Nonnull))addParameters {
    id blk = ^(NSDictionary *params){
        if ([params isKindOfClass:[NSDictionary class]]) {
            [self.parametersM addEntriesFromDictionary:params];
        }
        return self;
    };
    
    return blk;
}

// 待定：支持单个route配置interceptor
- (id<HTRouterConfigurationProtocol>  _Nonnull (^)(id<HTRouteInterceptorProtocol> _Nonnull))addInterceptor {
    id blk = ^(id<HTRouteInterceptorProtocol> interceptor) {
        if (interceptor && ![self.interceptorsM containsObject:interceptor]) {
            [self.interceptorsM addObject:interceptor];
        }
        return self;
    };
    return blk;
}

- (id<HTRouterConfigurationProtocol>  _Nonnull (^)(HTRouteTransitionType transition))transition {
    return ^(HTRouteTransitionType transition) {
        self.transitionType = transition;
        return self;
    };
}

- (id<HTRouterConfigurationProtocol>  _Nonnull (^)(HTRoutePreferOption))prefer {
    return ^(HTRoutePreferOption preferOption) {
        self.preferOption = preferOption;
        return self;
    };
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    HTXRouterConfiguration *copyed = [[self.class alloc] init];
    copyed.preferOption = self.preferOption;
    copyed.transitionType = self.transitionType;
    copyed.matchMode = self.matchMode;
    copyed.parametersM = [NSMutableDictionary dictionaryWithDictionary:self.parametersM];
    
    return copyed;
}

@end
