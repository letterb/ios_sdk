//
//  ATAdCustomEvent.m
//  AnyThinkSDK
//
//  Created by Martin Lau on 05/07/2018.
//  Copyright © 2018 Martin Lau. All rights reserved.
//

#import "ATAdCustomEvent.h"
#import "ATAPI+Internal.h"
#import "ATThreadSafeAccessor.h"
#import "Utilities.h"
#import "ATGeneralAdAgentEvent.h"
#import "ATAgentEvent.h"
#import "ATCapsManager.h"
#import "ATAdAdapter.h"
#import "ATLoadingScheduler.h"
#import "ATPlacementSettingManager.h"
#import "ATAdLoader.h"
#import "ATAdManager+Internal.h"
#import "ATWaterfallManager.h"

NSString *const kATSDKFailedToLoadSplashADMsg = @"AnythinkSDK has failed to load splash ad.";
NSString *const kATSDKFailedToLoadBannerADMsg = @"AnythinkSDK has failed to load banner ad.";
NSString *const kATSDKFailedToLoadInterstitialADMsg = @"AnythinkSDK has failed to load interstitial ad.";
NSString *const kATSDKFailedToLoadNativeADMsg = @"AnythinkSDK has failed to load native ad.";
NSString *const kATSDKFailedToLoadRewardedVideoADMsg = @"AnythinkSDK has failed to load rewarded video ad.";
NSString *const kATSDKSplashADTooLongToLoadPlacementSettingMsg = @"It took too long to load placement setting.";
NSString *const kSDKImportIssueErrorReason = @"This might be due to %@ SDK not being imported or it's imported but a unsupported version is being used.";
NSString *const kSDKImportIssueRecoverySuggestionKey = @"Make sure %@ are correctly imported.";
NSString *const kATAdAssetsAppIDKey = @"app_id";
@interface ATAdCustomEvent()
@property(nonatomic, readonly) ATThreadSafeAccessor *assetsAccessor;
@property(nonatomic, readonly) NSMutableArray<NSDictionary*>* assets_impl;

@property(nonatomic, readonly) ATThreadSafeAccessor *numberOfFinishedRequestsAccessor;
@property(nonatomic, readonly) NSInteger numberOfFinishedRequests_impl;
@end
@implementation ATAdCustomEvent
+(NSDictionary*)customInfoWithUnitGroupModel:(ATUnitGroupModel*)unitGroupModel extra:(NSDictionary*)extra {
    NSMutableDictionary *info = [NSMutableDictionary dictionaryWithDictionary:unitGroupModel.content];
    info[kAdLoadingExtraFilledByReadyFlagKey] = @YES;
    return info;
}

-(instancetype) initWithUnitID:(NSString*)unitID serverInfo:(NSDictionary*)serverInfo localInfo:(NSDictionary*)localInfo {
    self = [super init];
    if (self != nil) {
        _assetsAccessor = [ATThreadSafeAccessor new];
        _assets_impl = [NSMutableArray<NSDictionary*> array];
        _numberOfFinishedRequestsAccessor = [ATThreadSafeAccessor new];
        
        _serverInfo = serverInfo;
        _localInfo = localInfo;
    }
    return self;
}

-(NSMutableArray<NSDictionary*>*) assets {
    return [_assetsAccessor readWithBlock:^id{ return _assets_impl; }];
}

-(void) setRequestNumber:(NSInteger)requestNumber {
    _requestNumber = requestNumber;
    self.numberOfFinishedRequests = 0;
}

-(NSInteger) numberOfFinishedRequests {
    return [[_numberOfFinishedRequestsAccessor readWithBlock:^id{ return @(_numberOfFinishedRequests_impl); }] integerValue];
}

-(void) setNumberOfFinishedRequests:(NSInteger)numberOfFinishedRequests {
    [_numberOfFinishedRequestsAccessor writeWithBlock:^{ _numberOfFinishedRequests_impl = numberOfFinishedRequests; }];
}

