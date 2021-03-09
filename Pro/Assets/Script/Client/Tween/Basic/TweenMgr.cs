using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.3.15
    /// BG:补间动画管理
    /// </summary>
    public static class TweenMgr
    {
        #region 字段

        private static List<TweenBase> lst = new List<TweenBase>();
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
        public static void Update()
        {
            if (lst.Count == 0) return;
            int beg = lst.Count - 1;
            for (int i = beg; i > -1; i--)
            {
                lst[i].Update();
            }
        }
        /// <summary>
        /// 添加
        /// </summary>
        /// <param name="value"></param>
        public static void Add(TweenBase value)
        {
            if (!lst.Contains(value))
            {
                lst.Add(value);
            }
        }

        /// <summary>
        /// 移除
        /// </summary>
        /// <param name="value"></param>
        public static void Remove(TweenBase value)
        {
            if (lst.Contains(value))
            {
                lst.Remove(value);
            }
        }

        /// <summary>
        /// 判断是否包含
        /// </summary>
        /// <param name="value"></param>
        /// <returns></returns>
        public static bool Contains(TweenBase value)
        {
            if (value == null) return false;
            if (lst.Count == 0) return false;
            return lst.Contains(value);
        }

        /// <summary>
        /// 释放
        /// </summary>
        public static void Dispose()
        {
            while (lst.Count != 0)
            {
                var last = lst.Count - 1;
                var item = lst[last];
                lst.RemoveAt(last);
                item.Stop();
            }
        }
        #endregion
    }
}