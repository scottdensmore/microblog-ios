//
//  RFPostController.h
//  Snippets
//
//  Created by Manton Reece on 8/18/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>
#import "RFViewController.h"

@class RFFeedsController;

@interface RFPostController : RFViewController <UITextViewDelegate, UIDropInteractionDelegate, UITextFieldDelegate, NSLayoutManagerDelegate, UICollectionViewDelegate, UICollectionViewDataSource>

@property (strong, nonatomic) IBOutlet UITextView* textView;
@property (strong, nonatomic) IBOutlet UILabel* remainingField;
@property (strong, nonatomic) IBOutlet UILabel* blognameField;
@property (strong, nonatomic) IBOutlet UIButton* photoButton;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView* networkSpinner;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* bottomConstraint;
@property (strong, nonatomic) IBOutlet UICollectionView* collectionView;
@property (strong, nonatomic) IBOutlet UIView* progressHeaderView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* progressHeaderHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* progressHeaderTopConstraint;
@property (strong, nonatomic) IBOutlet UILabel* progressHeaderField;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* titleHeaderHeightConstraint;
@property (strong, nonatomic) IBOutlet UITextField* titleField;
@property (strong, nonatomic) IBOutlet UIView* editingBar;
@property (strong, nonatomic) IBOutlet UIButton* markdownBoldButton;
@property (strong, nonatomic) IBOutlet UIButton* markdownItalicsButton;
@property (strong, nonatomic) IBOutlet UIButton* markdownLinkButton;
@property (strong, nonatomic) IBOutlet UIButton* settingsButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* photoButtonLeftConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* photoBarHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* settingsButtonRightConstraint;

@property (strong, nonatomic) IBOutlet UIView* autoCompleteContainerView;
@property (strong, nonatomic) IBOutlet UICollectionView* autoCompleteCollectionView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint* autoCompleteHeightConstraint;

@property (assign, nonatomic) BOOL isSent;
@property (assign, nonatomic) BOOL isReply;
@property (assign, nonatomic) BOOL isDraft;
@property (assign, nonatomic) BOOL isAnimatingTitle;
@property (strong, nonatomic) NSString* replyPostID;
@property (strong, nonatomic) NSString* replyUsername;
@property (strong, nonatomic) NSString* initialText;
@property (strong, nonatomic) NSString* channel;
@property (strong, nonatomic) NSArray* attachedPhotos; // RFPhoto
@property (strong, nonatomic) NSArray* queuedPhotos; // RFPhoto
@property (strong, nonatomic) NSSet* selectedCategories; // NSString
@property (strong, nonatomic) id textStorage;
@property (strong, nonatomic) NSLayoutManager* textLayout;
@property (strong, nonatomic) RFFeedsController* feedsController;

- (instancetype) initWithText:(NSString *)text;
- (instancetype) initWithReplyTo:(NSString *)postID replyUsername:(NSString *)username;
- (instancetype) initWithChannel:(NSString *)channel;

@end
