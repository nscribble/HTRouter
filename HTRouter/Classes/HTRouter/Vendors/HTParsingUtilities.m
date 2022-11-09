/*
 Copyright (c) 2017, Joel Levin
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 Neither the name of JLRoutes nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "HTParsingUtilities.h"


@interface NSArray (STRoutes_Utilities)

- (NSArray<NSArray *> *)STRoutes_allOrderedCombinations;
- (NSArray *)STRoutes_filter:(BOOL (^)(id object))filterBlock;
- (NSArray *)STRoutes_map:(id (^)(id object))mapBlock;

@end


@interface NSString (STRoutes_Utilities)

- (NSArray <NSString *> *)STRoutes_trimmedPathComponents;

@end


#pragma mark - Parsing Utility Methods


@interface HTParsingUtilities_RouteSubpath : NSObject

@property (nonatomic, strong) NSArray <NSString *> *subpathComponents;
@property (nonatomic, assign) BOOL isOptionalSubpath;

@end


@implementation HTParsingUtilities_RouteSubpath

- (NSString *)description
{
    NSString *type = self.isOptionalSubpath ? @"OPTIONAL" : @"REQUIRED";
    return [NSString stringWithFormat:@"%@ - %@: %@", [super description], type, [self.subpathComponents componentsJoinedByString:@"/"]];
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    HTParsingUtilities_RouteSubpath *otherSubpath = (HTParsingUtilities_RouteSubpath *)object;
    if (![self.subpathComponents isEqual:otherSubpath.subpathComponents]) {
        return NO;
    }
    
    if (self.isOptionalSubpath != otherSubpath.isOptionalSubpath) {
        return NO;
    }
    
    return YES;
}

- (NSUInteger)hash
{
    return self.subpathComponents.hash ^ self.isOptionalSubpath;
}

@end


@implementation HTParsingUtilities

+ (NSString *)variableValueFrom:(NSString *)value decodePlusSymbols:(BOOL)decodePlusSymbols
{
    if (!decodePlusSymbols) {
        return value;
    }
    return [value stringByReplacingOccurrencesOfString:@"+" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, value.length)];
}

+ (NSDictionary *)queryParams:(NSDictionary *)queryParams decodePlusSymbols:(BOOL)decodePlusSymbols
{
    if (!decodePlusSymbols) {
        return queryParams;
    }
    
    NSMutableDictionary *updatedQueryParams = [NSMutableDictionary dictionary];
    
    for (NSString *name in queryParams) {
        id value = queryParams[name];
        
        if ([value isKindOfClass:[NSArray class]]) {
            NSMutableArray *variables = [NSMutableArray array];
            for (NSString *arrayValue in (NSArray *)value) {
                [variables addObject:[self variableValueFrom:arrayValue decodePlusSymbols:YES]];
            }
            updatedQueryParams[name] = [variables copy];
        } else if ([value isKindOfClass:[NSString class]]) {
            NSString *variable = [self variableValueFrom:value decodePlusSymbols:YES];
            updatedQueryParams[name] = variable;
        } else {
            NSAssert(NO, @"Unexpected query parameter type: %@", NSStringFromClass([value class]));
        }
    }
    
    return [updatedQueryParams copy];
}

+ (NSArray <NSString *> *)expandOptionalRoutePatternsForPattern:(NSString *)routePattern
{
    /* this method exists to take a route pattern that is known to contain optional params, such as:
     
     /path/:thing/(/a)(/b)(/c)
     
     and create the following paths:
     
     /path/:thing/a/b/c
     /path/:thing/a/b
     /path/:thing/a/c
     /path/:thing/b/a
     /path/:thing/a
     /path/:thing/b
     /path/:thing/c
     
     */
    
    if ([routePattern rangeOfString:@"("].location == NSNotFound) {
        return @[];
    }
    
    // First, parse the route pattern into subpath objects.
    NSArray <HTParsingUtilities_RouteSubpath *> *subpaths = [self _routeSubpathsForPattern:routePattern];
    if (subpaths.count == 0) {
        return @[];
    }
    
    // Next, etract out the required subpaths.
    NSSet <HTParsingUtilities_RouteSubpath *> *requiredSubpaths = [NSSet setWithArray:[subpaths STRoutes_filter:^BOOL(HTParsingUtilities_RouteSubpath *subpath) {
        return !subpath.isOptionalSubpath;
    }]];
    
    // Then, expand the subpath permutations into possible route patterns.
    NSArray <NSArray <HTParsingUtilities_RouteSubpath *> *> *allSubpathCombinations = [subpaths STRoutes_allOrderedCombinations];
    
    // Finally, we need to filter out any possible route patterns that don't actually satisfy the rules of the route.
    // What this means in practice is throwing out any that do not contain all required subpaths (since those are explicitly not optional).
    NSArray <NSArray <HTParsingUtilities_RouteSubpath *> *> *validSubpathCombinations = [allSubpathCombinations STRoutes_filter:^BOOL(NSArray <HTParsingUtilities_RouteSubpath *> *possibleRouteSubpaths) {
        return [requiredSubpaths isSubsetOfSet:[NSSet setWithArray:possibleRouteSubpaths]];
    }];
    
    // Once we have a filtered list of valid subpaths, we just need to convert them back into string routes that can we registered.
    NSArray <NSString *> *validSubpathRouteStrings = [validSubpathCombinations STRoutes_map:^id(NSArray <HTParsingUtilities_RouteSubpath *> *subpaths) {
        NSString *routePattern = @"/";
        for (HTParsingUtilities_RouteSubpath *subpath in subpaths) {
            NSString *subpathString = [subpath.subpathComponents componentsJoinedByString:@"/"];
            routePattern = [routePattern stringByAppendingPathComponent:subpathString];
        }
        return routePattern;
    }];
    
    // Before returning, sort them by length so that the longest and most specific routes are registered first before the less specific shorter ones.
    validSubpathRouteStrings = [validSubpathRouteStrings sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"length" ascending:NO selector:@selector(compare:)]]];
    
    return validSubpathRouteStrings;
}

