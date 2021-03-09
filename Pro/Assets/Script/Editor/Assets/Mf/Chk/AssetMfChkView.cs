/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/10/7 22:10:28
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// AssetMd5ChkView
    /// </summary>
    public class AssetMfChkView : EditViewBase
    {
        #region 字段

        /// <summary>
        /// true:压缩
        /// </summary>
        public bool isComp = false;

        /// <summary>
        /// true:检查大小
        /// </summary>
        public bool chkSize = false;

        /// <summary>
        /// 资源目录
        /// </summary>
        public string assetDir = "";
        /// <summary>
        /// 无效列表
        /// </summary>
        public List<string> invalids = null;
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private bool Precheck()
        {
            if (!Directory.Exists(assetDir))
            {
                UIEditTip.Error("目录:{0}不存在", assetDir);
                return false;
            }
            var mfPath = Path.Combine(assetDir, AssetMf.Name);
            if (!File.Exists(mfPath))
            {
                UIEditTip.Error("路径:{0}不存在", mfPath);
                return false;
            }
            return true;
        }

        private void Check()
        {
            if (Precheck())
            {
                invalids = AssetMfUtil.Check(assetDir, isComp, chkSize);
                if (invalids == null) UIEditTip.Log("没有无效内容");
            }
        }

        private void Regen()
        {
            if (Precheck())
            {
                invalids = AssetMfUtil.Reset(assetDir, isComp);
                if (invalids == null) UIEditTip.Log("没有无效内容");
            }
        }
        #endregion

        #region 保护方法
        protected override void Title()
        {
            EditorGUILayout.BeginHorizontal(EditorStyles.toolbar);
            GUILayout.FlexibleSpace();
            if (TitleBtn("检查"))
            {
                DialogUtil.Show("", "确定检查？", Check);
            }
            else if (TitleBtn("重新生成"))
            {
                DialogUtil.Show("", "重新生成？,清单信息将被重新写入！", Regen);
            }

            EditorGUILayout.EndHorizontal();
        }

        protected override void OnGUICustom()
        {
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.Toggle("清单是否压缩:", ref isComp, this);
            UIEditLayout.Toggle("检查大小:", ref chkSize, this);
            UIEditLayout.SetFolder("资源目录:", ref assetDir, this);
            EditorGUILayout.EndVertical();

            EditorGUILayout.Space();

            if (invalids == null)
            {
                UIEditLayout.HelpInfo("没有无效内容");
            }
            else
            {
                UIDrawTool.StringLst(this, invalids, "invalids", "无效列表");
            }
        }
        #endregion

        #region 公开方法

        #endregion
    }
}