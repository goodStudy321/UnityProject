using System;
using System.IO;
using System.Text;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{

    /// <summary>
    /// AU:Loong
    /// TM:2013.8.17
    /// BG:
    /// </summary>
    [System.Serializable]
    public class FolderInfo
    {
        /// <summary>
        /// 信息
        /// </summary>
        public string info;
        /// <summary>
        /// 目录
        /// </summary>
        public string folder;
        /// <summary>
        /// 完整路径
        /// </summary>
        public string fullPath;

        /// <summary>
        /// 相对路径
        /// </summary>
        public string RelativePath
        {
            get { return AssetPathUtil.GetRelativePath(fullPath); }
        }

        /// <summary>
        /// 构造方法
        /// </summary>
        /// <param name="folder">目录</param>
        /// <param name="info">信息</param>
        /// <param name="prefix">前缀</param>
        public FolderInfo(string folder, string info, string prefix = "")
        {
            this.info = info;
            this.folder = folder;
            SetFullPath(prefix);
        }

        private void SetFullPath(string prefix)
        {
            StringBuilder sb = new StringBuilder();
            sb.Append(Directory.GetCurrentDirectory());
            sb.Append("/").Append("Assets/").Append(prefix).Append("/").Append(folder);
            fullPath = sb.ToString();
        }
    }
}