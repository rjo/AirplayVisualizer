//
//  TracListViewController.m
//  grid
//
//  Created by Robert Olivier on 4/4/10.
//  Copyright 2010 RJO Management, Inc. All rights reserved.
//

#import "TrackViewController.h"

@interface TrackViewController ()

@property (strong,nonatomic) MPMediaItemCollection*			collection;
@property (strong,nonatomic) IBOutlet UITableView*			tableView;
@property (strong,nonatomic) NSMutableDictionary*			itemsAndPaths;

@end

@implementation TrackViewController

@synthesize delegate;
@synthesize collection;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

-(id)initWithDelegate:(id<GridViewControllerDelegate>)_delegate  {
	if(self = [super init]) {
		self.delegate = _delegate;
		self.collection = nil;
		self.title = nil;
		self.itemsAndPaths = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)viewDidLoad  {
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor clearColor];
	self.tableView.backgroundColor = [UIColor clearColor];
	self.tableView.separatorColor = [UIColor purpleColor];
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
	[[NSNotificationCenter defaultCenter] removeObserver:self name: nil object: nil];

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}



-(void)setCollection:(MPMediaItemCollection*)_collection withTitle:(NSString*)text
{
	self.collection = _collection;
	self.title = text;
	[self.itemsAndPaths removeAllObjects];
	[self.tableView reloadData];
}

-(void)setCurrentItem:(MPMediaItem*)item {
	[self.tableView selectRowAtIndexPath:[self.itemsAndPaths objectForKey:[item  valueForProperty:MPMediaItemPropertyTitle]] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
}

-(void)selectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionBottom];
}

#pragma mark As UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[collection items] count];
}

-(UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {

	if(collection != nil) {
		[self.itemsAndPaths setObject:indexPath forKey:[[[collection items] objectAtIndex:[indexPath indexAtPosition:1]]   valueForProperty:MPMediaItemPropertyTitle]  ];
	}
	
	MediaNavigationCell* cell  = [tableView dequeueReusableCellWithIdentifier:@"track cell"];
    if(cell == nil) {
        cell = [[MediaNavigationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"track cell"];
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont fontWithName:@"Optima-Bold" size:18];
        cell.textLabel.textColor = [UIColor blackColor];
    }
	cell.textLabel.text = [[[collection items] objectAtIndex:[indexPath indexAtPosition:1]]  valueForProperty:MPMediaItemPropertyTitle];
	return cell;
}

#pragma mark As UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSLog(@"didSelectRowAtIndexPath");
	NSLog(@"selected [%@]",[[[collection items] objectAtIndex:[indexPath indexAtPosition:1]]  valueForProperty:MPMediaItemPropertyTitle]);
	[delegate playMediaItem:[[collection items] objectAtIndex:[indexPath indexAtPosition:1]] ];
}


@end
