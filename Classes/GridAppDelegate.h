//
//  gridAppDelegate.h
//  grid
//
//  Created by Robert Olivier on 4/4/10.
//  Copyright RJO Management, Inc. 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GridViewController.h"

//@class gridViewController;

@interface GridAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    GridViewController *viewController;
}

@property (nonatomic) IBOutlet UIWindow *window;
@property (nonatomic) IBOutlet GridViewController *viewController;

@end

