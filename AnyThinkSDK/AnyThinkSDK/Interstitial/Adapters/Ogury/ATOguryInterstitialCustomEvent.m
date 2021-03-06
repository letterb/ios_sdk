//
//  ATOguryInterstitialCustomEvent.m
//  AnyThinkOguryInterstitialAdapter
//
//  Created by Topon on 2019/11/27.
//  Copyright © 2019 AnyThink. All rights reserved.
//

#import "ATOguryInterstitialCustomEvent.h"
#import "ATOguryInterstitialAdapter.h"
#import "Utilities.h"
#import "ATInterstitialManager.h"

@interface ATOguryInterstitialCustomEvent ()
@property (nonatomic,assign)BOOL isReload;
@end
@implementation ATOguryInterstitialCustomEvent

-(void)oguryAdsInterstitialAdAvailable {
    [ATLogger logMessage:@"OguryInterstitial::oguryAdsInterstitialAdAvailable:" type:ATLogTypeExternal];
    if (self.customEventMetaDataDidLoadedBlock != nil) { self.customEventMetaDataDidLoadedBlock(); }
}

-(void)oguryAdsInterstitialAdNotAvailable {
    NSString *desc = @"oguryAdsInterstitialAdNotAvailable";
    NSError *error = [NSError errorWithDomain:desc code:0 userInfo:nil];
    [ATLogger logError:[NSString stringWithFormat:@"OguryInterstitial::oguryAdsInterstitialAdNotAvailable:%@", error] type:ATLogTypeExternal];
//    [self handleLoadingFailure:error];
    [self trackInterstitialAdLoadFailed:error];
}

-(void)oguryAdsInterstitialAdLoaded {
    [ATLogger logMessage:@"OguryInterstitial::oguryAdsInterstitialAdLoaded:" type:ATLogTypeExternal];
//    NSMutableDictionary *assets = [NSMutableDictionary dictionaryWithDictionary:@{kInterstitialAssetsCustomEventKey:self, kAdAssetsCustomObjectKey:self.oguryAds, kInterstitialAssetsUnitIDKey:[self.unitID length] > 0 ? self.unitID : @""}];
//    [self handleAssets:assets];
    [self trackInterstitialAdLoaded:self.oguryAds adExtra:nil];
}

-(void)oguryAdsInterstitialAdNotLoaded {

}

-(void)oguryAdsInterstitialAdDisplayed {
    [ATLogger logMessage:@"OguryInterstitial::oguryAdsInterstitialAdDisplayed:" type:ATLogTypeExternal];
    [self trackInterstitialAdShow];
}

-(void)oguryAdsInterstitialAdClosed {
    [ATLogger logMessage:@"OguryInterstitial::oguryAdsInterstitialAdClosed:" type:ATLogTypeExternal];
    [self trackInterstitialAdVideoEnd];
    [self trackInterstitialAdClose];
}

-(void)oguryAdsInterstitialAdError:(ATOguryAdsErrorType)errorType {
    NSString *desc = OguryIVStatusTypeStringMap[errorType];
    NSError *error = [NSError errorWithDomain:desc code:errorType userInfo:nil];
    [ATLogger logError:[NSString stringWithFormat:@"OguryInterstitial::oguryAdsInterstitialAdError:%@", error] type:ATLogTypeExternal];

    [self trackInterstitialAdLoadFailed:error];
}

NSString *OguryIVStatusTypeStringMap[] = {
    [OguryAdsErrorLoadFailed] = @"OguryAdsErrorLoadFailed",
    [OguryAdsErrorNoInternetConnection] = @"OguryAdsErrorNoInternetConnection",
    [OguryAdsErrorAdDisable] = @"OguryAdsErrorAdDisable",
    [OguryAdsErrorProfigNotSynced] = @"OguryAdsErrorProfigNotSynced",
    [OguryAdsErrorAdExpired] = @"OguryAdsErrorAdExpired",
    [OguryAdsErrorSdkInitNotCalled] = @"OguryAdsErrorSdkInitNotCalled"
};

- (NSString *)networkUnitId {
    return self.serverInfo[@"unit_id"];
}

//-(NSDictionary*)delegateExtra {
//    NSMutableDictionary* extra = [[super delegateExtra] mutableCopy];
//    extra[kATADDelegateExtraNetworkPlacementIDKey] = self.interstitial.unitGroup.content[@"unit_id"];
//    return extra;
//}
@end
