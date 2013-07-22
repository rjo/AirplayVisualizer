//
//  MediaNavigationCell.m
//  grid
//
//  Created by Robert Olivier on 4/5/10.
//  Copyright 2010 RJO Management, Inc. All rights reserved.
//

#import "MediaNavigationCell.h"


@implementation MediaNavigationCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Initialization code
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

	if(selected) {
		//self.contentView.backgroundColor = [UIColor colorWithRed:0.3 green:0.0 blue:0.8 alpha:0.3];
		self.textLabel.textColor = [UIColor blueColor];
	} else {
		//self.contentView.backgroundColor = [UIColor clearColor];
		self.textLabel.textColor = [UIColor blackColor];
	}


    // Configure the view for the selected state
}


-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {

	if(highlighted)
		self.textLabel.textColor = [UIColor blueColor];
	else
		self.textLabel.textColor = [UIColor blackColor];

}



@end
