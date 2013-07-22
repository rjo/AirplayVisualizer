//
//  AlbumNavigationViewController.m
//  grid
//
//  Created by Robert Olivier on 5/31/12.
//  Copyright (c) 2012 RJO Management, inc. All rights reserved.
//

#import "AlbumViewController.h"

@interface AlbumViewController () 

@property  NSArray* collections;
@property (strong,nonatomic) IBOutlet UITableView* tableView;

@end

@implementation AlbumViewController

@synthesize master;
@synthesize collections = _collections;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor clearColor];
	self.tableView.backgroundColor = [UIColor clearColor];
	self.tableView.separatorColor = [UIColor purpleColor];
	self.tableView.dataSource = self;
	self.tableView.delegate = self;
	[self.tableView reloadData];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)setCollections:(NSArray*)collections withTitle:(NSString*)text {
    self.collections = collections;
	self.title = text;
}



#pragma mark As UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.collections count];
}

-(UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	MediaNavigationCell* cell = [tableView dequeueReusableCellWithIdentifier:@"album cell"];
    if(cell == nil) {
        cell = [[MediaNavigationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"album cell"];
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont fontWithName:@"Optima-Bold" size:18];
        cell.textLabel.textColor = [UIColor blackColor];
    }

	cell.textLabel.text = [[[self.collections objectAtIndex:[indexPath indexAtPosition:1]] representativeItem]  valueForProperty:MPMediaItemPropertyAlbumTitle];
	return cell;
}

#pragma mark As UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[master showTrackListWithCollection:[self.collections objectAtIndex:[indexPath indexAtPosition:1]] title:[[[self.collections objectAtIndex:[indexPath indexAtPosition:1]] representativeItem] valueForProperty:MPMediaItemPropertyAlbumTitle]];
}

@end
