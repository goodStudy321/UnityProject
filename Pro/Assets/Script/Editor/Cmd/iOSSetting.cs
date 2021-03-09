/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2016/8/10 10:52:26
 ============================================================================*/

using System;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    using StrDic = Dictionary<string, string>;

    /// <summary>
    /// ios设置
    /// </summary>
    public class iOSSetting : CmdSetting
    {
        #region 字段


        #endregion

        #region 属性
        public override VerData Data
        {
            get
            {
                return WinUtil.Get<VerData, iOSVerWin>();
            }
        }
        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public iOSSetting()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void SetVerCode(int ver)
        {
            PlayerSettings.iOS.buildNumber = ver.ToString();
        }

        protected override string GetVerCode()
        {
            return PlayerSettings.iOS.buildNumber;
        }

        #endregion

        #region 公开方法

        #endregion
    }
}