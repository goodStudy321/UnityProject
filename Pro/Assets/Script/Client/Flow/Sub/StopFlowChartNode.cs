using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Loong.Game;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Phantom
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.12.23,11:21:14
    /// CO:nuolan1.ActionSoso1
    /// BG:
    /// </summary>
    [System.Serializable]
    public class StopFlowChartNode : HandleNode
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void Handle(FlowChartNode node)
        {
            node.Stop();
        }
        #endregion

        #region 公开方法

        #endregion
    }
}