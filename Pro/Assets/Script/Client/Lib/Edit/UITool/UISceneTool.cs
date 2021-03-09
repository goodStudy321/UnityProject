#if UNITY_EDITOR
using System;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM::2014.10.16
    /// BG:编辑器场景视图绘制工具
    /// </summary>
    public static class UISceneTool
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 场景视图中绘制IDrawScene接口列表
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="obj">列表所在对象</param>
        /// <param name="lst">IDrawScene接口列表</param>
        /// <param name="select">选择项,绘制接口OnSceneSelect</param>
        public static void Draw<T>(Object obj, List<T> lst, int select, Color color) where T : IDrawScene
        {
            if (obj == null) return;
            if (lst == null) return;
            int length = lst.Count;
            if (length == 0) return;
            Color oriColor = Handles.color;
            Handles.color = color;
            for (int i = 0; i < length; i++)
            {
                IDrawScene draw = lst[i];
                draw.OnSceneGUI(obj);
                if (select != i) continue;
                draw.OnSceneSelect(obj);
            }
            Handles.color = oriColor;
        }
        #endregion
    }
}
#endif