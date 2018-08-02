//
//  StampCollectionViewCell.h
//  GeojeSmartTour
//
//  Created by min su kwon on 2017. 12. 18..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StampCollectionViewCell : UICollectionViewCell

-(void)setStampWithInfo:(NSDictionary*)stampInfo cateCd:(NSString*)cateCd dataIndex:(NSInteger)datIndex;

@end
