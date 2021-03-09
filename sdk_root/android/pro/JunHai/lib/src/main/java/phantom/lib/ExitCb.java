package phantom.lib;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.util.Log;

import org.json.JSONObject;

import prj.chameleon.channelapi.Constants;
import prj.chameleon.channelapi.IDispatcherCb;

/**
 * Created by 龙的传人 on 2018/3/12.
 */

public class ExitCb implements IDispatcherCb
{
    /**
     * 回调活动参数
     */
    private Activity act = null;

    private static final String TAG = MainActivity.TAG;

    public ExitCb(Activity act)
    {
        this.act = act;
    }

    @Override
    public void onFinished(int code, JSONObject data)
    {
        if (code == Constants.ErrorCode.EXIT_NO_UI)
        {
            Log.d(TAG, "channel has not exit ui");
            final AlertDialog.Builder dialog = new AlertDialog.Builder(act);
            dialog.setMessage("退出游戏?");

            dialog.setPositiveButton("确定", new DialogInterface.OnClickListener()
            {
                @Override
                public void onClick(DialogInterface dialog, int which)
                {
                    Log.d(TAG, "SDK select quit game");
                    dialog.dismiss();
                    act.finish();
                }
            });

            dialog.setNegativeButton("取消", new DialogInterface.OnClickListener()
            {
                @Override
                public void onClick(DialogInterface dialog, int which)
                {
                    Log.d(TAG, "SDK select continue game");
                    dialog.dismiss();
                }
            });
            dialog.show();
        }
        else if (code == Constants.ErrorCode.EXIT_WITH_UI)
        {
            Log.d(TAG, "channel has exit ui");
            int result = data.optInt("content", Constants.ErrorCode.CONTINUE_GAME);
            if (result == Constants.ErrorCode.CONTINUE_GAME)
            {
                // 继续游戏, 这里游戏可以无需做任何逻辑处理.
                Log.d(TAG, "SDK continue game");
            }
            else
            {
                // 退出游戏, 游戏需要做退出程序逻辑
                Log.d(TAG, "SDK quit game");
                act.finish();
            }
        }
    }
}
