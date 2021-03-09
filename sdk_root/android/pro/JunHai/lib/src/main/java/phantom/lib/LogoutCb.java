package phantom.lib;

import android.util.Log;

import com.unity3d.player.UnityPlayer;

import org.json.JSONObject;

import prj.chameleon.channelapi.Constants;
import prj.chameleon.channelapi.IDispatcherCb;

/**
 * Created by 龙的传人 on 2018/3/13.
 */

public class LogoutCb implements IDispatcherCb
{
    private static final String TAG = MainActivity.TAG;

    @Override
    public void onFinished(int code, JSONObject data)
    {
        if (code == Constants.ErrorCode.LOGOUT_SUCCESS)
        {
            Log.d(TAG, "SDK logout success");
            UnityPlayer.UnitySendMessage(uTool.SDK, "LogoutSuc", "");
        }
        else
        {
            Log.e(TAG, "SDK logout failure, code:" + code);
            UnityPlayer.UnitySendMessage(uTool.SDK, "LogoutFail", "");
        }
    }
}
