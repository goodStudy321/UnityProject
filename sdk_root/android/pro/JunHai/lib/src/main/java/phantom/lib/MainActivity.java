package phantom.lib;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.KeyEvent;
import android.widget.Toast;

import com.tencent.bugly.agent.GameAgent;
import com.tencent.bugly.crashreport.CrashReport;
import com.unity3d.player.UnityPlayer;
import com.unity3d.player.UnityPlayerActivity;

import org.json.JSONObject;

import java.util.HashMap;

import prj.chameleon.channelapi.ChannelInterface;
import prj.chameleon.channelapi.Constants;
import prj.chameleon.channelapi.IDispatcherCb;


/**
 * Created by 龙的传人 on 2018/3/12.
 */

public class MainActivity extends UnityPlayerActivity
{
    /**
     * true:已经初始化
     */
    private static boolean isInit = false;

    public static final String TAG = "MainActivity";

    /**
     * 获取用户数据
     *
     * @param svrID        区服id
     * @param svrName      区服名字
     * @param roleID       角色id
     * @param roleName     角色名
     * @param roleLv       角色等级
     * @param vipLv        VIP 等级
     * @param totalCoin    玩家游戏币总额
     * @param familyName   帮派,公会名称
     * @param roleCreateTm 角色创建的服务器时间
     * @param roleUpgLvTm  角色升级的服务器时间
     * @return
     */
    private HashMap<String, Object> getUserData(String svrID, String svrName, String roleID,
                                                String roleName, int roleLv, int vipLv, long totalCoin,
                                                String familyName, long roleCreateTm, long roleUpgLvTm)
    {
        HashMap<String, Object> data = new HashMap<>();
        data.put(Constants.User.SERVER_ID, svrID); // 区服id
        data.put(Constants.User.SERVER_NAME, svrName); // 区服名字
        data.put(Constants.User.ROLE_ID, roleID); // 角色id
        data.put(Constants.User.ROLE_NAME, roleName); // 角色名
        data.put(Constants.User.ROLE_LEVEL, roleLv); // 角色等级
        data.put(Constants.User.VIP_LEVEL, vipLv); // VIP 等级
        data.put(Constants.User.BALANCE, totalCoin); // 玩家游戏币总额,如 100 金币
        if (StrTool.isEmpty(familyName)) familyName = "unknown";
        data.put(Constants.User.PARTY_NAME, familyName); // 帮派,公会名称. 若无,填unknown
        // ROLE_CREATE_TIME参数必传，不然uc审核不通过
        // 此字段为角色创建(CREATE_ROLE)的时间,(单位：秒 即10位数),必须传服务器时.ENTER_SERVER和UPDATE_LEVEL时如果有角色,必须传入真实时间,没有的话,传入-1
        data.put(Constants.User.ROLE_CREATE_TIME, roleCreateTm);
        // 此字段为角色升级(UPDATE_LEVEL)的时间,(单位：秒 即10位数),必须传服务器时间.ENTER_SERVER和CREATE_ROLE时如果有角色,必须传入最新一次角色升级的真实时间，没有的话，传入角色创建时间,或是-1
        data.put(Constants.User.ROLE_UPDATE_TIME, roleUpgLvTm);

        return data;
    }

    /**
     * 初始化
     */
    private void init()
    {
        Log.d(TAG, "init");
        InitCb cb = new InitCb(MainActivity.this);
        ChannelInterface.init(this, true, cb);
    }

    /**
     * 退出
     */
    private void exit()
    {
        if (isInit)
        {
            Log.d(TAG, "exit");
            ExitCb cb = new ExitCb(MainActivity.this);
            ChannelInterface.exit(this, cb);
        }
        else
        {
            Toast.makeText(this, "SDK初始化中···,请稍候", Toast.LENGTH_SHORT).show();
        }
    }

    /**
     * 登陆
     */
    public void login()
    {
        if (!isInit)
        {
            Log.e(TAG, "not init");
            return;
        }
        LoginCb loginCb = new LoginCb();
        loginCb.setActivity(MainActivity.this);
        AccountActionCb accountActionCb = new AccountActionCb();
        ChannelInterface.login(this, loginCb, accountActionCb);
    }

