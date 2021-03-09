using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using Object = UnityEngine.Object;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Phantom
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        4f37105c-662a-4da4-a264-83493b830ce6
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/7/5 10:46:00
    /// BG:自动挂机节点
    /// </summary>
    [Serializable]
    public class AutoHangupNode : FlowChartNode
    {
        #region 字段
        [SerializeField]
        private int option = 1;
        #endregion

        #region 属性

        /// <summary>
        /// 自动挂机选项 0:取消 1:进入
        /// </summary>
        public int Option
        {
            get { return option; }
            set { option = value; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public AutoHangupNode()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            bool isHangup = (option > 0) ? true : false;
            HangupMgr.instance.IsAutoSkill = isHangup;
            Complete();
        }
        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            option = br.ReadInt32();
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(option);
        }
        #endregion

        #region 编辑器字段/属性/方法

#if UNITY_EDITOR
        private string[] optionArr = new string[] { "取消", "进入" };

        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as AutoHangupNode;
            if (node == null) return;
            option = node.option;
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 2";
        }

        public override void EditDrawProperty(Object o)
        {
            EditorGUILayout.BeginVertical(StyleTool.Box);
            UIEditLayout.Popup("自动挂机:", ref option, optionArr, o);
            EditorGUILayout.EndVertical();
        }

#endif
        #endregion
    }
}