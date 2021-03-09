//
//  GamedreamerManager.h
//  InternationalSDK_Third
//
//  Created by efunfun on 2016/4/12.
//  Copyright © 2016年 Efunfun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


// In app event names constants
//完成新手任務
#define EventTutorial_completion            @"af_tutorial_completion"
//开始新手教程
#define EventTutorial_begin                 @"tutorial_begin"
//角色等級達成，每10級記錄一次（10、20、30、40、50、60、70、80、90）
#define EventLevelAchieved                  @"af_level_achieved"
//打开储值界面
#define EventEnterPayment                   @"enter_payment"
//活躍天數
#define EventActiveDays                     @"active_days"
//Vip等级
#define EventVIPLevel                       @"vip_level"

//開始下載資源
#define EvenStartDownloadSRC                @"start_download_src"
//資源下載完成
#define EvenFinishDownloadSRC               @"finish_download_src"

// In app event parameter names
//角色等級事件參數
#define EventParamLevel                     @"af_key"
//活躍天數事件參數
#define EventParamDay                       @"af_key"
//Vip事件参数
#define EventParamVip                       @"af_key"




@protocol GamedreamerDelegate <NSObject>

/**
 *  session過期，需要重新登入
 */
- (void)gamedreamerNeedRelogin;

@end

@interface GamedreamerManager : NSObject


@property (nonatomic,assign) id<GamedreamerDelegate> delegate;


+ (instancetype)shareInstance;



#pragma mark - 開始
/**
 *  调试接口
 *  該接口為Gamedreamer平台SDK开启打印日志接口，正式打包请移除
 *
 *  @param bl  是否开启调试功能。
 *
 */
+ (void)setShowDebugMessage:(BOOL)bl;

#pragma mark - 開始
/**
 *  開始接口
 *  該接口為Gamedreamer平台SDK最先調用接口，用於在服務器獲取SDK必要數據、更新檢測等
 *
 *  @param superView  開始視圖的父視圖，傳入父視圖可讓開始視圖加入到父視圖上顯示。此參數可以為nil。當傳入nil時，SDK內部會將視圖加入到keywindow上顯示。
 *  @param loadCallback 開始接口block。
 */
- (void)gamedreamerStartWithSuperView:(UIView *)superView
                        andCompletion:(void (^)(NSDictionary *result, NSError *error))loadCallback;

#pragma mark - 登入
/**
 *  登入接口
 *  該接口為Gamedreamer平台登入接口，用於顯示登入視圖，提供玩家登入相關行為功能。
 *
 *  @param superView  登入視圖的父視圖，傳入父視圖可讓登入視圖加入到父視圖上顯示。此參數可以為nil。當傳入nil時，SDK內部會將視圖加入到keywindow上顯示。
 *  @param loginCallback 登入接口block。
 */
- (void)gamedreamerLoginWithSuperView:(UIView *)superView
                        andCompletion:(void (^)(NSDictionary *userInfo, NSError *error))loginCallback;


/**
 *  登出接口
 *  該接口為Gamedreamer平台登出接口，用於清除玩家登陸信息。
 *
 */
- (BOOL)gamedreamerLogout;


/**
 *  伺服器列表接口
 *  該接口為Gamedreamer伺服器列表接口，用於顯示伺服器選擇視圖，提供玩家選擇新伺服器功能。
 *
 *  @param superView  伺服器列表視圖的父視圖，傳入父視圖可讓伺服器列表視圖加入到父視圖上顯示。此參數可以為nil。當傳入nil時，SDK內部會將視圖加入到keywindow上顯示。
 *  @param serverListCallback 伺服器列表block。
 */
- (void)gamedreamerServerListWithSuperView:(UIView *)superView
                             andCompletion:(void (^)(NSDictionary *userInfo))serverListCallback;


/**
 *  記錄開始遊戲事件
 *  用於防止行銷廣告防止刷數據問題
 */
- (BOOL)gamedreamerStartGameForEventRecorded;

