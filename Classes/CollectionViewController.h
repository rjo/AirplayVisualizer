//
//  CollectionSelectorViewController.h
//  grid
//
//  Created by Robert Olivier on 4/4/10.
//  Copyright 2010 RJO Management, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlaylistViewController.h"

@interface CollectionViewController : UIViewController {
	id<GridViewControllerDelegate> delegate;
}

@property  id<GridViewControllerDelegate> delegate;

-(id)initWithDelegate:(id<GridViewControllerDelegate>)_delegate;

-(IBAction)playlists;
-(IBAction)artists;
-(IBAction)albums;

@end
