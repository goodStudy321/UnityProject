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
    /// TM:2016.05.09,14:20:15
    /// CO:nuolan1.ActionSoso1
    /// BG:释放节点的节点
    /// </summary>
    [System.Serializable]
    public class DisposeNode : HandleNode
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
            node.Dispose();
        }
        #endregion

        #region 公开方法

        #endregion

    }
}