/**
 *  保存角色名和角色id接口
 *  用於保存遊戲內玩家的角色名和角色id，如遊戲內無角色設定，可以不調用本接口。
 *
 *  @param rolename  角色名
 *  @param roleid 角色id
 *  @param rolelevel 角色等級
 */
- (BOOL)gamedreamerSaveRoleName:(NSString *)rolename andRoleId:(NSString *)roleid  andRoleLevel:(NSString *)rolelevel;



/**
 *  新建角色接口
 *  用於保存遊戲內玩家新建角色名和角色id，如遊戲內無角色設定，可以不調用本接口。
 *
 *  @param rolename  角色名
 *  @param roleid 角色id
 */
- (BOOL)gamedreamerNewRoleName:(NSString *)rolename andRoleId:(NSString *)roleid;


#pragma mark - 伺服器檢查
/**
 *  伺服器檢查接口
 *  用於進入遊戲前檢查伺服器狀態，請務必在調用登入接口玩家登入操作完成后，進入遊戲前調用一次本接口。在block里會返回檢查后用戶的信息
 *
 *  @param serverid  伺服器id。當使用gamedreamer伺服器選擇界面時，此參數可以直接傳nil；當使用遊戲內伺服器選擇界面時務必傳入所選的伺服器id。
 *  @param detectInfoCallback 伺服器檢查block。
 */
- (void)gamedreamerCheckServerWithServerId:(NSString *)serverid
                             andCompletion:(void (^)(NSDictionary *userInfo, NSError *error))detectInfoCallback;


#pragma mark - 客服

/**
 *  客服接口
 *  用於顯示Gamedreamer客服視圖，提供客服功能
 *
 *  @param superView  客服視圖的父視圖，傳入父視圖可讓客服視圖加入到父視圖上顯示。此參數可以為nil。當傳入nil時，SDK內部會將視圖加入到keywindow上顯示。
 *
 */
- (void)gamedreamerCsWithSuperView:(UIView *)superView;

/**
 *  客服接口
 *  用於顯示Gamedreamer客服視圖，提供客服功能
 *
 *  @param superView  客服視圖的父視圖，傳入父視圖可讓客服視圖加入到父視圖上顯示。此參數可以為nil。當傳入nil時，SDK內部會將視圖加入到keywindow上顯示。
 *  @param csCloseCallback 客服中心关闭的回调
 */
- (void)gamedreamerCsWithSuperView:(UIView *)superView
                     andCompletion:(void (^)(void))closeCallback;

/**
 *  綁定接口
 *  用於顯示Gamedreamer客服視圖，提供客服功能
 *
 *  @param superView  客服視圖的父視圖，傳入父視圖可讓客服視圖加入到父視圖上顯示。此參數可以為nil。當傳入nil時，SDK內部會將視圖加入到keywindow上顯示。

 */
- (void)gamedreamerBindWithSuperView:(UIView *)superView;
    
/**
 *  綁定接口
 *  用於顯示Gamedreamer客服視圖，提供客服功能
 *
 *  @param superView  客服視圖的父視圖，傳入父視圖可讓客服視圖加入到父視圖上顯示。此參數可以為nil。當傳入nil時，SDK內部會將視圖加入到keywindow上顯示。
 *  @param csCloseCallback 客服中心关闭的回调
 */
- (void)gamedreamerBindWithSuperView:(UIView *)superView
                       andCompletion:(void (^)(void))closeCallback;


#pragma mark - 儲值
/**
 *  儲值接口
 *  用於顯示Gamedreamer儲值視圖，提供儲值功能
 *
 *  @param superView  儲值視圖的父視圖，傳入父視圖可讓儲值視圖加入到父視圖上顯示。此參數可以為nil。當傳入nil時，SDK內部會將視圖加入到keywindow上顯示。
 *  @param storeCallback 儲值block。
 */
- (void)gamedreamerStoreWithSuperView:(UIView *)superView
                        andCompletion:(void (^)(NSDictionary *result, NSError *error))storeCallback;



