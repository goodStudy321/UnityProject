/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/12/11 11:37:59
 ============================================================================*/

using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// 材质工具
    /// </summary>
    public static class MatUtil
    {
        #region 字段
        public const int Pri = AssetUtil.Pri + 100;

        public const string Menu = AssetUtil.menu + "材质工具/";

        public const string AMenu = AssetUtil.AMenu + "材质工具/";
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

        public static bool Add(List<Object> objs, GameObject go, HashSet<string> names, bool isProject)
        {
            if (go == null) return false;
            var renders = go.GetComponentsInChildren<Renderer>(true);
            if (renders == null) return false;
            int length = renders.Length;
            for (int i = 0; i < length; i++)
            {
                var render = renders[i];
                var mats = render.sharedMaterials;
                if (mats == null) continue;
                int matLen = mats.Length;
                for (int j = 0; j < matLen; j++)
                {
                    var mat = mats[j];
                    if (mat == null) continue;
                    if (names.Contains(mat.name.ToLower()))
                    {
                        if (isProject)
                        {
                            objs.Add(go);
                            return true;
                        }
                        else
                        {
                            objs.Add(render.gameObject);
                        }
                    }
                }
            }
            return false;
        }

        /// <summary>
        /// 搜索具有指定材质球集合的对象
        /// </summary>
        /// <param name="names">小写的名称集合</param>
        /// <returns></returns>
        public static List<Object> SearchSelect(HashSet<string> names)
        {
            var type = (AssetType)(1 << (int)AssetType.Prefab | 1 << (int)AssetType.Model);
            var gos = SelectUtil.Get<GameObject>(type);
            if (gos == null) return null;
            float length = gos.Count;
            var objs = new List<Object>();
            var title = "搜索材质";
            for (int i = 0; i < length; i++)
            {
                var go = gos[i];
                ProgressBarUtil.Show(title, go.name, i / length);
                var path = AssetDatabase.GetAssetPath(go);
                bool isProject = (string.IsNullOrEmpty(path) ? false : true);
                Add(objs, go, names, isProject);

            }

            ProgressBarUtil.Clear();
            return objs;

        }
        #endregion
    }
}