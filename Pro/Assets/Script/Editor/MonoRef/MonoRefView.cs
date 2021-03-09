/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/8/31 18:10:00
 ============================================================================*/

using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// MonoRefView
    /// </summary>
    public class MonoRefView : AssetRefViewBase<MonoBehaviour>
    {
        #region 字段
        public string monoName = null;
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法


        protected override void SetObjs()
        {
            objs = ScriptUtil.SearchSelect(monoName);
        }

        protected override void DrawObj(Object obj)
        {
            UIEditLayout.TextField("脚本名:", ref monoName, obj);
        }
        #endregion

        #region 公开方法

        #endregion
    }
}