/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/7/11 17:31:13
 ============================================================================*/

using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// 升级条目
    /// </summary>
    public class UpgItem
    {
        #region 字段
        private string src = null;
        private string dest = null;
        private Md5Info info = null;
        #endregion

        #region 属性

        /// <summary>
        /// 源路径/压缩文件路径
        /// </summary>
        public string Src
        {
            get { return src; }
            set { src = value; }
        }



        /// <summary>
        /// 目标路径/解压后路径
        /// </summary>
        public string Dest
        {
            get { return dest; }
            set { dest = value; }
        }



        public Md5Info Info
        {
            get { return info; }
            set { info = value; }
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

        #endregion
    }
}