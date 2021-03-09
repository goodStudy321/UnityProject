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
     * GUID:        9916c0d9-a613-4c5c-86fe-69d6ab43da0d
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/6/17 17:42:16
    /// BG:玩家控制节点
    /// </summary>
    [Serializable]
    public class InputMgrNode : FlowChartNode
    {
        #region 字段
        /// <summary>
        /// 0:可以控制 1:不可控制
        /// </summary>
        [SerializeField]
        private int option = 0;
        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            if (option == 0)
            {
                if (!InputMgr.instance.CanInput)
                {
                    InputMgr.instance.CanInput = true;
                }
            }
            else
            {
                if (InputMgr.instance.CanInput)
                {
                    InputMgr.instance.CanInput = false;
                }
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

        private string[] optionArr = new string[] { "可以控制", "不可控制" };
        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as InputMgrNode;
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
            UIEditLayout.Popup("控制类型:", ref option, optionArr, o);
            EditorGUILayout.EndVertical();
        }

#endif
        #endregion
    }
}