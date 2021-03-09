using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using System.Collections;
using Object = UnityEngine.Object;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Phantom
{
    [Serializable]
    public class EndGame : FlowChartNode
    {

        #region 字段
        /// <summary>
        /// 结束类型 0:失败,1:胜利
        /// </summary>
        public int endOption;

        /// <summary>
        /// 切换场景
        /// </summary>
        public bool changeScene = true;
        /// <summary>
        /// 是否释放 
        /// </summary>
        public bool disposeOption = false;

        /// <summary>
        /// 结束事件 参数1:流程树名称 参数2:true胜利 false失败
        /// </summary>
        public static event Action<string, bool> end = null;

        #endregion

        #region 属性

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            Complete();
        }

        protected override void CompleteCustom()
        {
            base.CompleteCustom();
            bool win = (endOption == 1) ? true : false;
            flowChart.ExecuteEndHandler(win);
            flowChart.Stop();
            flowChart.Reset();
            if (end != null) end(flowChart.name, win);
            EventMgr.Trigger(EventKey.FlowChartEnd, flowChart.name, win, changeScene);
            if (disposeOption) FlowChartMgr.Remove(flowChart);
            if (!Object.ReferenceEquals(flowChart, FlowChartMgr.Current)) return;
            FlowChartMgr.Current = null;
        }
        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            endOption = br.ReadInt32();
            changeScene = br.ReadBoolean();
            disposeOption = br.ReadBoolean();
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(endOption);
            bw.Write(changeScene);
            bw.Write(disposeOption);
        }

        public static void CleanEndEvent()
        {
            if (end == null) return;
            end = null;
        }

        #endregion

        #region 编辑器字段/属性/方法
#if UNITY_EDITOR
        private string[] endOptionArr = new string[] { "失败", "胜利" };

        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as EndGame;
            if (node == null) return;
            endOption = node.endOption;
            changeScene = node.changeScene;
            disposeOption = node.disposeOption;
        }
        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            EditorGUILayout.BeginVertical(GUI.skin.box);
            UIEditLayout.HelpInfo("这个节点适合在关卡结束的时候使用");
            UIEditLayout.Popup("结束选项:", ref endOption, endOptionArr, o);
            UIEditLayout.Toggle("是否释放:", ref disposeOption, o);
            UIEditLayout.Toggle("是否切换场景:", ref changeScene, o);
            EditorGUILayout.EndVertical();
        }
#endif
        #endregion
    }

}
