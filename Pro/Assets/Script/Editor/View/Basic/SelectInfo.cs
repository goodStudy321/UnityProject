using System;
using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.9.28
    /// BG:选择信息
    /// </summary>
    [Serializable]
    public class SelectInfo
    {
        #region 字段
        [SerializeField]
        private bool isSelect = false;

        #endregion

        #region 属性

        public bool IsSelect
        {
            get { return isSelect; }
            set { isSelect = value; }
        }

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public virtual void OnGUI(Object obj)
        {

        }
        #endregion
    }
}