    /**
     * 退出登录
     */
    public void logout()
    {
        LogoutCb logoutCb = new LogoutCb();
        ChannelInterface.logout(this, logoutCb);
    }

    /**
     * 购买
     *
     * @param oId      订单号
     * @param roleID   玩家角色id
     * @param roleName 玩家角色名
     * @param svrId    区服id
     * @param proName  商品名,名称前请不要添加任何量词.如钻石,月卡即可
     * @param proID    商品ID
     * @param des      商品描述信息
     * @param cnt      购买的商品数量
     * @param money    支付金额 单位为分
     * @param url      支付结果回调地址
     */
    public void buy(String oId, String roleID, String roleName,
                    String svrId, String proName, String proID,
                    String des, int cnt, int money, String url)
    {
        StringBuffer sb = new StringBuffer();
        sb.append("SDK start buy:");
        sb.append("id:").append(oId).append(",roleID:").append(roleID);
        sb.append(",roleName:").append(roleName).append(", svrID:").append(svrId);
        sb.append(",proName").append(proName).append(",proID:").append(proID);
        sb.append(",des:").append(des).append(",cnt:").append(cnt);
        sb.append(",money:").append(money).append(",url:").append(url);
        Log.d(TAG, sb.toString());

        BuyCb buyCb = new BuyCb();
        ChannelInterface.buy(this, oId, roleID, roleName, svrId, proName, proID, des, cnt, money, url, buyCb);

    }

    /**
     * 上传数据当进入服务器时
     */
    public void uploadOnEnterSvr(String svrID, String svrName, String roleID,
                                 String roleName, int roleLv, int vipLv, long totalCoin,
                                 String familyName, long roleCreateTm, long roleUpgLvTm)
    {
        HashMap<String, Object> data = getUserData(svrID, svrName, roleID, roleName, roleLv, vipLv, totalCoin, familyName, roleCreateTm, roleUpgLvTm);
        data.put(Constants.User.ACTION, Constants.User.ENTER_SERVER);
        Log.d(TAG, "upDataOnEnterSvr: " + data);
        ChannelInterface.uploadUserData(this, data);
    }

    /**
     * 上传数据当创建角色时
     */
    public void uploadOnCreateRole(String svrID, String svrName, String roleID,
                                   String roleName, int roleLv, int vipLv, long totalCoin,
                                   String familyName, long roleCreateTm, long roleUpgLvTm)
    {
        HashMap<String, Object> data = getUserData(svrID, svrName, roleID, roleName, roleLv, vipLv, totalCoin, familyName, roleCreateTm, roleUpgLvTm);
        data.put(Constants.User.ACTION, Constants.User.CREATE_ROLE);
        Log.d(TAG, "upDataOnCreateRole: " + data);
        ChannelInterface.uploadUserData(this, data);
    }

    /**
     * 上传数据当角色升级时
     */
    public void uploadOnRoleUpgLv(String svrID, String svrName, String roleID,
                                  String roleName, int roleLv, int vipLv, long totalCoin,
                                  String familyName, long roleCreateTm, long roleUpgLvTm)
    {
        HashMap<String, Object> data = getUserData(svrID, svrName, roleID, roleName, roleLv, vipLv, totalCoin, familyName, roleCreateTm, roleUpgLvTm);
        data.put(Constants.User.ACTION, Constants.User.UPDATE_LEVEL);
        Log.d(TAG, "upDataOnRoleUpgLv: " + data);
        ChannelInterface.uploadUserData(this, data);
    }

