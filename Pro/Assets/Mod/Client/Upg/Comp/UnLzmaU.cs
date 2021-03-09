//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/5/16 23:23:54
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
    /// UnLzmaU
    /// </summary>
    public class UnLzmaU : DecompBase
    {
        #region 字段

        #endregion

        #region 属性
        public override bool IsFile
        {
            get
            {
                return true;
            }
        }
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
        public override bool Execute()
        {
            var suc = false;
            if (File.Exists(Src))
            {
                int i = 0;
                int code = 0;

                while (i < 5)
                {
                    code = lzma.LzmaUtilDecode(Src, Dest);
                    if (code == 1)
                    {
                        suc = true; break;
                    }
                    else if (code == -11)
                    {
                        if (File.Exists(Dest))
                        {
                            lzma.setFilePermissions(Dest, "rw", "rw", "rw");
                        }
                        suc = false;
                        var sleep = 60 + i * 30;
                        Thread.Sleep(sleep);
                        ++i;
                    }
                    else
                    {
                        suc = false; break;
                    }
                }
            }
            if (complete != null) complete(this, suc);
            return suc;
        }
        #endregion
    }
}