//
//  Video360ViewController.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2018. 1. 15..
//  Copyright © 2018년 min su kwon. All rights reserved.
//

#import "Video360ViewController.h"
#import "CardboardViewController.h"

@interface Video360ViewController ()

@property (nonatomic, strong) CardboardViewController *cardboardVC;

@end

@implementation Video360ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)dealloc
{
    [self removeCardboardView];
    [self removeGLKView];
}

#pragma mark - public

-(void)transformCardBoardView:(BOOL)bTransform
{
    if(bTransform)
    {
        [self removeGLKView];
        [self configureCardboardView];
    }
    else
    {
        [self removeCardboardView];
        [self configureGLKView];
    }
}

#pragma mark cardboard view

- (void)configureCardboardView
{
    _cardboardVC = [[CardboardViewController alloc] init];
    
    _cardboardVC.videoPlayerController = self;
    
    [self.view insertSubview:_cardboardVC.view belowSubview:[self getIconsBackView]];
    [self addChildViewController:_cardboardVC];
    [_cardboardVC didMoveToParentViewController:self];
    
    _cardboardVC.view.frame = self.view.bounds;
}

- (void)removeCardboardView
{
    _cardboardVC.videoPlayerController = nil;
    [_cardboardVC.view removeFromSuperview];
    [_cardboardVC removeFromParentViewController];
    _cardboardVC = nil;
}

@end

