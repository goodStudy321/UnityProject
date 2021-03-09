//*****************************************************************************
// Copyright (C) 2020, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2020/4/8 15:04:21
//*****************************************************************************

using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// 处理包资源分类
    /// </summary>
    public enum PkgKind
    {
        /// <summary>
        /// 所有文件1个包 
        /// </summary>
        Single,

        /// <summary>
        /// 一个文件1个包
        /// </summary>
        Gradule,
    }


    /// <summary>
    /// 资源分包类型
    /// </summary>
    public enum PkgType
    {
        /// <summary>
        /// 分包
        /// </summary>
        Sub,

        /// <summary>
        /// 整包
        /// </summary>
        All,
    }


    /// <summary>
    /// 包资源管理
    /// </summary>
    public class PkgMgr
    {
        #region 字段
        public static readonly PkgMgr Instance = new PkgMgr();
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        private PkgMgr()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        public DecompAssetBase Create()
        {
            var kind = App.Info.Pkg;
            return Create(kind);
        }


        public DecompAssetBase Create(PkgKind kind)
        {
            DecompAssetBase pkg = null;
            switch (kind)
            {
                case PkgKind.Single:
                    pkg = new PkgSingle();
                    break;
                case PkgKind.Gradule:
                    if (App.IsEditor)
                    {
                        pkg = new DecompGranuleAssets();
                    }
                    else if (App.IsAndroid)
                    {
                        pkg = new DecompGranulesAndroid();
                    }
                    else
                    {
                        pkg = new DecompGranuleAssets();
                    }
                    break;
                default:
                    break;
            }

            return pkg;
        }
        #endregion
    }
}