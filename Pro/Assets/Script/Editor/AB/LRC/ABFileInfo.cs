//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/3/28 23:20:14
//=============================================================================

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
    /// ABFileInfo
    /// </summary>
    [Serializable]
    public class ABFileInfo : IComparable<ABFileInfo>, IComparer<ABFileInfo>
    {
        #region 字段
        /// <summary>
        /// AB名称
        /// </summary>
        public string abName = "";

        /// <summary>
        /// 资源路径
        /// </summary>
        public List<string> assetPaths = null;

        [SerializeField]
        private long diskUsage = 0;

        private string diskUsageStr = null;

        #endregion

        #region 属性

        /// <summary>
        /// 磁盘占用大小
        /// </summary>
        public long DiskUsage
        {
            get { return diskUsage; }
            set
            {
                diskUsage = value;
                diskUsageStr = ByteUtil.GetSizeStr(diskUsage);
            }
        }
        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void SetDiskUsageStr()
        {
            diskUsageStr = ByteUtil.GetSizeStr(diskUsage);
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public int CompareTo(ABFileInfo other)
        {
            return diskUsage.CompareTo(other.diskUsage);
        }

        public int Compare(ABFileInfo lhs, ABFileInfo rhs)
        {
            return lhs.CompareTo(rhs);
        }

        public void OnGUI(Object o)
        {
            EditorGUILayout.BeginVertical(StyleTool.Group);
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.TextField(abName);
            if (diskUsageStr == null) SetDiskUsageStr();
            EditorGUILayout.LabelField(diskUsageStr, UIOptUtil.btn);
            EditorGUILayout.EndHorizontal();
            if (assetPaths.Count > 0)
            {
                EditorGUILayout.BeginVertical();
                EditorGUILayout.LabelField("工程内依赖资源:");
                int length = assetPaths.Count;
                for (int i = 0; i < length; i++)
                {
                    EditorGUILayout.TextField(assetPaths[i]);
                }
                EditorGUILayout.EndVertical();
            }
            EditorGUILayout.EndVertical();
        }
        #endregion
    }
}