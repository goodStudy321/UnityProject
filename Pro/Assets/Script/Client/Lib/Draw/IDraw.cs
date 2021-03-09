//=============================================================================
// Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2014.8.15 00:41:50
// 绘制接口
//=============================================================================

#if UNITY_EDITOR
using System.Collections;

namespace Loong.Game
{

    public interface IDraw
    {
        #region 属性

        #endregion

        #region 方法

        /// <summary>
        /// 绘制,并在集合中
        /// </summary>
        /// <param name="obj"></param>
        /// <param name="lst">所在集合</param>
        /// <param name="idx">所在集合索引</param>
        void Draw(UnityEngine.Object obj, IList lst, int idx);
        #endregion

        #region 索引器

        #endregion

        #region 事件

        #endregion
    }
}
#endif