+ (NSArray <HTParsingUtilities_RouteSubpath *> *)_routeSubpathsForPattern:(NSString *)routePattern
{
    NSMutableArray <HTParsingUtilities_RouteSubpath *> *subpaths = [NSMutableArray array];
    
    NSScanner *scanner = [NSScanner scannerWithString:routePattern];
    while (![scanner isAtEnd]) {
        NSString *preOptionalSubpath = nil;
        BOOL didScan = [scanner scanUpToString:@"(" intoString:&preOptionalSubpath];
        if (!didScan) {
            NSAssert([routePattern characterAtIndex:scanner.scanLocation] == '(', @"Unexpected character: %c", [routePattern characterAtIndex:scanner.scanLocation]);
        }
        
        if (!scanner.isAtEnd) {
            // otherwise, advance past the ( character
            scanner.scanLocation = scanner.scanLocation + 1;
        }
        
        if (preOptionalSubpath.length > 0 && ![preOptionalSubpath isEqualToString:@")"] && ![preOptionalSubpath isEqualToString:@"/"]) {
            // content before the start of an optional subpath
            HTParsingUtilities_RouteSubpath *subpath = [[HTParsingUtilities_RouteSubpath alloc] init];
            subpath.subpathComponents = [preOptionalSubpath STRoutes_trimmedPathComponents];
            [subpaths addObject:subpath];
        }
        
        if (scanner.isAtEnd) {
            break;
        }
        
        NSString *optionalSubpath = nil;
        didScan = [scanner scanUpToString:@")" intoString:&optionalSubpath];
        NSAssert(didScan, @"Could not find closing parenthesis");
        
        scanner.scanLocation = scanner.scanLocation + 1;
        
        if (optionalSubpath.length > 0) {
            HTParsingUtilities_RouteSubpath *subpath = [[HTParsingUtilities_RouteSubpath alloc] init];
            subpath.isOptionalSubpath = YES;
            subpath.subpathComponents = [optionalSubpath STRoutes_trimmedPathComponents];
            [subpaths addObject:subpath];
        }
    }
    
    return [subpaths copy];
}

