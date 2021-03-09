using System;
using UnityEngine;
using System.Collections;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Phantom
{
    /// <summary>
    /// Loong 2015.11.20对特效进行抽象修改
    /// </summary>
    [Serializable]
    public class CameraSlowDownNode : FlowChartNode
    {

        #region 字段

        private CamSlowDownFx camFx = new CamSlowDownFx();

        #endregion

        #region 属性

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void ProcessUpdate()
        {
            base.ProcessUpdate();
            camFx.Execute();
        }

        protected override void CompleteCustom()
        {
            base.CompleteCustom();
            camFx.Reset();
        }
        #endregion

        #region 公开方法
        public override void Initialize()
        {
            base.Initialize();
            camFx.callBack += Complete;
            camFx.Initialize();
        }


        #endregion


        #region 编辑器字段/属性/方法
#if UNITY_EDITOR


        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 4";
        }

#endif
        #endregion
    }

}
