//
//  ATBaiduSplashCustomEvent.h
//  AnyThinkBaiduSplashAdapter
//
//  Created by Martin Lau on 2018/12/21.
//  Copyright © 2018 Martin Lau. All rights reserved.
//

#import "ATSplashCustomEvent.h"
#import "ATBaiduSplashAdapter.h"

@interface ATBaiduSplashCustomEvent : ATSplashCustomEvent<BaiduMobAdSplashDelegate>
-(instancetype)initWithPublisherID:(NSString*)publisherID unitID:(NSString *)unitID customInfo:(NSDictionary *)customInfo;
@property(nonatomic) UIWindow *window;
@property(nonatomic) UIView *containerView;
@end