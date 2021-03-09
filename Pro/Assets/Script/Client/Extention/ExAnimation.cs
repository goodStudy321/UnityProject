#if UNITY_EDITOR
using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.10.25
    /// BG:动画组件扩展工具
    /// </summary>
    public static class ExAnimation
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
        /// 获取所有动画剪辑名称的字符串数组
        /// </summary>
        /// <param name="anim"></param>
        /// <returns></returns>
        public static string[] GetNames(this Animation anim)
        {
            int count = anim.GetClipCount();
            if (count == 0) return null;
            int index = 0;
            string[] names = new string[count];
            foreach (AnimationState item in anim)
            {
                names[index] = item.name;
                ++index;
            }
            return names;
        }
        #endregion
    }
}

#endif