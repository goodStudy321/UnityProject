package com.junhai.agent.demo;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;

import com.ijunhai.sdk.common.util.SdkInfo;
import com.ijunhai.sdk.common.util.TimeUtil;

import org.json.JSONObject;

import java.util.HashMap;

import asynchttp.AsyncHttpClient;
import asynchttp.JsonHttpResponseHandler;
import asynchttp.RequestParams;
import cz.msebera.android.httpclient.Header;
import prj.chameleon.channelapi.ChannelInterface;
import prj.chameleon.channelapi.Constants;
import prj.chameleon.channelapi.IDispatcherCb;
import prj.chameleon.channelapi.cbinding.AccountActionListener;

/**
 * Created by jerry on 17-2-17.
 */

public class DemoActivity extends Activity {
    private static final String TAG = "DemoActivity";
    private boolean isInit = false;

    private void init() {
        Log.d(TAG, "SDK start init");
        // 强烈建议尽可能提早调用初始化接口，并且在收到初始化成功回调后，才可以进入游戏。
        // 因为有些渠道要求他们闪屏必须最先调起，而渠道初始化完成之后才会调起闪屏页面。
        ChannelInterface.init(this, true, new IDispatcherCb() {
            @Override
            public void onFinished(int code, JSONObject jsonObject) {
                if (Constants.ErrorCode.ERR_OK == code) {
                    // 初始化成功,游戏可以进行其他逻辑操作,如调用SDK的login接口进行登录
                    isInit = true;
                    Log.d(TAG, "SDK init success");
                } else {
                    // 初始化失败,强烈建议游戏再收到初始化失败回调后,给一个初始化失败的对话框,并且退出游戏.
                    Log.d(TAG, "SDK init fail");
                }
            }
        });
    }


    public void login(View view) {
        if (isInit) {
            Log.d(TAG, "SDK start login");
            ChannelInterface.login(this, new IDispatcherCb() {
                @Override
                public void onFinished(int code, JSONObject jsonObject) {
                    if (code == Constants.ErrorCode.ERR_OK) {
                        // 登录成功，进行服务器登录信息校验
                        try {
                            Log.d(TAG, "SDK login success");
                            RequestParams req = new RequestParams();
                            req.put("uid", (String) jsonObject.get("uid"));
                            req.put("user_name", (String) jsonObject.get("user_name"));
                            req.put("session_id", (String) jsonObject.get("session_id"));
                            req.put("channel_id", ChannelInterface.getChannelID());
                            req.put("game_channel_id", ChannelInterface.getGameChannelId());
                            req.put("game_id", SdkInfo.getInstance().getGameId());
                            req.put("others", (String) jsonObject.get("others"));
                            Log.d(TAG, req.toString());
                            String url = ""; // 这里的url,为游戏研发服务器地址,用于登录信息校验.
                            new AsyncHttpClient().get(url, req, new JsonHttpResponseHandler() {
                                @Override
                                public void onSuccess(int statusCode, Header[] headers, JSONObject response) {
                                    // 游戏需要根据实际情况拼接 JSON 字符串
                                    /*
                                     {
                                     "code": 0,
                                     "loginInfo": {
                                     "uid": "123456",
                                     "token": "xxxaaaa"
                                     }
                                     }
                                     */
                                    //请务必在服务器登录验证成功后,调用该接口,该接口接收的参数,如上所示
                                    ChannelInterface.onLoginRsp(response.toString());
                                }

                                @Override
                                public void onFailure(int statusCode, Header[] headers, String responseBody, Throwable e) {
                                }
                            });
                        } catch (Exception e) {

                        }
                    } else {
                        Log.d(TAG, "SDK login fail");
                    }
                }
            }, new AccountActionListener() {
                @Override
                public void onAccountLogout() {
                    Log.d(TAG, "SDK logout success");
                    //@TODO 游戏收到登出回调后,需要退到游戏登录界面,让玩家重新登录游戏.
                }
            });
        } else {
            Log.d(TAG, "please call init method first");
        }
    }

