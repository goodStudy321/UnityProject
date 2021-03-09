using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
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
     * GUID:        c6175124-ae1a-41c1-8f66-d5498bfc00e4
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/7/7 17:45:56
    /// BG:激活隐藏玩家节点
    /// </summary>
    [Serializable]
    public class ActivePlayerNode : FlowChartNode
    {
        #region 字段
        [SerializeField]
        private int option = 0;

        #endregion

        #region 属性

        public int Option
        {
            get { return option; }
            set { option = value; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public ActivePlayerNode()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            Unit player = InputVectorMove.instance.MoveUnit;
            if (player == null)
            {
                LogError("本地玩家不存在");
            }
            else if (player.UnitTrans == null)
            {
                LogError("本地玩家模型不存在");
            }
            else if (Option < 1)
            {
                UnitMgr.instance.SetUnitActive(player, false);
                PendantMgr.instance.ShowContrl = false;
            }
            else
            {
                PendantMgr.instance.ShowContrl = true;
                UnitMgr.instance.SetUnitActive(player, true);
            }
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

        private string[] optionArr = new string[] { "隐藏", "激活" };

        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as ActivePlayerNode;
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
            UIEditLayout.Popup("选项:", ref option, optionArr, o);
            EditorGUILayout.EndVertical();
        }

#endif
        #endregion
    }
}