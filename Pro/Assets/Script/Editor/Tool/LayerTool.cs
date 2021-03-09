using System;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;
using LT = Loong.Game.LayerTool;
using Object = UnityEngine.Object;


namespace Loong.Edit
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        a946c807-5143-4d38-98fe-9314ab5c0214
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/11/15 12:06:29
    /// BG:编辑器层级工具
    /// </summary>
    public static class LayerTool
    {
        #region 字段
        /// <summary>
        /// 优先级
        /// </summary>
        public const int Pri = MenuTool.NormalPri + 45;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = MenuTool.Loong + "层级工具/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = MenuTool.ALoong + "层级工具/";
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
        /// 删除选择对象
        /// </summary>
        [MenuItem(menu + "设置特效层级", false, Pri + 1)]
        [MenuItem(AMenu + "设置特效层级", false, Pri + 1)]
        public static void SetFxEffect()
        {
            Object[] gos = SelectUtil.Get<Object>(SelectionMode.DeepAssets, Suffix.Prefab);
            if (gos == null || gos.Length == 0) return;
            float length = gos.Length;
            for (int i = 0; i < length; i++)
            {
                var go = gos[i] as GameObject;
                if (go == null) continue;
                string name = go.name.ToLower();
                float pro = i / length;
                if (name.StartsWith("fx"))
                {
                    EditorUtility.DisplayProgressBar("设置层级", go.name, pro);
                    LT.Set(go.transform, LT.FX);
                }
                else
                {
                    EditorUtility.DisplayProgressBar("无效特效", go.name, pro);
                }
            }
            EditorUtility.ClearProgressBar();
        }
        #endregion
    }
}