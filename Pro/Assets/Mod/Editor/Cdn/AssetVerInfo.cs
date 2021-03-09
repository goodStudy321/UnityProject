//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/31 15:47:33
//=============================================================================

using System;
using System.IO;
using Loong.Game;
using System.Text;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    using Object = UnityEngine.Object;
    /// <summary>
    /// 资源版本号信息
    /// </summary>
    [Serializable]
    public class AssetVerInfo
    {
        #region 字段
        /// <summary>
        /// 资源版本号
        /// </summary>
        public int ver = 0;

        /// <summary>
        /// 1;静默下载
        /// 0:正常下载
        /// </summary>
        public int quiet = 0;

        /// <summary>
        /// quiet为1时,静默下载的阈值,超出此值时静默下载无效
        /// </summary>
        public int quietVpt = 1024 * 1024 * 10;

        public string content = null;

        public string quietVptStr = null;

        private string[] quietArr = new string[] { "否", "是" };
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public AssetVerInfo()
        {
            SetChanged();
        }
        #endregion

        #region 私有方法

        private void SetContent()
        {
            content = ToString();
        }

        private void SetChanged()
        {
            SetContent();
            quietVptStr = ByteUtil.GetSizeStr(quietVpt);
        }

        private int GetDefaultQuietVpt()
        {
            return 1024 * 1024 * 10;
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        public void Reset()
        {
            ver = 0;
            quiet = 0;
            quietVpt = GetDefaultQuietVpt();
            SetChanged();
        }

        public void OnGUI(Object o)
        {
            UIEditLayout.UIntField("资源版本号:", ref ver, o, SetContent);
            UIEditLayout.Popup("静默更新", ref quiet, quietArr, o, SetContent);

            EditorGUILayout.BeginHorizontal();
            UIEditLayout.UIntField("静默更新阈值", ref quietVpt, o, SetChanged);
            EditorGUILayout.LabelField(quietVptStr);
            EditorGUILayout.EndHorizontal();

            EditorGUILayout.TextField("版本号内容:", content);
        }

        public override string ToString()
        {
            return string.Format("{0},{1},{2}", ver, quiet, quietVpt);
        }

        public string GetInitStr()
        {
            return string.Format("0,0,{0}", GetDefaultQuietVpt());
        }
        #endregion
    }
}