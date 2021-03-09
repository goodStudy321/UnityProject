//*****************************************************************************
// Copyright (C) 2020, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2020/4/10 11:54:59
//*****************************************************************************

using System;
using System.IO;
using UnityEngine;
using System.Threading;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// DecompPkgSingle
    /// </summary>
    public class DecompPkgSingle
    {
        #region 字段

        private PkgSingle pkg = null;

        private DecompBase decomp = null;

        public int decompCount = 0;


        #endregion

        #region 属性

        #endregion

        #region 委托事件
        public event Action<DecompPkgSingle, bool> complete;
        #endregion

        #region 构造方法
        public DecompPkgSingle(PkgSingle pkg, DecompBase decomp)
        {
            this.pkg = pkg;
            this.decomp = decomp;
        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected bool Decomp(Md5Info info)
        {
            var rPath = info.path;
            bool suc = true;
            var tempPath = AssetPath.Cache + rPath;

            decomp.Src = tempPath;
            decomp.Dest = AssetPath.Persistent + "/" + rPath;
            var destDir = Path.GetDirectoryName(decomp.Dest);
            if (!Directory.Exists(destDir)) Directory.CreateDirectory(destDir);

            suc = decomp.Execute();

            if (suc)
            {
                FileTool.SafeDelete(tempPath);
            }
            else
            {
                iTrace.Error("Loong", "decomp pkgsingle fail,temppath:{0}, {1}", tempPath, decomp.Dest);
            }
            return suc;
        }
        #endregion

        #region 公开方法
        public void Start(object o)
        {
            bool suc = true;
            decompCount = 0;
            Md5Info info = null;
            var infos = pkg.syncs;
            while (true)
            {
                info = null;
                if (pkg.WriteOver)
                {
                    break;
                }
                infos.TryDequeue(out info);
                if (info == null)
                {
                    Thread.Sleep(0);
                    continue;
                }
                suc = Decomp(info);
                if (!suc) break;
                ++decompCount;
            }

            if (App.IsDebug)
            {
                Debug.LogFormat("Loong, decomp end");
            }
            if (complete != null) complete(this, suc);
        }
        #endregion
    }
}