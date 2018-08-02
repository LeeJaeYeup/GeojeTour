//
//  StampCollectionViewCell.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 18..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import "StampCollectionViewCell.h"

@interface StampCollectionViewCell ()
@property (weak, nonatomic) IBOutlet UIImageView *stampImgView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (strong, nonatomic) NSDictionary *stampInfoDict;
@property (nonatomic, assign) NSInteger dataIndex;
@property (nonatomic, strong) NSString *cateCdStr;

//하단 시간앞에 이미지 시계표시 아이콘
@property (weak, nonatomic) IBOutlet UIImageView *clockIcoImageView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLabelConstraint;

@end

@implementation StampCollectionViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
}

-(void)setStampWithInfo:(NSDictionary*)stampInfo cateCd:(NSString*)cateCd dataIndex:(NSInteger)datIndex
{
    self.stampInfoDict = stampInfo;
    self.dataIndex = datIndex;
    self.cateCdStr = cateCd;
    
//    NSLog(@"self.dataIndex : %ld",self.dataIndex);
//    NSLog(@"cateCd : %@",self.cateCdStr);
    
    self.titleLabel.text = [stampInfo objectForKey:@"title"];
    
    if([[stampInfo objectForKey:@"regDate"] length] > 0)
        self.dateLabel.text = [stampInfo objectForKey:@"regDate"];
    //시간 정보가 없을때..(발견하지 않은 스탬프일때)
    else
    {
        [self layoutIfNeeded];
        
        //시간표기 라벨 숨기고 타이틀 라벨 센터로 정렬하기.
        self.clockIcoImageView.hidden = self.dateLabel.hidden = YES;
        CGFloat newConstrantValue = self.titleLabel.superview.bounds.size.height/2 - self.titleLabel.bounds.size.height/2;
        [self.titleLabelConstraint setConstant:newConstrantValue];
    }
    
    BOOL bEnableStamp = [[stampInfo objectForKey:@"cateCd2Ok"] integerValue];
    
    NSString *stampImgFileName = @"stamp_disable";
    if(bEnableStamp)
        stampImgFileName = @"stamp_enable";
    
    _stampImgView.image = [UIImage imageNamed:stampImgFileName];
}

#pragma mark - button event

- (IBAction)pressedBottomBtn:(id)sender
{
    NSString *contentsUrl = [_stampInfoDict objectForKey:@"url"];
    
    if([contentsUrl length] < 1)    return;
    
    [UTILITY.rootViewControllerPtr showWebViewWithUrl:contentsUrl];
}

@end
