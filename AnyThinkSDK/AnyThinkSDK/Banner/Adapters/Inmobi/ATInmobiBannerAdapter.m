//
//  ATInmobiBannerAdapter.m
//  AnyThinkInmobiBannerAdapter
//
//  Created by Martin Lau on 2018/10/8.
//  Copyright © 2018 Martin Lau. All rights reserved.
//

#import "ATInmobiBannerAdapter.h"
#import "ATInmobiBannerCustomEvent.h"
#import "ATAPI+Internal.h"
#import "Utilities.h"
#import "ATAdAdapter.h"
#import "ATAppSettingManager.h"
@interface ATInmobiBannerAdapter()
@property(nonatomic, readonly) id<ATIMBanner> banner;
@property(nonatomic, readonly) ATInmobiBannerCustomEvent *customEvent;
@property(nonatomic, readonly) NSDictionary *info;
@property(nonatomic, readonly) NSDictionary *localInfo;
@property(nonatomic, readonly) void (^LoadCompletionBlock)(NSArray<NSDictionary*> *assets, NSError *error);
@end

static NSString *const kUnitIDKey = @"unit_id";
static NSString *const kATInmobiSDKInitedNotification = @"com.anythink.InMobiInitNotification";
@implementation ATInmobiBannerAdapter
-(instancetype) initWithNetworkCustomInfo:(NSDictionary*)serverInfo localInfo:(NSDictionary*)localInfo {
    self = [super init];
    if (self != nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{ [[ATAPI sharedInstance] setVersion:[NSClassFromString(@"IMSdk") getVersion] forNetwork:kNetworkNameInmobi]; });
    }
    return self;
}

-(void) loadADWithInfo:(NSDictionary*)serverInfo localInfo:(NSDictionary*)localInfo completion:(void (^)(NSArray<NSDictionary *> *, NSError *))completion {
    if (NSClassFromString(@"IMBanner") != nil && NSClassFromString(@"IMSdk") != nil) {
        [[ATAPI sharedInstance] inspectInitFlagForNetwork:kNetworkNameInmobi usingBlock:^NSInteger(NSInteger currentValue) {
            if (currentValue == 0) {//not inited
//                [[ATAPI sharedInstance] setInitFlag:1 forNetwork:kNetworkNameInmobi];
                BOOL set = NO;
                ATUnitGroupModel *unitGroupModel =(ATUnitGroupModel*)serverInfo[kAdapterCustomInfoUnitGroupModelKey];
                BOOL limit = [[ATAppSettingManager sharedManager] limitThirdPartySDKDataCollection:&set networkFirmID:unitGroupModel.networkFirmID];
                if (set) { [NSClassFromString(@"IMSdk") updateGDPRConsent:@{@"gdpr_consent_available":limit ? @"false" : @"true", @"gdpr":[[ATAPI sharedInstance] inDataProtectionArea] ? @"1" : @"0"}]; }
                [NSClassFromString(@"IMSdk") initWithAccountID:serverInfo[@"app_id"] andCompletionHandler:^(NSError *error) {
                    if (error == nil) {
                        [[ATAPI sharedInstance] setInitFlag:2 forNetwork:kNetworkNameInmobi];
                        [[NSNotificationCenter defaultCenter] postNotificationName:kATInmobiSDKInitedNotification object:nil];
                        [self loadADUsingInfo:serverInfo localInfo:localInfo completion:completion];
                    } else {
                        completion(nil, error != nil ? error : [NSError errorWithDomain:@"com.anythink.InmobiBannerLoading" code:0 userInfo:@{NSLocalizedDescriptionKey:ATSDKAdLoadFailedErrorMsg, NSLocalizedFailureReasonErrorKey:@"IMSDK has failed to initialize"}]);
                    }
                }];
                return 1;
            } else if (currentValue == 1) {//initing
                self->_info = serverInfo;
                self->_localInfo = localInfo;
                self->_LoadCompletionBlock = completion;
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInitNotification:) name:kATInmobiSDKInitedNotification object:nil];
                return currentValue;
            } else if (currentValue == 2) {//inited
                [self loadADUsingInfo:serverInfo localInfo:localInfo completion:completion];
                return currentValue;
            }
            return currentValue;
        }];
    } else {
        completion(nil, [NSError errorWithDomain:ATADLoadingErrorDomain code:ATADLoadingErrorCodeThirdPartySDKNotImportedProperly userInfo:@{NSLocalizedDescriptionKey:kATSDKFailedToLoadBannerADMsg, NSLocalizedFailureReasonErrorKey:[NSString stringWithFormat:kSDKImportIssueErrorReason, @"Inmobi"]}]);
    }
}

-(void) handleInitNotification:(NSNotification*)notification {
    [self loadADUsingInfo:self.info localInfo:self.localInfo completion:self.LoadCompletionBlock];
}

-(void) loadADUsingInfo:(NSDictionary*)serverInfo localInfo:(NSDictionary*)localInfo completion:(void (^)(NSArray<NSDictionary*> *assets, NSError *error))completion {
    _customEvent = [[ATInmobiBannerCustomEvent alloc] initWithInfo:serverInfo localInfo:localInfo];
    _customEvent.requestCompletionBlock = completion;
    ATUnitGroupModel *unitGroupModel =(ATUnitGroupModel*)serverInfo[kAdapterCustomInfoUnitGroupModelKey];
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_banner = [[NSClassFromString(@"IMBanner") alloc] initWithFrame:CGRectMake(.0f, .0f, unitGroupModel.adSize.width, unitGroupModel.adSize.height) placementId:[serverInfo[kUnitIDKey] longLongValue] delegate:self->_customEvent];
        self->_banner.refreshInterval = [serverInfo[@"nw_rft"] integerValue] / 1000;
        [self->_banner load];
    });
}
@end
