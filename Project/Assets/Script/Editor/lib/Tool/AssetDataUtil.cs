using Hello.Game;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

namespace Hello.Edit
{
    public static partial class AssetDataUtil
    {
        /// <summary>
        /// 编辑器资源文件存放根目录路径
        /// </summary>
        public const string RootDir = "Assets/Script/Editor/Asset/";

        /// <summary>
        /// 获取资源路径
        /// </summary>
        /// <param name="name">资源名称</param>
        /// <param name="parentFolder">父文件夹</param>
        /// <returns></returns>
        public static string GetPath(string name, string parentFolder = "")
        {
            string path = null;
            if (string.IsNullOrEmpty(parentFolder))
            {
                path = string.Format("{0}{1}{2}", RootDir, name, Suffix.Asset);
            }
            else
            {
                path = string.Format("{0}{1}/{2}{3}", RootDir, parentFolder, name, Suffix.Asset);
            }
            return path;
        }

        /// <summary>
        /// 在指定路径创建指定类型的资源
        /// </summary>
        /// <typeparam name="T">类型</typeparam>
        /// <param name="path">路径</param>
        /// <returns></returns>
        public static T Create<T>(string path) where T : ScriptableObject
        {
            T t = ScriptableObject.CreateInstance<T>();
            if (t == null)
            {
                for (int i = 0; i < 8; i++)
                {
                    t = ScriptableObject.CreateInstance<T>();
                    if (t != null) break;
                }
            }
            t.hideFlags = HideFlags.None | HideFlags.NotEditable;
            AssetDatabase.CreateAsset(t, path);
            AssetDatabase.SaveAssets();
            t = AssetDatabase.LoadAssetAtPath<T>(path);

            return t;
        }

        /// <summary>
        /// 获取指定类型的资源
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="parentFolder">父文件夹</param>
        /// <returns></returns>
        public static T Get<T>(string parentFolder = "") where T : ScriptableObject
        {
            return Get<T>(typeof(T).Name, parentFolder);
        }


        /// <summary>
        /// 通过类型名称获取指定类型的资源
        /// </summary>
        /// <typeparam name="T">类型</typeparam>
        /// <param name="name">类型名称</param>
        /// <param name="parentFolder">父文件夹</param>
        /// <returns></returns>
        public static T Get<T>(string name, string parentFolder = "") where T : ScriptableObject
        {
            string path = GetPath(name, parentFolder);
            string fullPath = string.Format("{0}/{1}", Directory.GetCurrentDirectory(), path);
            FileTool.CheckDir(fullPath);
            T t = null;
            if (!File.Exists(fullPath))
            {
                t = Create<T>(path);
            }
            else
            {
                t = AssetDatabase.LoadAssetAtPath<T>(path);
                if (t == null)
                {
                    AssetDatabase.DeleteAsset(path);
                    AssetDatabase.Refresh();
                    t = Create<T>(path);
                }
            }
            return t;
        }
    }
}

