//
//  GetPostNumView.h
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 27..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GetPostNumViewDelegate;
@interface GetPostNumView : UIView

@property (nonatomic, weak) id <GetPostNumViewDelegate> delegate;

@end

@protocol GetPostNumViewDelegate <NSObject>

-(void)getPostNumView:(GetPostNumView*)gpnView didFinishGetPostNum:(NSDictionary*)postInfo;
-(void)didSelectCloseBtnWithPostNumView:(GetPostNumView*)gpnView;

@end
