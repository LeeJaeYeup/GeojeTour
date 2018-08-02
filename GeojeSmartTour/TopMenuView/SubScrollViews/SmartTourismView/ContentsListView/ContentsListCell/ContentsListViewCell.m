//
//  ContentsListViewCell.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2018. 1. 9..
//  Copyright © 2018년 min su kwon. All rights reserved.
//

#import "ContentsListViewCell.h"

@interface ContentsListViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *thumbImgView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation ContentsListViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
//    _thumbImgView.layer.cornerRadius = _thumbImgView.bounds.size.width/2;
}

-(void)prepareForReuse
{
    [super prepareForReuse];
    self.thumbImgView.image = nil;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

-(void)setContentsInfo:(NSDictionary*)contentsInfo
{
    _titleLabel.text = [contentsInfo objectForKey:@"beaconTitle"];
    
    NSString *smartcontentimg = [contentsInfo objectForKey:@"smartcontentimg"];
    
    if([smartcontentimg length] > 1)
    {
        smartcontentimg = [smartcontentimg stringByReplacingOccurrencesOfString:@"/data/web/RFC3" withString:@""];
        NSString *imgPath = [NSString stringWithFormat:@"%@%@",BASE_URL,smartcontentimg];
        
//        NSLog(@"선택한 그룹 imgPath2 : %@",imgPath);
        
        ContentsListViewCell* __weak weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *image = [UIImage imageWithData: [NSData dataWithContentsOfURL:
                                                      [NSURL  URLWithString:imgPath]]];
            dispatch_sync(dispatch_get_main_queue(),^ {
                //run in main thread
                [weakSelf handleDelayedImage:image];
            });
        });
    }
}

-(void)handleDelayedImage:(UIImage*)image
{
    _thumbImgView.image = image;
}

@end
