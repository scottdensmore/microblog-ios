//
//  RFDiscoverController.m
//  Micro.blog
//
//  Created by Manton Reece on 4/28/17.
//  Copyright © 2017 Riverfold Software. All rights reserved.
//

#import "RFDiscoverController.h"

#import "RFFeaturedPhoto.h"
#import "RFFeaturedPhotoCell.h"
#import "RFTagmojiController.h"
#import "RFSearchController.h"
#import "RFClient.h"
#import "RFMacros.h"
#import "RFConstants.h"
#import "NSString+Extras.h"
#import "RFAutoCompleteCache.h"
#import "UIView+Extras.h"
#import "UIFont+Extras.h"
#import "UITraitCollection+Extras.h"

static NSString* const kPhotoCellIdentifier = @"PhotoCell";

@implementation RFDiscoverController

- (instancetype) init
{
    self = [super initWithNibName:@"Discover" bundle:nil];
    if (self) {
        self.endpoint = @"/hybrid/discover";
        self.timelineTitle = @"Discover";
    }
    
    return self;
}

- (instancetype) initWithEndpoint:(NSString *)endpoint title:(NSString *)title
{
    self = [self init];
    if (self) {
        self.endpoint = endpoint;
        self.timelineTitle = title;
    }
    
    return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];

	[self setupNavigation];
	[self setupSearchButton];
    [self setupEmojiPicker];
    [self setupNotifications];
}

- (void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[self setupSearchButton];
}

- (void) setupNavigation
{
	[super setupNavigation];

	self.title = @"Discover";
}

- (void) setupSearchButton
{
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(showSearch:)];
}

- (void) setupEmojiPicker
{
    self.stackViewContainerView.hidden = YES;
    self.stackViewContainerView.layer.borderWidth = 0.5;
    self.stackViewContainerView.layer.cornerRadius = 5.0;

    int width = self.view.bounds.size.width;
    CGFloat fontsize = [UIFont rf_preferredTimelineFontSize];
    
    RFClient* client = [[RFClient alloc] initWithFormat:@"%@?width=%d&fontsize=%f", @"/posts/discover", width, fontsize];
    [client getWithQueryArguments:nil completion:^(UUHttpResponse *response) {
        NSDictionary* dictionary = response.parsedResponse;
        if (dictionary && [dictionary isKindOfClass:[NSDictionary class]])
        {
            NSDictionary* microblogDictionary = [dictionary objectForKey:@"_microblog"];
            if (microblogDictionary && [microblogDictionary isKindOfClass:[NSDictionary class]])
            {
                NSArray* tagmoji = [microblogDictionary objectForKey:@"tagmoji"];
                if (tagmoji && [tagmoji isKindOfClass:[NSArray class]])
                {
					BOOL had_previous_emoji = (self.tagmoji.count > 0);
                    self.tagmoji = tagmoji;
                    
                    [[NSUserDefaults standardUserDefaults] setObject:tagmoji forKey:@"Saved::Tagmoji"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    
                    if (!had_previous_emoji) {
						dispatch_async(dispatch_get_main_queue(), ^{
							[self updateTagmoji:NO];
						});
                    }
                }
            }
            
        }
    }];
    
    self.tagmoji = [[NSUserDefaults standardUserDefaults] objectForKey:@"Saved::Tagmoji"];
    [self updateTagmoji:NO];
    
    self.emojiPickerView.clipsToBounds = YES;
	self.emojiPickerView.layer.borderColor = [UIColor colorNamed:@"color_emoji_button_outline"].CGColor;
    self.emojiPickerView.layer.borderWidth = 1.0;
    self.emojiPickerView.layer.cornerRadius = 5.0;
}

- (void) setupNotifications
{
	[super setupNotifications];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectTagmojiNotification:) name:kSelectTagmojiNotification object:nil];
}

