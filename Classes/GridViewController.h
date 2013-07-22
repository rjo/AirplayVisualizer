//
//  gridViewController.h
//  grid
//
//  Created by Robert Olivier on 4/4/10.
//  Copyright RJO Management, Inc. 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "CollectionViewController.h"
#import "PlaylistViewController.h"
#import "AlbumViewController.h"
#import "ArtistViewController.h"
#import "TrackViewController.h"
#import "GridViewControllerDelegate.h"
#import "RotatingCubeGLView.h"
#import "SonogramGLView.h"
#import "SpectrumGLView.h"
#import "FNAudioUnitPlaybackManager.h"

typedef enum {
    FNPlaybackStatePlaying,
    FNPlaybackStatePaused,
    FNPlaybackStateStopped,
    FNPlaybackStateInterrupted
} FNPlaybackState;

@interface GridViewController : UIViewController <GridViewControllerDelegate,FNAudioUnitPlaybackMangerDelegate> {

	IBOutlet UIButton*					skipBack;
	IBOutlet UIButton*					rewind;
	IBOutlet UIButton*					playButton;
	IBOutlet UIButton*					fastForward;
	IBOutlet UIButton*					skipForward;

	IBOutlet UIView*					navViewContainer;
	IBOutlet UINavigationController*	navController;
	UIImage*							playIconImage;
	UIImage*							pauseIconImage;
	
}

@property (nonatomic,retain) FNAudioUnitPlaybackManager*    playbackManager;
@property (nonatomic,assign) FNPlaybackState                playbackState;
//@property (nonatomic,retain) RotatingCubeGLView*                glView;
@property (nonatomic,strong) SpectrumGLView*                glView;
@property (nonatomic,retain) UINavigationController*        navController;
@property (nonatomic,retain) CollectionViewController*      collectionViewController;
@property (nonatomic,retain) TrackViewController*           tracklistViewController;
//@property (nonatomic,retain) PlaylistViewController*        playlistViewController;
@property (nonatomic,retain) ArtistViewController*          artistViewController;
@property (nonatomic,retain) AlbumViewController*           albumViewController;
@property (nonatomic,retain) UIScreen*                      externalScreen;
@property (nonatomic,retain) UIWindow*                      externalWindow;
@property (nonatomic,retain) MPMediaItemCollection*         currentCollection;
@property (nonatomic,retain) MPMediaItem*                   currentItem;

-(IBAction)skipBack;
-(IBAction)rewind;
-(IBAction)play;
-(IBAction)play:(MPMediaItem*)item;
-(IBAction)fastForward;
-(IBAction)skipForward;

#pragma mark GridViewControllerDelegate

-(void)showTrackListWithCollection:(MPMediaItemCollection*)_collection title:(NSString*)text;


-(void)playbackStateChanged:(FNPlaybackState)state;

#pragma mark FNAudioUnitPlaybackManagerDelegate

- (void)playbackDidStop;

@end