    public void uploadUserData(View view) {
        HashMap<String, Object> params = new HashMap<>();
        // Constants.User.ENTER_SERVER为进入服务器
        params.put(Constants.User.ACTION, Constants.User.ENTER_SERVER);
        params.put(Constants.User.SERVER_ID, "1"); // 区服id
        params.put(Constants.User.SERVER_NAME, "s1"); // 区服名字
        params.put(Constants.User.ROLE_ID, "100"); // 角色id
        params.put(Constants.User.ROLE_NAME, "小海"); // 角色名
        params.put(Constants.User.ROLE_LEVEL, 10); // 角色等级
        params.put(Constants.User.VIP_LEVEL, 5); // VIP 等级
        params.put(Constants.User.BALANCE, 100); // 玩家游戏币总额， 如 100 金币
        params.put(Constants.User.PARTY_NAME, "小海公会"); // 帮派，公会名称。 若无，填 unknown
        // ROLE_CREATE_TIME参数必传，不然uc审核不通过
        // 此字段为角色创建(CREATE_ROLE)的时间,(单位：秒 即10位数)，必须传服务器时间。ENTER_SERVER和UPDATE_LEVEL时如果有角色，必须传入真实时间，没有的话，传入-1
        params.put(Constants.User.ROLE_CREATE_TIME, TimeUtil.unixTime());
        // 此字段为角色升级(UPDATE_LEVEL)的时间,(单位：秒 即10位数)，必须传服务器时间。ENTER_SERVER和CREATE_ROLE时如果有角色，必须传入最新一次角色升级的真实时间，没有的话，传入角色创建时间,或是-1
        params.put(Constants.User.ROLE_UPDATE_TIME, TimeUtil.unixTime());
        Log.d(TAG, "uploadUserInfo params: " + params);
        ChannelInterface.uploadUserData(this, params);

        // Constants.User.CREATE_ROLE为角色创建
        params.put(Constants.User.ACTION, Constants.User.CREATE_ROLE);
        Log.d(TAG, "uploadUserInfo params: " + params);
        ChannelInterface.uploadUserData(this, params);

        // Constants.User.UPDATE_LEVEL为角色升级
        params.put(Constants.User.ACTION, Constants.User.UPDATE_LEVEL);
        Log.d(TAG, "uploadUserInfo params: " + params);
        ChannelInterface.uploadUserData(this, params);
    }


    public void logout(View view) {
        Log.d(TAG, "SDK start logout");
        ChannelInterface.logout(this, new IDispatcherCb() {
            @Override
            public void onFinished(int code, JSONObject jsonObject) {
                if (Constants.ErrorCode.LOGOUT_SUCCESS == code) {
                    Log.d(TAG, "SDK logout success");
                    // 帐号登出成功,游戏需要回到登录主界面,让玩家重新登录帐号
                } else {
                    Log.d(TAG, "SDK logout fail");
                    // 帐号登出失败,玩家可以继续游戏
                }
            }
        });
    }


    public void buy(View view) {
        Log.d(TAG, "SDK start buy");
        String orderId = "123" + TimeUtil.unixTimeString(); //订单号，必传。
        String roleID = "123"; //玩家角色id，必传。
        String roleName = "test_user_name_in_game"; //玩家角色名，必传。
        String serverId = "1"; //区服id，必传。
        String productName = "钻石";  //商品名，商品名称前请不要添加任何量词。如钻石，月卡即可。必传。
        String productID = "test_product_id"; //商品ID，必传。
        String payInfo = "test pay info"; //商品描述信息，必传。
        int productCount = 1; // 购买的商品数量，必传。
        int realPayMoney = 100; //支付金额，单位为分，必传。
        String notifyUrl = ""; //支付结果回调地址，必传。
        ChannelInterface.buy(this, orderId, roleID, roleName, serverId, productName, productID, payInfo, productCount, realPayMoney, notifyUrl, new IDispatcherCb() {
            @Override
            public void onFinished(int code, JSONObject jsonObject) {
                if (Constants.ErrorCode.ERR_OK == code) {
                    Log.d(TAG, "SDK buy success");
                    // 游戏收到回调后, 不要去提示玩家支付成功之类的信息.因为有些渠道SDK还未支付成功,就给了成功支付回调.
                } else {
                    Log.d(TAG, "SDK buy fail");
                    // 游戏收到回调后, 不要去提示玩家支付失败之类的信息.因为有些渠道SDK还未支付成功,就给了失败支付回调.
                }
            }
        });
    }


