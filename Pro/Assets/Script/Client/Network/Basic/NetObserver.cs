/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.4.26 22:38:16
 * 网络状态发生改变时,会触发change事件
 ============================================================================*/

using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;


namespace Loong.Game
{

    using UApp = Application;
    using NRB = NetworkReachability;

    /// <summary>
    /// 网络观察者
    /// </summary>
    public static class NetObserver
    {
        #region 字段
        /// <summary>
        /// 上次网络类型
        /// </summary>
        private static NRB last;

        /// <summary>
        /// 当前网络类型
        /// </summary>
        private static NRB cur;

        #endregion

        #region 属性
        /// <summary>
        /// 当前网络类型
        /// </summary>
        public static NRB Cur
        {
            get { return cur; }
        }

        #endregion

        #region 事件
        /// <summary>
        /// 网络类型发生改变时的事件 参数 <旧网络类型,当前网络类型>
        /// </summary>
        public static event Action<NRB, NRB> change = null;
        #endregion

        #region 构造方法
        static NetObserver()
        {
            last = Application.internetReachability;
            cur = Application.internetReachability;
        }
        #endregion

        #region 私有方法


        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static void Update()
        {
            cur = Application.internetReachability;
            if (last == cur) return;
            if (change != null)
            {
                change(last, cur);
				EventMgr.Trigger("NetChange", (int)last, (int)cur);
#if GAME_DEBUG
                iTrace.Warning("Loong", string.Format("nettype changed,before:{0},now:{1}", last, cur));
#endif
            }
            last = cur;
        }

        /// <summary>
        /// 移动数据
        /// </summary>
        /// <returns></returns>
        public static bool IsCarrier()
        {
            return (cur == NRB.ReachableViaCarrierDataNetwork);
        }

        /// <summary>
        /// 无网络
        /// </summary>
        /// <returns></returns>
        public static bool NoNet()
        {
            return (cur == NRB.NotReachable);
        }

        #endregion
    }
}