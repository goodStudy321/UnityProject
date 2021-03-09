package phantom.lib;

import android.util.Log;

import com.unity3d.player.UnityPlayer;

import prj.chameleon.channelapi.cbinding.AccountActionListener;

/**
 * Created by 龙的传人 on 2018/3/13.
 */

public class AccountActionCb extends AccountActionListener
{
    private static final String TAG = MainActivity.TAG;

    @Override
    public void onAccountLogout()
    {
        Log.d(TAG, "onAccountLogout: SDK logout success");
        UnityPlayer.UnitySendMessage(uTool.SDK, "LogoutSuc", "");
    }
}
