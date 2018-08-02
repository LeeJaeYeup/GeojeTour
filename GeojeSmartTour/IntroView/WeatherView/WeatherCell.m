//
//  WeatherCell.m
//  UiryeongBeacon
//
//  Created by min su kwon on 2016. 10. 14..
//  Copyright © 2016년 SKOINFO. All rights reserved.
//

#import "WeatherCell.h"
#import "SubCell.h"

@implementation WeatherCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
    [_tableView registerNib:[UINib nibWithNibName:@"SubCell" bundle:nil]
     forCellReuseIdentifier:@"SubCell"];
    [_tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    _backRoundView.layer.cornerRadius = 5.f;
    _backRoundView.layer.borderColor = [UIColor whiteColor].CGColor;
    _backRoundView.layer.borderWidth = 1.f;

    _tableView.delegate = self;
    _tableView.dataSource = self;
}

#pragma mark - UITableView Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return _rowHeight;
}

#pragma mark - UITableView dataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_weatherArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SubCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SubCell"
                                                    forIndexPath:indexPath];
    cell.layer.cornerRadius = 10.f;
        
    [cell setInfo:[_weatherArray objectAtIndex:indexPath.row]];
    
    //마지막 셀이면 언더라인 감추기
    cell.underLineView.hidden = indexPath.row == [_weatherArray count] - 1;
    
    return cell;
}

@end
