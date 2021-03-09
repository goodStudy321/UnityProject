//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/3/1 15:18:18
// 应用信息
//=============================================================================

using System;
using System.Xml;
using UnityEngine;
using System.Collections;
using System.Xml.Serialization;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// AppInfo
    /// </summary>
    [Serializable]
    public class AppInfo
    {
        #region 字段
        [SerializeField]
        private PkgKind pkg;
        [SerializeField]
        private long pkgSz = 0;
        [SerializeField]
        private string pkgMD5;
        [SerializeField]
        private int gflag = 1;
        [SerializeField]
        private int verCode = 0;
        [SerializeField]
        private int inAssetVer = 0;
        [SerializeField]
        private string aid = "0";
        [SerializeField]
        private string cid = "0";
        [SerializeField]
        private string gcid = "0";
        [SerializeField]
        private bool enableFps = false;
        [SerializeField]
        private short splashTime = 0;
        [SerializeField]
        private bool isReleaseDebug = false;
        #endregion

        #region 属性

        [XmlAttribute]
        public PkgKind Pkg
        {
            get { return pkg; }
            set { pkg = value; }
        }

        [XmlAttribute]
        public string PkgMD5
        {
            get { return pkgMD5; }
            set { pkgMD5 = value; }
        }


        [XmlAttribute]
        public long PkgSz
        {
            get { return pkgSz; }
            set { pkgSz = value; }
        }


        /// <summary>
        /// 用于区分不同渠道的标识
        /// 0;自己
        /// 1:君海
        /// 2:爱奇艺
        /// </summary>
        [XmlAttribute]
        public int GFlag
        {
            get { return gflag; }
            set { gflag = value; }
        }

        /// <summary>
        /// 内部版本号
        /// </summary>
        [XmlAttribute]
        public int VerCode
        {
            get { return verCode; }
            set { verCode = value; }
        }

        /// <summary>
        /// 内部资源版本号
        /// </summary>
        [XmlAttribute]
        public int InAssetVer
        {
            get { return inAssetVer; }
            set { inAssetVer = value; }
        }

        /// <summary>
        /// ios APPLE ID
        /// </summary>
        [XmlAttribute]
        public string AID
        {
            get { return aid; }
            set { aid = value; }
        }

        /// <summary>
        /// ChannelID
        /// </summary>
        [XmlAttribute]
        public string CID
        {
            get { return cid; }
            set { cid = value; }
        }


        /// <summary>
        /// GameChannelID
        /// </summary>
        [XmlAttribute]
        public string GCID
        {
            get { return gcid; }
            set { gcid = value; }
        }

        /// <summary>
        /// true:正式环境下调试
        /// </summary>
        [XmlAttribute]
        public bool IsReleaseDebug
        {
            get { return isReleaseDebug; }
            set { isReleaseDebug = value; }
        }

        /// <summary>
        /// true:启用FPS
        /// </summary>
        [XmlAttribute]
        public bool EnableFps
        {
            get { return enableFps; }
            set { enableFps = value; }
        }

        /// <summary>
        /// 启动动画时间,默认1;<=0时不激活启动动画
        /// </summary>
        [XmlAttribute]
        public short SplashTime
        {
            get { return splashTime; }
            set { splashTime = value; }
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