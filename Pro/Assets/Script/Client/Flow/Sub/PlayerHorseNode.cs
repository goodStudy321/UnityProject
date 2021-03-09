//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/3/21 9:56:16
//=============================================================================

using System;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.IO;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Phantom
{
    /// <summary>
    /// PlayerHorseNode
    /// </summary>
    public class PlayerHorseNode : FlowChartNode
    {
        #region 字段
        /// <summary>
        /// 0:下马，1上马
        /// </summary>
        public int option = 0;
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
            var owner = InputMgr.instance.mOwner;
            if (!owner.Dead && !owner.DestroyState)
            {
                NetPendant.RequestChangeMount(option);
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

#if UNITY_EDITOR
        public string[] optionArr = new string[] { "下马", "上马" };
        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 2";
        }

        public override void EditDrawProperty(UnityEngine.Object o)
        {
            base.EditDrawProperty(o);

            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.Popup("选项", ref option, optionArr, o);

            EditorGUILayout.EndVertical();

        }

        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as PlayerHorseNode;
            if (node == null) return;
            option = node.option;
        }
#endif

    }
}