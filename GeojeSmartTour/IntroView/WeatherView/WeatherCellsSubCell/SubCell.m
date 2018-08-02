//
//  SubCell.m
//  UiryeongBeacon
//
//  Created by min su kwon on 2016. 10. 17..
//  Copyright © 2016년 SKOINFO. All rights reserved.
//

#import "SubCell.h"

@implementation SubCell

-(void)prepareForReuse
{
    [super prepareForReuse];
    _skyImageView.image = nil;
}

-(void)setInfo:(NSDictionary*)info
{
//    NSLog(@"info : %@",info);
    NSString *time_HH = [[info objectForKey:@"FCST_TIME"] substringWithRange:NSMakeRange(0, 2)];
    NSString *t3h = [info objectForKey:@"T3H"];
    NSString *reh = [info objectForKey:@"REH"];
    NSString *pop = [info objectForKey:@"POP"];
    
    _timeLabel.text = time_HH;
    _TemperatureLabel.text = [NSString stringWithFormat:@"%@℃",t3h];
    _wetLabel.text = [NSString stringWithFormat:@"%@%%",reh];
    _rainLabel.text = [NSString stringWithFormat:@"%@%%",pop];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        NSString *skyCode = [info objectForKey:@"SKY"];
        NSString *skyImgName = [NSString stringWithFormat:@"sun_small_0%@",skyCode];
        UIImage * img = [UIImage imageNamed:skyImgName];
        
        // Make a trivial (1x1) graphics context, and draw the image into it
        UIGraphicsBeginImageContext(CGSizeMake(1,1));
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextDrawImage(context, CGRectMake(0, 0, 1, 1), [img CGImage]);
        UIGraphicsEndImageContext();
        
        // Now the image will have been loaded and decoded and is ready to rock for the main thread
        dispatch_sync(dispatch_get_main_queue(), ^{
            _skyImageView.image = img;
        });
    });
}

@end
