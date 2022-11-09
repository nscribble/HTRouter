//
//  HTRouterProtocol.h
//  HTRouter
//
//  Created by cc on 2018/10/15.
//  Copyright © 2018 Jason. All rights reserved.
//  路由库协议

#import <Foundation/Foundation.h>

//! 转场方式
typedef NS_ENUM(NSInteger, HTRouteTransitionType) {
    HTRouteTransitionPush,
    HTRouteTransitionPresent,
    HTRouteTransitionModal,
};

//! 路由匹配模式
typedef NS_ENUM(NSInteger, HTRouteMatchMode) {
    HTRouteMatchStrictly    = 1 << 0,   // 严格匹配，要求路径完全一致
    HTRouteMatchFallback    = 1 << 1,   // 允许降级匹配，路由请求（前缀）能匹配路由定义完整路径即可
};

static CGFloat HTRoutePriorityDefault = 1;
static CGFloat HTRoutePriorityHigh = 100;

static CGFloat HTRouteInterceptLevelDefault = 1;
static CGFloat HTRouteInterceptLevelHigh = 100;

extern void HTRouterLog(NSString *fmt, ...);

NS_ASSUME_NONNULL_BEGIN

@protocol HTRouteDefinitionProtocol;
@protocol HTRouterConfigurationProtocol;
@protocol HTRouterProtocol;
@protocol HTRouteRequestProtocol;
@protocol HTRouteInterceptorProtocol;

#pragma mark - <HTRouteRequestProtocol>

//! 路由请求
@protocol HTRouteRequestProtocol <NSObject>

@property (nonatomic, copy, readonly) NSURL *URL;
@property (nonatomic, strong, readonly) id<HTRouterConfigurationProtocol> config;// request params, etc.
@property (nonatomic, strong, readonly) NSArray *pathComponents;
@property (nonatomic, strong, readonly) NSDictionary *queryParams;
@property (nonatomic, strong, readonly) id<HTRouteRequestProtocol> originalRequest;// 初始请求
@property (nonatomic, weak, readonly) id<HTRouteRequestProtocol> redirectedRequest;// 重定向后请求

//! 修改请求
- (void)updateWithConfigBlock:(void (^)(id<HTRouterConfigurationProtocol> config))configBlock;
//! 重定向（返回新的实例）
- (id<HTRouteRequestProtocol>)redirectForURL:(NSURL *)URL configBlock:(void (^)(id<HTRouterConfigurationProtocol> config))configBlock;

@end

#pragma mark - <HTRouteResponseProtocol>
//! 路由响应
@protocol HTRouteResponseProtocol <NSObject>

@property (nonatomic, assign) BOOL isMatched;
@property (nonatomic, assign) BOOL isFallback;
@property (nonatomic, strong, readonly) id<HTRouteRequestProtocol> request;
@property (nonatomic, copy, readonly, nullable) NSDictionary *parameters;
@property (nonatomic, strong) NSObject *resultObject;

@end

#pragma mark - <HTRouterConfigurationProtocol>

//! 路由匹配偏好
typedef NS_OPTIONS(NSInteger, HTRoutePreferOption) {
    HTRoutePreferPriority       = 1<<0, // 优先级（默认）
    HTRoutePreferPatternMatched = 1<<1, // 匹配深度
};

//! 路由请求配置
@protocol HTRouterConfigurationProtocol <NSObject, NSCopying>

@property (nonatomic, copy, readonly) id<HTRouterConfigurationProtocol> _Nonnull (^match)(HTRouteMatchMode matchMode);
@property (nonatomic, copy, readonly) id<HTRouterConfigurationProtocol> _Nonnull (^prefer)(HTRoutePreferOption preferOption);
@property (nonatomic, copy, readonly) id<HTRouterConfigurationProtocol> _Nonnull (^transition)(HTRouteTransitionType transition);
@property (nonatomic, copy, readonly) id <HTRouterConfigurationProtocol> _Nonnull (^addParameters)(NSDictionary *parameters);
@property (nonatomic, copy, readonly) id <HTRouterConfigurationProtocol> _Nonnull (^addInterceptor)(id<HTRouteInterceptorProtocol> interceptor);// 暂不支持
// from 来源配置

@property (nonatomic, assign, readonly) HTRoutePreferOption preferOption;
@property (nonatomic, assign, readonly) HTRouteTransitionType transitionType;
@property (nonatomic, assign, readonly) HTRouteMatchMode matchMode;
@property (nonatomic, strong, readonly, nullable) NSDictionary<NSString *,id> *parameters;
@property (nonatomic, strong, readonly, nullable) NSArray *interceptors;

@end

#pragma mark - <HTRouteDelegate>

//! 路由事件代理
@protocol HTRouteDelegate <NSObject>

