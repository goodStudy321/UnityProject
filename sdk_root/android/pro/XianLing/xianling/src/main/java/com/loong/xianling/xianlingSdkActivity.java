package com.loong.xianling;

import org.json.JSONException;
import org.json.JSONObject;

import android.annotation.TargetApi;
import android.app.Activity;
import android.content.Intent;
import android.content.res.Configuration;
import android.graphics.Color;
import android.os.Bundle;
import android.os.PersistableBundle;
import android.util.Log;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import com.qipa.gmsupersdk.base.GMHelper;
import com.qipa.gmsupersdk.base.GmTopupListen;
import com.supersdk.common.bean.GameInfor;
import com.supersdk.common.bean.SupersdkPay;
import com.supersdk.common.listen.CanEnterListen;
import com.supersdk.common.listen.GameInforListen;
import com.supersdk.common.listen.LoginListen;
import com.supersdk.common.listen.LogoutGameListen;
import com.supersdk.common.listen.LogoutListen;
import com.supersdk.common.listen.PayListen;
import com.supersdk.presenter.SuperHelper;
import com.supersdk.superutil.ToastUtils;

import com.unity3d.player.UnityPlayer;
import com.unity3d.player.UnityPlayerActivity;

public class xianlingSdkActivity extends UnityPlayerActivity {
    private SuperHelper superHelper;
    private GMHelper gmHelper;
    private boolean iscanenter; // 是否允许进入服务器

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.v("androidSdk","lgs 启动 onCreate ");
        superHelper = SuperHelper.geApi();
        gmHelper = GMHelper.geApi();
        superHelper.activity_creat(this, savedInstanceState);

        /*
         * SDK注册监听,游戏内接收到监听,做注销游戏操作
         */
        superHelper.register_logoutListen(new LogoutListen() {
            @Override
            public void defeat(String defeat) {
                // 注销失败,此处
                Log.v("androidSdk","lgs 注销失败  defeat: " + defeat);
                unitySend("LogoutFail",defeat);
            }

            @Override
            public void logout_success(String json) {
                // 注销成功,此处写游戏注销方法
                // 此处写游戏注销方法
                Log.v("androidSdk","lgs 注销成功 json: "+json);
                unitySend("LogoutSuc",json);
            }

            @Override
            public void logout_defeat(String arg0) {
                // 注销失败,
                Log.v("androidSdk","lgs 注销失败 arg0: "+arg0);
                unitySend("LogoutFail",arg0);
            }
        });

