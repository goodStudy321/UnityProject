/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.6.3 20:09:23
 ============================================================================*/
using System;
using UnityEngine;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// 升级信息
    /// </summary>
    [Serializable]
    public class UpgInfo
    {
        #region 字段
        /// <summary>
        /// 删除的文件
        /// </summary>
        [SerializeField]
        public List<Md5Info> deleted;
        /// <summary>
        /// 改变的文件
        /// </summary>
        [SerializeField]
        public List<Md5Info> changed;
        /// <summary>
        /// 新增的文件
        /// </summary>
        [SerializeField]
        public List<Md5Info> incresed;

        #endregion

        #region 属性

        #endregion

        #region 构造方法
        public UpgInfo()
        {

        }
        public UpgInfo(List<Md5Info> deleted, List<Md5Info> changed, List<Md5Info> incresed)
        {
            this.deleted = deleted;
            this.changed = changed;
            this.incresed = incresed;
        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 检查有效性
        /// </summary>
        public bool Check()
        {
            if (deleted != null) if (deleted.Count != 0) return true;
            if (changed != null) if (changed.Count != 0) return true;
            if (incresed != null) if (incresed.Count != 0) return true;
            return false;
        }

        public List<Md5Info> GetFixes()
        {
            List<Md5Info> fixes = null;
            if (changed != null)
            {
                if (changed.Count != 0)
                {
                    if (fixes == null) fixes = new List<Md5Info>();
                    fixes.AddRange(changed);
                }
            }
            if (incresed != null)
            {
                if (incresed.Count != 0)
                {
                    if (fixes == null) fixes = new List<Md5Info>();
                    fixes.AddRange(incresed);
                }
            }
            return fixes;
        }
        #endregion
    }
}