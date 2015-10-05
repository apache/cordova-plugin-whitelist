/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import "CDVWhitelistPlugin.h"
#import <Cordova/CDVViewController.h>

#pragma mark CDVWhitelistConfigParser

@interface CDVWhitelistConfigParser : NSObject <NSXMLParserDelegate> {}

@property (nonatomic, strong) NSMutableArray* navigationWhitelistHosts;
@property (nonatomic, strong) NSMutableArray* accessWhitelistHosts;
@property (nonatomic, strong) NSArray* defaultHosts;

@end

@implementation CDVWhitelistConfigParser

@synthesize navigationWhitelistHosts, accessWhitelistHosts;

- (id)init
{
    self = [super init];
    if (self != nil) {
        self.defaultHosts = @[
                              @"file:///*",
                              @"content:///*",
                              @"data:///*"
                             ];

        self.navigationWhitelistHosts = [[NSMutableArray alloc] initWithArray:self.defaultHosts];
        self.accessWhitelistHosts = [[NSMutableArray alloc] initWithArray:self.defaultHosts];
    }
    return self;
}

- (void)parser:(NSXMLParser*)parser didStartElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qualifiedName attributes:(NSDictionary*)attributeDict
{
    if ([elementName isEqualToString:@"allow-navigation"]) {
        [navigationWhitelistHosts addObject:attributeDict[@"href"]];
    }
    else if ([elementName isEqualToString:@"access"]) {
        [accessWhitelistHosts addObject:attributeDict[@"origin"]];
    }
}

- (void)parser:(NSXMLParser*)parser didEndElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qualifiedName
{
}

- (void)parser:(NSXMLParser*)parser parseErrorOccurred:(NSError*)parseError
{
    NSAssert(NO, @"config.xml parse error line %ld col %ld", (long)[parser lineNumber], (long)[parser columnNumber]);
}


@end

#pragma mark CDVWhitelistPlugin

@interface CDVWhitelistPlugin () {}
@property (nonatomic, strong) CDVWhitelist* navigationWhitelist;
@property (nonatomic, strong) CDVWhitelist* accessWhitelist;
@end

@implementation CDVWhitelistPlugin

@synthesize navigationWhitelist, accessWhitelist;

- (void)setViewController:(UIViewController *)viewController
{
    if ([viewController isKindOfClass:[CDVViewController class]]) {
        CDVWhitelistConfigParser *whitelistConfigParser = [[CDVWhitelistConfigParser alloc] init];
        [(CDVViewController *)viewController parseSettingsWithParser:whitelistConfigParser];
        self.navigationWhitelist = [[CDVWhitelist alloc] initWithArray:whitelistConfigParser.navigationWhitelistHosts];
        // if no access tags set, default to * (https://issues.apache.org/jira/browse/CB-9568)
        if ([whitelistConfigParser.accessWhitelistHosts isEqualToArray:whitelistConfigParser.defaultHosts]) {
            [whitelistConfigParser.accessWhitelistHosts addObject:@"*"];
        }
        self.accessWhitelist = [[CDVWhitelist alloc] initWithArray:whitelistConfigParser.accessWhitelistHosts];
    }
}

- (BOOL)shouldAllowNavigationToURL:(NSURL *)url
{
    return IsAtLeastiOSVersion(@"9.0") || [self.navigationWhitelist URLIsAllowed:url];
}

- (BOOL)shouldAllowRequestForURL:(NSURL *)url
{
    return IsAtLeastiOSVersion(@"9.0") || [self.accessWhitelist URLIsAllowed:url];
}

@end
