//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/5/16 23:23:40
//=============================================================================

using System;
using System.IO;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// LzmaU
    /// </summary>
    public class LzmaU : CompBase
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public LzmaU()
        {

        }
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
                var dir = Path.GetDirectoryName(Dest);
                if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
                var code = lzma.LzmaUtilEncode(Src, Dest);
                suc = (code == 1);
                if (code == 1)
                {
                    suc = true;
                }
                else
                {
                    Debug.LogWarningFormat("Loong, comp fail:{0}, code:{1}", Src, code);
                }
            }
            Complete(suc);
            return suc;
        }
        #endregion
    }
}