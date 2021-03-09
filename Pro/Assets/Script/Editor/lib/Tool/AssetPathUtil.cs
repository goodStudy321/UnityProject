using System;
using System.IO;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Hello.Edit
{
    public static class AssetPathUtil
    {
        private static string temp = null;
        private static string curDir = null;
        private static string streaming = null;
        private static string bSlashCurDir = null;

        public const string AssetRootFolder = "Assets";

        public static string CurDir
        {
            get
            {
                if (string.IsNullOrEmpty(curDir))
                {
                    curDir = Directory.GetCurrentDirectory();
                    curDir = curDir.Replace('\\', '/');
                    curDir += "/";
                }
                return curDir;
            }
        }

        public static string BSlashCuDir
        {
            get
            {
                if (string.IsNullOrEmpty(bSlashCurDir))
                {
                    bSlashCurDir = Directory.GetCurrentDirectory();
                    bSlashCurDir += "\\";
                }
                return bSlashCurDir;
            }
        }

        public static string Streaming
        {
            get
            {
                if (string.IsNullOrEmpty(streaming))
                {
                    streaming = CurDir + "Assets/StreamingAssets/";
                }
                return streaming;
            }
        }

        public static string Temp
        {
            get
            {
                if (string.IsNullOrEmpty(temp))
                {
                    temp = Path.GetFullPath("../Temp/");
                    if (!Directory.Exists(temp)) Directory.CreateDirectory(temp);
                }
                return temp;
            }
        }

        public static string GetRelativePath(string fullPath)
        {
            if (string.IsNullOrEmpty(fullPath)) return null;
            fullPath = fullPath.Replace('\\', '/');
            string rPath = FileUtil.GetProjectRelativePath(fullPath);
            return rPath;
        }

        public static string GetFullPath(string rPath)
        {
            if (rPath.StartsWith(CurDir)) return rPath;
            if (!rPath.StartsWith(AssetRootFolder)) return rPath;
            string fullPath = string.Format("{0}{1}", CurDir, rPath);
            return fullPath;
        }

        public static string GetTempPath(string name)
        {
            return Temp + name;
        }

        public static string GetNowName(string name)
        {
            name = Path.GetFileNameWithoutExtension(name);
            var newName = name + "_" + DateTime.Now.Ticks;
            return newName;
        }
    }
}

