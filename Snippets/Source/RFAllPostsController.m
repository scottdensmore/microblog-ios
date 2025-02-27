//
//  RFAllPostsController.m
//  Micro.blog
//
//  Created by Manton Reece on 3/12/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import "RFAllPostsController.h"

#import "RFPostCell.h"
#import "RFPost.h"
#import "RFEditPostController.h"
#import "RFPostController.h"
#import "RFSelectBlogViewController.h"
#import "RFSwipeNavigationController.h"
#import "RFOptionsController.h"
#import "UIBarButtonItem+Extras.h"
#import "RFExternalController.h"
#import "RFClient.h"
#import "RFSettings.h"
#import "RFConstants.h"
#import "RFMacros.h"
#import "UUDate.h"
#import "UUAlert.h"

static NSString* const kPostCellIdentifier = @"PostCell";

@implementation RFAllPostsController

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	[self setupNavigation];
	[self setupNotifications];
		
	[self fetchPosts];
}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kDidJustUpdatePostPrefKey]) {
		self.searchField.text = @"";
		[self fetchPosts];
	}

	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:kDidJustUpdatePostPrefKey];

//	[[self swipeNavigationController] disableGesture];
}

- (void) viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
//	[[self swipeNavigationController] enableGesture];
}

- (void) setupNavigation
{
	if (self.isShowingPages) {
		self.title = @"Pages";
	}
	else {
		self.title = @"Posts";
	}
	
	UIViewController* root_controller = [self.navigationController.viewControllers firstObject];
	if (self.navigationController.topViewController != root_controller) {
		self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_backBarButtonWithTarget:self action:@selector(back:)];
	}
	
	if (self.isShowingPages) {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"New Page" style:UIBarButtonItemStylePlain target:self action:@selector(promptNewPage:)];
	}
	else {
		if (@available(iOS 13.0, *)) {
			self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"square.and.pencil"] style:UIBarButtonItemStylePlain target:self action:@selector(promptNewPost:)];
		}
		else {
			self.navigationItem.rightBarButtonItem = [UIBarButtonItem rf_barButtonWithImageNamed:@"new_post_button" target:self action:@selector(promptNewPost:)];
		}
	}
}

- (void) setupNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedBlogNotification:) name:kPostToBlogSelectedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editPostNotification:) name:kEditPostNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deletePostNotification:) name:kDeletePostNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(publishPostNotification:) name:kPublishPostNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closePostingNotification:) name:kClosePostingNotification object:nil];
}

- (void) setupBlogName
{
	NSString* s = [RFSettings accountDefaultSite];
	if (s) {
		[self.hostnameButton setTitle:s forState:UIControlStateNormal];
	}
	else {
		self.hostnameButton.hidden = YES;
	}
}

- (void) fetchPosts
{
	[self fetchPostsForSearch:@""];
}

