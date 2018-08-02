//
//  StampListTableViewCell.h
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 18..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StampListTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *thumbImgView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *progressCountLabel;
@property (weak, nonatomic) IBOutlet UIImageView *stampCountBorderImage;

-(void)setCellContentsWithImageName:(NSString*)imgName title:(NSString*)title progressCount:(NSString*)count maxCount:(BOOL)isMaxed;

@end
