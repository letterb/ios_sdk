//
//  ATTTRewardedVideoAdapter.m
//  AnyThinkTTRewardedVideoAdapter
//
//  Created by Martin Lau on 14/08/2018.
//  Copyright © 2018 Martin Lau. All rights reserved.
//

#import "ATTTRewardedVideoAdapter.h"
#import "ATTTRewardedVideoCustomEvent.h"
#import "ATRewardedVideoManager.h"
#import "ATAPI+Internal.h"
#import "ATAdManager+RewardedVideo.h"
#import "Utilities.h"
#import "ATAdManager+Internal.h"
#import "ATAdAdapter.h"
static NSString *const kSlotIDKey = @"slot_id";
@interface ATTTRewardedVideoAdapter()
@property(nonatomic, readonly) ATTTRewardedVideoCustomEvent *customEvent;
@property(nonatomic, readonly) id<ATBURewardedVideoAd> rvAd;
@property(nonatomic, readonly) id<ATBUNativeExpressRewardedVideoAd> expressRvAd;
@end
@implementation ATTTRewardedVideoAdapter
//+(id<ATAd>) placeholderAdWithPlacementModel:(ATPlacementModel*)placementModel requestID:(NSString*)requestID unitGroup:(ATUnitGroupModel*)unitGroup finalWaterfall:(ATWaterfall *)finalWaterfall {
//    NSLog(@"tt placeholderAdWithPlacementModel");
//    return [[ATRewardedVideo alloc] initWithPriority:0 placementModel:placementModel requestID:requestID assets:@{kRewardedVideoAssetsUnitIDKey:unitGroup.content[kSlotIDKey]} unitGroup:unitGroup finalWaterfall:finalWaterfall];
//}

+(BOOL) adReadyWithCustomObject:(id)customObject info:(NSDictionary*)info {
    return ((id<ATBURewardedVideoAd>)customObject).adValid || ((id<ATBUNativeExpressRewardedVideoAd>)customObject).adValid;
}

+(void) showRewardedVideo:(ATRewardedVideo*)rewardedVideo inViewController:(UIViewController*)viewController delegate:(id<ATRewardedVideoDelegate>)delegate {
    ATTTRewardedVideoCustomEvent *customEvent = (ATTTRewardedVideoCustomEvent*)rewardedVideo.customEvent;
    customEvent.delegate = delegate;
    if ([rewardedVideo.customObject isKindOfClass:NSClassFromString(@"BUNativeExpressRewardedVideoAd")]) {
        [((id<ATBUNativeExpressRewardedVideoAd>)rewardedVideo.customObject) showAdFromRootViewController:viewController];
    } else {
        [((id<ATBURewardedVideoAd>)rewardedVideo.customObject) showAdFromRootViewController:viewController];
    }
}

-(instancetype) initWithNetworkCustomInfo:(NSDictionary*)serverInfo localInfo:(NSDictionary*)localInfo {
    self = [super init];
    if (self != nil) {
        if (![[ATAPI sharedInstance] initFlagForNetwork:kNetworkNameTT]) {
            [[ATAPI sharedInstance] setInitFlagForNetwork:kNetworkNameTT];
            [[ATAPI sharedInstance] setVersion:[NSClassFromString(@"BUAdSDKManager") SDKVersion] forNetwork:kNetworkNameTT];
            [NSClassFromString(@"BUAdSDKManager") setAppID:serverInfo[@"app_id"]];
        }
    }
    return self;
}

-(void) loadADWithInfo:(NSDictionary*)serverInfo localInfo:(NSDictionary*)localInfo completion:(void (^)(NSArray<NSDictionary *> *, NSError *))completion {
    if (NSClassFromString(@"BURewardedVideoModel") != nil && NSClassFromString(@"BURewardedVideoAd") != nil) {
        _customEvent = [[ATTTRewardedVideoCustomEvent alloc] initWithInfo:serverInfo localInfo:localInfo];
        _customEvent.requestCompletionBlock = completion;
        _customEvent.customEventMetaDataDidLoadedBlock = self.metaDataDidLoadedBlock;
        id<ATBURewardedVideoModel> model = [[NSClassFromString(@"BURewardedVideoModel") alloc] init];
        NSDictionary *extra = localInfo;
        if (extra[kATAdLoadingExtraUserIDKey] != nil) { model.userId = extra[kATAdLoadingExtraUserIDKey]; }
        if (extra[kATAdLoadingExtraMediaExtraKey] != nil) { model.extra = extra[kATAdLoadingExtraMediaExtraKey]; }
        if ([serverInfo[@"personalized_template"]integerValue] == 1) {
            _expressRvAd = [[NSClassFromString(@"BUNativeExpressRewardedVideoAd") alloc] initWithSlotID:serverInfo[kSlotIDKey] rewardedVideoModel:model];
            _expressRvAd.rewardedVideoModel = model;
            _expressRvAd.delegate = _customEvent;
            [_expressRvAd loadAdData];
        } else {
            _rvAd = [[NSClassFromString(@"BURewardedVideoAd") alloc] initWithSlotID:serverInfo[kSlotIDKey] rewardedVideoModel:model];
            _rvAd.delegate = _customEvent;
            [_rvAd loadAdData];
        }
        //todo isPersonalizedtemplates = YES


    } else {
        completion(nil, [NSError errorWithDomain:ATADLoadingErrorDomain code:ATADLoadingErrorCodeThirdPartySDKNotImportedProperly userInfo:@{NSLocalizedDescriptionKey:kATSDKFailedToLoadRewardedVideoADMsg, NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:kSDKImportIssueErrorReason, @"TT"]}]);
    }
}
@end
