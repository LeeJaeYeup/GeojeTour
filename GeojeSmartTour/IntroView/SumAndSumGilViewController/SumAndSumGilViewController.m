//
//  SumAndSumGilViewController.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2018. 3. 23..
//  Copyright © 2018년 min su kwon. All rights reserved.
//

#import "SumAndSumGilViewController.h"
#import "SumAndSumGilTableViewCell.h"

#define kTableViewCellReuseKey      @"cellReuseKey"


@interface SumAndSumGilViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) NSArray *sumAndSumGilDataInfoArr;
@end

@implementation SumAndSumGilViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"sumAndSumGilUrl" ofType:@"plist"];
    self.sumAndSumGilDataInfoArr = [NSArray arrayWithContentsOfFile:filePath];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_scrollView setContentSize:CGSizeMake(0, 880)];
}

- (IBAction)pressedBackBtn:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableView DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _sumAndSumGilDataInfoArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SumAndSumGilTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTableViewCellReuseKey];
    
    if(cell == nil)
    {
        [tableView registerNib:[UINib nibWithNibName:@"SumAndSumGilTableViewCell"
                                              bundle:nil]
        forCellReuseIdentifier:kTableViewCellReuseKey];
        cell = [tableView dequeueReusableCellWithIdentifier:kTableViewCellReuseKey];
    }
    
    cell.thumbImageView.image =
    [UIImage imageNamed:[NSString stringWithFormat:@"sum&sumgil_item_0%ld",indexPath.row + 1]];
    
    NSDictionary *dataInfo = [_sumAndSumGilDataInfoArr objectAtIndex:indexPath.row];
    cell.titleLabel.text = [dataInfo objectForKey:@"title"];
    
    return cell;
}

#pragma mark - UITableview Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *url = [[_sumAndSumGilDataInfoArr objectAtIndex:indexPath.row] objectForKey:@"url"];
    [UTILITY.rootViewControllerPtr showWebViewWithUrl:url];
    
//    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]
//                                       options:@{}
//                             completionHandler:nil];
}

@end