- (void) fetchPostsForSearch:(NSString *)search
{
	self.allPosts = @[];
	self.currentPosts = @[];
	self.hostnameButton.hidden = YES;
	self.tableView.alpha = 0.0;
	[self.progressSpinner startAnimating];

	NSString* destination_uid = [RFSettings selectedBlogUid];
	if (destination_uid == nil) {
		destination_uid = @"";
	}

	NSString* channel = @"default";
	if (self.isShowingPages) {
		channel = @"pages";
	}
	
	NSDictionary* args = @{
		@"q": @"source",
		@"mp-destination": destination_uid,
		@"mp-channel": channel,
		@"filter": search
	};

	RFClient* client = [[RFClient alloc] initWithPath:@"/micropub"];
	[client getWithQueryArguments:args completion:^(UUHttpResponse* response) {
		if ([response.parsedResponse isKindOfClass:[NSDictionary class]]) {
			NSMutableArray* new_posts = [NSMutableArray array];

			NSArray* items = [response.parsedResponse objectForKey:@"items"];
			for (NSDictionary* item in items) {
				RFPost* post = [[RFPost alloc] init];
				NSDictionary* props = [item objectForKey:@"properties"];
				post.postID = [[props objectForKey:@"uid"] firstObject];
				post.title = [[props objectForKey:@"name"] firstObject];
				post.text = [[props objectForKey:@"content"] firstObject];
				post.url = [[props objectForKey:@"url"] firstObject];
				post.channel = channel;
				post.isTemplate = [[[props objectForKey:@"microblog-template"] firstObject] boolValue];

				NSString* date_s = [[props objectForKey:@"published"] firstObject];
				post.postedAt = [NSDate uuDateFromRfc3339String:date_s];

				NSString* status = [[props objectForKey:@"post-status"] firstObject];
				post.isDraft = [status isEqualToString:@"draft"];

				[new_posts addObject:post];
			}
			
			RFDispatchMainAsync (^{
				self.allPosts = new_posts;
				self.currentPosts = new_posts;
				[self.tableView reloadData];
				[self.progressSpinner stopAnimating];
				[self setupBlogName];
				self.hostnameButton.hidden = NO;
				
				[UIView animateWithDuration:0.3 animations:^{
					self.tableView.alpha = 1.0;
				}];
			});
		}
	}];
}

- (void) searchPosts:(NSString *)text
{
	NSString* q = [text lowercaseString];
	[self fetchPostsForSearch:q];
		
//	NSMutableArray* filtered_posts = [NSMutableArray array];
//	for (RFPost* post in self.allPosts) {
//		if ([[post.title lowercaseString] containsString:q] || [[post.text lowercaseString] containsString:q]) {
//			[filtered_posts addObject:post];
//		}
//	}
//
//	self.currentPosts = filtered_posts;
//	[self.tableView reloadData];
}

- (RFSwipeNavigationController *) swipeNavigationController
{
	if ([self.navigationController isKindOfClass:[RFSwipeNavigationController class]]) {
		RFSwipeNavigationController* nav_controller = (RFSwipeNavigationController *)self.navigationController;
		return nav_controller;
	}
	else {
		return nil;
	}
}

- (void) back:(id)sender
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction) promptNewPost:(id)sender
{
	if ([RFSettings needsExternalBlogSetup]) {
		RFExternalController* wordpress_controller = [[RFExternalController alloc] init];
		UINavigationController* nav_controller = [[UINavigationController alloc] initWithRootViewController:wordpress_controller];
		[self.navigationController presentViewController:nav_controller animated:YES completion:NULL];
	}
	else {
		RFPostController* post_controller = [[RFPostController alloc] init];
		UINavigationController* nav_controller = [[UINavigationController alloc] initWithRootViewController:post_controller];
		[self.navigationController presentViewController:nav_controller animated:YES completion:NULL];
	}
}

- (void) promptNewPage:(id)sender
{
	RFPostController* post_controller = [[RFPostController alloc] initWithChannel:@"pages"];
	UINavigationController* nav_controller = [[UINavigationController alloc] initWithRootViewController:post_controller];
	[self.navigationController presentViewController:nav_controller animated:YES completion:NULL];
}

- (IBAction) blogHostnamePressed:(id)sender
{
	NSArray* blogs = [RFSettings blogList];
	if (blogs.count > 1) {
		UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Blogs" bundle:nil];
		UIViewController* controller = [storyboard instantiateViewControllerWithIdentifier:@"BlogsNavigation"];
		RFSelectBlogViewController* select_controller = [controller.childViewControllers firstObject];
		select_controller.isCancelable = YES;
		[self presentViewController:controller animated:YES completion:NULL];
	}
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
	RFDispatchMainAsync(^{
		[self.searchField resignFirstResponder];
		[self searchPosts:self.searchField.text];
	});

	return YES;
}

