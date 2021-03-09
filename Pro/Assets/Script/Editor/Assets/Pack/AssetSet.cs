/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/9/9 22:28:51
 ============================================================================*/

using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// AssetSet
    /// </summary>
    public class AssetSet
    {
        #region 字段
        private HashSet<string> sets = new HashSet<string>();
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
        public bool Add(string path)
        {
            if (string.IsNullOrEmpty(path)) return false;
            var newPath = path.ToLower();
            if (sets.Contains(newPath)) return false;
            sets.Add(newPath);
            return true;
        }

        public void Remove(string path)
        {
            if (string.IsNullOrEmpty(path)) return;
            var newPath = path.ToLower();
            sets.Remove(newPath);
        }

        public bool Contains(string path)
        {
            if (string.IsNullOrEmpty(path)) return true;
            var newPath = path.ToLower();
            return sets.Contains(newPath);
        }

        public void Clear()
        {
            sets.Clear();
        }
        #endregion
    }
}