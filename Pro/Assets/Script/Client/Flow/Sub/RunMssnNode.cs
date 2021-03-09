using System;
using Loong.Game;
using UnityEngine;
using System.Collections.Generic;
using Object = UnityEngine.Object;

#if UNITY_EDITOR
using UnityEditor;
#endif


namespace Phantom
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        5fffbf79-0ead-4a94-9a67-db1d436f9c40
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/11/15 11:20:17
    /// BG:
    /// </summary>
    [Serializable]
    public class RunMssnNode : FlowChartNode
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

        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            EventMgr.Trigger("RunMssn");
            Complete();
        }
        #endregion

        #region 公开方法

        #endregion

#if UNITY_EDITOR


        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 1";
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            UIEditLayout.HelpInfo("继续执行主线任务");
        }
#endif
    }
}