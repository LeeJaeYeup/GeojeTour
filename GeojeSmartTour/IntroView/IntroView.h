//
//  IntroView.h
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 19..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol IntroViewDelegate;
@interface IntroView : UIView

@property (nonatomic, weak) id <IntroViewDelegate> delegate;

-(void)setAllUIText;

@end

@protocol IntroViewDelegate <NSObject>

-(void)introView:(IntroView*)introView didSelectMainMenuIndex:(NSInteger)index;

@end
