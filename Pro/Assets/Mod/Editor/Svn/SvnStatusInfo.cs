//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/8/1 17:43:50
//=============================================================================

using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// SvnStatusInfo
    /// </summary>
    public class SvnStatusInfo
    {
        #region 字段
        /// <summary>
        /// 已添加的
        /// </summary>
        public List<string> adds = new List<string>();

        /// <summary>
        /// 无版本号控制
        /// </summary>
        public List<string> unvers = new List<string>();

        /// <summary>
        /// 不存在的
        /// </summary>
        public List<string> misses = new List<string>();

        /// <summary>
        /// 已删除的
        /// </summary>
        public List<string> deletes = new List<string>();

        /// <summary>
        /// 发生改变的
        /// </summary>
        public List<string> modifies = new List<string>();

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
        /// <summary>
        /// 判断是否可以提交
        /// </summary>
        /// <returns></returns>
        public bool CanCommit()
        {
            if (adds.Count > 0) return true;
            if (unvers.Count > 0) return true;
            if (misses.Count > 0) return true;
            if (deletes.Count > 0) return true;
            if (modifies.Count > 0) return true;
            return false;
        }

        #endregion
    }
}