+ (NSArray<NSString *> *)extractPathComponentsForURLComponents:(NSURLComponents *)components {
    BOOL treatsHostAsPathComponent = YES;
    
    if (components.host.length > 0 && (treatsHostAsPathComponent || (![components.host isEqualToString:@"localhost"] && [components.host rangeOfString:@"."].location == NSNotFound))) {
        // convert the host to "/" so that the host is considered a path component
        NSString *host = [components.percentEncodedHost copy];
        components.host = @"/";
        components.percentEncodedPath = [host stringByAppendingPathComponent:(components.percentEncodedPath ?: @"")];
    }
    
    NSString *path = [components percentEncodedPath];
    
    // handle fragment if needed
    if (components.fragment != nil) {
        BOOL fragmentContainsQueryParams = NO;
        NSURLComponents *fragmentComponents = [NSURLComponents componentsWithString:components.percentEncodedFragment];
        
        if (fragmentComponents.query == nil && fragmentComponents.path != nil) {
            fragmentComponents.query = fragmentComponents.path;
        }
        
        if (fragmentComponents.queryItems.count > 0) {
            // determine if this fragment is only valid query params and nothing else
            fragmentContainsQueryParams = fragmentComponents.queryItems.firstObject.value.length > 0;
        }
        
        if (fragmentContainsQueryParams) {
            // include fragment query params in with the standard set
            components.queryItems = [(components.queryItems ?: @[]) arrayByAddingObjectsFromArray:fragmentComponents.queryItems];
        }
        
        if (fragmentComponents.path != nil && (!fragmentContainsQueryParams || ![fragmentComponents.path isEqualToString:fragmentComponents.query])) {
            // handle fragment by include fragment path as part of the main path
            path = [path stringByAppendingString:[NSString stringWithFormat:@"#%@", fragmentComponents.percentEncodedPath]];
        }
    }
    
    // strip off leading slash so that we don't have an empty first path component
    if (path.length > 0 && [path characterAtIndex:0] == '/') {
        path = [path substringFromIndex:1];
    }
    
    // strip off trailing slash for the same reason
    if (path.length > 0 && [path characterAtIndex:path.length - 1] == '/') {
        path = [path substringToIndex:path.length - 1];
    }
    
    // split apart into path components
    NSArray *pathComponents = [path componentsSeparatedByString:@"/"];
    return pathComponents;
}

+ (NSDictionary *)queryItemOfComponents:(NSURLComponents *)components {
    NSArray <NSURLQueryItem *> *queryItems = [components queryItems] ?: @[];
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    for (NSURLQueryItem *item in queryItems) {
        if (item.value == nil) {
            continue;
        }
        
        if (queryParams[item.name] == nil) {
            // first time seeing a param with this name, set it
            queryParams[item.name] = item.value;
        } else if ([queryParams[item.name] isKindOfClass:[NSArray class]]) {
            // already an array of these items, append it
            NSArray *values = (NSArray *)(queryParams[item.name]);
            queryParams[item.name] = [values arrayByAddingObject:item.value];
        } else {
            // existing non-array value for this key, create an array
            id existingValue = queryParams[item.name];
            queryParams[item.name] = @[existingValue, item.value];
        }
    }
    
    return queryParams;
}

@end


#pragma mark - Categories


@implementation NSArray (STRoutes_Utilities)

- (NSArray<NSArray *> *)STRoutes_allOrderedCombinations
{
    NSInteger length = self.count;
    if (length == 0) {
        return [NSArray arrayWithObject:[NSArray array]];
    }
    
    id lastObject = [self lastObject];
    NSArray *subarray = [self subarrayWithRange:NSMakeRange(0, length - 1)];
    NSArray *subarrayCombinations = [subarray STRoutes_allOrderedCombinations];
    NSMutableArray *combinations = [NSMutableArray arrayWithArray:subarrayCombinations];
    
    for (NSArray *subarrayCombos in subarrayCombinations) {
        [combinations addObject:[subarrayCombos arrayByAddingObject:lastObject]];
    }
    
    return [NSArray arrayWithArray:combinations];
}

- (NSArray *)STRoutes_filter:(BOOL (^)(id object))filterBlock
{
    NSParameterAssert(filterBlock != nil);
    NSMutableArray *filteredArray = [NSMutableArray array];
    
    for (id object in self) {
        if (filterBlock(object)) {
            [filteredArray addObject:object];
        }
    }
    
    return [filteredArray copy];
}

- (NSArray *)STRoutes_map:(id (^)(id object))mapBlock
{
    NSParameterAssert(mapBlock != nil);
    NSMutableArray *mappedArray = [NSMutableArray array];
    
    for (id object in self) {
        id mappedObject = mapBlock(object);
        [mappedArray addObject:mappedObject];
    }
    
    return [mappedArray copy];
}

@end


@implementation NSString (STRoutes_Utilities)

- (NSArray <NSString *> *)STRoutes_trimmedPathComponents
{
    // Trims leading and trailing slashes and then separates by slash
    return [[self stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]] componentsSeparatedByString:@"/"];
}

@end


