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
    /*
     * CO:            
     * Copyright:   2018-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        4364c47a-6e98-4ba0-ab6a-8d94f89f5e5e
    */

    /// <summary>
    /// AU:Loong
    /// TM:2018/1/23 15:44:14
    /// BG:
    /// </summary>
    [System.Serializable]
    public class TimeScaleNode : FlowChartNode
    {
        #region 字段
        private float cnt = 0;

        private float ori = -1f;

        /// <summary>
        /// 持续时间
        /// </summary>
        public float dur = 1f;

        /// <summary>
        /// 时间缩放系数
        /// </summary>
        public float factor = 0.25f;

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            cnt = 0;
            ori = Time.timeScale;
            Time.timeScale = factor;
        }

        protected override void ProcessUpdate()
        {
            cnt += Time.unscaledDeltaTime;
            if (cnt < dur) return;
            Complete();
        }

        protected override void CompleteCustom()
        {
            base.CompleteCustom();
            Clear();
        }



        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            factor = br.ReadSingle();
            dur = br.ReadSingle();
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(factor);
            bw.Write(dur);
        }
        public void Clear()
        {
            if (ori > 0)
            {
                Time.timeScale = ori;
            }
            ori = -1;
        }
        public override void Stop()
        {
            base.Stop();
            Clear();
        }

        public override void Dispose()
        {
            Clear();
        }
        #endregion

#if UNITY_EDITOR
        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as TimeScaleNode;
            if (node == null) return;
            factor = node.factor;
            dur = node.dur;
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 5";
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);

            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.Slider("缩放系数:", ref factor, 0.001f, 1f, o);
            UIEditLayout.HelpInfo("指的是正常游戏时间在此基础上增速/放缓的倍数");
            UIEditLayout.Slider("持续时间:", ref dur, 0.05f, 10f, o);

            EditorGUILayout.EndVertical();

        }


#endif
    }
}