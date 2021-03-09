/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/9/20 18:16:03
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    using Object = UnityEngine.Object;

    /// <summary>
    /// 模型工具
    /// </summary>
    public static class ModUtil
    {
        #region 字段
        /// <summary>
        /// 菜单优先级
        /// </summary>
        public const int Pri = MenuTool.AssetPri + 30;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = AssetProcessor.menu + "模型/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = AssetProcessor.AMenu + "模型/";

        public const string defaultMatName = "Default-Material";


        #endregion

        #region 属性
        private static Material defaultMat;

        public static Material DefaultMat
        {
            get
            {
                if (defaultMat == null)
                {
                    defaultMat = AssetDatabase.LoadAssetAtPath<Material>("Assets/DefaultMat.mat");
                }
                return defaultMat;
            }
        }

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
        /// 设置对应平台格式图标
        /// </summary>
        [MenuItem(menu + "移除默认材质球", false, Pri + 1)]
        [MenuItem(AMenu + "移除默认材质球", false, Pri + 1)]
        public static void RemoveDefaultMatWithDialog()
        {
            DialogUtil.Show("", "移除默认材质球?", RemoveDefaultMat);
        }


        public static void RemoveDefaultMat(GameObject go)
        {
            if (go == null) return;
            var renders = go.GetComponentsInChildren<Renderer>();
            if (renders == null) return;
            int length = renders.Length;
            for (int i = 0; i < length; i++)
            {
                var rd = renders[i];
                if (rd.sharedMaterial.name != defaultMatName) continue;
                var matLen = rd.sharedMaterials.Length;
                rd.sharedMaterials = new Material[1];
                EditorUtility.SetDirty(go);
            }
        }

        /// <summary>
        /// 移除默认材质球
        /// </summary>
        public static void RemoveDefaultMat()
        {
            var objs = SelectUtil.Get<Object>();
            var title = "处理中···";
            float length = objs.Length;
            for (int i = 0; i < length; i++)
            {
                var obj = objs[i];
                var path = AssetDatabase.GetAssetPath(obj);
                if (string.IsNullOrEmpty(path)) continue;
                var sfx = Path.GetExtension(path).ToLower();
                if (sfx != Suffix.Fbx) continue;

                ProgressBarUtil.Show(title, path, i / length);
                var go = obj as GameObject;
                RemoveDefaultMat(go);
                /*var opt = ImportAssetOptions.ImportRecursive | ImportAssetOptions.ForceUpdate;
                AssetDatabase.ImportAsset(path, opt);*/
            }

            ProgressBarUtil.Clear();
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
        }
        #endregion
    }
}