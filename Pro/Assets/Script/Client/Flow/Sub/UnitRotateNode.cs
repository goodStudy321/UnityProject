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
     * Copyright:   2018-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        098d15c5-ee8d-4871-b764-1347e87215ac
    */

    /// <summary>
    /// AU:Loong
    /// TM:2018/1/4 15:56:02
    /// BG:旋转单位节点
    /// </summary>
    [Serializable]
    public class UnitRotateNode : FlowChartNode
    {
        #region 字段
        /// <summary>
        /// 单位UID
        /// </summary>
        public long uid = 0;

        /// <summary>
        /// 旋转角度
        /// </summary>
        public int eulerY = 0;

        public Vector3 oriPos = Vector3.zero;
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
            Unit target = null;

            if (uid == 0)
            {
                target = InputVectorMove.instance.MoveUnit;
            }
            else
            {
                target = UnitMgr.instance.FindUnitByUid(uid);
            }
            if (target == null)
            {
                LogError(string.Format("没有UID为:{0}的单位", uid));
            }
            else
            {
                target.SetOrientation(eulerY * Mathf.Deg2Rad);
            }
            Complete();
        }
        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            uid = br.ReadInt64();
            eulerY = br.ReadInt32();
            ExVector.Read(ref oriPos, br);
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(uid);
            bw.Write(eulerY);
            oriPos.Write(bw);
        }
        #endregion

#if UNITY_EDITOR

        private Vector3 euler = Vector3.zero;
        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as UnitRotateNode;
            if (node == null) return;
            uid = node.uid;
            eulerY = node.eulerY;
            oriPos = node.oriPos;
        }

        public override void EditCreate()
        {
            oriPos = SceneViewUtil.GetCenterPosGround();
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            EditorGUILayout.BeginVertical(StyleTool.Group);

            UIEditLayout.IntSlider("Y轴角度:", ref eulerY, 0, 360, o);

            UIEditLayout.UlongField("单位UID:", ref uid, o);
            if (uid == 0)
            {
                UIEditLayout.HelpInfo("代表本地玩家");
            }
            EditorGUILayout.EndVertical();

        }

        public override void EditDrawSceneGui(Object o)
        {
            base.EditDrawSceneGui(o);
            euler.y = eulerY;
            Quaternion rot = Quaternion.Euler(euler);
            Handles.ArrowHandleCap(o.GetInstanceID(), oriPos, rot, 2, EventType.Repaint);
            UIHandleTool.FreeMove(o, ref oriPos, Handles.RectangleHandleCap);
        }
#endif
    }
}