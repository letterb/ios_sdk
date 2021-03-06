//
//  ATBaiduNativeAdapter.m
//  AnyThinkBaiduNativeAdapter
//
//  Created by Martin Lau on 2019/7/23.
//  Copyright © 2019 Martin Lau. All rights reserved.
//

#import "ATBaiduNativeAdapter.h"
#import "ATBaiduNativeCustomEvent.h"
#import "ATRewardedVideoManager.h"
#import "ATAPI+Internal.h"
#import <objc/runtime.h>
#import "ATAdManager+RewardedVideo.h"
#import "Utilities.h"
#import "ATAdManager+Internal.h"
#import "ATAdAdapter.h"
#import "NSObject+ExtraInfo.h"
#import "ATAdCustomEvent.h"
#import "ATBaiduNativeRenderer.h"

@interface ATBaiduNativeAdapter()
@property(nonatomic, readonly) ATBaiduNativeCustomEvent *customEvent;
@property(nonatomic, readonly) id<ATBaiduMobAdNative> naitve;
@end
@implementation ATBaiduNativeAdapter
+(Class) rendererClass {
    return [ATBaiduNativeRenderer class];
}

-(instancetype) initWithNetworkCustomInfo:(NSDictionary*)serverInfo localInfo:(NSDictionary*)localInfo {
    self = [super init];
    if (self != nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [[ATAPI sharedInstance] setVersion:@"" forNetwork:kNetworkNameBaidu];
            if (![[ATAPI sharedInstance] initFlagForNetwork:kNetworkNameBaidu]) {
                [[ATAPI sharedInstance] setInitFlagForNetwork:kNetworkNameBaidu];
                id<BaiduMobAdSetting> setting = [NSClassFromString(@"BaiduMobAdSetting") sharedInstance];
                setting.supportHttps = YES;
                [NSClassFromString(@"BaiduMobAdSetting") setMaxVideoCacheCapacityMb:30];
            }
        });
    }
    return self;
}

-(void) loadADWithInfo:(NSDictionary*)serverInfo localInfo:(NSDictionary*)localInfo completion:(void (^)(NSArray<NSDictionary *> *, NSError *))completion {
    if (NSClassFromString(@"BaiduMobAdNative") != nil && NSClassFromString(@"BaiduMobAdNativeAdView") != nil) {
        _customEvent = [[ATBaiduNativeCustomEvent alloc] init];
        _customEvent.unitID = serverInfo[@"placement_id"];
        _customEvent.requestCompletionBlock = completion;
        NSDictionary *extraInfo = localInfo;
        _customEvent.requestExtra = extraInfo;
        
        [NSClassFromString(@"BaiduMobAdNativeAdView") dealTapGesture:YES];
        _naitve = [[NSClassFromString(@"BaiduMobAdNative") alloc] init];
        _naitve.delegate = _customEvent;
        _customEvent.baiduNative = _naitve;
        _naitve.publisherId = serverInfo[@"app_id"];
        _naitve.adId = serverInfo[@"ad_place_id"];
        [_naitve requestNativeAds];
    } else {
        completion(nil, [NSError errorWithDomain:ATADLoadingErrorDomain code:ATADLoadingErrorCodeThirdPartySDKNotImportedProperly userInfo:@{NSLocalizedDescriptionKey:kATSDKFailedToLoadNativeADMsg, NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:kSDKImportIssueErrorReason, @"Baidu"]}]);
    }
}
@end
