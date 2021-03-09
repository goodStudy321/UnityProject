/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/8/28 19:28:32
 ============================================================================*/

using System;
using System.IO;
using System.Text;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.iOS
{
    /// <summary>
    /// XClass
    /// </summary>
    public class XClass : IDisposable
    {
        #region 字段
        private string filePath;

        #endregion

        #region 属性

        public string FilePath
        {
            get { return filePath; }
            set { filePath = value; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public XClass()
        {

        }

        public XClass(string filePath)
        {
            this.filePath = filePath;
        }
        #endregion

        #region 私有方法
        private string GetText(string below, ref int begIdx)
        {
            if (!File.Exists(filePath))
            {
                Debug.LogError(string.Format("XCode, {0} not exist", filePath));
                return null;
            }
            string all = null;
            using (var sr = new StreamReader(filePath))
            {
                all = sr.ReadToEnd();
            }
            begIdx = all.IndexOf(below);
            if (begIdx < 0)
            {
                var msg = string.Format("XCode filePath: {0} not found:{1}", filePath, below);
                Debug.LogError(msg);
            }
            return all;
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public void Write(string below, string text)
        {
            int begIdx = -1;
            var all = GetText(below, ref begIdx);
            if (begIdx < 0) return;
            int endIdx = all.LastIndexOf('\n', begIdx + below.Length);
            var sb = new StringBuilder();
            var t1 = all.Substring(0, endIdx);
            sb.Append(t1).Append('\n').Append(text).Append('\n');
            var t2 = all.Substring(endIdx);
            sb.Append(t2);
            all = sb.ToString();
            using (var sw = new StreamWriter(filePath))
            {
                sw.Write(all);
            }
        }

        public void Replace(string below, string text)
        {
            int begIdx = -1;
            var all = GetText(below, ref begIdx);
            if (begIdx < 0) return;
            all = all.Replace(below, text);
            using (var sw = new StreamWriter(filePath))
            {
                sw.Write(all);
            }
        }

        public void Dispose()
        {

        }
        #endregion
    }
}