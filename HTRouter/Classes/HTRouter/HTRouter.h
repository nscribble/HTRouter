//
//  HTRouter.h
//  HTRouter
//
//  Created by cc on 2018/10/15.
//  Copyright © 2018 Jason. All rights reserved.
//  路由器

#import <Foundation/Foundation.h>
#import "HTRouterProtocol.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^HTRouteFallbackBlock)(id<HTRouteRequestProtocol> request);

@interface HTRouter : NSObject

@property (nonatomic, copy) HTRouteFallbackBlock onFallback;

/**
 获取Router单例
 */
+ (instancetype)defaultRouter;

#pragma mark -

+ (id<HTRouterConfigurationProtocol>)createConfig;

//! 查询路由系统能否响应URL
- (BOOL)canRouteURL:(nullable NSURL *)URL;

//! 注册Route（路由处理）
- (id<HTRouteDefinitionProtocol>)addRoute:(NSString *)routePattern
                               definition:(void(^_Nullable)(id<HTRouteDefinitionProtocol>route))definition
                             handlerBlock:(HTRouteHandlerBlock)handlerBlock;
//! 注册Route（提供Object）
- (id<HTRouteDefinitionProtocol>)addRoute:(NSString *)routePattern
                               definition:(void(^_Nullable)(id<HTRouteDefinitionProtocol>route))definition
                              objectBlock:(HTRouteObjectBlock _Nullable)objectBlock;

//! 执行路由
- (void)routeURL:(NSURL *)URL
     configBlock:(id<HTRouterConfigurationProtocol> (^_Nullable)(void))configuration
      completion:(HTRouteCompletionBlock _Nullable)completion;

//! 根据路由URL获取对象
- (id)requestObjectForURL:(NSURL *)URL
              configBlock:(id<HTRouterConfigurationProtocol> (^_Nullable)(void))configBlock;

#pragma mark - Override

//! 指定 路由执行器类型（内置：HTXRouter）
+ (Class)routerClass;

#pragma mark - Interceptor

- (void)addInterceptor:(id<HTRouteInterceptorProtocol>)interceptor;

#pragma mark - Logger

+ (void)setLogger:(void(^)(NSString *msg))blk;

@end

NS_ASSUME_NONNULL_END
