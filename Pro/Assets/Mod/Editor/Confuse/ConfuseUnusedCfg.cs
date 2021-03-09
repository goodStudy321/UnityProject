//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/16 15:05:44
//=============================================================================

using System;
using System.IO;
using Loong.Edit;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit.Confuse
{
    [Serializable]
    public class ConfuseUnusedCfg
    {
        #region 字段
        /// <summary>
        /// 无用资源标识
        /// </summary>
        public string fileFlag = "_0x";

        /// <summary>
        /// 无用资源生成目录
        /// </summary>
        public string destDir = "../Confuse/File";

        /// <summary>
        /// 无用资源生成数量
        /// </summary>
        public int fileCount = 0;


        public List<string> fileSfxs = new List<string>()
        {
             "bytes", "txt", "json", "xml"
        };

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
        public void OnGUI(Object o)
        {
            if (!UIEditTool.DrawHeader("无用资源", "ConfuseUnusedFile", StyleTool.Host)) return;

            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.SetFolder("无用资源目录:", ref destDir, o);
            UIEditLayout.TextField("无用资源标识:", ref fileFlag, o);
            if (string.IsNullOrEmpty(destDir))
            {
                EditorGUILayout.LabelField("默认:", "../Confuse/File");
            }
            UIEditLayout.IntField("无用资源数量:", ref fileCount, o);
            UIDrawTool.StringLst(o, fileSfxs, "ConfuseUnusedFileSfxs", "无用资源后缀");
            EditorGUILayout.EndVertical();

        }
        #endregion
    }
}