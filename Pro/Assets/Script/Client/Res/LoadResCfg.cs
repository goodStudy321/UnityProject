//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/8/9 19:44:38
//=============================================================================


using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// LoadResCfg
    /// </summary>
    [Serializable]
    public class LoadResCfg
    {
        #region 字段
        public List<string> texDirs = new List<string>();

        public List<string> textDirs = new List<string>();

        public List<string> animDirs = new List<string>();

        public List<string> audioDirs = new List<string>();

        public List<string> prefabDirs = new List<string>();

        #endregion

        #region 属性

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
        public bool NoCfg()
        {
            if (texDirs.Count > 0) return false;
            if (textDirs.Count > 0) return false;
            if (animDirs.Count > 0) return false;
            if (audioDirs.Count > 0) return false;
            if (prefabDirs.Count > 0) return false;
            return true;
        }
        #endregion
    }
}