using System.IO;
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
    /// TM:2016.03.29,19:38:46
    /// CO:nuolan1.ActionSoso1
    /// BG:计时圆形范围触发器
    /// </summary>
    [System.Serializable]
    public class CircleTimerTriggerNode : CircleTriggerNode
    {
        #region 字段
        private DateTimer timer;

        [SerializeField]
        private float seconds = 5f;

        #endregion

        #region 属性

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            timer.Start();

        }

        protected override void ProcessUpdate()
        {
            base.ProcessUpdate();
            timer.Update();
        }

        protected override void CompleteCustom()
        {
            base.CompleteCustom();
            timer.Reset();
            ObjPool.Instance.Add(timer);
            timer = null;
        }
        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            seconds = br.ReadSingle();

        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(seconds);

        }
        public override void Initialize()
        {
            base.Initialize();
            if (timer == null) timer = ObjPool.Instance.Get<DateTimer>();
            timer.Seconds = seconds;
            timer.complete += Fail;
        }

        public override void Reset()
        {
            base.Reset();
            if (timer != null) timer.Reset();
        }
        #endregion

        #region 编辑器字段/属性/方法
#if UNITY_EDITOR

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            EditorGUILayout.Space();
            EditorGUILayout.BeginVertical("box");
            seconds = EditorGUILayout.FloatField("倒计时/秒:", seconds);
            if (seconds < 1f) seconds = 1f;
            EditorGUILayout.EndVertical();
        }
#endif
        #endregion
    }
}