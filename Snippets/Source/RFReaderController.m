//
//  RFReaderController.m
//  Micro.blog
//
//  Created by Manton Reece on 9/12/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import "RFReaderController.h"

#import "RFAccount.h"
#import "UIBarButtonItem+Extras.h"

@implementation RFReaderController

- (void) viewDidLoad
{
	[super viewDidLoad];

	[self setupReader];
	[self setupNavigation];
}

- (void) setupReader
{
	NSString* url = @"http://localhost:3000/hybrid/bookmarks/123";
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
	
	RFAccount* a = [RFAccount defaultAccount];
	if (a) {
		NSString* token = [a password];
		if (token) {
			NSString* auth = [NSString stringWithFormat:@"Bearer %@", token];
			[request addValue:auth forHTTPHeaderField:@"Authorization"];
		}
	}
	
	[self.webView loadRequest:request];
}

- (void) setupNavigation
{
//	self.title = @"Reader";
	self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_backBarButtonWithTarget:self action:@selector(back:)];
}

- (void) back:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

@end
