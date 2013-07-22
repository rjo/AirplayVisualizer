//
//  GridViewController.m
//  
//
//  Created by Robert Olivier on 4/4/10.
//  Copyright RJO Management, Inc. 2010. All rights reserved.
//

#import "GridViewController.h"

@implementation GridViewController

@synthesize playbackManager;
@synthesize glView;
@synthesize navController;
@synthesize collectionViewController;
@synthesize tracklistViewController;
//@synthesize playlistViewController;
@synthesize artistViewController;
@synthesize albumViewController;
@synthesize playbackState;
@synthesize externalScreen;
@synthesize externalWindow;
@synthesize currentItem;
@synthesize currentCollection;

-(void)viewWillAppear:(BOOL)animated
{
    NSArray* screens = [UIScreen screens];
    if ([screens count] > 1) {
        NSLog(@"more than one screen exists %d",[[UIScreen screens] count]);
        self.externalScreen = [screens objectAtIndex:[screens count]-1];
        [self startVisualizerOnExternalScreen:[[UIScreen screens] objectAtIndex:[screens count]-1]];
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
	
	playIconImage = [UIImage imageNamed:@"play.png"];
	pauseIconImage = [UIImage imageNamed:@"pause.png"];
	
//	navViewContainer.backgroundColor = [UIColor clearColor];
	self.navController = [[UINavigationController alloc] init];
	self.navController.view.frame = CGRectMake(0, 0, navViewContainer.frame.size.width, navViewContainer.frame.size.height);
	
	[navViewContainer addSubview:self.navController.view];

	self.collectionViewController = [[CollectionViewController alloc] initWithDelegate:self];
    
    
    self.artistViewController = [[ArtistViewController alloc] init];
    self.artistViewController.master = self;
    
    self.albumViewController = [[AlbumViewController alloc] init];
    self.albumViewController.master = self;
	
    self.tracklistViewController = [[TrackViewController alloc] initWithDelegate:self];

	[self.navController pushViewController:collectionViewController animated:YES];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(playbackStateChanged:) name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(itemChanged:) name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenDidConnect:) name:UIScreenDidConnectNotification object:nil];
    
	[playButton setImage:playIconImage forState:UIControlStateNormal];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    self.playbackManager = [[FNAudioUnitPlaybackManager alloc] init];
    [self.playbackManager setup];
    self.playbackManager.delegate = self;
    [self playbackStateChanged:FNPlaybackStateStopped];
    
    [[UINavigationBar appearance] setBackgroundImage:[UIImage  imageNamed:@"main-navbar-clear-background.png"]  forBarMetrics:UIBarMetricsDefault];
    UINavigationBar* navBar = self.navController.navigationBar;
    NSMutableDictionary* attributes = [NSMutableDictionary dictionaryWithDictionary:navBar.titleTextAttributes];
    attributes[UITextAttributeFont] = [UIFont fontWithName:@"Optima-Bold" size:20];
    attributes[UITextAttributeTextColor] = [UIColor blackColor];
    
    navBar.titleTextAttributes = attributes;
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name: nil object: nil];
}
	
-(IBAction)play
{
	NSLog(@"play button touched");
	if(self.playbackState == FNPlaybackStatePlaying) {
		NSLog(@"pause");
		[playbackManager pause];
	} else {
		NSLog(@"play");
		[playbackManager resume];
	}
}

-(void)play:(MPMediaItem*)item {
    [self.playbackManager play:item];
	[playButton setImage:pauseIconImage forState:UIControlStateNormal];
}	

-(IBAction)skipBack {
    [self playPreviousTrackInCurrentCollection];
}

-(IBAction)rewind {
}

-(IBAction)fastForward {
}

-(IBAction)skipForward {
    [self playNextTrackInCurrentCollection];
}


#pragma mark as GridViewControllerDelegate

-(void)showPlaylistsWithParentPersistentID:(NSNumber*)persistentID title:(NSString*)title {

	NSLog(@"show playlists");
    self.currentCollection = nil;
	//MPMediaQuery *query = [[MPMediaQuery alloc] init];
	//query.groupingType = MPMediaGroupingPlaylist;
    MPMediaQuery* query = [MPMediaQuery playlistsQuery];
    [query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeMusic] forProperty:MPMediaItemPropertyMediaType]];
    [query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:persistentID forProperty:@"parentPersistentID"]];
	NSArray* collections = [query collections];
    PlaylistViewController* playlistViewController = [[PlaylistViewController alloc] init];
	[playlistViewController setCollections:collections withTitle:title];
	playlistViewController.master = self;

	[navController pushViewController:playlistViewController animated:YES];
    
}

-(void)showArtists {

	NSLog(@"show artists");
    self.currentCollection = nil;
	MPMediaQuery *query = [[MPMediaQuery alloc] init];
	query.groupingType = MPMediaGroupingArtist;
    [query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeMusic] forProperty:MPMediaItemPropertyMediaType]];
	NSArray* collections = [query collections];
    NSLog(@"artist collection count = %d",[collections count]);
	[self.artistViewController setCollections:collections withTitle:@"Artists"];
	[navController pushViewController:self.artistViewController animated:YES];

}

