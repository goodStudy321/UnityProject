package phantom.lib;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.util.Log;

import com.ijunhai.sdk.common.util.SdkInfo;
import com.unity3d.player.UnityPlayer;

import org.json.JSONException;
import org.json.JSONObject;

import asynchttp.AsyncHttpClient;
import asynchttp.JsonHttpResponseHandler;
import asynchttp.RequestParams;
import cz.msebera.android.httpclient.Header;
import prj.chameleon.channelapi.ChannelInterface;
import prj.chameleon.channelapi.Constants;
import prj.chameleon.channelapi.IDispatcherCb;

/**
 * Created by 龙的传人 on 2018/3/13.
 */

public class LoginCb implements IDispatcherCb
{

    private Activity activity;

    private static final String TAG = MainActivity.TAG;


    public void setActivity(Activity act)
    {
        activity = act;
    }

    @Override
    public void onFinished(final int code, JSONObject data)
    {
        if (code == Constants.ErrorCode.ERR_OK)
        {
            Log.d(TAG, "SDK login success");
            try
            {
                RequestParams req = new RequestParams();
                req.put("uid", data.getString("uid"));
                req.put("user_name", data.getString("user_name"));
                req.put("session_id", data.getString("session_id"));
                final String channel_id = ChannelInterface.getChannelID();
                req.put("channel_id", channel_id);

                final String game_channel_id = ChannelInterface.getGameChannelId();
                req.put("game_channel_id", game_channel_id);
                req.put("game_id", SdkInfo.getInstance().getGameId());
                req.put("others", data.getString("others"));
                //String url = "http://api.sl-xyjgx.com/index/Junhai/auth";
                String url = App.getBSUrl() +"index/Junhai/auth";
                Log.d(TAG, "url:" + url + ", SDK login req check data:" + req.toString());
                AsyncHttpClient client = new AsyncHttpClient();
                client.get(url, req, new JsonHttpResponseHandler()
                {
                    @Override
                    public void onSuccess(int statusCode, Header[] headers, JSONObject data)
                    {
                        if (data == null)
                        {
                            Log.e(TAG, "SDK login check data failure, no data ");
                            UnityPlayer.UnitySendMessage(uTool.SDK, "LoginFail", "");
                            return;
                        }

                        try
                        {
                            String ret = data.toString();
                            JSONObject data2 = data.getJSONObject("data");
                            Log.d(TAG, "SDK login check data:" + ret);
                            int chkCode = data2.getInt("code");
                            if (chkCode == 0)
                            {
                                JSONObject loginInfo = data2.getJSONObject("loginInfo");
                                final String uid = loginInfo.getString("uid");
                                String res2 = data2.toString();
                                ChannelInterface.onLoginRsp(res2);
                                Log.d(TAG, "SDK login check data success:" + ret + ", onLoginRsp:" + res2);
                                UnityPlayer.UnitySendMessage(uTool.SDK, "LoginSuc", uid);
                                ChannelInterface.getPlayerInfo(activity, new GetPlayerInfoCb());
                            }
                            else
                            {
                                Log.e(TAG, "SDK login check data failure: " + ret);
                                UnityPlayer.UnitySendMessage(uTool.SDK, "LoginFail", ret);
                            }
                        }
                        catch (Exception e)
                        {
                            String err = e.getMessage();
                            if (err == null || err.equals(""))
                            {
                                err = " ";
                            }
                            Log.e(TAG, "SDK login check failure, err:" + err);
                            UnityPlayer.UnitySendMessage(uTool.SDK, "LoginFail", err);
                        }
                    }

                    @Override
                    public void onFailure(int statusCode, Header[] headers, String resp, Throwable e)
                    {
                        String err = " ";
                        if (e != null)
                        {
                            err = e.getMessage();
                            if (err == null || err.equals(""))
                            {
                                err = " ";
                            }
                        }
                        String err2 = "";
                        if (resp != null)
                        {
                            err2 = resp;
                            if (err2 == null || err2.equals(""))
                            {
                                err2 = " ";
                            }
                        }
                        Log.e(TAG, "get url check failure, code:" + statusCode + ", resp:" + err2 + " e:" + err);
                        UnityPlayer.UnitySendMessage(uTool.SDK, "LoginFail", err);
                    }

                    @Override
                    public void onFailure(int statusCode, Header[] headers, Throwable e, JSONObject errResp)
                    {
                        String err = " ";
                        if (e != null)
                        {
                            err = e.getMessage();
                            if (err == null || err.equals(""))
                            {
                                err = " ";
                            }
                        }
                        String err2 = " ";
                        if (errResp != null)
                        {
                            err2 = errResp.toString();
                            if (err2 == null || err2.equals(""))
                            {
                                err2 = " ";
                            }
                        }

                        Log.e(TAG, "get url check failure, code:" + statusCode + ", errorResponse:" + err2 + " e:" + err);
                        UnityPlayer.UnitySendMessage(uTool.SDK, "LoginFail", err);
                    }
                });

            }
            catch (Exception e)
            {
                String err = e.getMessage();
                if (err == null || err.equals(""))
                {
                    err = " ";
                }
                Log.e(TAG, "SDK login success but get url error" + err);
                UnityPlayer.UnitySendMessage(uTool.SDK, "LoginFail", err);
            }
        }
        else
        {
            UnityPlayer.UnitySendMessage(uTool.SDK, "LoginFail", Integer.toString(code));
            Log.e(TAG, "SDK login failure, code:" + code);
        }
    }
}
