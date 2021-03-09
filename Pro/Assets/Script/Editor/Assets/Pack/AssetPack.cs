/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/7/30 17:38:53
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Xml.Serialization;
using System.Collections.Generic;
using Object = UnityEngine.Object;
using Random = UnityEngine.Random;

namespace Loong.Edit
{
    /// <summary>
    /// AssetPack
    /// </summary>
    [Serializable]
    public class AssetPack : IDraw, IComparer<AssetPack>, IComparable<AssetPack>
    {
        #region 字段
        private AssetSet set = null;

        [SerializeField]
        [HideInInspector]
        private string key = "AssetPack";

        [SerializeField]
        [HideInInspector]
        private string key2 = "AssetPacks";

        [SerializeField]
        [HideInInspector]
        private string text = "分包";

        /// <summary>
        /// 包索引
        /// </summary>
        public int idx = 0;

        /// <summary>
        /// 总大小
        /// </summary>
        public float total = 0;

        /// <summary>
        /// 压缩后大小
        /// </summary>
        public float zipSize = 0;

        /// <summary>
        /// 模块列表
        /// </summary>
        [XmlArrayItem("mod")]
        public List<AssetMod> mods = new List<AssetMod>();
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public AssetPack()
        {

        }
        #endregion

        #region 私有方法

        private void SetTotal(Object obj)
        {
            var title = "统计路径";
            var pro = Random.Range(0.2f, 1f);
            ProgressBarUtil.Show(title, "", pro);
            var paths = GetPaths();
            var data = AssetDataUtil.Get<ABView>();
            var dir = (data == null ? "../Assets" : data.Output);
            dir = dir + "/" + EditUtil.GetPlatform();
            long lt = ABUtil.GetSize(dir, paths.ToArray());
            total = ByteUtil.GetMB(lt);
            zipSize = total * 0.4f;
            if (obj != null) EditorUtility.SetDirty(obj);
        }

        private void Added(int action)
        {
            if (set == null) return;
            int length = mods.Count;
            for (int i = 0; i < length; i++)
            {
                mods[i].Set(set);
            }
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 获取所有模块文件路径
        /// </summary>
        /// <returns></returns>
        public List<string> GetPaths()
        {
            var paths = new List<string>();
            float length = mods.Count;
            for (int i = 0; i < length; i++)
            {
                var mod = mods[i];
                var infos = mod.page.lst;
                for (int j = 0; j < infos.Count; j++)
                {
                    var info = infos[j];
                    var path = info.path;
                    if (paths.Contains(path)) continue;
                    paths.Add(path);
                }
            }
            return paths;
        }


        /// <summary>
        /// 获取依赖文件数组
        /// </summary>
        /// <returns></returns>
        public string[] GetDepends()
        {
            var paths = GetPaths();
            if (paths.Count < 1) return null;
            var depends = AssetDatabase.GetDependencies(paths.ToArray());
            return depends;
        }

        public void Draw(Object obj, IList lst, int idx)
        {
            if (!UIEditTool.DrawHeader(text, key, StyleTool.Host)) return;
            EditorGUILayout.BeginHorizontal(StyleTool.Group);
            UIEditLayout.IntField("包索引:", ref idx, obj, SetIdx);
            EditorGUILayout.Space();
            EditorGUILayout.LabelField("总大小(M):", total.ToString());
            EditorGUILayout.LabelField("压缩后大小(M,比率%42):", zipSize.ToString());
            if (GUILayout.Button("计算")) SetTotal(obj);
            EditorGUILayout.EndHorizontal();
            UIDrawTool.IDrawLst<AssetMod>(obj, mods, key2, "模块列表", changed: Added);
        }

        public void Init()
        {
            SetIdx();
        }

        public int CompareTo(AssetPack rhs)
        {
            return idx.CompareTo(rhs.idx);
        }

        public int Compare(AssetPack lhs, AssetPack rhs)
        {
            return lhs.CompareTo(rhs);
        }

        public void Sort()
        {
            int length = mods.Count;
            for (int i = 0; i < length; i++)
            {
                var mod = mods[i];
                mod.Sort();
            }
        }

        /// <summary>
        /// 校验
        /// </summary>
        /// <returns></returns>
        public bool Valid()
        {
            int length = mods.Count;
            bool valid = true;
            for (int i = 0; i < length; i++)
            {
                var mod = mods[i];
                if (mod.Valid()) continue;
                valid = false;
            }
            return valid;
        }


        public void Set(AssetSet set)
        {
            this.set = set;
            int length = mods.Count;
            for (int i = 0; i < length; i++)
            {
                mods[i].Set(set);
            }
        }

        public void SetIdx()
        {
            var name = this.GetType().Name;
            key = name + idx;
            key2 = key + "_2";
            text = (idx == 0 ? "首包" : string.Format("分包{0}", idx));
        }

        #endregion
    }
}