-(void)showAlbums {
	NSLog(@"show albums");
    self.currentCollection = nil;
	MPMediaQuery *query = [[MPMediaQuery alloc] init];
	query.groupingType = MPMediaGroupingAlbumArtist;
    [query addFilterPredicate:[MPMediaPropertyPredicate predicateWithValue:[NSNumber numberWithInteger:MPMediaTypeMusic] forProperty:MPMediaItemPropertyMediaType]];
	NSArray* collections = [query collections];
    NSLog(@"album collection count = %d",[collections count]);
	[self.albumViewController setCollections:collections withTitle:@"Albums"];
	[navController pushViewController:self.albumViewController animated:YES];
}

-(void)showTrackListWithCollection:(MPMediaItemCollection*)collection title:(NSString*)text {
	
	NSLog(@"show tracklist for title: %@",text);
    self.currentCollection = collection;

	[self.tracklistViewController setCollection:collection withTitle:text];
	[navController pushViewController:self.tracklistViewController animated:YES];
}


-(void)playMediaItem:(MPMediaItem*)item {
    self.currentItem = item;
	[self play:item];
}

-(NSNumber*)playlistPersistentId
{
    
}


-(void)playbackStateChanged:(FNPlaybackState)state {
	NSLog(@"playback state changed");
    self.playbackState = state;

	switch (self.playbackState) {
        case FNPlaybackStatePlaying:
            NSLog(@"playing");
            [playButton setImage:pauseIconImage forState:UIControlStateNormal];
            break;
        case FNPlaybackStateInterrupted:
            NSLog(@"interrupted");
            break;
        case FNPlaybackStatePaused:
            NSLog(@"paused");
            [playButton setImage:playIconImage forState:UIControlStateNormal];
            break;
        case FNPlaybackStateStopped:
            NSLog(@"stopped");
            [playButton setImage:playIconImage forState:UIControlStateNormal];
            break;
        default:
            NSLog(@"some other state");
            break;
    }
}


- (void) startVisualizerOnExternalScreen:(UIScreen *)connectedScreen {
    NSLog(@"starting visualizer on external screen with size = %f,%f",connectedScreen.bounds.size.width,connectedScreen.bounds.size.height);
    CGRect frame = connectedScreen.bounds;
    self.externalWindow = [[UIWindow alloc] initWithFrame:frame];
    [self.externalWindow setScreen:connectedScreen];
    self.externalWindow.hidden = NO;
//    glView = [[RotatingCubeGLView alloc] init];
//    glView = [[SonogramGLView alloc] init];
    glView = [[SpectrumGLView alloc] init];
    glView.animationInterval = 1.0 / 60.0;
    playbackManager.visualizer = glView;
    [glView startAnimation];
    [self.externalWindow addSubview:glView];
}


- (void) screenDidConnect:(NSNotification *)notification {
    NSLog(@"screenDidConnect");
    [self startVisualizerOnExternalScreen:[notification object]];
}

- (void)playPreviousTrackInCurrentCollection {
    NSUInteger index = [self.currentCollection.items indexOfObjectIdenticalTo:self.currentItem]; 
    if(index == 0) return;
    index--;
    self.currentItem = [self.currentCollection.items objectAtIndex:index];
    NSUInteger indexPath[2] = {0,index};
    [tracklistViewController selectRowAtIndexPath:[NSIndexPath indexPathWithIndexes:&indexPath[0] length:2]];
    [self playMediaItem:self.currentItem];
    
}

- (void)playNextTrackInCurrentCollection {
    NSUInteger index = [self.currentCollection.items indexOfObjectIdenticalTo:self.currentItem]; 
    if([self.currentCollection.items count] == index+1) return;
    index++;
    self.currentItem = [self.currentCollection.items objectAtIndex:index];
    NSUInteger indexPath[2] = {0,index};
    [tracklistViewController selectRowAtIndexPath:[NSIndexPath indexPathWithIndexes:&indexPath[0] length:2]];
    [self playMediaItem:self.currentItem];
}

#pragma mark FNAudioUnitPlaybackManagerDelegate


- (void)playbackDidStop {
    NSLog(@"playbackDidStop");
    [self playbackStateChanged:FNPlaybackStateStopped];
}

- (void)playbackDidPause {
    NSLog(@"playbackDidPause");
    [self playbackStateChanged:FNPlaybackStatePaused];
}

- (void)playbackDidStart {
    NSLog(@"playbackDidStart");
    [self playbackStateChanged:FNPlaybackStatePlaying];
}

- (void)trackDidEnd {
    NSLog(@"trackDidEnd");
    [self playNextTrackInCurrentCollection];
}

@end




