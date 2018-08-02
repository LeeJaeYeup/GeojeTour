//
//  WebView.h
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 20..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MainWebView : UIView

@property (nonatomic, strong, nullable) NSString *homeUrlStr;

-(void)loadRequestWithUrl:(NSString* __nonnull)url;
-(void)setHidden:(BOOL)hidden completion:(void (^ __nullable)(BOOL finished))completion;

@end
