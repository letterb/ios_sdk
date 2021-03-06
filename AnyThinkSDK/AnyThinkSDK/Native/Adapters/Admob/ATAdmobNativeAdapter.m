//
//  ATAdmobNativeAdapter.m
//  AnyThinkSDK
//
//  Created by Martin Lau on 26/04/2018.
//  Copyright © 2018 Martin Lau. All rights reserved.
//

#import "ATAdmobNativeAdapter.h"
#import "ATAdMobCustomEvent.h"
#import "ATAdMobNativeADRenderer.h"
#import "NSObject+ExtraInfo.h"
#import "ATAPI+Internal.h"
#import "Utilities.h"
#import "ATAdAdapter.h"
#import "ATAppSettingManager.h"
//NSString *const kATGADAdLoaderAdTypeUnifiedNative = @"6";
//
//NSString * const ATGADUnifiedNativeHeadlineAsset = @"3001";
//NSString * const ATGADUnifiedNativeCallToActionAsset = @"3002";
//NSString * const ATGADUnifiedNativeIconAsset = @"3003";
//NSString * const ATGADUnifiedNativeBodyAsset = @"3004";
//NSString * const ATGADUnifiedNativeAdvertiserAsset = @"3005";
//NSString * const ATGADUnifiedNativeStoreAsset = @"3006";
//NSString * const ATGADUnifiedNativePriceAsset = @"3007";
//NSString * const ATGADUnifiedNativeImageAsset = @"3008";
//NSString * const ATGADUnifiedNativeStarRatingAsset = @"3009";
//NSString * const ATGADUnifiedNativeMediaViewAsset = @"3010";
//NSString * const ATGADUnifiedNativeAdChoicesViewAsset = @"3013";
@interface ATAdmobNativeAdapter()
@property(nonatomic, readonly) id<ATGADAdLoader> loader;
@property(nonatomic, readonly) ATAdMobCustomEvent *customEvent;
@end
@implementation ATAdmobNativeAdapter
+(Class) rendererClass {
    return [ATAdMobNativeADRenderer class];
}

-(instancetype) initWithNetworkCustomInfo:(NSDictionary*)serverInfo localInfo:(NSDictionary*)localInfo {
    self = [super init];
    if (self != nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [[ATAPI sharedInstance] setVersion:[[NSClassFromString(@"GADMobileAds") sharedInstance] sdkVersion] forNetwork:kNetworkNameAdmob];
                [[NSClassFromString(@"GADMobileAds") sharedInstance] configureWithApplicationID:serverInfo[@"app_id"]];
                if (![[ATAPI sharedInstance] initFlagForNetwork:kNetworkNameAdmob]) {
                    [[ATAPI sharedInstance] setInitFlagForNetwork:kNetworkNameAdmob];
                    id<ATPACConsentInformation> consentInfo = [NSClassFromString(@"PACConsentInformation") sharedInstance];
                    if ([[ATAPI sharedInstance].networkConsentInfo containsObjectForKey:kNetworkNameAdmob]) {
                        consentInfo.consentStatus = [[ATAPI sharedInstance].networkConsentInfo[kNetworkNameAdmob][kAdmobConsentStatusKey] integerValue];
                        consentInfo.tagForUnderAgeOfConsent = [[ATAPI sharedInstance].networkConsentInfo[kNetworkNameAdmob][kAdmobUnderAgeKey] boolValue];
                    } else {
                        BOOL set = NO;
                        ATUnitGroupModel *unitGroupModel =(ATUnitGroupModel*)serverInfo[kAdapterCustomInfoUnitGroupModelKey];
                        BOOL limit = [[ATAppSettingManager sharedManager] limitThirdPartySDKDataCollection:&set networkFirmID:unitGroupModel.networkFirmID];
                        if (set) { consentInfo.consentStatus = limit ? ATPACConsentStatusNonPersonalized : ATPACConsentStatusPersonalized; }
                    }
                }
            });
        });
    }
    return self;
}

-(void) loadADWithInfo:(NSDictionary*)serverInfo localInfo:(NSDictionary*)localInfo completion:(void (^)(NSArray<NSDictionary*> *assets, NSError *error))completion {
    if (NSClassFromString(@"GADAdLoader") != nil) {
        _customEvent = [ATAdMobCustomEvent new];
        _customEvent.unitID = serverInfo[@"unit_id"];
        _customEvent.requestCompletionBlock = completion;
        _customEvent.requestNumber = [serverInfo[@"request_num"] longValue];
        NSDictionary *extraInfo = localInfo;
        _customEvent.requestExtra = extraInfo;
        
        NSMutableArray<id<ATGADAdLoaderOptions>>* options = [NSMutableArray<id<ATGADAdLoaderOptions>> array];
        id<ATGADMultipleAdsAdLoaderOptions> option = [NSClassFromString(@"GADMultipleAdsAdLoaderOptions") new];
        option.numberOfAds = [serverInfo[@"request_num"] longValue];
        if (option != nil) { [options addObject:option]; }
        
        id<ATGADNativeAdMediaAdLoaderOptions> mediaOption = [NSClassFromString(@"GADNativeAdMediaAdLoaderOptions") new];
        mediaOption.mediaAspectRatio = [serverInfo[@"media_ratio"] integerValue];
        if (mediaOption != nil) { [options addObject:mediaOption]; }
        
        _loader = [[NSClassFromString(@"GADAdLoader") alloc] initWithAdUnitID:serverInfo[@"unit_id"] rootViewController:nil adTypes:@[ kATGADAdLoaderAdTypeUnifiedNative ] options:options];
        _loader.delegate = _customEvent;
        id<ATGADRequest> request = [NSClassFromString(@"GADRequest") request];
        id<ATPACConsentInformation> consentInfo = [NSClassFromString(@"PACConsentInformation") sharedInstance];
        if (consentInfo.consentStatus == ATPACConsentStatusNonPersonalized) {
            id<ATGADExtras> extras = [[NSClassFromString(@"GADExtras") alloc] init];
            extras.additionalParameters = @{@"npa":@"1"};
            [request registerAdNetworkExtras:extras];
        }
        [_loader loadRequest:request];
    } else {
        completion(nil, [NSError errorWithDomain:ATADLoadingErrorDomain code:ATADLoadingErrorCodeThirdPartySDKNotImportedProperly userInfo:@{NSLocalizedDescriptionKey:kATSDKFailedToLoadNativeADMsg, NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:kSDKImportIssueErrorReason, @"Admob"]}]);
    }
}
@end
