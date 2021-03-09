using System;
using System.IO;
using PathTool;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;
using PathResult = AsPathfinding.PathResultType;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Phantom
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        a7a6025e-f439-426d-8534-65cf36f6efd6
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/6/8 18:05:19
    /// BG:导航玩家节点
    /// </summary>
    [System.Serializable]
    public class NavPlayerNode : FlowChartNode
    {
        #region 字段
        [SerializeField]
        private int pathID = 0;

        [SerializeField]
        private string begAnimID = "N0020";

        [SerializeField]
        private string endAnimID = "N0000";
        #endregion

        #region 属性

        /// <summary>
        /// 开始移动时动画ID
        /// </summary>
        public string BegAnimID
        {
            get { return begAnimID; }
            set { begAnimID = value; }
        }

        /// <summary>
        /// 结束移动时动画ID
        /// </summary>
        public string EndAnimID
        {
            get { return endAnimID; }
            set { endAnimID = value; }
        }

        /// <summary>
        /// 路径点ID
        /// </summary>
        public int PathID
        {
            get { return pathID; }
            set { pathID = value; }
        }

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            Unit player = InputVectorMove.instance.MoveUnit;
            if (player == null)
            {
                Debug.LogError(Format("玩家不存在或者未创建,无法导航"));
                Complete();
            }
            else if (player.Dead || player.DestroyState)
            {
                Debug.LogError(Format("玩家已死亡,无法导航"));
                Complete();
            }
            else
            {
                InputMgr.instance.CanInput = false;
                ushort uPathID = (ushort)PathID;
                PathMoveMgr.instance.RunSpecifyPath(uPathID, false, MoveOnPath.FaceType.FT_FORWORDXZ, player, NavComplete);
                if (!string.IsNullOrEmpty(BegAnimID)) player.ActionStatus.ChangeAction(BegAnimID, 0);
            }
        }

        protected override void CompleteCustom()
        {
            base.CompleteCustom();
            Unit player = InputVectorMove.instance.MoveUnit;
            NetMove.RequestChangePosDir(player, player.Position);
            Unit parent = InputMgr.instance.mOwner;
            PendantMgr.instance.SetLocalPendantsShowState(parent, false, OpStateType.MoveToPoint);
            InputMgr.instance.CanInput = true;
            if (!string.IsNullOrEmpty(EndAnimID)) player.ActionStatus.ChangeAction(EndAnimID, 0);

        }

        protected void NavComplete(PathTool.MoveOnPath.FinishType finType)
        {
            Complete();
        }
        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            pathID = br.ReadInt32();
            ExString.Read(ref begAnimID, br);
            ExString.Read(ref endAnimID, br);
            //begAnimID = br.ReadString();
            //endAnimID = br.ReadString();
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(pathID);
            ExString.Write(begAnimID, bw);
            ExString.Write(endAnimID, bw);
            //bw.Write(begAnimID);
            //bw.Write(endAnimID);
        }
        #endregion

        #region 编辑器字段/属性/方法

#if UNITY_EDITOR
        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as NavPlayerNode;
            if (node == null) return;
            pathID = node.pathID;
            begAnimID = node.begAnimID;
            endAnimID = node.endAnimID;
        }

        private void OpenExcel()
        {
            string path = "../table/L 路径点.xls";
            ProcessUtil.Execute(path, wairForExit: false);
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 3";
        }


        public override void EditDrawProperty(Object o)
        {
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.HelpInfo("路径移动");
            UIEditLayout.TextField("起始动画ID:", ref begAnimID, o);
            UIEditLayout.TextField("结束动画ID:", ref endAnimID, o);
            UIEditLayout.UIntField("路径点ID:", ref pathID, o);
            if (pathID < 1)
            {
                UIEditLayout.HelpError("无效ID");
            }
            UIEditLayout.HelpInfo("可通过【Alt+Y】快速打开路径点编辑器");
            EditorGUILayout.EndVertical();
        }


#endif
        #endregion
    }
}