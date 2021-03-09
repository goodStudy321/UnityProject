/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/10/13 0:05:33
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
    /// AssetMfSizeInfo
    /// </summary>
    [Serializable]
    public class AssetMfSizeInfo : IComparable<AssetMfSizeInfo>, IComparer<AssetMfSizeInfo>
    {
        #region 字段
        /// <summary>
        /// 资源名
        /// </summary>
        public string name = "";

        /// <summary>
        /// 左侧大小
        /// </summary>
        public int lhsSize = 0;

        /// <summary>
        /// 右侧大小
        /// </summary>
        public int rhsSize = 0;

        /// <summary>
        /// 右侧-左侧不同大小
        /// </summary>
        public int difSize = 0;

        /// <summary>
        /// 不同大小的字符串
        /// </summary>
        public string difSizeStr = "";
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
        public void OnGUI(Object obj)
        {
            EditorGUILayout.TextField(name);
            EditorGUILayout.LabelField(lhsSize.ToString(), UIOptUtil.btn);
            EditorGUILayout.LabelField(rhsSize.ToString(), UIOptUtil.btn);
            EditorGUILayout.LabelField(difSize.ToString(), UIOptUtil.btn);
            EditorGUILayout.LabelField(difSizeStr, UIOptUtil.btn);
            if (GUILayout.Button("定位", UIOptUtil.btn)) Ping();
        }
        #endregion

        #region 公开方法
        public void Set(string name, int lSize, int rSize)
        {
            this.name = name;
            lhsSize = lSize;
            rhsSize = rSize;
            difSize = rSize - lSize;
            if (difSize < 0) difSize = -difSize;
            difSizeStr = ByteUtil.GetSizeStr(difSize);
        }

        public void Ping()
        {
            var paths = AssetDatabase.GetAssetPathsFromAssetBundle(name);
            if (paths == null || paths.Length < 1)
            {
                UIEditTip.Error("{0} 不存在", name);
            }
            else if (paths.Length == 1)
            {
                EditUtil.Ping(paths[0]);
            }
            else
            {
                var objs = new List<Object>();
                int length = paths.Length;
                for (int i = 0; i < length; i++)
                {
                    var path = paths[i];
                    var obj = AssetDatabase.LoadAssetAtPath<Object>(path);
                    if (obj == null) continue;
                    objs.Add(obj);
                }
                string msg = null;
                if (objs.Count > 0)
                {
                    msg = string.Format("有{0}个资源打包成:{1},已打开定位面板", paths.Length, name);
                    ObjsWin.Open(objs);
                }
                else
                {
                    msg = string.Format("{0} 不存在", name);
                }
                UIEditTip.Log(msg);
            }
        }

        public int CompareTo(AssetMfSizeInfo other)
        {
            return Compare(this, other);
        }

        public int Compare(AssetMfSizeInfo lhs, AssetMfSizeInfo rhs)
        {
            if (lhs.difSize < rhs.difSize) return 1;
            if (lhs.difSize > rhs.difSize) return -1;
            return 0;
        }
        #endregion
    }
}