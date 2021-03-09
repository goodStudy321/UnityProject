/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/12/17 15:45:36
 ============================================================================*/

#if LOONG_ENABLE_UPG
using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;


namespace Loong.Game
{
    /// <summary>
    /// TestAssetRepair
    /// </summary>
    public class TestAssetRepair : TestMonoBase
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
        [ContextMenu("开始一键修复")]
        private void StartRepair()
        {
            AssetRepair.Instance.StartUp();
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        #endregion
    }
}
#endif