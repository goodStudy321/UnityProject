/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/6/19 19:29:52
 ============================================================================*/

using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// 内存工具
    /// </summary>
    public static class MemUtil
    {
        #region 字段
        /// <summary>
        /// 上一次可用内存
        /// </summary>
        private static int lastAvaiMem = 0;
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
        /// 内存快照
        /// </summary>
        /// <param name="des"></param>
        public static void Snap(string des = null)
        {
            if (string.IsNullOrEmpty(des))
            {
                des = "app";
            }
            int avaiMem = Device.Instance.AvaiMem;
            if (lastAvaiMem < 1)
            {
                iTrace.Log("Loong", string.Format("{0}, AvaiMem:{1}M", des, avaiMem));
            }
            else
            {
                int dif = 0;
                string str = null;
                if (avaiMem < lastAvaiMem)
                {
                    dif = lastAvaiMem - avaiMem;
                    str = " ,decreased:";
                }
                else
                {
                    dif = avaiMem - lastAvaiMem;
                    str = " ,increased:";
                }
                iTrace.Log("Loong", string.Format("{0}, AvaiMem:{1}M ,{2}{3}", des, avaiMem, str, dif));
            }
        }
        #endregion
    }
}