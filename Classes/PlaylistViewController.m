    //
//  MediaNavigationViewController.m
//  grid
//
//  Created by Robert Olivier on 4/4/10.
//  Copyright 2010 RJO Management, Inc. All rights reserved.
//

#import "PlaylistViewController.h"

@interface PlaylistViewController ()

@property (strong,nonatomic) NSArray*						collections;
@property (strong,nonatomic) IBOutlet UITableView*			tableView;

@end

@implementation PlaylistViewController

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor clearColor];
	self.tableView.backgroundColor = [UIColor clearColor];
	self.tableView.dataSource = self;
	self.tableView.delegate = self;
	[self.tableView reloadData];
	
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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



-(void)setCollections:(NSArray*)collections withTitle:(NSString*)text {
	NSLog(@"plvc setCollections");
	self.collections = collections;
	self.title = text;
}



#pragma mark As UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSLog(@"section number %d",section);
	return [self.collections count];
}

-(UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	
    MediaNavigationCell* cell = [tableView dequeueReusableCellWithIdentifier:@"playlist cell"];
    if(cell == nil) {
        cell = [[MediaNavigationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"playlist cell"];
        cell.contentView.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont fontWithName:@"Optima-Bold" size:18];
        cell.textLabel.textColor = [UIColor redColor];
    }

    cell.textLabel.text = [[self.collections objectAtIndex:[indexPath indexAtPosition:1]]  valueForProperty:MPMediaPlaylistPropertyName];

	return cell;
}

#pragma mark As UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"%@",[collections objectAtIndex:[indexPath indexAtPosition:1]]);
    MPMediaEntity* e = [self.collections objectAtIndex:[indexPath indexAtPosition:1]];
    //NSLog(@"attributes: %@",[e valueForProperty:MPMediaPlaylistPropertyPlaylistAttributes]);
    //NSLog(@"parent: %@",[e valueForProperty:@"parentPersistentID"]);
    NSNumber* isFolder = [e valueForProperty:@"isFolder"];
    NSNumber* persistentID = [e valueForProperty:MPMediaEntityPropertyPersistentID];
    //NSLog(@"persistent id:%@",persistentID);

    if(isFolder.boolValue) {
        [self.master showPlaylistsWithParentPersistentID:persistentID title:[e valueForProperty:MPMediaPlaylistPropertyName]];
    } else {
        [self.master showTrackListWithCollection:[self.collections objectAtIndex:[indexPath indexAtPosition:1]] title:[[self.collections objectAtIndex:[indexPath indexAtPosition:1]] valueForProperty:MPMediaPlaylistPropertyName]];
    }
}

@end
