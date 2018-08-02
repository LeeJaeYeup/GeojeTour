//
//  ContentsListView.m
//  GeojeSmartTour
//
//  Created by min su kwon on 2018. 1. 9..
//  Copyright © 2018년 min su kwon. All rights reserved.
//

#import "ContentsListView.h"
#import "ContentsListViewCell.h"

@interface ContentsListView () <UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic) IBOutlet UIView *xibMainView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *currentListArray;
@property (weak, nonatomic) IBOutlet UIImageView *topImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@end

@implementation ContentsListView

-(id)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
    {
        [[NSBundle mainBundle] loadNibNamed:@"ContentsListView" owner:self options:nil];
        [_xibMainView setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [self addSubview:_xibMainView];
    }
    
    return self;
}

#pragma mark - public

-(void)setContentsWithGroupSid:(int)groupSid contentsImg:(UIImage*)img imgPath:(NSString*)path title:(NSString*)title
{
    _titleLabel.text = title;
    _topImageView.image = img;
    
    if(img == nil && [path length] > 1)
    {
        path = [path stringByReplacingOccurrencesOfString:@"/data/web/RFC3" withString:@""];
        NSString *imgPath = [NSString stringWithFormat:@"%@%@",BASE_URL,path];
        
//        NSLog(@"선택한 그룹 imgPath : %@",imgPath);
        
        ContentsListView* __weak weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *image = [UIImage imageWithData: [NSData dataWithContentsOfURL:
                                                      [NSURL  URLWithString:imgPath]]];
            dispatch_sync(dispatch_get_main_queue(),^ {
                //run in main thread
                [weakSelf handleDelayedImage:image];
            });
        });
    }
    
    //넘겨받은 groupSid를 가지고 모든비콘 db에서 groupSid가 같은 비콘들을 가져온다..
    self.currentListArray = [[[UTILITY.rootViewControllerPtr beaconDataManager] dbInterface]
                             selectWithColumns:@[@"beaconFullPathLink", @"beaconTitle", @"smartcontentimg"]
                             WithTableName:kTableNameAllBeacon
                             where:[NSString stringWithFormat:@"where groupSid = '%d'",groupSid]
                             distinct:YES];
    
//    NSLog(@"선택된 그룹에서 보여줄 컨텐츠 정보 : %@",_currentListArray);
    
    if(_currentListArray.count > 0)
        [_tableView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_currentListArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const cellReuseKey = @"cellKey";
    
    ContentsListViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseKey];
    
    if(cell == nil)
    {
        [tableView registerNib:[UINib nibWithNibName:@"ContentsListViewCell"
                                              bundle:nil]
        forCellReuseIdentifier:cellReuseKey];
        cell = [tableView dequeueReusableCellWithIdentifier:cellReuseKey];
    }
    
    [cell setContentsInfo:[_currentListArray objectAtIndex:indexPath.row]];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *contentsUrl = [UTILITY.rootViewControllerPtr beaconContentsUrlWithFullPathLink:[[_currentListArray objectAtIndex:indexPath.row] objectForKey:@"beaconFullPathLink"]];
    
    [UTILITY.rootViewControllerPtr showWebViewWithUrl:contentsUrl];
}

#pragma mark -

-(void)handleDelayedImage:(UIImage*)image
{
    _topImageView.image = image;
}

@end