    /**
     * 上传购买道具统计数据
     *
     * @param con        购买道具所花费的游戏币
     * @param conBind    购买道具所花费的绑定游戏币
     * @param remain     剩余多少游戏币
     * @param remainBind 剩余多少绑定游戏币
     * @param cnt        购买道具的数量
     * @param name       道具名称
     * @param des        道具描述,可以传空串
     */
    public void uploadBuyData(int con, int conBind, long remain,
                              long remainBind, int cnt, String name, String des)
    {
        HashMap<String, Object> data = new HashMap<>();
        data.put(Constants.User.ACTION, Constants.User.BUY_ITEM); // 事件名称
        data.put(Constants.User.CONSUME_COIN, con);
        data.put(Constants.User.CONSUME_BIND_COIN, conBind);
        data.put(Constants.User.REMAIN_COIN, remain);
        data.put(Constants.User.REMAIN_BIND_COIN, remainBind);// 剩余多少绑定游戏币
        data.put(Constants.User.ITEM_COUNT, cnt);//购买道具的数量
        data.put(Constants.User.ITEM_NAME, name);// 道具名称
        data.put(Constants.User.ITEM_DESC, des); // 道具描述,可以传空串
        Log.d(TAG, "uploadBuyData: " + data);
        ChannelInterface.uploadUserData(this, data);
    }

    /**
     * 打开用户中心/论坛
     */
    public void openUserCenter()
    {
        String uc = ChannelInterface.hasUserCenter();
        if (uc == null || uc.equals(""))
        {
            Log.d(TAG, "no UserCenter");
            UnityPlayer.UnitySendMessage(uTool.SDK, "OpenUserCenterCb", "0");
        }
        else
        {
            Log.d(TAG, "UserCenter: " + uc);
            UserCenterCb cb = new UserCenterCb();
            cb.setActivity(MainActivity.this);
            ChannelInterface.openUserCenter(this, cb);
        }
    }

    /**
     * 判断是否有论坛接口
     */
    public void hasUserCenter()
    {
        String uc = ChannelInterface.hasUserCenter();
        if (uc == null || uc.equals(""))
        {
            Log.d(TAG, "no UserCenter");
            UnityPlayer.UnitySendMessage(uTool.SDK, "HasUserCenterCb", "0");
        }
        else
        {
            UnityPlayer.UnitySendMessage(uTool.SDK, "HasUserCenterCb", "1");
        }
    }


    /**
     * 设置是否初始化
     *
     * @param val
     */
    public static void setIsInit(boolean val)
    {
        isInit = val;
    }


    @Override
    public boolean onKeyDown(int keyCode, KeyEvent keyEvent)
    {
        if (keyCode == KeyEvent.KEYCODE_BACK)
        {
            exit();
        }
        return super.onKeyDown(keyCode, keyEvent);
    }

    @Override
    protected void onCreate(Bundle bundle)
    {
        super.onCreate(bundle);
        Log.d(TAG, "onCreate: ");
        String bid = "70638cc62c";
        GameAgent.initCrashReport(bid, false);
        CrashReport.initCrashReport(MainActivity.this);
        ChannelInterface.onCreate(this);
        init();
    }

    @Override
    protected void onResume()
    {
        super.onResume();
        ChannelInterface.onResume(this);
    }

    @Override
    protected void onPause()
    {
        super.onPause();
        ChannelInterface.onPause(this);
    }

    @Override
    protected void onStop()
    {
        super.onStop();
        ChannelInterface.onStop(this);
    }

    @Override
    protected void onRestart()
    {
        super.onRestart();
        ChannelInterface.onRestart(this);
    }

    @Override
    protected void onDestroy()
    {
        super.onDestroy();
        ChannelInterface.onDestroy(this);
        Log.d(TAG, "onDestroy: ");
    }

    @Override
    protected void onStart()
    {
        super.onStart();
        ChannelInterface.onStart(this);
    }

    @Override
    protected void onNewIntent(Intent intent)
    {
        super.onNewIntent(intent);
        ChannelInterface.onNewIntent(this, intent);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data)
    {
        super.onActivityResult(requestCode, resultCode, data);
        ChannelInterface.onActivityResult(this, requestCode, resultCode, data);
    }

    @Override
    public void onWindowFocusChanged(boolean b)
    {
        super.onWindowFocusChanged(b);
        ChannelInterface.onWindowFocusChanged(this, b);
        Log.d(TAG, "onWindowFocusChanged: ");
    }

    public void setBSUrl(String val)
    {
        App.setBSUrl(val);
    }
}
