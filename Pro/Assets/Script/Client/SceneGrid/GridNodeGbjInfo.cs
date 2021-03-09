using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.8.10
    /// BG:场景九宫格游戏对象信息
    /// 目的是通过位置将游戏对象放在指定位置的九宫格中
    /// </summary>
    [Serializable]
    public class GridNodeGbjInfo : VectorInfo
#if UNITY_EDITOR
        , IDraw
#endif
    {
        #region 字段
        [SerializeField]
        private string path = "";

        #endregion

        #region 属性

        /// <summary>
        /// 路径
        /// </summary>
        public string Path
        {
            get { return path; }
            set { path = value; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public GridNodeGbjInfo()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        #endregion

#if UNITY_EDITOR
        public void Draw(Object obj, IList lst, int idx)
        {
            UIEditLayout.TextField("路径:", ref path, obj);
            UIEditLayout.Vector3Field("位置:", ref pos, obj);
        }

        public override void OnSceneGUI(Object obj)
        {
            Vector3 namePos = pos + Vector3.one;
            Handles.Label(namePos, path);
        }

        public override void OnSceneContext<T>(Object obj, List<T> lst, int index)
        {
            GenericMenu menu = new GenericMenu();
            GenericMenu.MenuFunction2 func2 = (o) =>
            {
                EditUtil.RegisterUndo("DeletePoint", obj);
                lst.RemoveAt(index);
            };
            menu.AddItem(new GUIContent("删除"), false, func2, obj);
            menu.ShowAsContext();
        }
#endif
    }
}