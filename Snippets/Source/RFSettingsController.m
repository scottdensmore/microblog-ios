//
//  RFSettingsController.m
//  Snippets
//
//  Created by Manton Reece on 9/1/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFSettingsController.h"

#import "RFSettingChoiceCell.h"
#import "RFConstants.h"
#import "UIBarButtonItem+Extras.h"

static NSString* const kServerCellIdentifier = @"ServerCell";

@implementation RFSettingsController

- (instancetype) init
{
	self = [super initWithNibName:@"Settings" bundle:nil];
	if (self) {
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];

	[self setupNavigation];
	[self setupServers];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];

	NSIndexPath* index_path;
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ExternalBlogIsPreferred"]) {
		index_path = [NSIndexPath indexPathForRow:1 inSection:0];
	}
	else {
		index_path = [NSIndexPath indexPathForRow:0 inSection:0];
	}

	[self.serversTableView selectRowAtIndexPath:index_path animated:NO scrollPosition:UITableViewScrollPositionNone];
}

- (void) setupNavigation
{
	self.title = @"Settings";
	
	self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"back_button" target:self action:@selector(back:)];
}

- (void) setupServers
{
	self.serverNames = @[ @"Snippets.today hosted microblog", @"WordPress or Movable Type weblog" ];

	[self.serversTableView registerNib:[UINib nibWithNibName:@"SettingChoiceCell" bundle:nil] forCellReuseIdentifier:kServerCellIdentifier];
}

- (IBAction) back:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.serverNames.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	RFSettingChoiceCell* cell = [tableView dequeueReusableCellWithIdentifier:kServerCellIdentifier forIndexPath:indexPath];
		
	cell.nameField.text = [self.serverNames objectAtIndex:indexPath.row];
	cell.checkmarkField.hidden = (indexPath.row > 0);

	return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	BOOL prefer_external_blog = (indexPath.row == 1);
	[[NSUserDefaults standardUserDefaults] setBool:prefer_external_blog forKey:@"ExternalBlogIsPreferred"];
}

@end