- (void)router:(id<HTRouterProtocol>)router didRegisterRoute:(id<HTRouteDefinitionProtocol>)route;
- (void)router:(id<HTRouterProtocol>)router didUnRegisterRoute:(id<HTRouteDefinitionProtocol>)route;
- (void)router:(id<HTRouterProtocol>)router willRoute:(id<HTRouteDefinitionProtocol>)route request:(id<HTRouteRequestProtocol>)request callback:(void(^)(BOOL pass))callback;
- (void)router:(id<HTRouterProtocol>)router didRoute:(id<HTRouteDefinitionProtocol>)route response:(id<HTRouteResponseProtocol>)response;
- (void)router:(id<HTRouterProtocol>)router didFailedToRoute:(id<HTRouteRequestProtocol>)request;

@end

#pragma mark - <HTRouterProtocol>

typedef NS_ENUM(NSInteger, HTRouteRespCode) {
    HTRouteRespCodeSuccess      = 200,
    HTRouteRespCodeRedirect302  = 302,
    HTRouteRespCodeForbidden403 = 403,  // 如未登录
    HTRouteRespCodeNotFound404  = 404,
};

// response.onNext | response.onComplete(code)
typedef void(^HTRouteCompletionBlock2)(HTRouteRespCode code);
typedef void(^HTRouteCompletionBlock)(BOOL success);
typedef void(^HTRouteHandlerBlock)(id<HTRouteDefinitionProtocol>route, id<HTRouteResponseProtocol> response, HTRouteCompletionBlock callback);
typedef id _Nullable (^HTRouteObjectBlock)(id<HTRouteDefinitionProtocol>route, id<HTRouteResponseProtocol> response);

//! 路由执行器
@protocol HTRouterProtocol <NSObject>

//! 事件拦截
@property (nonatomic, weak) id<HTRouteDelegate> routeDelegate;

//! 获取scheme对应的路由执行器
+ (instancetype)routerForScheme:(NSString *)scheme;

//! 查询路由系统能否响应URL
- (BOOL)canRouteURL:(nullable NSURL *)URL;

/**
 注册路由
 
 @param routePattern 路径
 @param definition 路由定义配置
 @param handlerBlock 路由命中处理
 @return 路由定义
 */
- (id<HTRouteDefinitionProtocol>)addRoute:(NSString *)routePattern
                               definition:(void(^_Nullable)(id<HTRouteDefinitionProtocol>route))definition
                             handlerBlock:(HTRouteHandlerBlock)handlerBlock;

/**
 执行路由
 
 @param URL 路由链接
 @param configuration 路由请求配置
 @param completion 路由完成回调
 @return 是否路由成功
 */
- (void)routeURL:(nullable NSURL *)URL
   configuration:(id<HTRouterConfigurationProtocol>)configuration
      completion:(HTRouteCompletionBlock _Nullable)completion;

//! 注册Route（提供Object）
- (id<HTRouteDefinitionProtocol>)addRoute:(NSString *)routePattern
                               definition:(void(^_Nullable)(id<HTRouteDefinitionProtocol>route))definition
                              objectBlock:(HTRouteObjectBlock _Nullable)objectBlock;
//! 根据路由URL获取对象
- (id)requestObjectForURL:(NSURL *)URL
            configuration:(id<HTRouterConfigurationProtocol>)configuration;

- (void)redirectRouteRequest:(id<HTRouteRequestProtocol>)request
                  completion:(HTRouteCompletionBlock _Nullable)completion;

@end

#pragma mark - <HTRouteDefinitionProtocol>

//! 路由定义
@protocol HTRouteDefinitionProtocol <NSObject>

@property (nonatomic, assign) HTRouteMatchMode matchMode;// 匹配模式
@property (nonatomic, assign) BOOL continueNext;// 匹配成功后是否允许后续匹配
@property (nonatomic, assign) CGFloat priority;// 优先级
@property (nonatomic, assign) BOOL skipInterception;// 是否忽略全局拦截器

@property (nonatomic, copy, readonly) NSString *scheme;
@property (nonatomic, copy, readonly) NSString *pattern;
@property (nonatomic, copy, readonly) NSArray <NSString *> *patternPathComponents;
@property (nonatomic, copy, readonly) HTRouteHandlerBlock handlerBlock;
@property (nonatomic, copy, readonly) HTRouteObjectBlock objectBlock;// 待定

- (instancetype)initWithScheme:(NSString *)scheme routePattern:(NSString *)pattern handlerBlock:(HTRouteHandlerBlock)handlerBlock;
- (instancetype)initWithScheme:(NSString *)scheme routePattern:(NSString *)pattern objectBlock:(HTRouteObjectBlock)objectBlock;

- (id<HTRouteResponseProtocol>)routeResponseForRequest:(id<HTRouteRequestProtocol>)request;
- (BOOL)executeWithResponse:(id<HTRouteResponseProtocol>)response callback:(HTRouteCompletionBlock)callback;

@end

typedef void(^HTRouteInterceptorResultBlock)(BOOL pass, id<HTRouteRequestProtocol>_Nullable  redirectRequest);

//! 路由拦截器
@protocol HTRouteInterceptorProtocol <NSObject>

- (NSInteger)interceptorLevel;
//! 拦截器的意义要求此方法须同步方式执行
- (void)onRoute:(id<HTRouteDefinitionProtocol>)route request:(id<HTRouteRequestProtocol>)request result:(HTRouteInterceptorResultBlock)result;

@end

NS_ASSUME_NONNULL_END
