/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/12/25 16:51:51
 ============================================================================*/

using System;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// 资源升级命令行管理
    /// </summary>
    public static class AssetUpgCmdMgr
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        private static void Collect()
        {
            //if (BuildArgs.DelAB) return;
            int ver = BuildArgs.AssetVer;
            Debug.LogFormat("Loong, AssetUpgCmdMgr,Collect Ver:{0}", ver);
            if (ver < 1)
            {
                var target = BuildSettingsUtil.Target;
                AssetUpgUtil.Delete(target, 0);
                AssetUpgUtil.Collect(target, 0);
            }
            else
            {
                Debug.LogFormat("Loong, AssetVer:{0}>0,do nothing", ver);
            }
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static void Execute()
        {
            Collect();
        }


        public static void HandleOnHotfix()
        {
            int ver = BuildArgs.AssetVer;
            if (ver < 1)
            {
                Debug.LogFormat("Loong, AssetVer:{0}<1,do nothing", ver);
            }
            else
            {
                var mod = BuildArgs.AssetUpgMode;
                var mode = (AssetUpgMode)mod;
                var target = BuildSettingsUtil.Target;
                Debug.LogFormat("Loong, AssetVer:{0}, mode:{1}", ver, mode);
                AssetUpgUtil.Delete(target, ver);
                if (AssetUpgUtil.Data.Upgrade(target, ver, mode)) return;
                Environment.Exit(2);
                //AssetUpgUtil.Collect(target, ver);
            }
        }
        #endregion
    }
}