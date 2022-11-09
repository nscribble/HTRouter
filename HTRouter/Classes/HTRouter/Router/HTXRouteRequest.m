//
//  HTXRouterequest.m
//  HTRouter
//
//  Created by cc on 2018/10/16.
//  Copyright © 2018 Jason. All rights reserved.
//

#import "HTXRouteRequest.h"
#import "HTParsingUtilities.h"

@interface HTXRouterequest()

@property (nonatomic, strong, readwrite) id<HTRouteRequestProtocol> originalRequest;
@property (nonatomic, weak, readwrite) id<HTRouteRequestProtocol> redirectedRequest;

@end

@implementation HTXRouterequest

@synthesize URL = _URL;
@synthesize pathComponents = _pathComponents;
@synthesize queryParams = _queryParams;
//@synthesize additionalParameters = _additionalParameters;
@synthesize config = _config;
@synthesize originalRequest = _originalRequest;

- (instancetype)initWithURL:(NSURL *)URL configuration:(id<HTRouterConfigurationProtocol>)configuration {
    if (self = [super init]) {
        _URL = URL;
        _config = configuration;
        
        {// JLRouteRequest
            NSURLComponents *components = [NSURLComponents componentsWithString:URL.absoluteString];
            _pathComponents = [HTParsingUtilities extractPathComponentsForURLComponents:components];
            _queryParams = [HTParsingUtilities queryItemOfComponents:components];
        }
    }
    
    return self;
}

- (void)updateWithConfigBlock:(void (^)(id<HTRouterConfigurationProtocol> _Nonnull))configBlock {
    if (configBlock) {
        configBlock(self.config);
    }
}

- (id<HTRouteRequestProtocol>)redirectForURL:(NSURL *)URL configBlock:(void (^)(id<HTRouterConfigurationProtocol> _Nonnull))configBlock {
    id<HTRouterConfigurationProtocol> configuration = [(NSObject *)self.config copy];
    HTXRouterequest *redirectRequest = [[self.class alloc] initWithURL:URL configuration:configuration];
    redirectRequest.originalRequest = self;
    if (configBlock) {
        configBlock(configuration);
    }
    self.redirectedRequest = redirectRequest;
    
    return redirectRequest;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@:<URL: %@, config: %@>, originalRequest: %@", [super description], self.URL, self.config, self.originalRequest];
}

@end
