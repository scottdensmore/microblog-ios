//
//  RFAllPostsController.h
//  Micro.blog
//
//  Created by Manton Reece on 3/12/20.
//  Copyright © 2020 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class RFPost;

@interface RFAllPostsController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView* progressSpinner;
@property (strong, nonatomic) IBOutlet UIButton* hostnameButton;
@property (strong, nonatomic) IBOutlet UITextField* searchField;
@property (strong, nonatomic) IBOutlet UITableView* tableView;

@property (strong, nonatomic) NSArray* allPosts; // RFPost
@property (strong, nonatomic) NSArray* currentPosts; // RFPost
@property (strong, nonatomic) RFPost* selectedPost;
@property (assign, nonatomic) BOOL isShowingPages;

@end

NS_ASSUME_NONNULL_END
