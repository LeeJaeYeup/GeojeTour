//
//  CouponCollectionCell.h
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 19..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CouponCollectionCellDelegate;
@interface CouponCollectionCell : UICollectionViewCell

@property (nonatomic, weak) id <CouponCollectionCellDelegate> delegate;

-(void)setCouponInfo:(NSDictionary*)info;
@end

@protocol CouponCollectionCellDelegate <NSObject>

-(void)couponCollectionCell:(CouponCollectionCell*)cell didFinishCouponUseWithResult:(id)result couponDataInfo:(NSDictionary*)couponDataInfo;
@end
