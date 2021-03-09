/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2015/4/9 11:10:44
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using System.Text;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// My资源工具
    /// </summary>
    public static partial class iAssetUtil
    {
        #region 字段
        /// <summary>
        /// 菜单优先级
        /// </summary>
        public const int Pri = AssetUtil.Pri + 21;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = AssetUtil.menu + "My/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = AssetUtil.AMenu + "My/";

        /// <summary>
        /// 根目录
        /// </summary>
        public const string RootDir = "Assets/Editor/Loong/";

        /// <summary>
        /// 图标目录
        /// </summary>
        public const string IconDir = RootDir + "Icon/";

        /// <summary>
        /// GUI皮肤
        /// </summary>
        public const string SkinDir = RootDir + "Skin/";
        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private static string GetPath(string dir, string name)
        {
            if (string.IsNullOrEmpty(name)) return null;
            string path = string.Format("{0}{1}", dir, name);
            return path;
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 创建目录
        /// </summary>
        [MenuItem(menu + "创建目录", false, Pri)]
        [MenuItem(AMenu + "创建目录", false, Pri)]
        public static void Create()
        {
            string[] dirArr = new string[2];
            dirArr[0] = IconDir;
            dirArr[1] = SkinDir;
            StringBuilder sb = new StringBuilder();
            int length = dirArr.Length;
            for (int i = 0; i < length; i++)
            {
                string dir = dirArr[i];
                string fullDir = AssetPathUtil.GetFullPath(dir);
                sb.Append(dir);
                if (Directory.Exists(fullDir))
                {
                    sb.Append("已存在");
                }
                else
                {
                    sb.Append("已创建");
                    Directory.CreateDirectory(fullDir);
                }
            }
            AssetDatabase.Refresh();
        }

        /// <summary>
        /// 获取图标资源路径
        /// </summary>
        /// <param name="iconName">图标名称</param>
        /// <returns></returns>
        public static string GetIconPath(string iconName)
        {
            return GetPath(IconDir, iconName);
        }

        /// <summary>
        /// 加载Icon
        /// </summary>
        /// <param name="iconName">图标名称</param>
        /// <returns></returns>
        public static Texture2D LoadIcon(string iconName)
        {
            string path = GetIconPath(iconName);
            Texture2D tex = AssetDatabase.LoadAssetAtPath<Texture2D>(path);
            return tex;
        }

        /// <summary>
        /// 获取GUI皮肤路径
        /// </summary>
        /// <param name="skinName">GUI皮肤名称</param>
        /// <returns></returns>
        public static string GetSkinPath(string skinName)
        {
            return GetPath(SkinDir, skinName);
        }

        /// <summary>
        /// 加载GUI皮肤
        /// </summary>
        /// <param name="skinName">GUI皮肤名称</param>
        /// <returns></returns>
        public static GUISkin LoadSkin(string skinName)
        {
            string path = GetSkinPath(skinName);
            GUISkin skin = AssetDatabase.LoadAssetAtPath<GUISkin>(path);
            return skin;
        }


        #endregion
    }
}