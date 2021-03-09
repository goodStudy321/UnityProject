package phantom.lib;
//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/2/23 16:23
// SDK信息
//=============================================================================

import com.unity3d.player.UnityPlayer;

import prj.chameleon.channelapi.ChannelInterface;

public final class Sdk
{
    /**
     * 未初始化
     */
    public static final int INIT_NONE = 0;

    /**
     * 初始化成功
     */
    public static final int INIT_SUC = 1;

    /**
     * 初始化失败
     */
    public static final int INIT_FAIL = 2;

    /**
     * 初始化结果
     */
    private static int initOp = INIT_NONE;

    /**
     * true:可以发送初始化事件
     */
    private static boolean canSendInit = false;

    /**
     * true:已经发送初始化事件
     */
    private static boolean hasSendInit = false;

    /**
     * 获取初始化结果
     *
     * @return
     */
    public static int getInitOp()
    {
        return initOp;
    }

    /**
     * 设置初始化结果
     *
     * @param op
     */
    public static void setInitOp(int op)
    {
        initOp = op;
    }

    /**
     * 获取渠道信息
     *
     * @return
     */
    public static String getChannelInfo()
    {
        final String channel_id = ChannelInterface.getChannelID();
        final String game_channel_id = ChannelInterface.getGameChannelId();
        String arg = channel_id + "|" + game_channel_id;
        return arg;
    }

    /**
     * 设置能发送
     */
    public static void setCanSendInit()
    {
        canSendInit = true;
        if (initOp == INIT_SUC)
        {
            sendInitSuc();
        }
        else if (initOp == INIT_FAIL)
        {
            sendInitFail();
        }
    }

    public static boolean getCanSendInit()
    {
        return canSendInit;
    }

    public static void sendInitSuc()
    {
        if (hasSendInit) return;
        hasSendInit = true;
        String arg = getChannelInfo();
        UnityPlayer.UnitySendMessage(uTool.SDK, "InitSuc", arg);
    }

    public static void sendInitFail()
    {
        if (hasSendInit) return;
        hasSendInit = true;
        UnityPlayer.UnitySendMessage(uTool.SDK, "InitFail", "");
    }
}
