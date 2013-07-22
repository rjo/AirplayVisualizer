//
//  AlbumNavigationViewController.h
//  grid
//
//  Created by Robert Olivier on 5/31/12.
//  Copyright (c) 2012 RJO Management, inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "MediaNavigationCell.h"
#import "GridViewControllerDelegate.h"

@interface AlbumViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    id<GridViewControllerDelegate>	master;
}

@property  id<GridViewControllerDelegate> master;

-(void)setCollections:(NSArray*)collections withTitle:(NSString*)title;

@end
