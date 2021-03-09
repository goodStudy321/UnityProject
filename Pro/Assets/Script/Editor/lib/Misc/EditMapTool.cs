using System;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.2.23
    /// BG:地图工具
    /// </summary>
    public class EditMapTool : EditWinBase
    {

        #region 字段
        /// <summary>
        /// 菜单优先级
        /// </summary>
        public const int Pri = MenuTool.ScenePri + 1;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = MenuTool.Loong + "寻路地图工具/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = MenuTool.ALoong + "寻路地图工具/";
        #endregion

        #region 属性

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 打开寻路地图编辑器窗口
        /// </summary>
        [MenuItem(menu + "编辑 %#&m", false, Pri)]
        [MenuItem(AMenu + "编辑", false, Pri)]
        public static void Open()
        {
            WinUtil.Open<EditMapTool, EditMapView>("寻路地图编辑器", 600, 800);
        }
        #endregion
    }

    /// <summary>
    /// 编辑器地图数据
    /// </summary>
    public class EditMapView : EditViewBase
    {
        #region 字段
        [SerializeField]
        [HideInInspector]
        private int mapSize = 40;
        [SerializeField]
        [HideInInspector]
        private float nodeSize = 1;
        #endregion

        #region 属性

        #endregion

        #region 私有方法


        private void DrawSetting()
        {
            if (!UIEditTool.DrawHeader("地图设置", "MapSetting", "hostview")) return;
            EditorGUILayout.BeginVertical("box");
            UIEditLayout.IntSlider("地图尺寸:", ref mapSize, 5, 200, this);
            UIEditLayout.FloatField("节点大小: ", ref nodeSize, this);
            if (GUILayout.Button("创建新地图")) CreateNewMap();
            EditorGUILayout.EndVertical();
        }

        private void CreateNewMap()
        {

        }

        #endregion

        #region 保护方法
        /// <summary>
        /// 绘制
        /// </summary>
        protected override void OnGUICustom()
        {
            DrawSetting();
        }
        #endregion

        #region 公开方法

        #endregion
    }
}
