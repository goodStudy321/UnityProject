/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/6/18 15:46:33
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// 图集引用工具
    /// </summary>
    public static class AtlasUtil
    {
        #region 字段
        public const int Pri = NGUIUtil.Pri + 20;

        public const string Menu = NGUIUtil.menu + "图集/";

        public const string AMenu = NGUIUtil.AMenu + "图集/";
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

        public static void Search(GameObject go, UIAtlas atlas, List<Object> objs, string spriteName)
        {
            if (go == null) return;
            if (objs == null) return;
            if (atlas == null) return;

            var arr = go.GetComponentsInChildren<UISprite>(true);
            if (arr == null) return;
            int length = arr.Length;
            for (int i = 0; i < length; i++)
            {
                var it = arr[i];
                if (Object.ReferenceEquals(it.atlas, atlas))
                {
                    if (spriteName == null)
                    {
                        objs.Add(it.gameObject);
                    }
                    else if (it.spriteName.Equals(spriteName))
                    {
                        objs.Add(it.gameObject);
                    }
                }
            }
        }

        public static List<Object> Search(UIAtlas atlas, string spriteName, bool defaultUIRoot = true)
        {

            if (atlas == null) return null;
            GameObject[] arr = null;
            if (defaultUIRoot)
            {
                var go = GameObject.Find("UI Root");
                if (go == null)
                {
                    arr = SelectUtil.Get<GameObject>();
                }
                else
                {
                    arr = new GameObject[] { go };
                }
            }
            else
            {
                arr = SelectUtil.Get<GameObject>();
            }
            if (arr == null) return null;
            float length = arr.Length;
            var sn = (string.IsNullOrEmpty(spriteName) ? "无" : spriteName);
            var title = string.Format("搜索图集:{0}, 精灵:{1}", atlas.name, sn);
            var lst = new List<Object>();
            for (int i = 0; i < length; i++)
            {
                var go = arr[i];
                ProgressBarUtil.Show(title, go.name, i / length);
                Search(go, atlas, lst, spriteName);
            }
            ProgressBarUtil.Clear();
            return lst;
        }


        /// <summary>
        /// 在选择的资源中搜索引用指定资源的列表
        /// </summary>
        /// <param name="atlas">引用图集</param>
        /// <returns></returns>
        public static List<Object> SearchSelect(UIAtlas atlas, bool defaultUIRoot = true)
        {
            return Search(atlas, null, defaultUIRoot);
        }

        /// <summary>
        /// 搜索指定目录的图集
        /// </summary>
        /// <param name="assetDir">目录</param>
        /// <returns></returns>
        public static List<UIAtlas> Search(string assetDir)
        {
            var curDir = Directory.GetCurrentDirectory();
            var fullDir = Path.Combine(curDir, assetDir);
            var lst = AssetQueryUtil.GetComponents<UIAtlas>(fullDir, false);
            return lst;
        }

        public static List<T> Search<T>(List<UIAtlas> atlases, string spriteName) where T : Object
        {
            if (atlases == null) return null;
            if (string.IsNullOrEmpty(spriteName)) return null;
            List<T> dest = null;
            var name = spriteName.ToLower();
            int length = atlases.Count;
            for (int i = 0; i < length; i++)
            {
                var atlas = atlases[i];
                var sprites = atlas.spriteList;
                if (sprites == null) continue;
                int spriteLen = sprites.Count;
                for (int j = 0; j < spriteLen; j++)
                {
                    var spData = sprites[j];
                    var spName = spData.name.ToLower();
                    if (spName != name) continue;
                    if (dest == null) dest = new List<T>();
                    T t = atlas as T;
                    dest.Add(t);
                    break;
                }
            }
            return dest;
        }

        public static List<Object> Search(Texture tex, bool defaultUIRoot = true)
        {
            if (tex == null) return null;
            GameObject[] arr = null;
            if (defaultUIRoot)
            {
                var go = GameObject.Find("UI Root");
                if (go == null)
                {
                    arr = SelectUtil.Get<GameObject>();
                }
                else
                {
                    arr = new GameObject[] { go };
                }
            }
            else
            {
                arr = SelectUtil.Get<GameObject>();
            }
            if (arr == null) return null;
            
            float length = arr.Length;
            var title = string.Format("搜索图片引用:{0}", tex.name);
            var lst = new List<Object>();
            for (int i = 0; i < length; i++)
            {
                var go = arr[i];
                ProgressBarUtil.Show(title, go.name, i / length);
                Search(go, tex, lst);
            }
            ProgressBarUtil.Clear();
            return lst;
        }

        public static void Search(GameObject go, Texture tex, List<Object> objs)
        {
            if (go == null) return;
            if (objs == null) return;
            if (tex == null) return;

            var arr = go.GetComponentsInChildren<UITexture>(true);
            if (arr == null) return;
            int length = arr.Length;
            for (int i = 0; i < length; i++)
            {
                var it = arr[i];
                if (Object.ReferenceEquals(it.mainTexture, tex))
                {
                    objs.Add(it.gameObject);
                }
            }
        }
        #endregion
    }
}