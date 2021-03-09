using ProtoBuf;
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
    /// TM:2016.6.29
    /// BG:播放单位动画
    /// </summary>
    [System.Serializable]
    public class UnitAnimNode : FlowChartNode
    {
        #region 字段
        [SerializeField]
        [HideInInspector]
        private long uid = 0;

        [SerializeField]
        [HideInInspector]
        private string animID = "";

        private Coroutine coro = null;

        #endregion

        #region 属性

        #endregion

        #region 私有方法

        private IEnumerator YieldCompleteProcess(float duration)
        {
            yield return new WaitForSeconds(duration);
            Complete();
        }

        private void Play(Unit unit)
        {
            if (unit.ActionStatus.ChangeAction(animID, 0))
            {
                ActionData data = unit.ActionStatus.ActiveAction;
                float duration = ActionHelper.GetActionTotalTime(data);
                duration = duration * 0.001f;
                coro = MonoEvent.Start(YieldCompleteProcess(duration));
            }
            else
            {
                Complete();
            }
        }

        private void Clear()
        {
            if (coro != null) MonoEvent.Stop(coro);
            coro = null;
        }

        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            Unit target = null;
            if (uid < 1)
            {
                target = InputMgr.instance.mOwner;
            }
            else
            {
                target = UnitMgr.instance.FindUnitByUid(uid);
            }
            if (target == null)
            {
                Debug.LogError(Format(string.Format("没有发现ID为{0}的单位", uid)));
                Complete();
            }
            else if (target.Dead || target.DestroyState)
            {
                LogError(string.Format("ID为{0}的单位已经死亡,无法播放指定动画", uid));
                Complete();
            }
            else
            {
                Play(target);
            }
        }
        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            uid = br.ReadInt64();
            ExString.Read(ref animID, br);
            //animID = br.ReadString();
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(uid);
            ExString.Write(animID, bw);
            //bw.Write(animID);
        }

        public override void Stop()
        {
            base.Stop();
            Clear();
        }

        public override void Dispose()
        {
            base.Dispose();
            Clear();
        }
        #endregion



        #region 编辑器字段/属性/方法

#if UNITY_EDITOR
        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as UnitAnimNode;
            if (node == null) return;
            uid = node.uid;
            animID = node.animID;
        }

        protected override void EditCompleteDynamicCustom()
        {
            Clear();
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 5";
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            EditorGUILayout.BeginVertical("groupbox");
            UIEditLayout.UlongField("单位UID:", ref uid, o);
            if (uid < 1) UIEditLayout.HelpInfo("英雄");
            UIEditLayout.TextField("动画ID:", ref animID, o);
            if (string.IsNullOrEmpty(animID))
            {
                UIEditLayout.HelpError("动画ID不能为空");
            }
            else
            {
                UIEditLayout.HelpInfo("此动作ID应该是动作编辑器中的ID");
            }
            EditorGUILayout.EndVertical();
        }

#endif
        #endregion
    }
}