    public void exit(View view) {
        exit();
    }

    @Override
    public void onBackPressed() {
        exit();
    }

    private void exit() {
        Log.d(TAG, "SDK start exit");
        ChannelInterface.exit(this, new IDispatcherCb() {
            @Override
            public void onFinished(int retCode, JSONObject data) {
                switch (retCode) {
                    case Constants.ErrorCode.EXIT_NO_UI:
                        Log.d(TAG, "channel has not exit ui");
                        // 渠道无退出UI，游戏自行处理
                        // 示例
                        final AlertDialog.Builder builder = new AlertDialog.Builder(DemoActivity.this);
                        builder.setPositiveButton("继续游戏", new DialogInterface.OnClickListener() {
                            @Override
                            public void onClick(DialogInterface dialog, int which) {
                                dialog.dismiss();
                            }
                        }).setNegativeButton("退出游戏", new DialogInterface.OnClickListener() {
                            @Override
                            public void onClick(DialogInterface dialog, int which) {
                                dialog.dismiss();
                            }
                        }).setMessage("这是Demo测试的退出UI，游戏需要自行实现。确定要退出游戏吗?")
                                .create().show();
                        break;
                    case Constants.ErrorCode.EXIT_WITH_UI:
                        Log.d(TAG, "channel has exit ui");
                        int result = data.optInt("content", Constants.ErrorCode.CONTINUE_GAME);
                        if (result == Constants.ErrorCode.CONTINUE_GAME) {
                            // 继续游戏, 这里游戏可以无需做任何逻辑处理.
                            Log.d(TAG, "continue game");
                        } else {
                            // 退出游戏, 游戏需要做退出程序逻辑
                            Log.d(TAG, "quit game");
                            finish();
                        }
                        break;
                }
            }
        });
    }


    public void buyItem(View view) {
        // 游戏内购买道具统计数据接口
        HashMap<String, Object> params = new HashMap<>();
        params.put(Constants.User.ACTION, Constants.User.BUY_ITEM); // 事件名称
        params.put(Constants.User.CONSUME_COIN, 100);// 购买道具所花费的游戏币
        params.put(Constants.User.CONSUME_BIND_COIN, 0);// 购买道具所花费的绑定游戏币
        params.put(Constants.User.REMAIN_COIN, 1000); //剩余多少游戏币
        params.put(Constants.User.REMAIN_BIND_COIN, 100);// 剩余多少绑定游戏币
        params.put(Constants.User.ITEM_COUNT, 10);//购买道具的数量
        params.put(Constants.User.ITEM_NAME, "套套");// 道具名称
        params.put(Constants.User.ITEM_DESC, "国庆大特价,走过路过不要错过"); // 道具描述,可以传空串
        ChannelInterface.uploadUserData(this, params);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.demo_activity);
        ChannelInterface.onCreate(this);
        init();
    }

    @Override
    protected void onResume() {
        super.onResume();
        ChannelInterface.onResume(this);
    }

    @Override
    protected void onPause() {
        super.onPause();
        ChannelInterface.onPause(this);
    }

    @Override
    protected void onStop() {
        super.onStop();
        ChannelInterface.onStop(this);
    }

    @Override
    protected void onRestart() {
        super.onRestart();
        ChannelInterface.onRestart(this);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        ChannelInterface.onDestroy(this);
    }

    @Override
    protected void onStart() {
        super.onStart();
        ChannelInterface.onStart(this);
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        ChannelInterface.onNewIntent(this, intent);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        ChannelInterface.onActivityResult(this, requestCode, resultCode, data);
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        ChannelInterface.onWindowFocusChanged(this, hasFocus);
    }


}
