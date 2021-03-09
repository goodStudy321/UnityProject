using System;
using PathTool;
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
     * GUID:        24856aa6-e735-470b-a6ac-7f25fecb09f5
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/7/22 17:30:46
    /// BG:
    /// </summary>
    [Serializable]
    public class AutoNavPlayerNode : FlowChartNode
    {
        #region 字段
        public Vector3 targetPos = Vector3.zero;
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public AutoNavPlayerNode()
        {

        }
        #endregion

        #region 私有方法
        private void NavComplete(Unit u, AsPathfinding.PathResultType result)
        {
            switch (result)
            {
                case AsPathfinding.PathResultType.PRT_UNKNOWN:
                    break;
                case AsPathfinding.PathResultType.PRT_PATH_SUC:
                    break;
                case AsPathfinding.PathResultType.PRT_CALL_BREAK:
                    break;
                case AsPathfinding.PathResultType.PRT_PASSIVEBREAK:
                    break;
                case AsPathfinding.PathResultType.PRT_ERROR_BREAK:
                    break;
                case AsPathfinding.PathResultType.PRT_FORBIDEN:
                    break;
                default:
                    break;
            }
            HangupMgr.instance.SetInfo(false);
            UnitHelper.instance.ResetUnitData(u);
            Complete();
        }
        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            Unit player = InputVectorMove.instance.MoveUnit;
            if (player == null)
            {
                Complete();
            }
            else if (player.Dead || player.DestroyState)
            {
                Complete();
            }
            else
            {
                InputMgr.instance.ClearTarget();
                HangupMgr.instance.SetInfo(true);
                player.mUnitMove.StartNav(targetPos, callback: NavComplete);
            }
        }
        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            ExVector.Read(ref targetPos, br);
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            targetPos.Write(bw);
        }
        #endregion

        #region 编辑器字段/属性/方法
#if UNITY_EDITOR
        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as AutoNavPlayerNode;
            if (node == null) return;
            targetPos = node.targetPos;
        }

        public override void EditClickNode()
        {
            SceneViewUtil.Focus(targetPos);
        }

        public override void EditCreate()
        {
            targetPos = SceneViewUtil.GetCenterPosGround();
        }
        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 3";
        }

        public override void EditDrawProperty(Object o)
        {
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.Vector3Field("自动寻路位置:", ref targetPos, o);
            UIEditLayout.HelpInfo("通过Ctrl+右键点击设置");
            EditorGUILayout.EndVertical();
        }


        public override void EditDrawSceneGui(Object o)
        {
            UIVectorUtil.Set(o, ref targetPos, "自动寻路位置", e.control);
            UIHandleTool.Position(o, ref targetPos);

        }
#endif
        #endregion
    }
}