using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.8.10
    /// BG:场景九宫格数据监视
    /// </summary>
    [CustomEditor(typeof(SceneGrid))]
    public class SceneGridInspector : Editor
    {
        #region 字段
        private SceneGrid sceneGrid = null;
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void OnEnable()
        {
            sceneGrid = target as SceneGrid;
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public override void OnInspectorGUI()
        {
            GUI.enabled = false;
            sceneGrid.DrawBasic();
            sceneGrid.DrawNodes();
            GUI.enabled = true;
        }
        #endregion
    }
}