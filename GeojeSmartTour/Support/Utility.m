//
//  Utility.m
//  GoChangAlime
//
//  Created by min su kwon on 2017. 5. 2..
//  Copyright © 2017년 min su kwon. All rights reserved.
//

#import "Utility.h"
#import "KeychainItemWrapper.h"
#import <UIView+Toast.h>

@interface Utility ()
{
    NSMutableArray *toastQueueArr;
}

@property (nonatomic, strong) NSString *uuid;

@end

@implementation Utility

+(Utility*_Nonnull)sharedObject;
{
    static Utility *sharedSingletonInstance = nil;
    
    @synchronized (self)
    {
        if(sharedSingletonInstance == nil)
            sharedSingletonInstance = [[Utility alloc] initPrivate];
    }
    
    return sharedSingletonInstance;
}

-(id)init
{
    @throw [NSException exceptionWithName:@"직접 호출이 금지되어 있음.\nsharedSingletonInstance를 호출하시오."
                                   reason:@"" userInfo:nil];
}

-(id)initPrivate
{
    if(self = [super init])
    {
        NSLog(@"initPrivate");
        _beaconProcessQueue = dispatch_queue_create("beaconQueue", DISPATCH_QUEUE_SERIAL);
        _objectSaveDictionary = [[NSMutableDictionary alloc] init];
        toastQueueArr = [[NSMutableArray alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:)
                                                     name:UIKeyboardWillHideNotification object:nil];
    }
    
    return self;
}

-(void)setRootViewcontrollerPtr:(ViewController*)ptr
{
    if([ptr isKindOfClass:[ViewController class]])
        _rootViewControllerPtr = ptr;    
//    NSLog(@"_rootViewControllerPtr : %@",_rootViewControllerPtr);
}

-(void)setLocationManagerPtr:(CLLocationManager*_Nonnull)ptr
{
    if([ptr isKindOfClass:[CLLocationManager class]])
        _locationManager = ptr;
}

//============================================================

//화면크기 타입 리턴...
-(ScreenType)screenType
{
    ScreenType type = ScreenType_Unknown;
    
    CGFloat screenHeight = [UIScreen mainScreen].nativeBounds.size.height;
    
    if(screenHeight == 960)
        type = ScreenType_3_5;
    else if(screenHeight == 1136)
        type = ScreenType_4_0;
    else if(screenHeight == 1334)
        type = ScreenType_4_7;
//    else if(screenHeight == 2208)
//        type = ScreenType_5_5;
    else
        type = ScreenType_5_5;
    
    return type;
}

// ================ animations ===========================//

-(void)setAlphaAnimationWithView:(UIView*_Nonnull)view alpha:(CGFloat)alpha completion:(void (^ __nullable)(BOOL finished))completion
{
    [UIView animateWithDuration:0.3f animations:^{
        
        [view setAlpha:alpha];
        
    } completion:completion];
}

-(void)setMoveAnimationWithView:(UIView*_Nonnull)view newFrame:(CGRect)frame completion:(void (^ __nullable)(BOOL finished))completion
{
    [UIView animateWithDuration:0.3f
                          delay:0.f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
         view.frame = frame;
     }
     completion:completion];
}

// ================= data ================================//
- (NSString* _Nonnull)UUID
{
    if([_uuid length] > 0 && _uuid != nil)  return _uuid;
    
    // initialize keychaing item for saving UUID.
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:@"UUID"
                                                                       accessGroup:nil];
    
    self.uuid = [wrapper objectForKey:(__bridge id)(kSecAttrAccount)];
    
    if(_uuid == nil || _uuid.length == 0)
    {
        // if there is not UUID in keychain, make UUID and save it.
        CFUUIDRef uuidRef = CFUUIDCreate(NULL);
        CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
        CFRelease(uuidRef);
        self.uuid = [NSString stringWithString:(__bridge NSString *) uuidStringRef];
        CFRelease(uuidStringRef);
        
        // save UUID in keychain
        [wrapper setObject:_uuid forKey:(__bridge id)(kSecAttrAccount)];
    }
    
    return _uuid;
}

-(NSString* _Nullable)textInKeyChainWithIdentifier:(NSString* _Nonnull)identifier
{
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:identifier
                                                                       accessGroup:nil];
    
    return [wrapper objectForKey:(__bridge id)(kSecValueData)];
}

-(void)saveTextInKeyChainWithIdentifier:(NSString* _Nonnull)identifier saveText:(NSString* _Nonnull)text
{
    KeychainItemWrapper *wrapper = [[KeychainItemWrapper alloc] initWithIdentifier:identifier
                                                                       accessGroup:nil];
    [wrapper setObject:identifier forKey:(id)kSecAttrAccount];
    [wrapper setObject:text forKey:(id)kSecValueData];
}

//========================= Alert ==========================//

-(void)makeAlertWithTitle:(NSString* _Nonnull)title message:(NSString* _Nonnull)msg viewController:(UIViewController* _Nonnull)vc
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:msg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"확인"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [vc presentViewController:alert animated:YES completion:nil];
}

//======================= Date ==============================//

-(NSString*_Nonnull)currentDateWithDateFormat:(NSString*_Nullable)dateFormat
{
    NSString *defaultDateFormat = @"yyyy-MM-dd HH:mm:ss";
    
    if(dateFormat != nil && dateFormat.length > 0)
        defaultDateFormat = dateFormat;
    
    NSDate *currentDateTime = [NSDate date];
    NSDateFormatter * dateFormatter = [NSDateFormatter new];
    dateFormatter.locale    = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.dateFormat = defaultDateFormat;
    dateFormatter.timeZone  = [NSTimeZone timeZoneForSecondsFromGMT:60*60*9];
    return [dateFormatter stringFromDate:currentDateTime];
}

//==================== Toast 메시지 뷰 ==========================================

-(void)showToastWithText:(NSString*_Nullable)text duration:(CGFloat)duration
{
    BOOL isContainsObject = [toastQueueArr containsObject:text];
    //똑같은 메시지가 여러번 반복되는걸 방지한다.
    if(isContainsObject == NO)
    {
        [toastQueueArr addObject:text];
        
        //토스트 위치 설정
        id toastPosition = (NSString*)CSToastPositionBottom;
        if(self.keyBoardVisible == YES)
            toastPosition = [NSValue valueWithCGPoint:CGPointMake([APP_DEL window].center.x, 100)];
        
        CSToastStyle *style = [[CSToastStyle alloc] initWithDefaultStyle];
        style.backgroundColor = [UIColor colorWithRed:0.192f green:0.416f blue:0.722f alpha:1.f];
        style.displayShadow = YES;
        style.shadowOpacity = 0.8f;
        
        [[APP_DEL window] makeToast:text
                           duration:duration
                           position:toastPosition
                              title:nil
                              image:nil
                              style:style
                         completion:^(BOOL didTap)
         {
             [toastQueueArr removeObject:text];
         }];
        
    }
}

#pragma mark - keyboard

- (void)keyboardWillShow:(NSNotification*)aNotification
{
    _keyBoardVisible = YES;
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    _keyBoardVisible = NO;
}


@end
