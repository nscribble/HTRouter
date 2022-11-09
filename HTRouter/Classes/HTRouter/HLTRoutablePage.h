//
//  HLTRoutablePage.h
//  HTRouter
//
//  Created by cc on 2020/4/22.
//  Copyright © 2020 Jason. All rights reserved.
//  可路由页面协议（目前仅支持UIViewController子类）

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HLTRoutablePage <NSObject>

- (instancetype)initWithRouteParameters:(NSDictionary *)parameters;

@end

NS_ASSUME_NONNULL_END
