//
//  gridAppDelegate.m
//  grid
//
//  Created by Robert Olivier on 4/4/10.
//  Copyright RJO Management, Inc. 2010. All rights reserved.
//

#import "GridAppDelegate.h"

@implementation GridAppDelegate

@synthesize window;
@synthesize viewController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
  
    // Override point for customization after app launch    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];

	return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSLog(@"into background");
}


@end