        if (superHelper != null) {
            Log.v("androidSdk","lgs sdk初始化成功");
            unitySend("OnInitSuc","");
        }
    }

    public void login(){
        Log.v("androidSdk", "lgs  login unity已调用");
        SuperHelper.geApi().login(new LoginListen() {
            @Override
            public void login_success(String json) {
                Log.v("androidSdk", "lgs  登陆成功 json: "+json);
                try {
                    JSONObject jo = new JSONObject(json);
                    String super_user_id = jo.getString("super_user_id");
                    String token = jo.getString("token");
                    //以下两条实名信息不是必有，请做好兼容处理
                    int auth = jo.getInt("auth");//0未实名 1已实名 2未接入实名
                    String birthday = jo.getString("birthday");//出生日期，默认格式为 年-月-日，比如1990-1-1。如未实名或者没有实名信息可能为null或者空字符串
                    unitySend("LoginSuc",json);
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }

            @Override
            public void login_defeat(String s) {
                Log.v("androidSdk", "lgs  登陆失败  s: "+s);
                unitySend("LoginFail",s);
            }

            @Override
            public void defeat(String defeat) {
                Log.v("androidSdk", "lgs 登陆失败  defeat: "+defeat);
                unitySend("LoginFail",defeat);
            }
        });
    }

    public void logout(){
        Log.v("androidSdk", "lgs  logout unity已调用");
        SuperHelper.geApi().logout(new LogoutListen() {
            @Override
            public void logout_success(String json) {
                // 注销成功,此处写游戏注销方法
                // 此处写游戏注销方法
                Log.v("androidSdk","lgs  注销成功  json: "+json);
                iscanenter = false;
                unitySend("LogoutSuc",json);
            }

            @Override
            public void logout_defeat(String arg0) {
                // 注销失败,
                Log.v("androidSdk","lgs  注销失败  arg0: "+arg0);
                unitySend("LogoutFail",arg0);
            }

            @Override
            public void defeat(String defeat) {
                // 注销失败,此处
                Log.v("androidSdk","lgs  注销失败  defeat: "+defeat);
                unitySend("LogoutFail",defeat);
            }
        });
    }

    public void canenter(String svrID,String svrName){
        Log.v("androidSdk", "lgs  canEnter  unity已调用");
        GameInfor gameInfor1 = new GameInfor();
        gameInfor1.setService_name(svrName); // 区服名字(必填)
        gameInfor1.setService_id(svrID); // 区服id(必填)
        SuperHelper.geApi().canEnter(gameInfor1, new CanEnterListen() {
            @Override
            public void canEnterListen(boolean b) {
                // TODO Auto-generated method stub
                iscanenter = b;
                String can = "false";
                if (b){
                    can = "true";
                }
                Log.v("androidSdk","lgs  是否允许新增  can: "+can);
                unitySend("CanEnter",can);
            }
        });
    }

    public void uploadUserInfo(String roleType,String svrId,String svrName,String roleId,
                               String roleName,String roleDes,String roleLv,String roleVip,
                               String money,String familyName,String roleExp,String roleTime){
        // 如果允许新增,则进入游戏调用角色接口
        String can = "false";
        if (iscanenter){
            can = "true";
        }
        Log.v("androidSdk", "lgs  setData  unity已调用  roleType："+roleType+ "  iscanenter: "+ can);
        if (iscanenter) {
            GameInfor gameInfor = new GameInfor();
            // 角色上报类型:
            // createrole 创建角色
            // levelup 升级角色
            // enterserver  进入服务器调用

            gameInfor.setRole_type(roleType);
            gameInfor.setService_name(svrName); // 区服名字(必填)
            // gameInfor.setService_id("10086"); // 区服id(必填)
            // gameInfor.setRole_id("123"); // 角色id(必填)
            gameInfor.setService_id(svrId); // 区服id(必填)
            gameInfor.setRole_id(roleId); // 角色id(必填)
            gameInfor.setRole_name(roleName); // 角色名字(必填)
            gameInfor.setRole_level(roleLv); // 角色等级数字.int类型(必填,首次创建默认0级)
            gameInfor.setDescribe(roleDes); // 角色描述(选填,默认为"")
            gameInfor.setMoney(money); // 金额(选填,默认为0)
            gameInfor.setExperience(roleExp); // 角色经验(选填,默认为1,可以填写等级)
            gameInfor.setVip(roleVip); // 角色VIP(选填,默认为1)
            gameInfor.setPartyName(familyName); // 角色工会(选填,默认为"")
            gameInfor.setRole_time(roleTime); // 角色变化时间(必填,默认为当前时间)
            SuperHelper.geApi().setData(gameInfor, new GameInforListen() {
                @Override
                public void game_info_success(String json) {
                    Log.v("androidSdk", "lgs  角色上报成功  json: " + json);
                }

                @Override
                public void game_info_defeat(String reason) {
                    Log.v("androidSdk", "lgs  角色上报失败  reason: " + reason);
                }

                @Override
                public void defeat(String defeat) {
                    Log.v("androidSdk", "lgs  角色上报失败  defeat: " + defeat);
                }
            });
        }
    }

    public void buy(String orderId,String roleId,String roleName,String svrId,String proName,
                    String proId,String svrName,int cnt,float money,String payTime,String remark,
                    String roleLv){
        Log.v("androidSdk", "lgs  pay  unity已调用");
        SupersdkPay supersdkPay = new SupersdkPay();
        supersdkPay.setCount(cnt); // 商品数量,(必填默认1)
        supersdkPay.setGame_order_sn(orderId); // 订单号(必填)
        supersdkPay.setGood_id(proId); // 商品id(必填)
        supersdkPay.setGood_name(proName); // 商品名字(必填)
        supersdkPay.setMoney(money); // 金额(必填float类型)
        supersdkPay.setPay_time(payTime); // 支付时间(必填,没有填当前时间)
        supersdkPay.setRemark(remark); // 扩展参数(选填,没有填"remark",不能为空)
        supersdkPay.setRole_id(roleId); // 角色id(必填)
        supersdkPay.setRole_name(roleName); // 角色名字(必填)
        supersdkPay.setRole_level(roleLv);// 角色经验
        supersdkPay.setService_id(svrId); // 服务器id(必填)
        supersdkPay.setService_name(svrName); // 服务器名字(必填)
        SuperHelper.geApi().pay(supersdkPay, new PayListen() {
            @Override
            public void pay_success(String json) {
                Log.v("androidSdk", "lgs  支付上报成功  json: " + json);
                unitySend("PaySuc",json);
            }

            @Override
            public void pay_defeat(String json) {
                Log.v("androidSdk", "lgs  支付上报失败  json: " + json);
                unitySend("PayFail",json);
            }

            @Override
            public void defeat(String defeat) {
                Log.v("androidSdk", "lgs  支付上报失败  defeat: " + defeat);
                unitySend("PayFail",defeat);
            }
        });
    }

    public void store(){
        Log.v("androidSdk", "lgs  store(Android SDK GM商城)   unity已调用");
        gmHelper.openGMStore(this,new GmTopupListen(){
            @Override
            public void onTopupClick(String json) {
                unitySend("StoreGMMsg",json);
                // TODO 玩家点击GM商城充值按钮的回调监听，研发在此打开游戏里的充值界面
            }

            @Override
            public void onPayGoods(String json) {
                // unity不用做处理
                // TODO 购买道具成功或是失败回调    status：200为成功
                //  {"status":400,"msg":"每日道具已领取","type":0,"data":{}}
            }
        });
    }

    public void endgame(){
        Log.v("androidSdk", "lgs  EndGame  unity已调用");
        SuperHelper.geApi().EndGame(new LogoutGameListen() {
            @Override
            public void confirm() {
                Log.v("androidSdk", "lgs  我是游戏退出方法");
                unitySend("ExitSuc","");
                finish();
                // 这里要调用游戏的退出.如System.exit(0).确保完全退出
                System.exit(0); // 在退出游戏时候请调用此方法,确保完全退出
            }

            @Override
            public void cancel() {
                Log.v("androidSdk", "lgs  我是游戏取消方法");
                unitySend("ExitCancel","");
            }
        });
    }

    private void unitySend(String method,String arg){
        UnityPlayer.UnitySendMessage("Sdk",method,arg);
    }

    /*@Override
    public void onClick(View v) {
        int vid = v.getId();
        // 登录
        if(vid == R.id.btn_login){
            SuperHelper.geApi().login(new LoginListen() {
                @Override
                public void defeat(String json) {
                    tv_userInfo.setTextColor(Color.RED);
                    tv_userInfo.setText("登录失败" + "\n" + "" + json);
                    Log.e("zkf", json);

                }

                @Override
                public void login_defeat(String json) {
                    tv_userInfo.setTextColor(Color.RED);
                    tv_userInfo.setText("登录失败" + "\n" + "" + json);
                    Log.e("zkf", json);
                }

                @Override
                public void login_success(String json) {
                    tv_userInfo.setTextColor(Color.BLACK);
                    tv_userInfo.setText("登录成功" + "\n" + "" + json);
                    Log.e("zkf", json);
                    try {
                        JSONObject jo = new JSONObject(json);
                        String super_user_id = jo.getString("super_user_id");
                        String token = jo.getString("token");
                        //以下两条实名信息不是必有，请做好兼容处理
                        int auth = jo.getInt("auth");//0未实名 1已实名 2未接入实名
                        String birthday = jo.getString("birthday");//出生日期，默认格式为 年-月-日，比如1990-1-1。如未实名或者没有实名信息可能为null或者空字符串
                    } catch (JSONException e) {
                        e.printStackTrace();
                    }
                }
            });
        }
        else if(vid == R.id.btn_logout){
            SuperHelper.geApi().logout(new LogoutListen() {

                @Override
                public void defeat(String defeat) {
                    tv_userInfo.setTextColor(Color.RED);
                    tv_userInfo.setText("注销失败" + "\n" + "" + defeat);
                    Log.e("zkf", defeat);
                }

                @Override
                public void logout_success(String json) {
                    Log.e("zkf", json);
                    tv_userInfo.setTextColor(Color.BLACK);
                    tv_userInfo.setText("注销成功" + "\n" + "" + json);
                    iscanenter = false;
                }

                @Override
                public void logout_defeat(String string) {
                    tv_userInfo.setTextColor(Color.RED);
                    tv_userInfo.setText("注销失败" + "\n" + "" + string);
                    Log.e("zkf", string);
                }
            });
        }
        // 是否允许新增
        else if (vid == R.id.btn_canenter){
            GameInfor gameInfor1 = new GameInfor();
            gameInfor1.setService_name("测试服1"); // 区服名字(必填)
            gameInfor1.setService_id("10086"); // 区服id(必填)
            SuperHelper.geApi().canEnter(gameInfor1, new CanEnterListen() {

                @Override
                public void canEnterListen(boolean b) {
                    // TODO Auto-generated method stub
                    tv_userInfo.setText("是否允许新增" + b);
                    iscanenter = b;
                }
            });
        }
        // 角色上报
        else if (vid == R.id.btn_uploadUserInfo){
            // 如果允许新增,则进入游戏调用角色接口
            if (iscanenter) {
                GameInfor gameInfor = new GameInfor();
                gameInfor.setRole_type("createrole"); // 角色上报类型: createrole 创建角色
                // //levelup 升级角色//
                // ///enterserver
                // 进入服务器调用
                gameInfor.setService_name("测试服1"); // 区服名字(必填)
                // gameInfor.setService_id("10086"); // 区服id(必填)
                // gameInfor.setRole_id("123"); // 角色id(必填)
                gameInfor.setService_id("5099"); // 区服id(必填)
                gameInfor.setRole_id("509900091"); // 角色id(必填)
                gameInfor.setRole_name("慕容狗蛋"); // 角色名字(必填)
                gameInfor.setRole_level("1"); // 角色等级数字.int类型(必填,首次创建默认0级)
                gameInfor.setDescribe(""); // 角色描述(选填,默认为"")
                gameInfor.setMoney("0"); // 金额(选填,默认为0)
                gameInfor.setExperience("1"); // 角色经验(选填,默认为1,可以填写等级)
                gameInfor.setVip("1"); // 角色VIP(选填,默认为1)
                gameInfor.setPartyName(""); // 角色工会(选填,默认为"")
                gameInfor.setRole_time(System.currentTimeMillis() + ""); // 角色变化时间(必填,默认为当前时间)
                SuperHelper.geApi().setData(gameInfor, new GameInforListen() {

                    @Override
                    public void defeat(String defeat) {
                        tv_userInfo.setTextColor(Color.RED);
                        tv_userInfo.setText("上报角色失败" + "\n" + "" + defeat);
                        Log.e("zkf", "角色上报失败" + defeat);
                    }

                    @Override
                    public void game_info_success(String json) {
                        tv_userInfo.setTextColor(Color.BLACK);
                        tv_userInfo.setText("上报角色成功" + "\n" + "" + json);
                        Log.e("zkf", "角色上报成功" + json);
                    }

                    @Override
                    public void game_info_defeat(String reason) {
                        tv_userInfo.setTextColor(Color.RED);
                        tv_userInfo.setText("上报角色失败" + "\n" + "" + reason);
                        Log.e("zkf", "角色上报失败" + reason);
                    }
                });
            }
        }
        else if (vid == R.id.btn_pay){
            String money = edit_pay.getText().toString().trim();
            if (null == money || "".equals(money)) {
                money = 1 + "";
            }
            SupersdkPay supersdkPay = new SupersdkPay();
            supersdkPay.setCount(1); // 商品数量,(必填默认1)
            supersdkPay.setGame_order_sn(System.currentTimeMillis() + ""); // 订单号(必填)
            supersdkPay.setGood_id("123"); // 商品id(必填)
            supersdkPay.setGood_name("方天画戟削苹果"); // 商品名字(必填)
            supersdkPay.setMoney(1); // 金额(必填float类型)
            supersdkPay.setPay_time(System.currentTimeMillis() + ""); // 支付时间(必填,没有填当前时间)
            supersdkPay.setRemark("remark"); // 扩展参数(选填,没有填"remark",不能为空)
            supersdkPay.setRole_id("123"); // 角色id(必填)
            supersdkPay.setRole_name("慕容狗蛋"); // 角色名字(必填)
            supersdkPay.setRole_level("111");// 角色经验
            supersdkPay.setService_id("10086"); // 服务器id(必填)
            supersdkPay.setService_name("测试服1"); // 服务器名字(必填)
            SuperHelper.geApi().pay(supersdkPay, new PayListen() {
                @Override
                public void defeat(String defeat) {
                    tv_userInfo.setTextColor(Color.RED);
                    tv_userInfo.setText("上报支付失败" + "\n" + "" + defeat);
                    Log.e("zkf", "支付上报失败" + defeat);
                }

                @Override
                public void pay_success(String json) {
                    tv_userInfo.setTextColor(Color.BLACK);
                    tv_userInfo.setText("上报支付成功" + "\n" + "" + json);
                    Log.e("zkf", "支付上报成功" + json);
                }

                @Override
                public void pay_defeat(String string) {
                    tv_userInfo.setTextColor(Color.RED);
                    tv_userInfo.setText("上报支付失败" + "\n" + "" + string);
                    Log.e("zkf", "支付上报失败" + string);
                }
            });
        }
        else if (vid == R.id.btn_finish){
            SuperHelper.geApi().EndGame(new LogoutGameListen() {

                @Override
                public void confirm() {
                    Log.e("zkf", "我是游戏退出方法");
                    System.out.println("我是游戏退出方法");
                    finish();
                    // 这里要调用游戏的退出.如System.exit(0).确保完全退出
                    System.exit(0); // 在退出游戏时候请调用此方法,确保完全退出
                }

                @Override
                public void cancel() {
                    Log.e("zkf", "我是游戏取消方法");
                    System.out.println("我是游戏取消方法");
                }
            });
        }
    }*/

    @Override
    protected void onSaveInstanceState(Bundle outState) {
        // 这里请直接重写聚合方法.不要继承super
        superHelper.activity_save_instance_state(outState);
    }

    @Override
    protected void onRestoreInstanceState(Bundle savedInstanceState) {
        // 这里请直接重写聚合方法.不要继承super
        superHelper.activity_restore_instance_state(savedInstanceState);
    }

    @Override
    protected void onStart() {
        super.onStart();
        superHelper.activity_start();
    }

    @Override
    protected void onPause() {
        super.onPause();
        superHelper.activity_pause();
    }

    @Override
    protected void onRestart() {
        super.onRestart();
        superHelper.activity_restart();
    }

    @Override
    protected void onResume() {
        super.onResume();
        superHelper.activity_resume();
    }

    @Override
    protected void onStop() {
        super.onStop();
        superHelper.activity_stop();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        superHelper.activity_destroy();
    }

    @TargetApi(23)
    @Override
    public void onRequestPermissionsResult(int requestCode,
                                           String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        superHelper.activity_RequestPermissionsResult(requestCode, permissions,
                grantResults);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        superHelper.activity_Result(requestCode, resultCode, data);
        super.onActivityResult(requestCode, resultCode, data);
    }

    @Override
    protected void onNewIntent(Intent intent) {
        superHelper.activity_newIntent(intent);
        super.onNewIntent(intent);
    }

    @Override
    public void onConfigurationChanged(Configuration newConfig) {
        superHelper.activity_configurationChanged(newConfig);
        super.onConfigurationChanged(newConfig);
    }

    @Override
    public void onBackPressed() {
        SuperHelper.geApi().EndGame(new LogoutGameListen() {
            @Override
            public void confirm() {
                System.out.println("我是游戏退出方法");
                finish();
                // 这里要调用游戏的退出.如System.exit(0).确保完全退出
                System.exit(0); // 在退出游戏时候请调用此方法,确保完全退出
            }
            @Override
            public void cancel() {
                System.out.println("我是游戏取消方法");
            }
        });
    }
}
