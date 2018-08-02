//
//  SelectListView.h
//  UiryeongBeacon
//
//  Created by min su kwon on 2016. 11. 1..
//  Copyright © 2016년 SKOINFO. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol ComBoBoxViewDelegate;

@interface ComBoBoxView : UIView
{
    UITableView *selectTableView;
}

@property (nonatomic, weak) id <ComBoBoxViewDelegate> delegate;
@property (nonatomic, assign) CGFloat rowHeight;

-(void)show;
-(void)setListItemArray:(NSArray*)array;


@end

@protocol ComBoBoxViewDelegate <NSObject>

-(void)didSelectListView:(ComBoBoxView*)listView index:(NSInteger)index cellTitle:(NSString*)title;

@end
