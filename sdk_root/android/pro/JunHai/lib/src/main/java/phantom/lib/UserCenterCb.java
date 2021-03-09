package phantom.lib;

import android.app.Activity;
import android.util.Log;

import com.unity3d.player.UnityPlayer;

import org.json.JSONObject;

import prj.chameleon.channelapi.Constants;
import prj.chameleon.channelapi.IDispatcherCb;

/**
 * Created by 龙的传人 on 2018/9/27.
 */

public class UserCenterCb implements IDispatcherCb
{
    private Activity activity;

    private static final String TAG = MainActivity.TAG;


    public void setActivity(Activity act)
    {
        activity = act;
    }

    @Override
    public void onFinished(int retCode, JSONObject jsonObject)
    {
        if (retCode == Constants.ErrorCode.ERR_OK)
        {
            Log.d(TAG, "openUserCenter ok");
            UnityPlayer.UnitySendMessage(uTool.SDK, "OpenUserCenterCb", "1");
        }
        else
        {
            Log.d(TAG, "openUserCenter fail");
            UnityPlayer.UnitySendMessage(uTool.SDK, "OpenUserCenterCb", "2");
        }
    }
}
