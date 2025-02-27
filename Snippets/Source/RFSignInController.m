//
//  RFSignInController.m
//  Snippets
//
//  Created by Manton Reece on 8/18/15.
//  Copyright © 2015 Riverfold Software. All rights reserved.
//

#import "RFSignInController.h"

#import "RFClient.h"
#import "RFMacros.h"
#import "RFConstants.h"
#import "RFSettings.h"
#import "RFAccount.h"
#import "UUAlert.h"
#import "UILabel+MarkupExtensions.h"
#import "UIBarButtonItem+Extras.h"
#import "UIView+Extras.h"
#import "SSKeychain.h"
#import "RFAutoCompleteCache.h"
#import "RFUsernameController.h"
#import "UITraitCollection+Extras.h"
#import <AuthenticationServices/AuthenticationServices.h>

@import UserNotifications;

@implementation RFSignInController

- (instancetype) init
{
	self = [super initWithNibName:@"SignIn" bundle:nil];
	if (self) {
	}
	
	return self;
}

- (void) viewDidLoad
{
	[super viewDidLoad];

	if (@available(iOS 13.0, *)) {
		self.modalInPresentation = YES;
	}

	[self setupNavigation];
	[self setupNotifications];
	
	[self hideMessage];
}

- (void) viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
	
	[self setupAppleSignIn];
}

- (void) setupNavigation
{
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Continue" style:UIBarButtonItemStylePlain target:self action:@selector(finish:)];

	if ([[RFAccount allAccounts] count] > 0) {
		self.title = @"Add Account";
		self.navigationItem.leftBarButtonItem = [UIBarButtonItem rf_closeBarButtonWithTarget:self action:@selector(cancel:)];
	}
	else {
		self.title = @"Welcome";
	}
}

- (void) setupNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSigninTokenNotification:) name:kUpdateSigninTokenNotification object:nil];
}

- (void) setupAppleSignIn
{
	if (self.signInWithAppleButton) {
		if (@available(iOS 13.0, *)) {
			// replace placeholder button with real button
			ASAuthorizationAppleIDButton* button;
			if ([UITraitCollection rf_isDarkMode]) {
				button = [ASAuthorizationAppleIDButton buttonWithType:ASAuthorizationAppleIDButtonTypeDefault style:ASAuthorizationAppleIDButtonStyleWhite];
			}
			else {
				button = [ASAuthorizationAppleIDButton buttonWithType:ASAuthorizationAppleIDButtonTypeDefault style:ASAuthorizationAppleIDButtonStyleBlack];
			}
			button.cornerRadius = 5.0;
			button.translatesAutoresizingMaskIntoConstraints = NO;
			button.frame = self.signInWithAppleButton.frame;
			[button addTarget:self action:@selector(signInWithApple:) forControlEvents:UIControlEventTouchUpInside];
			[self.signInWithAppleButton.superview addSubview:button];

			NSLayoutConstraint* top_constraint = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.signInWithAppleIntro attribute:NSLayoutAttributeBottom multiplier:1.0 constant:15];
			[top_constraint setActive:YES];
			NSLayoutConstraint* center_constraint = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
			[center_constraint setActive:YES];
			NSLayoutConstraint* width_constraint = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:button.frame.size.width];
			[width_constraint setActive:YES];
			NSLayoutConstraint* height_constraint = [NSLayoutConstraint constraintWithItem:button attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:button.frame.size.height];
			[height_constraint setActive:YES];

			[self.signInWithAppleButton removeFromSuperview];
			self.signInWithAppleButton = nil;
		}
		else {
			// hide placeholder button and intro text
			self.signInWithAppleButton.hidden = YES;
			self.signInWithAppleIntro.hidden = YES;
			self.signInWithAppleButton = nil;
		}
	}
}

- (void) updateSigninTokenNotification:(NSNotification *)notification
{
	NSString* token = [notification.userInfo objectForKey:kUpdateSigninTokenKey];
	[self updateToken:token];
}

- (void) updateToken:(NSString *)appToken
{
	if (appToken.length > 0) {
		RFDispatchSeconds (0.5, ^{
			self.signinToken = appToken;
			[self.view endEditing:NO];
			[self verifyAppToken];
		});
	}
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
	[self finish:nil];
	return YES;
}

- (IBAction) finish:(id)sender
{
	if (self.tokenField.text.length > 0) {
		[self.networkSpinner startAnimating];
		
		if ([self.tokenField.text containsString:@"@"]) {
			[self sendSigninEmail];
		}
		else {
			self.signinToken = self.tokenField.text;
			[self verifyAppToken];
		}
	}
}

