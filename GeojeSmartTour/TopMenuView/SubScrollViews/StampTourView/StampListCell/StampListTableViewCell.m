//
//  StampListTableViewCell.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 18..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import "StampListTableViewCell.h"

@implementation StampListTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.backgroundColor = [UIColor clearColor];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
}

-(void)prepareForReuse
{
    [super prepareForReuse];
    self.thumbImgView.image = nil;
    self.titleLabel.text = nil;
    self.progressCountLabel.text = nil;
    self.stampCountBorderImage = nil;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

-(void)setCellContentsWithImageName:(NSString*)imgName title:(NSString*)title progressCount:(NSString*)count maxCount:(BOOL)isMaxed
{
    NSString *circleBorderImgName = @"stamp_total_circle_off";
    if(isMaxed) circleBorderImgName = @"stamp_total_circle_on";
    
    self.stampCountBorderImage.image = [UIImage imageNamed:circleBorderImgName];
    self.titleLabel.text = title;
    
    //이미지 비동기 로드...
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        
        UIImage *img = [UIImage imageNamed:imgName];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.thumbImgView.image = img;
        });
    });
    
    UIColor *progressCountTextColor = [UIColor colorWithRed:0.f green:0.396f blue:0.749f alpha:1.f];
    UIColor *maxCountTextColor = [UIColor grayColor];
    NSDictionary *attrs = @{NSForegroundColorAttributeName : progressCountTextColor};
    NSDictionary *attrs2 = @{NSForegroundColorAttributeName : maxCountTextColor};
//    NSDictionary *attrs2 = @{NSFontAttributeName : [UIFont boldSystemFontOfSize:fontSize]};

    NSMutableAttributedString *attString = [[NSMutableAttributedString alloc] initWithString:count];
    [attString addAttributes:attrs range:NSMakeRange(0, 1)];
    [attString addAttributes:attrs2 range:NSMakeRange(1, [count length] - 1)];
    
    self.progressCountLabel.attributedText = attString;
}

@end
