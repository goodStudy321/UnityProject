//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/5/21 23:14:11
//=============================================================================

using System;
using System.IO;
using UnityEngine;
using System.Threading;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// 
    /// </summary>
    public class DecompiOSStreaming : DecompFromStreaming
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public DecompiOSStreaming(DecompBase decomp) : base(decomp)
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override bool Decomped(Md5Info info)
        {
            decomp.Src = AssetPath.Streaming + "/" + info.path;
            decomp.Dest = AssetPath.Persistent + "/" + info.path;
            var dir = Path.GetDirectoryName(decomp.Dest);
            if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
            bool suc = decomp.Execute();
            return suc;
        }
        #endregion

        #region 公开方法

        #endregion
    }
}