/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/12/25 17:09:25
 ============================================================================*/

using System;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// 资源包命令行工具
    /// </summary>
    public static class ABCmdMgr
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
        private static void Delete()
        {
            if (BuildArgs.DelAB)
            {
                ABTool.Delete();
                Debug.LogWarning("Loong, Delete AB:Y");
            }
            else
            {
                Debug.Log("Loong, Delete AB:N");
            }
        }


        private static void Build()
        {
            if (BuildArgs.BuildAB)
            {
                ABTool.BuildUserSettings();
                Debug.LogWarning("Loong, Build AB:Y");
            }
            else
            {
                Debug.Log("Loong, Build AB:N");
            }
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static void Execute()
        {
            Delete();
            Build();
        }
        #endregion
    }
}