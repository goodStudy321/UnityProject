using System.IO;
using Loong.Game;
using UnityEngine;
using LuaInterface;
using System.Collections;
using System.Collections.Generic;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Phantom
{
    /// <summary>
    /// AU:Loong
    /// TM:2016.01.08,19:26:00
    /// CO:nuolan1.ActionSoso1
    /// BG:
    /// </summary>
    [System.Serializable]
    public class CamCrossfadeNode : FlowChartNode
    {
        #region 字段
        [SerializeField]
        private int option = 0;

        public float duration = 1.5f;

        public float blackDuration = 0.5f;


        /// <summary>
        /// 字幕 DELETE
        /// </summary>
        public string subTitle = "";

        public int subID = 0;

        /// <summary>
        /// 字幕开始时间
        /// </summary>
        public float subTitleBeg = 0f;

        /// <summary>
        /// 字幕持续时间
        /// </summary>
        public float subTitleDur = 0;

        #endregion

        #region 属性

        /// <summary>
        /// 0:淡入淡出完成时结束此节点 1:淡入淡出开始时结束此节点
        /// </summary>
        public int Option
        {
            get { return option; }
            set { option = value; }
        }

        #endregion

        #region 私有方法
        private void StartUp(LuaTable table)
        {
            LuaFunction func = LuaTool.GetFunc(table, "Start");
            LuaTool.Call(func, table, duration, blackDuration);
            if (func != null) func.Dispose();
            var subTitle = Localization.Instance.GetDes(subID);
            LuaFunction startSubTitle = LuaTool.GetFunc(table, "StartSubTitle");
            LuaTool.Call(startSubTitle, table, subTitleBeg, subTitleDur, subTitle);
        }

        private void OpenStartCallback(string uiName)
        {
            EventMgr.Add(EventKey.UIClose, CloseCallback);
            LuaTable table = UIMgr.Get(uiName);
            StartUp(table);
        }

        private void CloseCallback(params object[] args)
        {
            string uiName = args[0] as string;
            if (uiName != UIName.UICrossfade) return;
            EventMgr.Remove(EventKey.UIClose, CloseCallback);
            Complete();
        }

        private void OpenEndCallback(string uiName)
        {
            LuaTable table = UIMgr.Get(uiName);
            StartUp(table);
            Complete();
        }

        private void RemoveListener()
        {
            EventMgr.Remove(EventKey.UIClose, CloseCallback);
        }
        #endregion

        #region 保护方法

        protected override void ReadyCustom()
        {
            if (Option < 1)
            {
                UIMgr.Open(UIName.UICrossfade, OpenStartCallback);
            }
            else
            {
                UIMgr.Open(UIName.UICrossfade, OpenEndCallback);
            }
        }

        protected override void CompleteCustom()
        {
            base.CompleteCustom();
            RemoveListener();

        }

        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            option = br.ReadInt32();
            duration = br.ReadSingle();
            blackDuration = br.ReadSingle();
            ExString.Read(ref subTitle, br);
            subID = br.ReadInt32();
            subTitleBeg = br.ReadSingle();
            subTitleDur = br.ReadSingle();
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(option);
            bw.Write(duration);
            bw.Write(blackDuration);
            ExString.Write(subTitle, bw);
            bw.Write(subID);
            bw.Write(subTitleBeg);
            bw.Write(subTitleDur);
        }

        public override void Preload()
        {
            PreloadMgr.prefab.Add(UIName.UICrossfade);
        }

        public override void Stop()
        {
            base.Stop();
            RemoveListener();
            UIMgr.Close(UIName.UICrossfade);
        }

        public override void Dispose()
        {
            if (Application.isEditor) return;
            RemoveListener();
            UIMgr.Close(UIName.UICrossfade);
        }

        #endregion

        #region 编辑器字段/属性/方法
#if UNITY_EDITOR
        public override bool CanFlag
        {
            get
            {
                return true;
            }
        }

        private string[] optionArr = new string[] { "淡入淡出完成时结束此节点", "淡入淡出开始时结束此节点" };

        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as CamCrossfadeNode;
            if (node == null) return;
            option = node.option;
            duration = node.duration;
            blackDuration = node.blackDuration;
            subTitle = node.subTitle;
            subTitleBeg = node.subTitleBeg;
            subTitleDur = node.subTitleDur;
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 4";
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);

            EditorGUILayout.BeginVertical("box");
            UIEditLayout.Popup("选项:", ref option, optionArr, o);
            UIEditLayout.Slider("淡入淡出时间/秒:", ref duration, 0f, 20f, o);
            UIEditLayout.Slider("黑屏持续时间/秒:", ref blackDuration, 0.1f, 20f, o);
            UIEditLayout.HelpInfo("淡入淡出的过程是淡入" + duration + "秒,停顿" + blackDuration + "秒,再淡出" + duration + "秒!");
            EditorGUILayout.EndVertical();

            EditorGUILayout.BeginVertical("box");
            //TODO
            UIEditLayout.TextArea("字幕:", ref subTitle, o, null, GUILayout.MinHeight(80));
            EditorGUILayout.BeginHorizontal();
            UIEditLayout.IntField("字幕ID:", ref subID, o);
            EditorGUILayout.LabelField("", "", StyleTool.RedX, UIOptUtil.plus);
            EditorGUILayout.EndHorizontal();

            if (string.IsNullOrEmpty(subTitle))
            {
                UIEditLayout.HelpWaring("为空时,不显示字幕");
            }
            else
            {
                UIEditLayout.FloatField("字幕开始时间:", ref subTitleBeg, o);
                UIEditLayout.FloatField("字幕持续时间:", ref subTitleDur, o);
            }
            EditorGUILayout.Space();
            EditorGUILayout.EndVertical();

        }
#endif
        #endregion
    }
}