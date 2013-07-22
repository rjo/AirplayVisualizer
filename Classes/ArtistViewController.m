//
//  ArtistNavigationViewControllerViewController.m
//  grid
//
//  Created by Robert Olivier on 5/31/12.
//  Copyright (c) 2012 RJO Management, inc. All rights reserved.
//

#import "ArtistViewController.h"

@interface ArtistViewController ()

@property (strong,nonatomic) IBOutlet UITableView*			tableView;
@property  NSArray* collections;

@end


@implementation ArtistViewController

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
	
	MediaNavigationCell* cell = [tableView dequeueReusableCellWithIdentifier:@"artist cell"];
    if(cell == nil) {
        cell = [[MediaNavigationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"artist cell"];
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont fontWithName:@"Optima-Bold" size:18];
        cell.textLabel.textColor = [UIColor blackColor];
    }
	cell.textLabel.text = [[[self.collections objectAtIndex:[indexPath indexAtPosition:1]] representativeItem]  valueForProperty:MPMediaItemPropertyArtist];
	
	return cell;
}

#pragma mark As UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.master showTrackListWithCollection:[self.collections objectAtIndex:[indexPath indexAtPosition:1]] title:[[[self.collections objectAtIndex:[indexPath indexAtPosition:1]] representativeItem] valueForProperty:MPMediaItemPropertyArtist]];
}

@end
