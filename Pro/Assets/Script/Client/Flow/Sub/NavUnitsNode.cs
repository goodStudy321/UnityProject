using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using Phantom.Protocal;
using System.Collections.Generic;
using Random = UnityEngine.Random;
using Object = UnityEngine.Object;

#if UNITY_EDITOR
using UnityEditor;
#endif
namespace Phantom
{
    /// <summary>
    /// AU:Loong
    /// TM:2017.6.3
    /// BG:导航单位节点
    /// </summary>
    [Serializable]
    public class NavUnitsNode : FlowChartNode
    {
        #region 字段
        [SerializeField]
        private long uid = 0;

        [SerializeField]
        private int pathID = 0;

        #endregion

        #region 属性

        /// <summary>
        /// 导航单位的UID
        /// </summary>
        public long UID
        {
            get { return uid; }
            set { uid = value; }
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
        private void RemoveListener()
        {
            UnitEventMgr.born -= BornCallback;
            NetworkListener.Remove<m_monster_reach_toc>(RespPathMove);
        }

        private void OnDestroy()
        {
            RemoveListener();
        }

        /// <summary>
        /// 请求路径移动
        /// </summary>
        private void ReqPathMove()
        {
            m_single_ai_tos req = ObjPool.Instance.Get<m_single_ai_tos>();
            req.args = PathID.ToString();
            req.monster_id = UID;
            req.type = 3;
            NetworkClient.Send<m_single_ai_tos>(req);
            //EditorLog(string.Format("请求UID为:{0}的单位,按照ID为:{1}的路径移动", UID, PathID));
            NetworkListener.Add<m_monster_reach_toc>(RespPathMove);
        }

        /// <summary>
        /// 响应路径移动
        /// </summary>
        /// <param name="obj"></param>
        private void RespPathMove(object obj)
        {
            m_monster_reach_toc resp = obj as m_monster_reach_toc;
            if (resp.monster_id != UID) return;
            //EditorLog(string.Format("响应UID为:{0}的单位,按照ID为:{1}的结束路径移动", UID, PathID));
            Complete();
        }

        /// <summary>
        /// 出生回调
        /// </summary>
        /// <param name="unit"></param>
        private void BornCallback(Unit unit)
        {
            if (unit.UnitUID != UID) return;
            UnitEventMgr.born -= BornCallback;
            ReqPathMove();
        }

        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            Unit unit = UnitMgr.instance.FindUnitByUid(UID);
            if (unit == null)
            {
                string error = string.Format("没有发现UID为:{0}的单位", UID);
                Debug.LogError(Format(error));
                Complete();
            }
            else if (unit.Dead || unit.DestroyState)
            {
                string error = string.Format("UID为:{0}的单位已死亡或者销毁", UID);
                Debug.LogError(Format(error));
                Complete();
            }
            else
            {
                ushort uPathID = (ushort)PathID;
                PathInfo info = PathInfoManager.instance.Find(uPathID);
                if (info == null)
                {
                    LogError(string.Format("没有发现ID为:{0}的路径点配置", PathID));
                    Complete();
                }
                else if (unit.ActionStatus.ActionState == ActionStatus.EActionStatus.EAS_Born)
                {
                    UnitEventMgr.born += BornCallback;
                }
                else
                {
                    ReqPathMove();
                }
            }
        }



        protected override void CompleteCustom()
        {
            base.CompleteCustom();
            RemoveListener();
        }

        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            uid = br.ReadInt64();
            pathID = br.ReadInt32();
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(uid);
            bw.Write(pathID);
        }

        public override void Stop()
        {
            base.Stop();
            RemoveListener();
        }

        public override void Dispose()
        {
            RemoveListener();
        }
        #endregion
        #region 编辑器字段/属性/方法

#if UNITY_EDITOR

        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as NavUnitsNode;
            if (node == null) return;
            uid = node.uid;
            pathID = node.pathID;
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 3";
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);

            EditorGUILayout.BeginVertical(StyleTool.Box);
            UIEditLayout.LongField("单位UID:", ref uid, o);
            if (uid < 1)
            {
                UIEditLayout.HelpError("无效单位UID");
            }
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