//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/5/14 11:47:59
//=============================================================================

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
    /// CamFollowSpeciNode
    /// </summary>
    public class CamFollowSpeciNode : FlowChartNode
    {
        #region 字段
        public string speciName = null;
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
            if (string.IsNullOrEmpty(speciName))
            {
                CameraMgr.ResetOriFollow();
            }
            else
            {
                CameraMgr.FollowChildNode(speciName);
            }
            Complete();
        }
        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            ExString.Read(ref speciName, br);
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            ExString.Write(speciName, bw);

        }
        #endregion

#if UNITY_EDITOR
        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 4";
        }


        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);

            UIEditLayout.TextField("跟随变换名称:", ref speciName, o);
            if (string.IsNullOrEmpty(speciName))
            {
                UIEditLayout.HelpWaring("将重置");
            }
        }
#endif
    }
}