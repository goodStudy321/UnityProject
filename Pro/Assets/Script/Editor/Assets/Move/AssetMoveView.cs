/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/7/27 15:40:27
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
    /// AssetMoveView
    /// </summary>
    public class AssetMoveView : EditViewBase
    {
        #region 字段
        /// <summary>
        /// 目标文件夹
        /// </summary>
        public string targetDir = "";

        /// <summary>
        /// 过滤路径字符
        /// </summary>
        public List<string> filters = new List<string>();
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void Move()
        {
            if (string.IsNullOrEmpty(targetDir))
            {
                UIEditTip.Error("未设置目录"); return;
            }
            var cur = Directory.GetCurrentDirectory();
            cur = cur.Replace('\\', '/');
            targetDir = targetDir.Replace('\\', '/');
            if (!targetDir.StartsWith(cur))
            {
                UIEditTip.Error("非法目录:" + targetDir); return;
            }
            var msg = string.Format("移动资源到:\n{0}", targetDir);
            if (EditorUtility.DisplayDialog("", msg, "确定", "取消"))
            {
                AssetMoveUtil.MoveSelect(targetDir);
                UIEditTip.Log("完成");
            }

        }
        #endregion

        #region 保护方法
        protected override void OnGUICustom()
        {
            UIEditLayout.HelpWaring("若移动的资源包含列表中的任何字符将不移动,字符区分大小写");
            UIDrawTool.StringLst(this, filters, "moveFillters", "过滤字符");
            UIEditLayout.HelpWaring("将选择的资源(包含依赖)移动到指定目录");
            EditorGUILayout.BeginHorizontal();
            UIEditLayout.SetFolder("目标目录:", ref targetDir, this);
            EditorGUILayout.EndHorizontal();
            if (GUILayout.Button("移动")) Move();
        }
        #endregion

        #region 公开方法

        #endregion
    }
}