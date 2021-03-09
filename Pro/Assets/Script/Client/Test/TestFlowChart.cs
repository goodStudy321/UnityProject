#if UNITY_EDITOR
using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        ca7dbbad-59e3-41c0-9cd7-98da98d20652
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/7/7 17:09:17
    /// BG:
    /// </summary>
    public class TestFlowChart : TestMonoBase
    {
        #region 字段
        public string flowChartName = "TestFlow";
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public TestFlowChart()
        {

        }
        #endregion

        #region 私有方法
        private void Start()
        {
            AssetMgr.Instance.Load(flowChartName, Suffix.Prefab, LoadCallback);
        }
        private void LoadCallback(UnityEngine.Object obj)
        {
            GameObject go = GbjTool.Clone(obj);
            GbjPool.Instance.Add(go);
        }
        #endregion

        #region 保护方法
        protected override void OnGUICustom()
        {
            if (GUILayout.Button("加载流程树", btnOpts))
            {
                FlowChartMgr.Start(flowChartName);
            }
        }
        #endregion

        #region 公开方法

        #endregion
    }
}
#endif