- (void) updateTagmoji:(BOOL)includeAll
{
    if (self.tagmoji)
    {
        self.emojiPickerView.hidden = NO;

        for (UIView* subview  in self.emojiStackView.arrangedSubviews)
        {
            [subview removeFromSuperview];
        }
        
        NSString* emojiList = @"";
        NSMutableArray* featuredEmoji = [NSMutableArray array];
        for (NSDictionary* dictionary in self.tagmoji)
        {
            NSNumber* featured = [dictionary objectForKey:@"is_featured"];
            NSString* emoji = [dictionary objectForKey:@"emoji"];
            if ([featured boolValue]) {
                [featuredEmoji addObject:emoji];
			}
			
			if ([featured boolValue] || includeAll) {
				NSString* title = [NSString stringWithFormat:@"%@ %@", emoji, [dictionary objectForKey:@"title"]];
				UIButton* button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.emojiStackView.frame.size.width, 14.0)];
				button.translatesAutoresizingMaskIntoConstraints = NO;
				
				[button setTitle:title forState:UIControlStateNormal];
				button.titleLabel.font = [UIFont systemFontOfSize:15];
				[button setTitleColor:[UIColor colorNamed:@"color_popover_buttons"] forState:UIControlStateNormal];
				[button.titleLabel sizeToFit];
				button.tag = [self.tagmoji indexOfObject:dictionary];
				
				[self.emojiStackView addArrangedSubview:button];
				[button addTarget:self action:@selector(onHandleEmojiSelect:) forControlEvents:UIControlEventTouchUpInside];
			}
        }
        
        for (int i = 0; i < 3; i++)
        {
            NSUInteger index = arc4random_uniform((int)featuredEmoji.count);
			if (featuredEmoji.count > index) {
				NSString* emoji = [featuredEmoji objectAtIndex:index];
				emojiList = [emojiList stringByAppendingString:emoji];
				[featuredEmoji removeObject:emoji];
			}
        }
        
        self.emojiLabel.text = emojiList;
        [self.emojiLabel sizeToFit];
        [self.view layoutIfNeeded];
    }
    else {
        self.descriptionLabel.text = @"Some recent posts from the community.";
        self.emojiPickerView.hidden = YES;
    }
    
}

- (void) collapseTagmoji
{
	self.emojiWidthContraint.constant = 180;
}

- (void) showOverlay
{
	CGRect r = self.view.bounds;
	self.overlayButton = [[UIButton alloc] initWithFrame:r];
	self.overlayButton.backgroundColor = [UIColor clearColor];
	[self.view insertSubview:self.overlayButton belowSubview:self.stackViewContainerView];

	[self.overlayButton addTarget:self action:@selector(onSelectEmoji:) forControlEvents:UIControlEventTouchUpInside];
}

- (void) hideOverlay
{
	[self.overlayButton removeFromSuperview];
}

- (void) showSearch:(id)sender
{
	RFSearchController* search_controller = [[RFSearchController alloc] init];
	[self.navigationController pushViewController:search_controller animated:YES];
}

- (UITextField *) findTextFieldInView:(UIView *)v
{
	id result = nil;
	
	for (UIView* sub in v.subviews) {
		if ([sub isKindOfClass:[UITextField class]]) {
			result = sub;
			break;
		}
		else {
			result = [self findTextFieldInView:sub];
		}
	}
	
	return result;
}

- (void) showPhotos
{
	UICollectionViewFlowLayout* flow_layout = [[UICollectionViewFlowLayout alloc] init];

	CGRect r = self.view.bounds;
	r.origin.y += (44 + [self.view rf_statusBarHeight]);
	r.size.height -= (44 + [self.view rf_statusBarHeight]);

	self.photosCollectionView = [[UICollectionView alloc] initWithFrame:r collectionViewLayout:flow_layout];
	self.photosCollectionView.delegate = self;
	self.photosCollectionView.dataSource = self;
	self.photosCollectionView.alpha = 0.0;
	self.photosCollectionView.backgroundColor = [UIColor whiteColor];
	
	[self.photosCollectionView registerNib:[UINib nibWithNibName:@"FeaturedPhotoCell" bundle:nil] forCellWithReuseIdentifier:kPhotoCellIdentifier];
	
	[self.view addSubview:self.photosCollectionView];
	
	RFClient* client = [[RFClient alloc] initWithPath:@"/discover/photos"];
	[client getWithQueryArguments:nil completion:^(UUHttpResponse* response) {
		NSMutableArray* featured_photos = [NSMutableArray array];
		if (response.parsedResponse) {
			for (NSDictionary* info in response.parsedResponse) {
				RFFeaturedPhoto* photo = [[RFFeaturedPhoto alloc] init];
				photo.username = info[@"username"];
				photo.imageURL = info[@"image_url"];
				[featured_photos addObject:photo];
				
				[RFAutoCompleteCache addAutoCompleteString:info[@"username"]];
			}
			
			RFDispatchMain (^{
				self.featuredPhotos = featured_photos;
				[self.photosCollectionView reloadData];
			});
		}
	}];
	
	[UIView animateWithDuration:0.3 animations:^{
		self.photosCollectionView.alpha = 1.0;
	}];
}

