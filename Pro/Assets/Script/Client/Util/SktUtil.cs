/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2015/5/30 1:16:29
 ============================================================================*/

using System;
using System.Net.Sockets;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// Socket工具
    /// </summary>
    public static class SktUtil
    {
        #region 字段

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
        /// 判断Socket是否连接
        /// </summary>
        /// <param name="skt"></param>
        /// <returns></returns>
        public static bool IsConnect(Socket skt)
        {
            if (skt == null) return false;
            if (!skt.Connected) return false;
            bool connect = true;
            bool blockState = skt.Blocking;
            try
            {
                byte[] buf = new byte[1];
                skt.Blocking = false;
                skt.Send(buf, 0, 0);
            }
            catch (SocketException e)
            {
                if (e.NativeErrorCode != 10035)
                {
                    connect = false;
                }
            }
            catch (Exception)
            {
                connect = false;
            }
            finally
            {
                skt.Blocking = blockState;
            }
            return connect;
        }
        #endregion
    }
}