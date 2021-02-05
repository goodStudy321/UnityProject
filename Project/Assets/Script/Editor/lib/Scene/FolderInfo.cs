using System;
using System.IO;
using System.Text;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Hello.Edit
{
    [System.Serializable]
    public class FolderInfo
    {
        public string info;

        public string folder;

        public string fullPath;

        public string RelativePath
        {
            get { return AssetPathUtil.GetRelativePath(fullPath); }
        }

        public FolderInfo(string folder,string info,string prefix = "")
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

