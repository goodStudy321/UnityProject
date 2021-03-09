using UnityEngine;
using System.Collections;
using System.Collections.Generic;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Phantom
{
    /// <summary>
    /// AU:Loong
    /// TM:2016.03.30,09:55:49
    /// CO:nuolan1.ActionSoso1
    /// BG:
    /// </summary>
    [System.Serializable]
    public class MutexNode : FlowChartNode
    {
        #region 字段
        private bool success = false;
        #endregion

        #region 属性

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        /// <summary>
        /// 互斥输出
        /// </summary>
        protected override void CompleteCustom()
        {
            if (success)
            {
                if (outputLinks.Count > 1) outputLinks[1].end.StartProcess();
            }
            else
            {
                if (outputLinks.Count > 0) outputLinks[0].end.StartProcess();
            }
        }

        protected void Success()
        {
            success = true;
            Complete();
        }

        protected void Fail()
        {
            success = false;
            Complete();
        }
        #endregion

        #region 公开方法
        public override void Initialize()
        {
            base.Initialize();
            if ((outputLinks == null) || (outputLinks.Count != 2))
            {
                string tip = "这是一个互斥类型的节点,子节点数量必须为2个";
                Debug.LogError(Format(tip));
                return;
            }
            outputLinks.Sort();
        }

        public override void Reset()
        {
            base.Reset();
            success = false;
        }
        #endregion

        #region 编辑器字段/属性/方法
#if UNITY_EDITOR
        protected override void EditDrawOutputCustom(Object o)
        {
            EditorGUILayout.HelpBox("子节点的数量必须是2,左侧失败时执行,右侧成功时执行", MessageType.Warning);
            if (flowChart == null) { GUILayout.EndVertical(); return; }
            List<FlowChartLink> links = flowChart.FindLinkByStartNode(this);
            if (links == null || links.Count != 2)
            { EditorGUILayout.HelpBox("子节点的数量必须是2", MessageType.Error); return; }
            int length = links.Count;
            links.Sort();
            EditorGUILayout.TextField("失败路线:", links[0].eName);
            EditorGUILayout.TextField("成功路线:", links[1].eName);
        }
#endif
        #endregion
    }
}