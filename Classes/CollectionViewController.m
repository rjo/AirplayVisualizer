    //
//  CollectionSelectorViewController.m
//  grid
//
//  Created by Robert Olivier on 4/4/10.
//  Copyright 2010 RJO Management, Inc. All rights reserved.
//

#import "CollectionViewController.h"


@implementation CollectionViewController

@synthesize delegate;


/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor clearColor];
}


-(id)initWithDelegate:(id<GridViewControllerDelegate>)_delegate
{
	if(self = [super init]) {
		self.delegate = _delegate;
		self.title = @"Music";
	}
	return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}



-(IBAction)playlists {
	[delegate showPlaylistsWithParentPersistentID:@0 title:@"Playlists"];
}

-(IBAction)artists {
	[delegate showArtists];

}

-(IBAction)albums {
	[delegate showAlbums];

}


@end
