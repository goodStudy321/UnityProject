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
    /// TM:2016.05.11,12:07:02
    /// CO:nuolan1.ActionSoso1
    /// BG:
    /// </summary>
    [System.Serializable]
    public class CamShakeNode : FlowChartNode
    {
        #region 字段
        private Coroutine coro = null;

        /// <summary>
        /// 时间
        /// </summary>
        public float time = 0.5f;

        /// <summary>
        /// 频率
        /// </summary>
        public float frequence = 90;

        /// <summary>
        /// 振幅
        /// </summary>
        public float amplitude = 30;

        #endregion

        #region 属性

        #endregion

        #region 私有方法
        private IEnumerator YieldCompleteProcess()
        {
            yield return new WaitForSeconds(time);
            Complete();
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
            ExeScript.instance.CameraShake(time, frequence, amplitude);
            coro = MonoEvent.Start(YieldCompleteProcess());
        }

        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            time = br.ReadSingle();
            frequence = br.ReadSingle();
            amplitude = br.ReadSingle();

        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(time);
            bw.Write(frequence);
            bw.Write(amplitude);

        }

        public override void Dispose()
        {
            Clear();
        }

        public override void Stop()
        {
            base.Stop();
            Clear();
        }
        #endregion

        #region 编辑器字段/属性/方法
#if UNITY_EDITOR

        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as CamShakeNode;
            if (node == null) return;
            time = node.time;
            frequence = node.frequence;
            amplitude = node.amplitude;
        }

        protected override void EditCompleteDynamicCustom()
        {
            Clear();
            iTween.Stop(CameraMgr.Main.gameObject);
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 4";
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);

            EditorGUILayout.BeginVertical(GUI.skin.box);
            UIEditLayout.Slider("振动时间/秒:", ref time, 0, 8, o);
            UIEditLayout.Slider("频率:(每秒次数)", ref frequence, 1, 200, o);
            UIEditLayout.Slider("振幅/厘米:", ref amplitude, 1, 200, o);
            EditorGUILayout.EndVertical();
        }
#endif
        #endregion
    }
}