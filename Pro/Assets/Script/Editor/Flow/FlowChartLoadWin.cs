using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        4cd86a72-b61e-4de6-b3a9-6d54a3994210
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/10/25 14:28:48
    /// BG:
    /// </summary>
    public class FlowChartLoadWin : EditWinBase
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

        [MenuItem(MenuTool.Plan + "流程树动态加载 %L", false, -1002)]
        [MenuItem(MenuTool.APlan + "流程树动态加载", false, -1002)]
        private static void Open()
        {
            WinUtil.Open<FlowChartLoadWin>(300, 400);
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public override void Init()
        {
            Add<FlowChartLoadView>();
            Switch<FlowChartLoadView>();
        }
        #endregion
    }
}