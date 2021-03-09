package phantom.lib;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;

import android.util.Log;

import com.unity3d.player.UnityPlayer;

import org.json.JSONException;
import org.json.JSONObject;

import prj.chameleon.channelapi.ChannelInterface;
import prj.chameleon.channelapi.Constants;
import prj.chameleon.channelapi.IDispatcherCb;

/**
 * Created by 龙的传人 on 2018/3/12.
 */

public class InitCb implements IDispatcherCb
{
    /**
     * 回调活动参数
     */
    private Activity act = null;

    private static final String TAG = MainActivity.TAG;

    public InitCb(Activity act)
    {
        this.act = act;
    }


    @Override
    public void onFinished(int code, JSONObject data)
    {
        if (Constants.ErrorCode.ERR_OK == code)
        {
            MainActivity.setIsInit(true);
            Log.d(TAG, "SDK init success");

            Sdk.setInitOp(Sdk.INIT_SUC);
            if (Sdk.getCanSendInit())
            {
                Sdk.sendInitSuc();
            }

        }
        else
        {
            Log.e(TAG, "SDK init failure, code:" + code);
            Sdk.setInitOp(Sdk.INIT_FAIL);
            if (Sdk.getCanSendInit())
            {
                Sdk.sendInitFail();
            }
            AlertDialog.Builder normDialog = new AlertDialog.Builder(act);
            normDialog.setCancelable(false);
            normDialog.setTitle(" ");
            String msg = "网络出现异常,请检查您的WiFi,3G/4G连接是否正常?";
            normDialog.setMessage(msg);
            normDialog.setPositiveButton("我知道了", new DialogInterface.OnClickListener()
            {
                @Override
                public void onClick(DialogInterface dialog, int which)
                {
                    dialog.dismiss();
                    act.finish();
                }
            });
            normDialog.show();
        }
    }
}
