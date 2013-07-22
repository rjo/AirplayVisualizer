//
//  MediaNavigationViewController.h
//  grid
//
//  Created by Robert Olivier on 4/4/10.
//  Copyright 2010 RJO Management, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "MediaNavigationCell.h"
#import "GridViewControllerDelegate.h"

@interface PlaylistViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
}

@property  id<GridViewControllerDelegate> master;
@property (strong)  NSNumber*       persistentId;


-(void)setCollections:(NSArray*)collections withTitle:(NSString*)title;

@end
