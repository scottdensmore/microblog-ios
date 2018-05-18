//
//  RFConstants.h
//  Snippets
//
//  Created by Manton Reece on 8/25/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

static NSString* const kLoadTimelineNotification = @"RFLoadTimeline";
static NSString* const kOpenPostingNotification = @"RFOpenPosting";
static NSString* const kClosePostingNotification = @"RFClosePosting";

#define kShowConversationNotification @"RFShowConversationNotification"
#define kShowConversationPostIDKey @"post_id"

#define kPrepareConversationNotification @"RFPrepareConversationNotification"
#define kPrepareConversationPointKey @"point" // CGFloat y
#define kPrepareConversationControllersKey @"controllers" // NSMutableArray of UIViewController
#define kPrepareConversationTimelineKey @"timeline" // RFTimelineController

#define kShowUserProfileNotification @"RFShowUserProfileNotification"
#define kShowUserProfileUsernameKey @"username"

#define kShowUserFollowingNotification @"RFShowUserFollowingNotification"
#define kShowUserFollowingUsernameKey @"username"

#define kShowTopicNotification @"RFShowTopicNotification"
#define kShowTopicKey @"topic"

#define kShowReplyPostNotification @"RFShowReplyPostNotification"
#define kShowReplyPostIDKey @"post_id"
#define kShowReplyPostUsernameKey @"username"

#define kShowSigninNotification @"RFShowSigninNotification"

#define kPostWasFavoritedNotification @"RFPostWasFavoritedNotification"
#define kPostWasUnfavoritedNotification @"RFPostWasUnfavoritedNotification"
#define kPostWasDeletedNotification @"RFPostWasDeletedNotification"
#define kPostWasUnselectedNotification @"RFPostWasUnselectedNotification"
#define kPostNotificationPostIDKey @"post_id"

#define kMicroblogSelectNotification @"kMicroblogSelectNotification"

#define kPushNotificationReceived @"kPushNotificationReceived"

#define kSharePostNotification @"RFSharePostNotification"
#define kSharePostIDKey @"post_id"

#define kOpenURLNotification @"RFOpenURLNotification"
#define kOpenURLKey @"url"

static NSString* const kResetDetailNotification = @"RFResetDetail";
static NSString* const kResetDetailControllerKey = @"controller";

static NSString* const kShortcutActionNewPost = @"com.riverfold.snippets.shortcut.post";

#define APPSTORE 1