- (IBAction) signInWithApple:(id)sender
{
	if (@available(iOS 13.0, *)) {
		ASAuthorizationAppleIDProvider* provider = [[ASAuthorizationAppleIDProvider alloc] init];
		
		ASAuthorizationAppleIDRequest* request = [provider createRequest];
		request.requestedScopes = @[ ASAuthorizationScopeFullName, ASAuthorizationScopeEmail ];
		
		ASAuthorizationController* controller = [[ASAuthorizationController alloc] initWithAuthorizationRequests:@[ request ]];
		controller.delegate = self;
		controller.presentationContextProvider = self;
		
		[controller performRequests];
	}
}

- (IBAction) cancel:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark -

- (void) authorizationController:(ASAuthorizationController *)controller didCompleteWithAuthorization:(ASAuthorization *)authorization
{
	if (@available(iOS 13.0, *)) {
		ASAuthorizationAppleIDCredential* credential = authorization.credential;
		NSString* user_id = credential.user;
		NSData* identity_token = credential.identityToken;
		NSString* email = credential.email;
		NSPersonNameComponents* name_components = credential.fullName;
		NSString* full_name = [NSString stringWithFormat:@"%@ %@", name_components.givenName, name_components.familyName];
		NSString* identity_token_s = [[NSString alloc] initWithData:identity_token encoding:kCFStringEncodingUTF8];

//		NSData* auth_code = credential.authorizationCode;
//		NSString* auth_code_s = [[NSString alloc] initWithData:auth_code encoding:kCFStringEncodingUTF8];

		NSMutableDictionary* params = [NSMutableDictionary dictionary];
		[params setObject:user_id forKey:@"user_id"];
		[params setObject:full_name forKey:@"full_name"];
		[params setObject:identity_token_s forKey:@"identity_token"];
		if (email) {
			[params setObject:email forKey:@"email"];
		}

		RFClient* client = [[RFClient alloc] initWithPath:@"/account/apple"];
		[client postWithParams:params completion:^(UUHttpResponse* response) {
			NSString* username = [response.parsedResponse objectForKey:@"username"];
			NSString* token = [response.parsedResponse objectForKey:@"token"];
			NSString* error = [response.parsedResponse objectForKey:@"error"];
			RFDispatchMain (^{
				if (error) {
					[self showMessage:error];
				}
				else if ([username length] > 0) {
					// user already has an account, sign them in
					[self updateToken:token];
				}
				else {
					RFUsernameController* username_controller = [[RFUsernameController alloc] initWithUserID:user_id identityToken:identity_token_s];
					[self.navigationController pushViewController:username_controller animated:YES];
				}
			});
		}];
	}
}

- (void) authorizationController:(ASAuthorizationController *)controller didCompleteWithError:(NSError *)error
{
//	[self showMessage:@"Error from Sign in with Apple."];
}

#pragma mark -

- (void) hideMessage
{
	self.messageTopConstraint.constant = -65;
	self.messageContainer.alpha = 0.0;
}

- (void) showMessage:(NSString *)message
{
	self.messageField.text = message;

//	if ([message containsString:@"Error"]) {
//		self.messageContainer.backgroundColor = [UIColor colorWithWhite:0.972 alpha:1.0];
//	}
//	else {
//		self.messageContainer.backgroundColor = [UIColor colorWithRed:0.875 green:0.941 blue:0.847 alpha:1.0];
//	}
	
	if (self.messageContainer.alpha == 0.0) {
		[UIView animateWithDuration:0.3 animations:^{
			self.messageTopConstraint.constant = 0;
			self.messageContainer.alpha = 1.0;
			[self.view layoutIfNeeded];
		}];
	}

	[self.networkSpinner stopAnimating];
}

- (void) verifyAppToken
{
	RFClient* client = [[RFClient alloc] initWithPath:@"/account/verify"];
	NSString* token = self.signinToken;

	NSDictionary* args = @{
		@"token": token
	};
	[client postWithParams:args completion:^(UUHttpResponse* response) {
		NSString* error = [response.parsedResponse objectForKey:@"error"];
		if (error) {
			RFDispatchMainAsync ((^{
				[self showMessage:[NSString stringWithFormat:@"Error signing in: %@", error]];
			}));
		}
		else {
			NSString* new_token = [response.parsedResponse objectForKey:@"token"];
			NSString* full_name = [response.parsedResponse objectForKey:@"full_name"];
			NSString* username = [response.parsedResponse objectForKey:@"username"];
			NSString* default_site = [response.parsedResponse objectForKey:@"default_site"];

			self.signinToken = new_token;

			[RFSettings addAccountUsername:username];
			
			[RFSettings setSnippetsAccountFullName:full_name];
			[RFSettings setSnippetsUsername:username];
			[RFSettings setAccountDefaultSite:default_site];
			[RFSettings setSnippetsPassword:new_token useCurrentUser:YES];

			[self checkForMultipleBlogs];
		}
	}];
}

