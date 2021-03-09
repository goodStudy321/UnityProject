using System.IO;
using Loong.Game;
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
    /// TM:2015.12.23,10:52:12
    /// CO:nuolan1.ActionSoso1
    /// BG:
    /// </summary>
    [System.Serializable]
    public class RepeatNode : FlowChartNode
    {
        #region 字段

        private float timer = 0;

        public float interval = 1f;

        #endregion

        #region 属性

        #endregion

        #region 私有方法
        private void ChildComplete(FlowChartNode node)
        {
            node.Transition = TransitionState.Wait;
        }

        private IEnumerator ResetUpdate()
        {
            yield return 0;
            if (Transition == TransitionState.Stop) yield break;
            Transition = TransitionState.Update;
        }

        /// <summary>
        /// 添加子节点结束事件
        /// </summary>
        private void ChildrenAddCompleteEvent()
        {
            int length = outputLinks.Count;
            for (int i = 0; i < length; i++)
            {
                FlowChartLink link = outputLinks[i];
                if (link == null) continue;
                if (link.end == null) continue;
                link.end.complete += ChildComplete;
            }
        }

        /// <summary>
        /// 移除子节点结束事件
        /// </summary>
        private void ChildrenRemoveCompleteEvent()
        {
            int length = outputLinks.Count;
            for (int i = 0; i < length; i++)
            {
                FlowChartLink link = outputLinks[i];
                if (link == null) continue;
                if (link.end == null) continue;
                link.end.complete -= ChildComplete;
            }
        }

        #endregion

        #region 保护方法

        protected override void ReadyCustom()
        {
            ChildrenAddCompleteEvent();
            Complete();
        }

        protected override void ProcessUpdate()
        {
            timer += Time.unscaledDeltaTime;
            if (timer < interval) return;
            Complete();
            timer = 0f;
        }

        protected override void CompleteCustom()
        {
            base.CompleteCustom();
            MonoEvent.Start(ResetUpdate());
        }
        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            interval = br.ReadSingle();
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(interval);
        }

        public override void Stop()
        {
            base.Stop();
            ChildrenRemoveCompleteEvent();
        }

        public override void Dispose()
        {
            ChildrenRemoveCompleteEvent();
        }

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
            EditorGUILayout.BeginVertical("box");
            EditorGUILayout.HelpBox("此节点会按照一定间隔重复执行,所以其子节点也会跟着一起执行,除非手动停止,但停止时,其子节点并不会停止", MessageType.Warning);
            interval = EditorGUILayout.FloatField("间隔时间/秒", interval);
            interval = interval < 0.2f ? 0.2f : interval;
            EditorGUILayout.EndVertical();
        }
#endif
        #endregion
    }
}