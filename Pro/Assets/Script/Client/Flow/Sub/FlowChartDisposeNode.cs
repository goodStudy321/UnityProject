using System;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Phantom
{

    /*
     * CO:            
     * Copyright:   2016-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        0fe939ef-2b99-44ed-856f-470a35ac6c6f
    */

    /// <summary>
    /// AU:Loong
    /// TM:2016/10/19 14:30:32
    /// BG:释放流程树
    /// </summary>
    [Serializable]
    public class FlowChartDisposeNode : FlowChartNode
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            flowChart.Dispose();
        }
        #endregion

        #region 公开方法

        #endregion

        #region 编辑器字段/方法/属性
#if UNITY_EDITOR
        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 1";
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            EditorGUILayout.HelpBox("此节点将释放流程树", MessageType.Warning);
        }
#endif
        #endregion
    }
}