using System;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Post
{

    /// <summary>
    /// AU:Loong
    /// TM:2016.4.10
    /// BG:安卓发布后处理
    /// </summary>
    public class AndroidBuildPostProcessor : BuildPostProcessorBase
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法
        public AndroidBuildPostProcessor()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public override void Execute(BuildTarget target, string buildPath)
        {
            Debug.Log(string.Format("发布:{0},路径:{1}", target, buildPath));
        }
        #endregion
    }
}