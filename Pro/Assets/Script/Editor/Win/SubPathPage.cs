/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/11/3 17:16:55
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// 相对路径页面
    /// </summary>
    [Serializable]
    public class SubPathPage : FilePage
    {
        #region 字段
        /// <summary>
        /// 开始截取的索引
        /// </summary>
        public int startIdx = 0;
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
        protected override string GetPath(string path)
        {
            var length = path.Length;
            if (length < startIdx) return path;
            return path.Substring(startIdx);
        }
        #endregion
    }
}