+(NSInteger) calculateAdPriority:(id<ATAd>)ad {
    NSArray<ATUnitGroupModel*>* ugs = ad.finalWaterfall.unitGroups;
    __block NSInteger priority = NSNotFound;
    if (ugs != nil && ad != nil) {
           [ugs enumerateObjectsUsingBlock:^(ATUnitGroupModel * _Nonnull unitGroup, NSUInteger idx, BOOL * _Nonnull stop) {
               if ([unitGroup.unitID isEqualToString:ad.unitGroup.unitID]) {
                   *stop = YES;
                   priority = idx;
               }
           }];
       }
    return priority;
}

-(ATNativeADSourceType) adSourceType {
    return ATNativeADSourceTypeUnknown;
}

-(void) trackShow {
    if (self.ad != nil) {
        self.sdkTime = [Utilities normalizedTimeStamp];
        [[ATLoadingScheduler sharedScheduler] cancelScheduleLoadingWithPlacementModel:self.ad.placementModel unitGroup:self.ad.unitGroup requestID:self.ad.requestID];
        [ATLogger logMessage:[NSString stringWithFormat:@"\nImpression with ad info:\n*****************************\n%@ \n*****************************", [ATGeneralAdAgentEvent logInfoWithAd:self.ad event:ATGeneralAdAgentEventTypeImpression extra:self.localInfo error:nil]] type:ATLogTypeTemporary];
        [[ATCapsManager sharedManager] increaseCapWithPlacementID:self.ad.placementModel.placementID unitGroupID:self.ad.unitGroup.unitGroupID requestID:self.ad.requestID];
        [[ATCapsManager sharedManager] setLastShowTimeWithPlacementID:self.ad.placementModel.placementID unitGroupID:self.ad.unitGroup.unitGroupID];
        
        NSDictionary *loadExtra = [self.localInfo isKindOfClass:[NSDictionary class]] ? self.localInfo : nil;
        NSMutableDictionary *trackingExtra = [NSMutableDictionary dictionaryWithObjectsAndKeys:@([loadExtra[kAdLoadingExtraRefreshFlagKey] boolValue]), kATTrackerExtraRefreshFlagKey, @([loadExtra[kAdLoadingExtraAutoloadFlagKey] boolValue]), kATTrackerExtraAutoloadFlagKey, @([loadExtra[kAdLoadingExtraDefaultLoadKey] boolValue]), kATTrackerExtraDefaultLoadFlagKey, [ATTracker headerBiddingTrackingExtraWithAd:self.ad requestID:self.ad.requestID], kATTrackerExtraHeaderBiddingInfoKey, self.ad.unitGroup.unitID, kATTrackerExtraUnitIDKey, @(self.ad.unitGroup.networkFirmID), kATTrackerExtraNetworkFirmIDKey, @(self.ad.renewed), kATTrackerExtraOfferLoadedByAdSourceStatusFlagKey, self.sdkTime,kATTrackerExtraAdShowSDKTimeKey,nil];
        if (self.ad.autoReqType == 5) { trackingExtra[kATTrackerExtraRequestExpectedOfferNumberFlagKey] = @YES; }
        [[ATTracker sharedTracker] trackWithPlacementID:self.ad.placementModel.placementID requestID:self.ad.requestID trackType:ATNativeADTrackTypeADShow extra:trackingExtra];
    }
}

