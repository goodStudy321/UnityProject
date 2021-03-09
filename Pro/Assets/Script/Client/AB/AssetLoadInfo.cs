#if UNITY_EDITOR

/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/8/10 0:23:14
 ============================================================================*/

using System;
using System.Xml;
using UnityEngine;
using System.Collections;
using System.Xml.Serialization;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// 资源加载信息
    /// </summary>
    [Serializable]
    public class AssetLoadInfo : IComparable<AssetLoadInfo>, IComparer<AssetLoadInfo>
    {
        #region 字段
        private int lv = 0;

        private string _path = "";
        #endregion
        #region 属性

        /// <summary>
        /// 相对路径
        /// </summary>
        [XmlAttribute]
        public string path
        {
            get { return _path; }
            set { _path = value; }
        }

        /// <summary>
        /// 等级
        /// </summary>
        [XmlAttribute]
        public int Lv
        {
            get { return lv; }
            set { lv = value; }
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
        public int CompareTo(AssetLoadInfo rhs)
        {
            if (lv < rhs.lv) return -1;
            if (lv > rhs.lv) return 1;
            if (string.IsNullOrEmpty(_path)) return -1;
            if (string.IsNullOrEmpty(rhs._path)) return -1;
            return _path.CompareTo(rhs._path);
        }

        public int Compare(AssetLoadInfo lhs, AssetLoadInfo rhs)
        {
            return lhs.CompareTo(rhs);
        }
        #endregion
    }
}

#endif