/**
 *  儲值接口
 *  用於對單個禮包特殊品項儲值
 *
 *  @param proItemid  禮包品項id值
 *  @param storeCallback 儲值block。
 */
- (void)gamedreamerStoreWithProItemid:(NSString *)proItemid
                        andCompletion:(void (^)(NSDictionary *result, NSError *error))storeCallback;



#pragma mark - 會員中心
/**
 *  會員中心接口
 *  調用接口顯示Gamedreamer會員中心
 *
 *  @param superView  會員中心的父視圖，傳入父視圖可讓會員中心視圖加入到父視圖上顯示。此參數可以為nil。當傳入nil時，SDK內部會將視圖加入到keywindow上顯示。
 *  @param memberCenterCloseCallback 会员中心关闭的回调
 */
- (void)gamedreamerMemberCenterWithSuperView:(UIView *)superView
                               andCompletion:(void (^)(void))memberCenterCloseCallback;

/**
 *  會員中心接口
 *  調用接口顯示Gamedreamer會員中心
 *
 *  @param superView  會員中心的父視圖，傳入父視圖可讓會員中心視圖加入到父視圖上顯示。此參數可以為nil。當傳入nil時，SDK內部會將視圖加入到keywindow上顯示。
 */
- (void)gamedreamerMemberCenterWithSuperView:(UIView *)superView;


#pragma mark - 評分
/**
 *  應用內App Store評分接口
 *  調用接口顯示應用內App Store評分界面
 *
 */
- (void)gamedreamerAPPScore;


#pragma mark - 事件記錄
/**
 *  事件記錄
 *  用於記錄遊戲內玩家某些事件
 *
 *  @param name  事件的名稱，例如角色等級到達某一等級
 *  @param parameters 事件具體參數，可以為nil。
 */
- (void)gamedreamerLogEventWithName:(NSString *)name
                         parameters:(NSDictionary<NSString *, NSObject *> *)parameters;



/**
 *  儲值事件記錄
 *  用於記錄遊戲的儲值事件
 *
 *  @param price  儲值金額
 *  @param currency 貨幣單位。
 */
- (void)gamedreamerPayEventPrice:(NSString *)price
                        currency:(NSString *)currency;


#pragma mark - 分享

/*!
 @method
 
 Line share
 
 @param message share text
 
 */
- (BOOL)LineShareWithContentMessage:(NSString *)message NS_DEPRECATED_IOS(4_2, 8_0, "本方法已廢棄，請使用GDLineShare類里的分享接口") __TVOS_PROHIBITED;



/**
 *  facebook分享
 *  用於遊戲內分享內容到facebook
 *
 *  @param name  分享的名稱
 *  @param viewController  分享彈出界面從父節點 如無可以傳入nil
 *  @param description  分享的具體描述
 *  @param pictureUrl  分享的圖片鏈接
 *  @param callback 分享成功與否block。
 */
- (void)gamedreamerFacebookShare:(NSString *)name
                            From:(UIViewController *)viewController
                     Description:(NSString *)description
                            Link:(NSString *)link
                  withPictureURL:(NSString *)pictureUrl
                        complete:(void (^)(BOOL shareResult))callback NS_DEPRECATED_IOS(4_2, 8_0, "本方法已廢棄，請使用GDFacebookShare類里的分享接口") __TVOS_PROHIBITED;


#pragma mark - AppDelegate 接口
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;

- (void)applicationWillResignActive:(UIApplication *)application;

- (void)applicationDidEnterBackground:(UIApplication *)application;

- (void)applicationWillEnterForeground:(UIApplication *)application;

- (void)applicationDidBecomeActive:(UIApplication *)application;

- (void)applicationWillTerminate:(UIApplication *)application;

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken;

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error;

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url;

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation NS_DEPRECATED_IOS(4_2, 9_0, "Please use application:openURL:options:") __TVOS_PROHIBITED;

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options;

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *))restorationHandler NS_AVAILABLE_IOS(8_0);

@end


