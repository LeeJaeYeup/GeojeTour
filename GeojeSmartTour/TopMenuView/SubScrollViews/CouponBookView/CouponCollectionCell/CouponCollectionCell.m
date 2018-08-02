//
//  CouponCollectionCell.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 19..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import "CouponCollectionCell.h"
#import "TheConnection.h"

@interface CouponCollectionCell() <TheConnectionDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titlelabel;
@property (weak, nonatomic) IBOutlet UILabel *discountRateLabel;
@property (weak, nonatomic) IBOutlet UILabel *discountDayLabel;
@property (strong, nonatomic) NSDictionary *couponInfoData;

@end

@implementation CouponCollectionCell

- (void)awakeFromNib
{
    [super awakeFromNib];
}

-(void)prepareForReuse
{
    [super prepareForReuse];
    _titlelabel.text = nil;
    _discountRateLabel.text = nil;
    _discountDayLabel.text = nil;
}

-(void)setCouponInfo:(NSDictionary*)info
{
//    NSLog(@"쿠폰 정보 : %@",info);
    self.couponInfoData = info;
    _titlelabel.text = [info objectForKey:@"basicTitle"];
    _discountRateLabel.text = [info objectForKey:@"basicCouponContent"];

    //basicCoupondayType    1:상시 2:연중 3:날짜
    NSInteger basicCoupondayType = [[info objectForKey:@"basicCoupondayType"] integerValue];
    
    NSString *subtitleText = nil;
    
    if(basicCoupondayType == 1)
    {
        subtitleText = @"상시";
    }
    else if(basicCoupondayType == 2)
    {
        subtitleText = @"연중";
    }
    else
    {
        subtitleText = [NSString stringWithFormat:@"%@ ~ %@",[info objectForKey:@"basicCouponday1"],[info objectForKey:@"basicCouponday2"]];
    }
    
    _discountDayLabel.text = subtitleText;
}

#pragma mark - 사용하기 버튼

- (IBAction)pressedCouponUseBtn:(id)sender
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"알림"
                                                                   message:@"선택한 쿠폰을 사용합니다.\n사용한 쿠폰은 취소가 불가능 합니다.사용 하시겠습니까?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"취소"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    
    UIAlertAction* useAction = [UIAlertAction actionWithTitle:@"사용하기"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction * action)
                                {
                                    NSString *uuid = [UTILITY UUID];
                                    NSString *basicSid = [_couponInfoData objectForKey:@"basicSid"];
                                    
                                    NSString *url =
                                    [NSString stringWithFormat:@"%@/user/smartbeacon/push/couponDel.geoje?uuid=%@&couponCd=%@",BASE_URL,uuid,basicSid];
                                    
//                                    NSLog(@"쿠폰 사용하기 url : %@",url);
                                    TheConnection *connection = [[TheConnection alloc] init];
                                    [connection startConnectionWithUrl:url
                                                              delegate:self
                                                             queueName:nil];
                                    
                                }];
    [alert addAction:useAction];
    [UTILITY.rootViewControllerPtr presentViewController:alert animated:YES completion:nil];
}

#pragma mark - TheConnection Delegate

-(void)theConnection:(TheConnection*)connection didFinishConnectionWithResult:(id)result error:(NSError*)error
{
    if(error == nil)
    {
//        NSLog(@"쿠폰 사용하기 결과 : %@",result);
        
        if([self.delegate respondsToSelector:@selector(couponCollectionCell:didFinishCouponUseWithResult:couponDataInfo:)])
            [self.delegate couponCollectionCell:self didFinishCouponUseWithResult:result couponDataInfo:_couponInfoData];
    }
    else
    {
        [UTILITY makeAlertWithTitle:@"알림"
                            message:@"쿠폰을 사용할 수 없습니다.인터넷에 연결되어 있지 않거나 일시적인 서버 장애입니다.잠시 후 다시 시도해 주세요."
                     viewController:UTILITY.rootViewControllerPtr];
    }
}

@end