- (void) hidePhotos
{
	[UIView animateWithDuration:0.3 animations:^{
		self.photosCollectionView.alpha = 0.0;
	} completion:^(BOOL finished) {
		[self.photosCollectionView removeFromSuperview];
		self.photosCollectionView = nil;
		self.featuredPhotos = @[];
	}];
}

- (void) selectEmoji:(NSDictionary *)info
{
    NSString* emoji = [info objectForKey:@"emoji"];
    NSString* name = [info objectForKey:@"name"];
    NSString* title = [info objectForKey:@"title"];
    NSString* description = [NSString stringWithFormat:@"Some recent posts for %@ %@.", emoji, title];
    self.descriptionLabel.text = description;
    self.endpoint = [NSString stringWithFormat:@"/hybrid/discover/%@", name];
    self.stackViewContainerView.hidden = YES;
    [self refreshTimelineShowingSpinner:YES];

	[self collapseTagmoji];
	[self hideOverlay];
}

- (void) selectTagmojiNotification:(NSNotification *)notification
{
	NSDictionary* info = [notification.userInfo objectForKey:kSelectTagmojiInfoKey];
	[self selectEmoji:info];
}

- (IBAction) onSelectEmoji:(UIButton*)sender
{
    self.stackViewContainerView.hidden = !self.stackViewContainerView.hidden;
    if (self.stackViewContainerView.hidden) {
    	[self collapseTagmoji];
    	[self hideOverlay];
    }
    else {
		[self showOverlay];
    }
}

- (IBAction) onHandleEmojiSelect:(UIButton*)sender
{
    NSInteger index = sender.tag;
    NSDictionary* info = [self.tagmoji objectAtIndex:index];
	[self selectEmoji:info];
}

- (IBAction) onHandleZoom:(id)sender
{
//	[self updateTagmoji:YES];
	
//	[UIView animateWithDuration:0.3 animations:^{
//		const CGFloat popover_padding = 10;
//		const CGFloat inset_padding = 8;
//		self.emojiWidthContraint.constant = self.view.bounds.size.width - (popover_padding * 2) - (inset_padding * 2);
//	}];

	self.stackViewContainerView.hidden = YES;
	[self hideOverlay];

	self.tagmojiController = [[RFTagmojiController alloc] initWithTagmoji:self.tagmoji];
	UINavigationController* nav_controller = [[UINavigationController alloc] initWithRootViewController:self.tagmojiController];
	[self presentViewController:nav_controller animated:YES completion:NULL];
}

#pragma mark -

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return self.featuredPhotos.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	RFFeaturedPhotoCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:kPhotoCellIdentifier forIndexPath:indexPath];

	RFFeaturedPhoto* photo = [self.featuredPhotos objectAtIndex:indexPath.item];
	[cell setupWithPhoto:photo];
	
	return cell;
}

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	RFFeaturedPhoto* photo = [self.featuredPhotos objectAtIndex:indexPath.item];
	NSString* username = photo.username;
	[[NSNotificationCenter defaultCenter] postNotificationName:kShowUserProfileNotification object:self userInfo:@{ kShowUserProfileUsernameKey: username }];
}

- (CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
	return CGSizeMake (100, 130);
}

- (UIEdgeInsets) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
	return UIEdgeInsetsMake (8, 5, 5, 5);
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
	return 5;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
	return 0;
}

@end
