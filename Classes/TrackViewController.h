//
//  TracListViewController.h
//  grid
//
//  Created by Robert Olivier on 4/4/10.
//  Copyright 2010 RJO Management, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "MediaNavigationCell.h"
#import "GridViewControllerDelegate.h"

@interface TrackViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
	id<GridViewControllerDelegate>	delegate;
}

@property  id<GridViewControllerDelegate> delegate;

-(id)initWithDelegate:(id<GridViewControllerDelegate>)_delegate;
-(void)setCollection:(MPMediaItemCollection*)_collection withTitle:(NSString*)text;
-(void)setCurrentItem:(MPMediaItem*)item;
-(void)selectRowAtIndexPath:(NSIndexPath *)indexPath;

@end
