/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014/2/15 00:00:00
 ============================================================================*/

using System;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// 预处理指令信息
    /// </summary>
    [Serializable]
    public class PreprocessCmdInfo
    {
        #region 字段
        [SerializeField]
        private string des = "";
        [SerializeField]
        private string name = "";

        #endregion

        #region 属性


        /// <summary>
        /// 描述
        /// </summary>
        public string Des
        {
            get { return des; }
            set { des = value; }
        }

        /// <summary>
        /// 名称
        /// </summary>
        public string Name
        {
            get { return name; }
            set { name = value; }
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