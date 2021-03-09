#if UNITY_EDITOR
using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.8.15
    /// BG:在场景绘制接口
    /// </summary>
    public interface IDrawScene
    {
        #region 属性

        #endregion

        #region 方法
        /// <summary>
        /// 绘制UI
        /// </summary>
        /// <param name="obj"></param>
        void OnSceneGUI(UnityEngine.Object obj);

        /// <summary>
        /// 在列表中被选择操作
        /// </summary>
        /// <param name="obj"></param>
        void OnSceneSelect(UnityEngine.Object obj);
        #endregion

        #region 索引器

        #endregion

        #region 事件

        #endregion
    }
}
#endif