//*****************************************************************************
// Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2014/5/29 12:12:46
// 此类用于描述如果处理打包时包内资源
//*****************************************************************************

using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Threading;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// 处理包资源抽象基类
    /// </summary>
    public abstract class EditPkg
    {
        #region 字段

        private ElapsedTime elapsed = new ElapsedTime();

        #region 菜单

        #endregion

        #endregion

        #region 属性
        /// <summary>
        /// 简单描述
        /// </summary>
        public abstract string Des { get; }
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
        /// 处理所有资源
        /// </summary>
        /// <param name="targetVer">资源版本号</param>
        public abstract void StartAll(int targetVer = 0);


        /// <summary>
        /// 处理分包资源
        /// </summary>
        /// <param name="targetVer">资源版本号</param>
        /// <param name="containUpgs">true:包含所有热更资源</param>
        public abstract void StartSub(int targetVer = 0, bool containUpgs = true);


        /// <summary>
        /// 清理资源
        /// </summary>
        public virtual void Clean()
        {
            AssetPkgUtil.Delete();
            EditObbUtil.Delete();
        }

        /// <summary>
        /// 开始处理
        /// </summary>
        /// <param name="type">处理类型</param>
        /// <param name="targetVer">资源版本号</param>
        /// <param name="containUpgs">true:包含所有热更资源</param>
        public void Start(PkgType type, int targetVer = 0, bool containUpgs = true)
        {
            elapsed.Beg();
            Clean();
            if (type == PkgType.All)
            {
                StartAll(targetVer);
            }
            else
            {
                StartSub(targetVer, containUpgs);
            }
            elapsed.End("EditPkg:{0}", Des);
        }


        /// <summary>
        /// 开始处理,根据预处理不同自动选择处理分包或整包
        /// </summary>
        /// <param name="targetVer">资源版本号</param>
        /// <param name="containUpgs">true:包含所有热更资源</param>
        public void Start(int targetVer = 0, bool containUpgs = true)
        {
#if LOONG_SUB_ASSET
            Start(PkgType.Sub, targetVer, containUpgs);
#else
            Start(PkgType.All, targetVer, containUpgs);
#endif
        }

        #endregion
    }
}