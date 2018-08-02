//
//  GuideView.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2018. 1. 18..
//  Copyright © 2018년 min su kwon. All rights reserved.
//

#import "GuideView.h"

@interface GuideView () <UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UIView *mainXibView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;

@end

@implementation GuideView

-(id)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
    {
        [[NSBundle mainBundle] loadNibNamed:@"GuideView" owner:self options:nil];
        _mainXibView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        [self addSubview:_mainXibView];
        
        _pageControl.alpha = 0.7f;
        
        for(int i = 0; i < 8; i ++)
        {
            UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(i * frame.size.width, 0, frame.size.width, frame.size.height)];
            [_scrollView addSubview:imgView];
            
            NSString *imgName = [NSString stringWithFormat:@"guide%ld_%d",[UTILITY screenType],i + 1];
            imgView.image = [UIImage imageNamed:imgName];
        }
        
        [_scrollView setContentSize:CGSizeMake(frame.size.width * 8, 0)];
    }
    
    return self;
}

-(void)setPage:(NSInteger)page animation:(BOOL)animation
{
    CGFloat xPos = (page - 1) * self.frame.size.width;
//    CGFloat xPos = self.frame.size.width;
    [_scrollView setContentOffset:CGPointMake(xPos, 0) animated:animation];
    
    //페이지 설정...
    int pageNum = (xPos / self.frame.size.width);
    [_pageControl setCurrentPage:pageNum];
}

#pragma mark -

- (IBAction)pressedCloseBtn:(id)sender
{
    self.hidden = YES;
}

#pragma mark - UIScrollView delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat scrolledxPos = scrollView.contentOffset.x;
    
    int pageNum = (scrolledxPos / self.frame.size.width);
    [_pageControl setCurrentPage:pageNum];
}

@end
