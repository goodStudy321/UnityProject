/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2015/4/27 11:20:17
 ============================================================================*/

using System;
using System.IO;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// AB名称改变监听
    /// </summary>
    public static class ABNameChanged
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
        /// 资源包名称发生改变处理
        /// </summary>
        /// <param name="assetPath">资源路径</param>
        /// <param name="oldName">旧名称</param>
        /// <param name="newName">新名称</param>
        public static void Change(string assetPath, string oldName, string newName)
        {
            if (string.IsNullOrEmpty(oldName)) return;
            if (!assetPath.StartsWith(EditSceneView.prefix)) return;
            AssetProcessor.Delete(oldName);
        }
        #endregion
    }
}