-(void) trackClick {
    [ATLogger logMessage:[NSString stringWithFormat:@"\nClick with ad info:\n*****************************\n%@ \n*****************************", [ATGeneralAdAgentEvent logInfoWithAd:self.ad event:ATGeneralAdAgentEventTypeClick extra:self.localInfo error:nil]] type:ATLogTypeTemporary];
    NSDictionary *loadExtra = [self.localInfo isKindOfClass:[NSDictionary class]] ? self.localInfo : nil;
    NSMutableDictionary *trackingExtra = [NSMutableDictionary dictionaryWithObjectsAndKeys:@([loadExtra[kAdLoadingExtraRefreshFlagKey] boolValue]), kATTrackerExtraRefreshFlagKey, @([loadExtra[kAdLoadingExtraAutoloadFlagKey] boolValue]), kATTrackerExtraAutoloadFlagKey, @([loadExtra[kAdLoadingExtraDefaultLoadKey] boolValue]), kATTrackerExtraDefaultLoadFlagKey, [ATTracker headerBiddingTrackingExtraWithAd:self.ad requestID:self.ad.requestID], kATTrackerExtraHeaderBiddingInfoKey, self.ad.unitGroup.unitID, kATTrackerExtraUnitIDKey, @(self.ad.unitGroup.networkFirmID), kATTrackerExtraNetworkFirmIDKey, nil];
    if (self.ad.autoReqType == 5) { trackingExtra[kATTrackerExtraRequestExpectedOfferNumberFlagKey] = @YES; }
//    [[ATTracker sharedTracker] trackWithPlacementID:self.ad.placementModel.placementID requestID:self.ad.requestID trackType:ATNativeADTrackTypeADClicked extra:trackingExtra];
    [[ATTracker sharedTracker]trackClickWithAd:self.ad extra:trackingExtra];
}

-(void) handleAssets:(NSDictionary*)assets {
    [self.assets addObject:assets];
    self.numberOfFinishedRequests++;
    [ATLogger logMessage:[NSString stringWithFormat:@"Successfully loaded, event:%@, finishedNumber: %ld, successful loads:%ld, total: %ld", NSStringFromClass([self class]), [self.assets count], self.numberOfFinishedRequests, self.requestNumber] type:ATLogTypeInternal];
    if (self.numberOfFinishedRequests == self.requestNumber) {
        [ATLogger logMessage:@"Request number reached and will invoke callback" type:ATLogTypeInternal];
        if (self.requestCompletionBlock != nil) { self.requestCompletionBlock([NSArray arrayWithArray:self.assets], nil); }
        [self.assets removeAllObjects];
        [ATLogger logMessage:@"Remove assets after invoke the completion block" type:ATLogTypeInternal];
    }
}

-(void) handleLoadingFailure:(NSError*)error {
    self.numberOfFinishedRequests++;
    [ATLogger logMessage:[NSString stringWithFormat:@"Loading failed, event:%@, finishedNumber: %ld, successful loads:%ld, total: %ld", NSStringFromClass([self class]), [self.assets count], self.numberOfFinishedRequests, self.requestNumber] type:ATLogTypeInternal];
    if (self.numberOfFinishedRequests == self.requestNumber) {
        [ATLogger logMessage:@"Request number reached and will invoke callback" type:ATLogTypeInternal];
        if (self.requestCompletionBlock != nil) {
            self.requestCompletionBlock(self.assets, [self.assets count] > 0 ? nil : (error != nil ? error : [NSError errorWithDomain:ATADLoadingErrorDomain code:ATADLoadingErrorCodeADOfferLoadingFailed userInfo:@{NSLocalizedDescriptionKey:@"Third-party network offer loading has failed.", NSLocalizedFailureReasonErrorKey:@"Third-party SDK did not return any offer."}]));
        }
    }
}

-(void) handleClose {
    [ATLogger logMessage:[NSString stringWithFormat:@"\nClose with ad info:\n*****************************\n%@ \n*****************************", [ATGeneralAdAgentEvent logInfoWithAd:self.ad event:ATGeneralAdAgentEventTypeClose extra:nil error:nil]] type:ATLogTypeTemporary];
}

-(void) saveShowAPIContext {
    _showDate = [NSDate date];
    _psIDOnShow = [ATAPI sharedInstance].psID;
}

- (NSString *)networkUnitId {
    return @"";
}


@end
