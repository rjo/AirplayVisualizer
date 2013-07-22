//
//  GridViewControllerDelegate.h
//  grid
//
//  Created by Robert Olivier on 4/5/10.
//  Copyright 2010 RJO Management, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol GridViewControllerDelegate

-(void)showPlaylistsWithParentPersistentID:(NSNumber*)persistentID title:(NSString*)title;
-(void)showArtists;
-(void)showAlbums;
-(void)showTrackListWithCollection:(MPMediaItemCollection*)_collection title:(NSString*)text;
-(void)playMediaItem:(MPMediaItem*)item;
-(NSNumber*)playlistPersistentId;

@end
