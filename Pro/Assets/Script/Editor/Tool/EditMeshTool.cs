using System;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        e35de171-1ccd-4fa0-87af-23e83b4ae01b
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/3/13 10:26:07
    /// BG:
    /// </summary>
    public class EditMeshTool
    {
        #region 字段
        /// <summary>
        /// 优先级
        /// </summary>
        public const int Pri = MenuTool.NormalPri + 11;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = MenuTool.Loong + "网格工具/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = MenuTool.ALoong + "网格工具/";
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
        /// 网格合并
        /// </summary>
        [MenuItem(menu + "合并", false, Pri)]
        [MenuItem(AMenu + "合并", false, Pri)]
        public static void Combine()
        {
            if (Selection.activeGameObject == null)
            {
                UIEditTip.Warning("没有选择任何游戏对象");
            }
            else
            {
                MeshTool.Combine(Selection.activeGameObject);
            }
        }

        /// <summary>
        /// 网格合并
        /// </summary>
        [MenuItem(menu + "直接合并", false, Pri + 1)]
        [MenuItem(menu + "直接合并", false, Pri + 1)]
        public static void SetShareMat()
        {
            if (Selection.activeGameObject == null)
            {
                UIEditTip.Warning("没有选择任何游戏对象");
            }
            else
            {
                StaticBatchingUtility.Combine(Selection.activeGameObject);
            }
        }


        #endregion
    }
}