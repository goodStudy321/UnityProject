//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/5/14 16:20:01
//=============================================================================

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
    /// <summary>
    /// UnitResetToChildNode
    /// </summary>
    public class UnitResetToChildNode : FlowChartNode
    {
        #region 字段
        public string childName = null;
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public UnitResetToChildNode()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            UnitMgr.instance.SetOwnerToChildNodePos(childName);
            var unit = InputVectorMove.instance.MoveUnit;
            if (unit == null || unit.UnitTrans == null)
            {
                Complete();
            }
            else
            {
                var pos = InputVectorMove.instance.MoveUnit.Position;
                var id = MapPathMgr.instance.GetResIdByPos(pos);
                if (id < 0)
                {
                    Complete();
                }
                else
                {
                    PreloadAreaMgr.Instance.Start(id, Complete);
                }
            }
        }
        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            ExString.Read(ref childName, br);
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            ExString.Write(childName, bw);

        }
        #endregion

#if UNITY_EDITOR
        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 2";
        }
        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);

            UIEditLayout.TextField("子变换名称:", ref childName, o);
        }
#endif
    }
}