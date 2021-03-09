package phantom.lib;

import android.util.Log;

import org.json.JSONObject;

import prj.chameleon.channelapi.Constants;
import prj.chameleon.channelapi.IDispatcherCb;

/**
 * Created by 龙的传人 on 2018/3/13.
 * 支付回调
 */

public class BuyCb implements IDispatcherCb
{
    private static final String TAG = MainActivity.TAG;

    @Override
    public void onFinished(int code, JSONObject data)
    {
        if (code == Constants.ErrorCode.ERR_OK)
        {
            Log.d(TAG, "SDK buy success");
        }
        else
        {
            String msg = "";
            if (data != null) msg = data.toString();
            Log.d(TAG, "SDK buy failure ,code:" + code + ", data:" + msg);
        }
    }
}
