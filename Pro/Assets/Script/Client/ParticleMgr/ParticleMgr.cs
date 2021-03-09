using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.5.12
    /// BG:粒子管理器
    /// </summary>
    public static class ParticleMgr
    {
        #region 字段
        private static Transform root = null;

        #endregion

        #region 属性

        public static Transform Root
        {
            get
            {
                if (root == null) root = TransTool.CreateRoot("ParticleMgr");
                return root;
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
        public static void Dispose()
        {
            TransTool.ClearChildren(root);
        }
        #endregion
    }
}