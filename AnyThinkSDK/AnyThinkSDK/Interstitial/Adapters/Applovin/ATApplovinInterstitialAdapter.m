//
//  ATApplovinInterstitialAdapter.m
//  AnyThinkApplovinInterstitialAdapter
//
//  Created by Martin Lau on 25/09/2018.
//  Copyright © 2018 Martin Lau. All rights reserved.
//

#import "ATApplovinInterstitialAdapter.h"
#import "ATApplovinInterstitialCustomEvent.h"
#import "ATAPI+Internal.h"
#import "Utilities.h"
#import <objc/runtime.h>
#import "ATAppSettingManager.h"

@interface ATApplovinInterstitialAdapter()
@property(nonatomic, readonly) ATApplovinInterstitialCustomEvent *customEvent;
@end
@implementation ATApplovinInterstitialAdapter
+(BOOL) adReadyWithCustomObject:(id)customObject info:(NSDictionary*)info {
    return customObject != nil;
}

+(void) showInterstitial:(ATInterstitial*)interstitial inViewController:(UIViewController*)viewController delegate:(id<ATInterstitialDelegate>)delegate {
    id<ATALInterstitialAd> alInterstitial = [[NSClassFromString(@"ALInterstitialAd") alloc] initWithSdk:[NSClassFromString(@"ALSdk") sharedWithKey:interstitial.unitGroup.content[@"sdkkey"]]];
    alInterstitial.adDisplayDelegate = (ATApplovinInterstitialCustomEvent*)(interstitial.customEvent);
    alInterstitial.adVideoPlaybackDelegate = (ATApplovinInterstitialCustomEvent*)(interstitial.customEvent);
    interstitial.customEvent.delegate = delegate;
    [alInterstitial showAd:interstitial.customObject];
    //to keep alInterstitial around.
    objc_setAssociatedObject(interstitial.customEvent, "al_interstitial_ad", alInterstitial, OBJC_ASSOCIATION_RETAIN);
}

-(instancetype) initWithNetworkCustomInfo:(NSDictionary*)serverInfo localInfo:(NSDictionary*)localInfo {
    self = [super init];
    if (self != nil) {
        if (![[ATAPI sharedInstance] initFlagForNetwork:kNetworkNameApplovin]) {
            [[ATAPI sharedInstance] setVersion:@([NSClassFromString(@"ALSdk") versionCode]).stringValue forNetwork:kNetworkNameApplovin];
            [[ATAPI sharedInstance] setInitFlagForNetwork:kNetworkNameApplovin];
            if ([[ATAPI sharedInstance].networkConsentInfo containsObjectForKey:kNetworkNameApplovin]) {
                [NSClassFromString(@"ALPrivacySettings") setHasUserConsent:[[ATAPI sharedInstance].networkConsentInfo[kNetworkNameApplovin][kApplovinConscentStatusKey] boolValue]];
                [NSClassFromString(@"ALPrivacySettings") setIsAgeRestrictedUser:[[ATAPI sharedInstance].networkConsentInfo[kNetworkNameApplovin][kApplovinUnderAgeKey] boolValue]];
            } else {
                BOOL set = NO;
                ATUnitGroupModel *unitGroupModel =(ATUnitGroupModel*)serverInfo[kAdapterCustomInfoUnitGroupModelKey];
                BOOL limit = [[ATAppSettingManager sharedManager] limitThirdPartySDKDataCollection:&set networkFirmID:unitGroupModel.networkFirmID];
                if (set) {
                    /**
                    HasUserConsent: 0 Nonpersonalized, 1 Personalized
                    */
                    [NSClassFromString(@"ALPrivacySettings") setHasUserConsent:!limit];
                }
            }
        }
    }
    return self;
}

-(void) loadADWithInfo:(NSDictionary*)serverInfo localInfo:(NSDictionary*)localInfo completion:(void (^)(NSArray<NSDictionary *> *, NSError *))completion {
    if (NSClassFromString(@"ALSdk") != nil && NSClassFromString(@"ALAdService") != nil && NSClassFromString(@"ALInterstitialAd") != nil) {
        _customEvent = [[ATApplovinInterstitialCustomEvent alloc] initWithInfo:serverInfo localInfo:localInfo];
        _customEvent.requestCompletionBlock = completion;
        [((id<ATALSdk>)[NSClassFromString(@"ALSdk") sharedWithKey:serverInfo[@"sdkkey"]]).adService loadNextAdForZoneIdentifier:serverInfo[@"zone_id"] andNotify:_customEvent];
    } else {
        completion(nil, [NSError errorWithDomain:ATADLoadingErrorDomain code:ATADLoadingErrorCodeThirdPartySDKNotImportedProperly userInfo:@{NSLocalizedDescriptionKey:kATSDKFailedToLoadInterstitialADMsg, NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:kSDKImportIssueErrorReason, @"Applovin"]}]);
    }
}
@end
