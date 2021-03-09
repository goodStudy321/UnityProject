/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/5/30 23:18:27
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
    /// AssetQueryView
    /// </summary>
    public class AssetQueryView : EditViewBase
    {
        #region 字段
        /// <summary>
        /// 资源类型选项
        /// </summary>
        public int op = 1 << (int)AssetType.Prefab;

        /// <summary>
        /// 排序类型选项
        /// </summary>
        public int sortOp = 0;

        /// <summary>
        /// 包含依赖
        /// </summary>
        public bool containDepends = true;

        private string totalMemStr = "";

        private string totalDiskStr = "";

        private Vector2 detailScroll = Vector2.zero;

        [SerializeField]
        private List<AssetDetailInfo> details = null;


        private string[] sortTypes = new string[] { "运行内存", "磁盘占用", "名称" };

        private GUILayoutOption[] opts = new GUILayoutOption[] { GUILayout.Width(100) };

        private GUILayoutOption[] textOpts = new GUILayoutOption[] { GUILayout.Width(200) };
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public AssetQueryView()
        {

        }
        #endregion

        #region 私有方法
        private void SetObjs()
        {
            AssetType type = (AssetType)op;
            AssetSortType sortType = (AssetSortType)sortOp;
            SelectionMode mode = containDepends ? SelectionMode.DeepAssets : SelectionMode.Assets;
            details = AssetQueryUtil.SearchDetail(type, sortType, mode);
            long totalMem = 0;
            long totalDisk = 0;
            int length = details.Count;
            for (int i = 0; i < length; i++)
            {
                var it = details[i];
                totalMem += it.MemUsage;
                totalDisk += it.DiskUsage;
            }
            totalMemStr = EditorUtility.FormatBytes(totalMem);
            totalDiskStr = EditorUtility.FormatBytes(totalDisk);
        }
        #endregion

        #region 保护方法
        protected override void OnGUICustom()
        {
            if (UIEditTool.DrawHeader("注意事项", "AssetQueryViewNotice", StyleTool.Host))
            {
                UIEditLayout.HelpWaring("贴图如果勾选了MiniMap,实际运行内存会比不勾选多1/3");
                UIEditLayout.HelpWaring("未勾选Read/Write的贴图,在profiler中运行内存会比Inspector中显示多100%,发布后是原大小;若勾选,内存占用一定多一倍");
                UIEditLayout.HelpWaring("若贴图同时勾选MiniMap和Read/Write,对于运行内存的计算可能不准确!");
                UIEditLayout.HelpWaring("磁盘占用仅仅是文件占用的磁盘大小,并不是打包后的占用磁盘大小");
            }
            EditorGUILayout.BeginVertical(StyleTool.Box);
            EditorGUILayout.BeginHorizontal(StyleTool.Group);
            UIEditLayout.MaskField("资源类型:", ref op, AssetQueryUtil.typeNames, this);
            EditorGUILayout.Space();
            UIEditLayout.Popup("排序类型:", ref sortOp, sortTypes, this);
            EditorGUILayout.Space();
            UIEditLayout.Toggle("包含依赖:", ref containDepends, this);
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.BeginHorizontal(StyleTool.Group);
            EditorGUILayout.IntField("总数:", details == null ? 0 : details.Count);
            EditorGUILayout.Space();
            EditorGUILayout.LabelField("总磁盘占用:", totalDiskStr);
            EditorGUILayout.Space();
            EditorGUILayout.LabelField("总内存占用:", totalMemStr);
            if (GUILayout.Button("搜集", opts))
            {
                SetObjs();
            }
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.EndVertical();


            EditorGUILayout.Space();

            if (details == null || details.Count < 1)
            {
                UIEditLayout.HelpWaring("无");
                return;
            }

            EditorGUILayout.BeginHorizontal(StyleTool.Box);
            EditorGUILayout.LabelField("索引:", opts);
            EditorGUILayout.LabelField("名称:", textOpts);
            EditorGUILayout.LabelField("后缀:", opts);
            EditorGUILayout.LabelField("磁盘占用:", opts);
            EditorGUILayout.LabelField("运行内存:", opts);
            GUILayout.FlexibleSpace();
            EditorGUILayout.EndVertical();


            detailScroll = EditorGUILayout.BeginScrollView(detailScroll);

            int length = details.Count;
            for (int i = 0; i < length; i++)
            {
                var obj = details[i];
                if (obj == null) continue;
                EditorGUILayout.BeginHorizontal(StyleTool.Box);
                EditorGUILayout.LabelField(i.ToString(), opts);
                obj.OnGUI(this);

                EditorGUILayout.EndHorizontal();
            }

            EditorGUILayout.EndScrollView();
        }

        protected override void OnDestroyCustom()
        {
            if (details != null) details.Clear();
        }
        #endregion

        #region 公开方法

        #endregion
    }
}