- (void) setupFollowerAutoComplete
{
	NSString* username = [RFSettings snippetsUsername];
	if (username == nil) {
		return;
	}
	
	NSString* path = [NSString stringWithFormat:@"/users/following/%@", username];
	RFClient* client = [[RFClient alloc] initWithPath:path];
	[client getWithQueryArguments:nil completion:^(UUHttpResponse *response)
	{
		// We didn't get a valid response...
		if (response.httpResponse.statusCode < 200 || response.httpResponse.statusCode > 299)
		{
			return;
		}
		
		NSArray* array = response.parsedResponse;
		if (array && [array isKindOfClass:[NSArray class]])
		{
 			for (NSDictionary* dictionary in array)
			{
				NSString* username = dictionary[@"username"];
				if (username)
				{
					[RFAutoCompleteCache addAutoCompleteString:username];
				}
			}
		}
	}];
}

- (void) completeLoginProcess
{
	RFDispatchMainAsync (^{
		[[NSNotificationCenter defaultCenter] postNotificationName:kLoadTimelineNotification object:self userInfo:@{
			@"token": self.signinToken
		}];
		[self.presentingViewController dismissViewControllerAnimated:YES completion:^{

			//Now that we're logged in, request push tokens...
			UNAuthorizationOptions options = UNAuthorizationOptionBadge | UNAuthorizationOptionAlert | UNAuthorizationOptionSound;
			[[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError * _Nullable error)
			{
				dispatch_async(dispatch_get_main_queue(), ^
				{
					[UIApplication.sharedApplication registerForRemoteNotifications];
				});
			}];
		}];
	});
}

- (void) checkForMultipleBlogs
{
    // After login, pre-populate the auto-complete cache...
    [self setupFollowerAutoComplete];
    
	RFClient* client = [[RFClient alloc] initWithPath:@"/micropub?q=config"];
	[client getWithQueryArguments:nil completion:^(UUHttpResponse* response) {
		NSArray* blogs = [response.parsedResponse objectForKey:@"destination"];
		RFDispatchMainAsync ((^{
			[RFSettings setBlogList:blogs];

			if (blogs.count > 0)
			{
				if (blogs.count > 1)
				{
					// set the blog info for the current default
					for (NSDictionary* blogInfo in blogs) {
						if ([blogInfo[@"name"] isEqualToString:[RFSettings accountDefaultSite]]) {
							[RFSettings setSelectedBlogInfo:blogInfo];
							break;
						}
					}
				
					// prompt for them to select a client-side default
					UIViewController* savedParent = self.presentingViewController;
					dispatch_async(dispatch_get_main_queue(), ^
					{
						[[NSNotificationCenter defaultCenter] postNotificationName:kLoadTimelineNotification object:self userInfo:@{ @"token": self.signinToken }];
						[self.presentingViewController dismissViewControllerAnimated:NO completion:^
						{
							UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Blogs" bundle:nil];
							UIViewController* controller = [storyboard instantiateViewControllerWithIdentifier:@"BlogsNavigation"];
							[savedParent presentViewController:controller animated:NO completion:NULL];
						}];
					});
				}
				else
				{
					// only 1 blog, set it as default
					NSDictionary* blogInfo = blogs.firstObject;
					[RFSettings setSelectedBlogInfo:blogInfo];
					[self completeLoginProcess];
				}

				[[NSNotificationCenter defaultCenter] postNotificationName:kRefreshMenuNotification object:self];
			}
			else
			{
				[self completeLoginProcess];
			}

			[[NSNotificationCenter defaultCenter] postNotificationName:kRefreshUserNotification object:self];
		}));
	}];
}

- (void) sendSigninEmail
{
	RFClient* client = [[RFClient alloc] initWithPath:@"/account/signin"];
	NSDictionary* args = @{
		@"email": self.tokenField.text,
		@"is_mobile": @"1"
	};
	[client postWithParams:args completion:^(UUHttpResponse* response) {
		RFDispatchMainAsync ((^{
			NSString* error = [response.parsedResponse objectForKey:@"error"];
			if (error) {
				[self showMessage:[NSString stringWithFormat:@"Error signing in: %@", error]];
			}
			else {
				self.tokenField.text = @"";
				[self showMessage:@"Email sent! Check your email on this device and tap the \"Open in Micro.blog on iOS\" button."];
			}
		}));
	}];
}

@end
