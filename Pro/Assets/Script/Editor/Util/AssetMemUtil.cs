/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/6/19 20:55:20
 ============================================================================*/

using System;
using UnityEditor;
using UnityEngine;
using System.Collections;
using UnityEngine.Profiling;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// 编辑器资源内存工具
    /// </summary>
    public static class AssetMemUtil
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
        /// 获取贴图的运行时内存大小
        /// </summary>
        /// <param name="ti">导入设置</param>
        /// <param name="obj">贴图资源</param>
        public static long GetTexMemSize(TextureImporter ti, Object tex)
        {
            if (tex == null) return 0;
            long size = Profiler.GetRuntimeMemorySizeLong(tex);
            //iTrace.Log("Loong", ti.assetPath + ", " + size);
            float factor = 1f / 3f;

            if (ti.mipmapEnabled)
            {
                //if (!ti.isReadable)
                {
                    size = (long)(size * (1 - factor) / (0.5f + factor));
                }
            }
            else
            {
                if (!ti.isReadable)
                {
                    size = (long)(size * 0.5f);
                }
            }
            return size;
        }

        /// <summary>
        /// 返回内存大小
        /// </summary>
        /// <returns></returns>
        public static long GetMemSize(Object obj)
        {
            if (obj == null) return 0;
            string path = AssetDatabase.GetAssetPath(obj);
            return GetMemSize(path, obj);
        }

        public static long GetMemSize(string path)
        {
            var obj = AssetDatabase.LoadAssetAtPath<Object>(path);
            return GetMemSize(path, obj);
        }

        /// <summary>
        /// 返回内存大小
        /// </summary>
        /// <param name="path">对象路径</param>
        /// <param name="obj">对象</param>
        /// <returns></returns>
        public static long GetMemSize(string path, Object obj)
        {
            if (obj == null) return 0L;
            if (string.IsNullOrEmpty(path)) return 0L;
            var size = 0L;
            var import = AssetImporter.GetAtPath(path);
            if (import is TextureImporter)
            {
                TextureImporter ti = import as TextureImporter;
                size = GetTexMemSize(ti, obj);
            }
            else
            {
                size = Profiler.GetRuntimeMemorySizeLong(obj);
            }
            return size;

        }
        #endregion
    }
}