/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/10/12 23:36:28
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// AssetMfCmpSizeView
    /// </summary>
    public class AssetMfCmpSizeView : EditViewBase
    {
        #region 字段

        public bool isComp = true;
        /// <summary>
        /// 差值阈值
        /// </summary>
        public int difThreshold = 1024 * 10;

        /// <summary>
        /// 差值阈值字符串
        /// </summary>
        public string difThresholdStr = "10KB";

        /// <summary>
        /// 对比清单1
        /// </summary>
        public string lhsMfPath = "";

        /// <summary>
        /// 对比清单2
        /// </summary>
        public string rhsMfPath = "";


        public AssetMfSizePage page = new AssetMfSizePage();

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        protected override void Help()
        {
            var msg = string.Format("将清单{0}和清单{1}中相同文件大小差值超过{2}B({3})的文件列出", lhsMfPath, rhsMfPath, difThreshold, difThresholdStr);
            EditorUtility.DisplayDialog("", msg, "确定");
        }

        private void Compare()
        {
            if (!File.Exists(lhsMfPath))
            {
                UIEditTip.Error("未设置清单1");
            }
            else if (!File.Exists(rhsMfPath))
            {
                UIEditTip.Error("未设置清单2");
            }
            else
            {
                var lst = AssetMfUtil.CmpSizeInfo(lhsMfPath, rhsMfPath, difThreshold, isComp);
                page.SetLst(lst);
                if (page.lst == null || page.lst.Count < 1)
                {
                    UIEditTip.Log("未匹配到满足条件的信息");
                }
            }
        }

        private void SetDifThreahold()
        {
            difThresholdStr = ByteUtil.GetSizeStr(difThreshold);
        }

        #endregion

        #region 保护方法
        protected override void Title()
        {
            EditorGUILayout.BeginHorizontal(EditorStyles.toolbar);
            GUILayout.FlexibleSpace();
            if (TitleBtn("比较"))
            {
                Compare();
            }
            else if (TitleBtn("帮助"))
            {
                Help();
            }
            EditorGUILayout.EndHorizontal();
        }

        protected override void OnGUICustom()
        {
            EditorGUILayout.BeginVertical(StyleTool.Group);
            EditorGUILayout.BeginHorizontal();
            UIEditLayout.UIntField("差值阈值:", ref difThreshold, this, SetDifThreahold);
            EditorGUILayout.LabelField(difThresholdStr);
            UIEditLayout.Toggle("清单是否压缩", ref isComp, this);
            EditorGUILayout.EndHorizontal();
            UIEditLayout.SetPath("清单1:", ref lhsMfPath, this, "xml");
            EditorGUILayout.Space();
            UIEditLayout.SetPath("清单2:", ref rhsMfPath, this, "xml");

            EditorGUILayout.EndVertical();

            page.OnGUI(this);
        }
        #endregion

        #region 公开方法

        #endregion
    }
}