//
//  HTXRouteresponse.m
//  HTRouter
//
//  Created by cc on 2018/10/16.
//  Copyright © 2018 Jason. All rights reserved.
//

#import "HTXRouteresponse.h"

@interface HTXRouteresponse ()

@property (nonatomic, copy) NSDictionary *parameters;
@property (nonatomic,strong,readwrite) id<HTRouteRequestProtocol> request;

@end

@implementation HTXRouteresponse

@synthesize request = _request;
@synthesize parameters = _parameters;
@synthesize resultObject = _resultObject;
@synthesize isMatched = _isMatched;
@synthesize isFallback = _isFallback;

+ (instancetype)invalidMatchResponseForRequest:(id<HTRouteRequestProtocol>)request
{
    HTXRouteresponse *response = [[[self class] alloc] init];
    response.isMatched = NO;
    response.request = request;
    
    return response;
}

+ (instancetype)validMatchResponseWithParameters:(NSDictionary *)parameters request:(id<HTRouteRequestProtocol>)request
{
    HTXRouteresponse *response = [[[self class] alloc] init];
    response.isMatched = YES;
    response.parameters = parameters;
    response.request = request;
    return response;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@, isMatch: %@, isFallback: %@, parameters: %@, request:%@", [super description], @(self.isMatched), @(self.isFallback), self.parameters, self.request];
}

@end
