//
//  HTRouterTests.m
//  HTRouterTests
//
//  Created by nscribble on 02/21/2019.
//  Copyright (c) 2019 nscribble. All rights reserved.
//

// https://github.com/kiwi-bdd/Kiwi

SPEC_BEGIN(InitialTests)

describe(@"My initial tests", ^{

  context(@"will fail", ^{

      it(@"can do maths", ^{
          [[@1 should] equal:@2];
      });

      it(@"can read", ^{
          [[@"number" should] equal:@"string"];
      });
    
      it(@"will wait and fail", ^{
          NSObject *object = [[NSObject alloc] init];
          [[expectFutureValue(object) shouldEventually] receive:@selector(autoContentAccessingProxy)];
      });
  });

  context(@"will pass", ^{
    
      it(@"can do maths", ^{
        [[@1 should] beLessThan:@23];
      });
    
      it(@"can read", ^{
          [[@"team" shouldNot] containString:@"I"];
      });  
  });
  
});

SPEC_END

//#pragma mark - Test
//
//#if DEBUG
//
//- (void)testHttp {
//    [self.router addRoute:@"http://*/wap/special/emotion(/*)"
//               definition:^(id<HTRouteDefinitionProtocol>  _Nonnull route) {
//
//               } handlerBlock:^(id<HTRouteDefinitionProtocol>  _Nonnull route, id<HTRouteResponseProtocol>  _Nonnull response, HTRouteCompletionBlock  _Nonnull callback) {
//                   NSLog(@"[HTTP] route=%@, response=%@", route, response);
//               }];
//
//    [self.router routeURL:[NSURL URLWithString:@"https://love.163.com/wap/special/emotion/test?style=3fcf78aa"]
//              configBlock:^id<HTRouterConfigurationProtocol> _Nonnull{
//                  return [HTRouter createConfig]
//                  .match(HTRouteMatchStrictly)
//                  .prefer(HTRoutePreferPatternMatched);
//              } completion:^(BOOL success) {
//                  NSLog(@"[HTTP] success=%@", @(success));
//              }];
//}
//
//- (void)testNamedParam {
//
//}
//
//- (void)testOptional {
//    [self.router addRoute:@"jiaoyou://loveview/*" // (/:userId)
//               definition:NULL
//             handlerBlock:^(id<HTRouteDefinitionProtocol>  _Nonnull route, id<HTRouteResponseProtocol>  _Nonnull response, HTRouteCompletionBlock  _Nonnull callback) {
//                 if (callback) {
//                     callback(YES);
//                 }
//             }];
//    // jiaoyou://loveview/233333
//    // jiaoyou://loveview
//
//    [self.router routeURL:[NSURL URLWithString:@"jiaoyou://loveview/233333/hehe"]
//              configBlock:^id<HTRouterConfigurationProtocol> _Nonnull{
//                  return [HTRouter createConfig]
//                  .addParameters(@{})
//                  .transition(HTRouteTransitionPresent);
//              }completion:^(BOOL success) {
//              }];
//}
//
//- (void)testWildcard {
//    [self.router addRoute:@"jiaoyou://(*/)verified/house"
//               definition:NULL
//             handlerBlock:^(id<HTRouteDefinitionProtocol>  _Nonnull route, id<HTRouteResponseProtocol>  _Nonnull response, HTRouteCompletionBlock  _Nonnull callback) {
//             }];
//
//    //    [self.router routeURL:[NSURL URLWithString:@"jiaoyou://pay/services"]
//    //              configBlock:NULL
//    //               completion:^(BOOL success) {
//    //               }];
//    [self.router routeURL:[NSURL URLWithString:@"jiaoyou://love.163.com/verified/education"]
//              configBlock:NULL
//               completion:NULL];
//
//    [self.router addRoute:@"jiaoyou://wildcard(/*)/profile" // (/:userId)
//               definition:^(id<HTRouteDefinitionProtocol>  _Nonnull route) {
//                   route.continueNext = YES;
//                   route.matchMode = HTRouteMatchStrictly;
//                   route.priority = HTRoutePriorityDefault;
//               }
//             handlerBlock:^(id<HTRouteDefinitionProtocol>  _Nonnull route, id<HTRouteResponseProtocol>  _Nonnull response, HTRouteCompletionBlock  _Nonnull callback) {
//                 if (callback) {
//                     callback(YES);
//                 }
//             }];
//    [self.router addRoute:@"jiaoyou://wildcard/profile(/*)/" // (/:userId)
//               definition:^(id<HTRouteDefinitionProtocol>  _Nonnull route) {
//                   route.continueNext = YES;
//                   route.matchMode = HTRouteMatchStrictly;
//                   route.priority = HTRoutePriorityHigh;
//               }
//             handlerBlock:^(id<HTRouteDefinitionProtocol>  _Nonnull route, id<HTRouteResponseProtocol>  _Nonnull response, HTRouteCompletionBlock  _Nonnull callback) {
//                 if (callback) {
//                     callback(YES);
//                 }
//             }];
//
//    [self.router routeURL:[NSURL URLWithString:@"jiaoyou://wildcard/a/b/profile"]
//              configBlock:^id<HTRouterConfigurationProtocol> _Nonnull{
//                  return [HTRouter createConfig]
//                  .addParameters(@{})
//                  .transition(HTRouteTransitionPresent);
//              }completion:^(BOOL success) {
//              }];
//    [self.router routeURL:[NSURL URLWithString:@"jiaoyou://wildcard/profile"]
//              configBlock:NULL
//               completion:^(BOOL success) {
//               }];
//    [self.router routeURL:[NSURL URLWithString:@"jiaoyou://wildcard/profile/x/y"]
//              configBlock:NULL
//               completion:^(BOOL success) {
//               }];
//}
//
//- (void)testFallback {
//    [self.router addRoute:@"jiaoyou://topic/:topicId" // (/:userId)
//               definition:^(id<HTRouteDefinitionProtocol>  _Nonnull route) {
//                   route.priority = HTRoutePriorityHigh;
//                   route.continueNext = NO;
//                   route.matchMode = HTRouteMatchFallback;
//               }handlerBlock:^(id<HTRouteDefinitionProtocol>  _Nonnull route, id<HTRouteResponseProtocol>  _Nonnull response, HTRouteCompletionBlock  _Nonnull callback) {
//               }];
//
//    [self.router routeURL:[NSURL URLWithString:@"jiaoyou://topic/14002/0"]
//              configBlock:^id<HTRouterConfigurationProtocol> _Nonnull{
//                  return [HTRouter createConfig]
//                  .prefer(HTRoutePreferPriority)
//                  .transition(HTRouteTransitionPresent);
//              }
//               completion:^(BOOL success) {
//               }];
//}
//
//- (void)testContinueNext {
//    [self.router addRoute:@"jiaoyou://continue(/:userId)/next"
//               definition:^(id<HTRouteDefinitionProtocol>  _Nonnull route) {
//                   route.continueNext = NO;
//                   route.priority = HTRoutePriorityDefault;
//                   route.matchMode = HTRouteMatchStrictly;
//               } handlerBlock:^(id<HTRouteDefinitionProtocol>  _Nonnull route, id<HTRouteResponseProtocol>  _Nonnull response, HTRouteCompletionBlock  _Nonnull callback) {
//                   callback(NO);
//               }];
//    [self.router addRoute:@"jiaoyou://continue" definition:^(id<HTRouteDefinitionProtocol>  _Nonnull route) {
//        route.continueNext = YES;
//        route.priority = HTRoutePriorityHigh;
//        route.matchMode = HTRouteMatchFallback;
//    } handlerBlock:^(id<HTRouteDefinitionProtocol>  _Nonnull route, id<HTRouteResponseProtocol>  _Nonnull response, HTRouteCompletionBlock  _Nonnull callback) {
//    }];
//
//    [self.router routeURL:[NSURL URLWithString:@"jiaoyou://continue/next"]
//              configBlock:^id<HTRouterConfigurationProtocol> _Nonnull{
//                  return [HTRouter createConfig]
//                  .addParameters(@{@"URL": [NSURL URLWithString:@"http://love.163.com"]})
//                  .transition(HTRouteTransitionPush)
//                  .prefer(HTRoutePreferPatternMatched);
//              } completion:^(BOOL success) {
//                  ;
//              }];
//}
//
//- (void)testPriority {
//    [self.router addRoute:@"jiaoyou://topic(/:topicId)(/show)"
//               definition:^(id<HTRouteDefinitionProtocol>  _Nonnull route) {
//                   route.continueNext = YES;
//                   route.priority = HTRoutePriorityDefault;
//               } handlerBlock:^(id<HTRouteDefinitionProtocol>  _Nonnull route, id<HTRouteResponseProtocol>  _Nonnull response, HTRouteCompletionBlock  _Nonnull callback) {
//                   callback(NO);
//               }];
//    [self.router addRoute:@"jiaoyou://" definition:^(id<HTRouteDefinitionProtocol>  _Nonnull route) {
//        route.continueNext = NO;
//        route.priority = HTRoutePriorityHigh;
//        route.matchMode = HTRouteMatchFallback;
//    } handlerBlock:^(id<HTRouteDefinitionProtocol>  _Nonnull route, id<HTRouteResponseProtocol>  _Nonnull response, HTRouteCompletionBlock  _Nonnull callback) {
//    }];
//
//    [self.router routeURL:[NSURL URLWithString:@"jiaoyou://topic/233333/show"]
//              configBlock:^id<HTRouterConfigurationProtocol>{
//                  return [HTRouter createConfig]
//                  .addParameters(@{})
//                  .prefer(HTRoutePreferPriority)
//                  .transition(HTRouteTransitionPush);
//              }completion:^(BOOL success) {
//              }];
//}
//
//- (void)testRequestObject {
//    //    __weak typeof(self) wself = self;
//    [self.router addRoute:@"jiaoyou://app/createTestObject(/title/:title)"
//               definition:^(id<HTRouteDefinitionProtocol>  _Nonnull route) {
//                   route.continueNext = NO;
//                   route.priority = HTRoutePriorityHigh;
//               }
//              objectBlock:^id _Nullable(id<HTRouteDefinitionProtocol>  _Nonnull route, id<HTRouteResponseProtocol>  _Nonnull response) {
//                  NSObject *object = [NSObject new];
//                  return object;
//              }];
//
//    NSObject *obj =
//    [self.router requestObjectForURL:[NSURL URLWithString:@"jiaoyou://app/createTestObject/title/HelloKitty"]
//                         configBlock:^id<HTRouterConfigurationProtocol> _Nonnull{
//                             return [HTRouter createConfig]
//                             .prefer(HTRoutePreferPriority)
//                             .addParameters(@{@"image":[UIImage imageNamed:@"tabbar_msg_selected"],
//                                              @"info": @{@"x": @(20),
//                                                         @"y": @(40),
//                                                         },
//                                              });
//                         }];
//    NSLog(@"obj: %@", obj);
//}
//
//#endif