- (BOOL) textFieldShouldClear:(UITextField *)textField
{
	RFDispatchMainAsync(^{
		[self.searchField resignFirstResponder];
		[self searchPosts:@""];
	});

	return YES;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	RFEditPostController* edit_controller = [segue destinationViewController];
	edit_controller.post = self.selectedPost;
}

- (void) selectedBlogNotification:(NSNotification *)notification
{
	[self setupBlogName];
	[self fetchPosts];
}

- (void) editPostNotification:(NSNotification *)notification
{
	[self performSegueWithIdentifier:@"EditPostSegue" sender:self];
}

- (void) deletePostNotification:(NSNotification *)notification
{
	if (self.selectedPost) {
		NSString* destination_uid = [RFSettings selectedBlogUid];
		if (destination_uid == nil) {
			destination_uid = @"";
		}

		NSDictionary* info = @{
			@"action": @"delete",
			@"url": self.selectedPost.url,
			@"mp-destination": destination_uid
		};

		RFClient* client = [[RFClient alloc] initWithPath:@"/micropub"];
		[client postWithObject:info completion:^(UUHttpResponse* response) {
			RFDispatchMainAsync (^{
				if (response.parsedResponse && [response.parsedResponse isKindOfClass:[NSDictionary class]] && response.parsedResponse[@"error"]) {
					NSString* msg = response.parsedResponse[@"error_description"];
					[UUAlertViewController uuShowOneButtonAlert:@"Error Deleting Post" message:msg button:@"OK" completionHandler:NULL];
				}
				else {
					[self fetchPosts];
				}
			});
		}];
	}
}

- (void) publishPostNotification:(NSNotification *)notification
{
	if (self.selectedPost) {
		NSString* destination_uid = [RFSettings selectedBlogUid];
		if (destination_uid == nil) {
			destination_uid = @"";
		}

		NSString* post_status = @"published";

		NSDictionary* info = @{
			@"action": @"update",
			@"url": self.selectedPost.url,
			@"mp-destination": destination_uid,
			@"replace": @{
				@"name": self.selectedPost.title,
				@"content": self.selectedPost.text,
				@"post-status": post_status
			}
		};

		RFClient* client = [[RFClient alloc] initWithPath:@"/micropub"];
		[client postWithObject:info completion:^(UUHttpResponse* response) {
			RFDispatchMainAsync (^{
				if (response.parsedResponse && [response.parsedResponse isKindOfClass:[NSDictionary class]] && response.parsedResponse[@"error"]) {
					NSString* msg = response.parsedResponse[@"error_description"];
					[UUAlertViewController uuShowOneButtonAlert:@"Error Updating Post" message:msg button:@"OK" completionHandler:NULL];
				}
				else {
					[self fetchPosts];
				}
			});
		}];
	}
}

- (void) closePostingNotification:(NSNotification *)notification
{
	[self fetchPosts];
}

#pragma mark -

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [self.currentPosts count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	RFPostCell* cell = [tableView dequeueReusableCellWithIdentifier:kPostCellIdentifier forIndexPath:indexPath];
	
	RFPost* post = [self.currentPosts objectAtIndex:indexPath.row];
	[cell setupWithPost:post];
	
	return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	self.selectedPost = [self.currentPosts objectAtIndex:indexPath.row];

	RFDispatchMainAsync (^{
		RFOptionsPopoverType popover_type = kOptionsPopoverEditPost;
		if (self.selectedPost.isDraft) {
			popover_type = kOptionsPopoverEditWithPublish;
		}
		else if (self.selectedPost.isTemplate) {
			popover_type = kOptionsPopoverEditDeleteOnly;
		}
		
		CGRect r = [tableView rectForRowAtIndexPath:indexPath];
		NSString* post_id = [self.selectedPost.postID stringValue];
		
		RFOptionsController* options_controller = [[RFOptionsController alloc] initWithPostID:post_id username:@"" popoverType:popover_type];
		[options_controller attachToView:tableView atRect:r];
		[self presentViewController:options_controller animated:YES completion:NULL];
	});
}

@end
