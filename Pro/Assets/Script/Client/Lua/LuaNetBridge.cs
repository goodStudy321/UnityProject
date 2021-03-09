using System;
using UnityEngine;
using LuaInterface;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2018-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        c8472059-425b-4be6-846e-628bb3a66f47
    */

    /// <summary>
    /// AU:Loong
    /// TM:2018/4/19 16:22:50
    /// BG:lua协议传输数据
    /// </summary>
    public static class LuaNetBridge
    {
        #region 字段
        /// <summary>
        /// 发送数据
        /// </summary>
        [LuaByteBuffer]
        public static byte[] sendBytes = null;

        /// <summary>
        /// 接受数据
        /// </summary>
        [LuaByteBuffer]
        public static byte[] recvBytes = null;
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 发送lua传送的数据
        /// </summary>
        /// <param name="id"></param>
        public static void Send(ushort id)
        {
            if (sendBytes == null) return;
            NetworkClient.Send(id, sendBytes);
            sendBytes = null;
        }

        /// <summary>
        /// 传递接受到的数据到lua
        /// </summary>
        /// <param name="id"></param>
        /// <param name="bytes"></param>
        [NoToLua]
        public static void Execute(ushort id, byte[] bytes)
        {
            if (bytes == null) return;
            recvBytes = bytes;
            EventMgr.Trigger("RecvLuaData", id);
            recvBytes = null;
        }
        #endregion
    }
}