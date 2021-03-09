//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/5/21 23:13:53
//=============================================================================

#if UNITY_ANDROID
using System;
using System.IO;
using UnityEngine;
using System.Threading;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// DecompAndroidStreaming
    /// </summary>
    public class DecompAndroidStreaming : DecompFromStreaming
    {
        #region 字段
        private byte[] buf = new byte[4 * 1024];
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public DecompAndroidStreaming(DecompBase decomp) : base(decomp)
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        protected override bool Decomped(Md5Info info)
        {
            var rPath = info.path;
            bool suc = true;
            var tempPath = AssetPath.Cache + rPath;
            FileStream fs = null;
            try
            {
                var inStream = BetterStreamingAssets.OpenRead(rPath);

                var tempDir = Path.GetDirectoryName(tempPath);
                if (!Directory.Exists(tempDir)) Directory.CreateDirectory(tempDir);
                var bufLen = buf.Length;
                var readSize = 0;

                fs = decomp.Create(tempPath, bufLen);
                while ((readSize = inStream.Read(buf, 0, buf.Length)) > 0)
                {
                    fs.Write(buf, 0, readSize);
                }
            }
            catch (Exception e)
            {
                Debug.LogErrorFormat("Loong, DecompAndroidStreaming:{0} err:{1}", rPath, e.Message);
                suc = false;
            }
            finally
            {
                if (fs != null) fs.Dispose();
            }
            if (suc)
            {
                decomp.Src = tempPath;
                decomp.Dest = AssetPath.Persistent + "/" + rPath;
                var destDir = Path.GetDirectoryName(decomp.Dest);
                if (!Directory.Exists(destDir)) Directory.CreateDirectory(destDir);

                suc = decomp.Execute();
            }

            if (suc)
            {
                FileTool.SafeDelete(tempPath);
            }
            return suc;
        }

        #region 公开方法

        #endregion
    }
}
#endif