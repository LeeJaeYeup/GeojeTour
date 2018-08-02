//
//  SelectListView.m
//
//  Created by min su kwon on 2016. 11. 1..
//  Copyright © 2016년 SKOINFO. All rights reserved.
//

#import "ComBoBoxView.h"

@interface ComBoBoxView() <UITableViewDelegate, UITableViewDataSource>
{
    UIView *backView;
}

@property (nonatomic, strong) NSArray *listArray;

@end

@implementation ComBoBoxView

-(id)initWithFrame:(CGRect)frame
{
    if(self = [super initWithFrame:frame])
    {
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = YES;
        self.alpha = 0.f;
        
        backView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [self addSubview:backView];
        backView.backgroundColor = [UIColor colorWithRed:0.353f green:0.443f blue:0.459f alpha:1.f];
        backView.alpha = 0.8f;
        
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:backView.bounds byRoundingCorners:(UIRectCornerBottomLeft | UIRectCornerBottomRight) cornerRadii:CGSizeMake(10.f, 10.f)];
        
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.frame = self.bounds;
        maskLayer.path  = maskPath.CGPath;
        self.layer.mask = maskLayer;
        
        CGSize listSize = CGSizeMake(frame.size.width, frame.size.height);
        
        selectTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, listSize.width, listSize.height)];
        selectTableView.dataSource = self;
        selectTableView.delegate = self;
        [selectTableView setSeparatorInset:UIEdgeInsetsZero];
        [self addSubview:selectTableView];
        selectTableView.backgroundColor = [UIColor clearColor];

        _rowHeight = 40.f;
    }
    
    return self;
}

-(void)show
{
    CGFloat alpha = 1.f;
    if(self.alpha == 1.f)  alpha = 0.f;
    
    [self setAlphaAnimationWithView:self
                              alpha:alpha];
}

-(void)setListItemArray:(NSArray*)array
{
    if([array count] > 0)
    {
        self.listArray = array;
        [selectTableView reloadData];
    }
}

#pragma mark - private

-(void)setAlphaAnimationWithView:(UIView*)view alpha:(CGFloat)alpha
{
    [UIView animateWithDuration:0.3f
                     animations:^{view.alpha = alpha;}
                     completion:^(BOOL finished){}];
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self setAlphaAnimationWithView:self alpha:0.f];
}

#pragma mark - UITableView dataSource & delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_listArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellReuseKey = @"selectListCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseKey];
    
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:cellReuseKey];
        cell.textLabel.font = [UIFont systemFontOfSize:15.f];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.backgroundColor = [UIColor clearColor];
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        
    }
    
    cell.textLabel.text = [_listArray objectAtIndex:indexPath.row];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return _rowHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger selectCellIndex = indexPath.row;
    
    if([self.delegate respondsToSelector:@selector(didSelectListView:index:cellTitle:)])
        [self.delegate didSelectListView:self index:selectCellIndex cellTitle:[_listArray objectAtIndex:selectCellIndex]];
    
    [self show];
}

@end
