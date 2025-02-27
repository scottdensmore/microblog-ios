//
//  UIView+Extras.h
//  Micro.blog
//
//  Created by Manton Reece on 12/2/18.
//  Copyright © 2018 Riverfold Software. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (Extras)

- (CGFloat) rf_statusBarHeight;
- (CGFloat) rf_statusBarAndNavigationHeight;
- (CGFloat) rf_bottomSafeArea;

@end

NS_ASSUME_NONNULL_END
