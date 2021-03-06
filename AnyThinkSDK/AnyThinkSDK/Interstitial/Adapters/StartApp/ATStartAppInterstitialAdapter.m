//
//  ATStartAppInterstitialAdapter.m
//  AnyThinkStartAppInterstitialAdapter
//
//  Created by Martin Lau on 2020/3/19.
//  Copyright © 2020 AnyThink. All rights reserved.
//

#import "ATStartAppInterstitialAdapter.h"
#import "ATStartAppInterstitialCustomEvent.h"
#import "ATAPI+Internal.h"
#import "Utilities.h"
#import "ATInterstitialManager.h"
#import "ATAdAdapter.h"
#import "ATAppSettingManager.h"
@interface ATStartAppInterstitialAdapter()
@property(nonatomic, readonly) id<ATSTAStartAppAd> interstitialAd;
@property(nonatomic, readonly) ATStartAppInterstitialCustomEvent *customEvent;
@end

@implementation ATStartAppInterstitialAdapter
+(BOOL) adReadyWithCustomObject:(id<ATSTAStartAppAd>)customObject info:(NSDictionary*)info {
    return [customObject isReady];
}

+(void) showInterstitial:(ATInterstitial*)interstitial inViewController:(UIViewController*)viewController delegate:(id<ATInterstitialDelegate>)delegate {
    interstitial.customEvent.delegate = delegate;
    [((id<ATSTAStartAppAd>)interstitial.customObject) showAdWithAdTag:interstitial.unitGroup.content[@"ad_tag"]];
}

-(instancetype) initWithNetworkCustomInfo:(NSDictionary*)serverInfo localInfo:(NSDictionary*)localInfo {
    self = [super init];
    if (self != nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            if (![[ATAPI sharedInstance] initFlagForNetwork:kNetworkNameStartApp]) {
                [[ATAPI sharedInstance] setInitFlagForNetwork:kNetworkNameStartApp];
                dispatch_async(dispatch_get_main_queue(), ^{
                    id<ATSTAStartAppSDK> sdk = [NSClassFromString(@"STAStartAppSDK") sharedInstance];
                    BOOL set = NO;
                    ATUnitGroupModel *unitGroupModel =(ATUnitGroupModel*)serverInfo[kAdapterCustomInfoUnitGroupModelKey];
                    BOOL limit = [[ATAppSettingManager sharedManager] limitThirdPartySDKDataCollection:&set networkFirmID:unitGroupModel.networkFirmID];
                    if (set) { [sdk setUserConsent:!limit forConsentType:@"pas" withTimestamp:[[NSDate date] timeIntervalSince1970]]; }
                    sdk.appID = serverInfo[@"app_id"];
                });
            }
        });
    }
    return self;
}

-(void) loadADWithInfo:(NSDictionary*)serverInfo localInfo:(NSDictionary*)localInfo completion:(void (^)(NSArray<NSDictionary *> *, NSError *))completion {
    if (NSClassFromString(@"STAStartAppAd") != nil) {
        _customEvent = [[ATStartAppInterstitialCustomEvent alloc] initWithInfo:serverInfo localInfo:localInfo];
        _customEvent.requestCompletionBlock = completion;
        dispatch_async(dispatch_get_main_queue(), ^{
            id<ATSTAAdPreferences> pre = [NSClassFromString(@"STAAdPreferences") preferencesWithMinCPM:0];
            pre.adTag = serverInfo[@"ad_tag"];
            
            self->_interstitialAd = [[NSClassFromString(@"STAStartAppAd") alloc] init];
            if ([serverInfo[@"is_video"] boolValue]) {
                [self->_interstitialAd loadVideoAdWithDelegate:self->_customEvent withAdPreferences:pre];
            } else {
                [self->_interstitialAd loadAdWithDelegate:self->_customEvent withAdPreferences:pre];
            }
        });
    } else {
        completion(nil, [NSError errorWithDomain:ATADLoadingErrorDomain code:ATADLoadingErrorCodeThirdPartySDKNotImportedProperly userInfo:@{NSLocalizedDescriptionKey:kATSDKFailedToLoadInterstitialADMsg, NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:kSDKImportIssueErrorReason, @"StartApp"]}]);
    }
    
}
@end
