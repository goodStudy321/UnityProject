/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2018/5/8 15:43:59
 ============================================================================*/

using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// 升级失败信息
    /// </summary>
    public class UpgFailInfo
    {
        #region 字段
        private List<string> files = new List<string>();

        #endregion
        /// <summary>
        /// 失败文件信息列表
        /// </summary>
        public List<string> Files
        {
            get { return files; }
            set { files = value; }
        }

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
        public void Add(string file)
        {
            if (string.IsNullOrEmpty(file)) return;
            if (files == null) return;
            if (files.Contains(file)) return;
            files.Add(file);
        }

        public void Remove(string file)
        {
            if (string.IsNullOrEmpty(file)) return;
            if (files == null) return;
            files.Remove(file);
        }

        public bool Contains(string file)
        {
            if (files == null) return false;
            return files.Contains(file);
        }

        public void Clear()
        {
            if (files != null) files.Clear();
        }
        #endregion
    }
}