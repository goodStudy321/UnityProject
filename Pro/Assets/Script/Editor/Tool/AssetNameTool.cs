using System;
using System.IO;
using System.Text;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.4.9
    /// BG:资源名称工具
    /// </summary>
    public static class AssetNameTool
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
        /// 获取唯一的对象名称
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="lst">对象列表</param>
        /// <param name="name">名称</param>
        /// <returns></returns>
        public static string GetUnique<T>(List<T> lst, string name) where T : Object
        {
            int index = 0;
            bool unique = true;
            string newName = string.Empty;
            StringBuilder temp = new StringBuilder();
            while (true)
            {
                temp.Remove(0, temp.Length);
                temp.Append(name).Append(index);
                newName = temp.ToString();
                unique = CheckUnique(lst, newName);
                if (unique) { return newName; }
                unique = true;
                index++;
            }
        }

        /// <summary>
        /// 检查新名称在对象列表中是否是唯一的
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="lst">对象列表</param>
        /// <param name="newName">新名称</param>
        /// <returns></returns>
        public static bool CheckUnique<T>(List<T> lst, string newName) where T : Object
        {
            int length = lst.Count;
            for (int i = 0; i < length; i++)
            {
                if (newName.Equals(lst[i].name)) return false;
            }
            return true;
        }

        /// <summary>
        /// 在指定资源目录下获取唯一资源名称
        /// </summary>
        /// <param name="assetDir">资源目录</param>
        /// <param name="assetName">资源名称</param>
        /// <returns></returns>
        public static string GetUniqueName(string assetDir, string assetName)
        {
            StringBuilder sb = new StringBuilder();
            string fileName = string.Empty;
            int i = 0;
            while (true)
            {
                fileName = assetName + i.ToString().PadLeft(3, '0');
                sb.Append(AssetPathUtil.CurDir);
                sb.Append(assetDir).Append("/");
                sb.Append(fileName).Append(".asset");
                string filePath = sb.ToString();
                if (!File.Exists(filePath)) { break; }
                else { sb.Remove(0, sb.Length); ++i; if (i > 1000) break; }
            }
            return fileName;
        }
        #endregion
    }
}