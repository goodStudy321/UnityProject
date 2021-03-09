package phantom.lib;

import android.util.Log;

import com.unity3d.player.UnityPlayer;

import org.json.JSONException;
import org.json.JSONObject;

import prj.chameleon.channelapi.Constants;
import prj.chameleon.channelapi.IDispatcherCb;

/**
 * Created by 龙的传人 on 2018/5/24.
 * 获取玩家信息
 */

public class GetPlayerInfoCb implements IDispatcherCb
{
    private static final String TAG = MainActivity.TAG;

    @Override
    public void onFinished(int retCode, JSONObject data)
    {
        int arg = 0;
        if (retCode == Constants.ErrorCode.AUTHENTICATION_OK)
        {
            arg = 1;
        }
        else if (retCode == Constants.ErrorCode.AUTHENTICATION_UNKNOWN)
        {
            arg = 2;
        }
        else if (retCode == Constants.ErrorCode.AUTHENTICATION_NEVER)
        {
            arg = 3;
        }
        JSONObject jo = new JSONObject();
        try
        {
            jo.put("state", arg);
            jo.put("data", data);
            String res = jo.toString();
            Log.d(TAG, "send realname:" + res);
            UnityPlayer.UnitySendMessage(uTool.SDK, "GetPlayerInfo", res);
        }
        catch (JSONException e)
        {
            Log.d(TAG, "send realname err:" + e.getMessage());
            UnityPlayer.UnitySendMessage(uTool.SDK, "GetPlayerInfo", data.toString());
        }
    }
}
