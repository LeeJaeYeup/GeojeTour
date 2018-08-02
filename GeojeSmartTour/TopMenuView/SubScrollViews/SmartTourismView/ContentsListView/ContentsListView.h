//
//  ContentsListView.h
//  GeojeSmartTour
//
//  Created by min su kwon on 2018. 1. 9..
//  Copyright © 2018년 min su kwon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContentsListView : UIView

-(void)setContentsWithGroupSid:(int)groupSid contentsImg:(UIImage*)img imgPath:(NSString*)path title:(NSString*)title;

@end
