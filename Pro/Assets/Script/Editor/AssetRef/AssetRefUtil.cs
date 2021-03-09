/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/6/17 17:28:03
 ============================================================================*/

using System;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// 资源引用工具
    /// </summary>
    public static class AssetRefUtil
    {
        #region 字段

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
        /// 判断资源是否引用指定路径的资源
        /// </summary>
        /// <param name="obj">资源</param>
        /// <param name="refPath">引用路径</param>
        /// <returns></returns>
        public static bool Contains(Object obj, string refPath)
        {
            if (obj == null) return false;
            if (string.IsNullOrEmpty(refPath)) return false;
            string objPath = AssetDatabase.GetAssetPath(obj);
            if (string.IsNullOrEmpty(objPath)) return false;
            string[] depends = AssetDatabase.GetDependencies(objPath);
            if (depends == null || depends.Length < 1) return false;
            int length = depends.Length;
            for (int i = 0; i < length; i++)
            {
                if (depends[i] == refPath) return true;
            }
            return false;
        }

        public static bool Contains(Object obj, Object refObj)
        {
            if (refObj == null) return false;
            var path = AssetDatabase.GetAssetPath(refObj);
            return Contains(obj, path);
        }

        /// <summary>
        /// 在选择的资源中搜索引用指定资源的列表
        /// </summary>
        /// <param name="refObj">引用资源</param>
        /// <returns></returns>
        public static List<Object> SearchSelect(Object refObj)
        {
            if (refObj == null) return null;
            Object[] arr = SelectUtil.Get<Object>();
            if (arr == null) return null;
            string refPath = AssetDatabase.GetAssetPath(refObj);
            int length = arr.Length;
            List<Object> lst = null;
            for (int i = 0; i < length; i++)
            {
                var obj = arr[i];
                if (!Contains(obj, refPath)) continue;
                if (lst == null) lst = new List<Object>();
                lst.Add(obj);
            }
            return lst;
        }
        #endregion
    }
}