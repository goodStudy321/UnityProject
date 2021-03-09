#if UNITY_EDITOR
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
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        32f2469a-7cbf-4bed-8c8f-cdbec471a22f
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/6/29 14:47:47
    /// BG:九宫格测试
    /// </summary>
    [AddComponentMenu("Loong/九宫格测试")]
    public class TestSceneGrid : TestMonoBase
    {
        #region 字段
        public string sceneGridName = "";
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void LoadSceneGridCallback(Object obj)
        {
            SceneGrid grid = obj as SceneGrid;
            iTrace.Log("Loong", string.Format("加载九宫格数据完成:{0}", grid.name));
            SceneGridMgr.Current = grid;
            grid.Target = Player.Instance.transform;
            SceneGridMgr.Start();
        }

        private void LoadSceneGrid()
        {
            if (string.IsNullOrEmpty(sceneGridName))
            {
                iTrace.Error("Loong", "场景九宫格资源名称为空");
            }
            else
            {
                AssetMgr.Instance.Load(sceneGridName, Suffix.Asset, LoadSceneGridCallback);
            }
        }
        #endregion

        #region 保护方法
        protected override void OnGUICustom()
        {
            if (SceneGridMgr.Running) return;
            if (Player.Instance == null) return;
            if (Player.Instance.transform == null) return;
            GUILayout.FlexibleSpace();
            if (GUILayout.Button("开始九宫格", btnOpts))
            {
                LoadSceneGrid();
            }
        }
        #endregion

        #region 公开方法

        #endregion
        #region 编辑器
#if UNITY_EDITOR
        public override void OnInspectorGUI()
        {
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.TextField("九宫格配置资源名称:", ref sceneGridName, this);
            if (string.IsNullOrEmpty(sceneGridName))
            {
                UIEditLayout.HelpError("不能为空");
            }
            EditorGUILayout.EndVertical();
        }
#endif
        #endregion
    }
}
#endif