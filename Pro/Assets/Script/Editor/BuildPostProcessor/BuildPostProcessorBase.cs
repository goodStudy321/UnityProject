using System;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Post
{

    /// <summary>
    /// AU:Loong
    /// TM:2016.4.10
    /// BG:发布后处理基类
    /// </summary>
    public abstract class BuildPostProcessorBase
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法
        public BuildPostProcessorBase()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 发布后处理方法
        /// </summary>
        /// <param name="target"></param>
        /// <param name="buildPath"></param>
        public abstract void Execute(BuildTarget target, string buildPath);
        #endregion
    }
}