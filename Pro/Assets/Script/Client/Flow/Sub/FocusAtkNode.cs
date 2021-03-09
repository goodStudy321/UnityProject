using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using Phantom.Protocal;
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
     * GUID:        51c120e0-a5c3-4277-9f65-3801e5ddf8cd
    */

    /// <summary>
    /// AU:Loong
    /// TM:2018/3/30 17:59:21
    /// BG:
    /// </summary>
    [Serializable]
    public class FocusAtkNode : FlowChartNode
    {
        #region 字段
        public long uid = 0;

        public long targetUID = 0;
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
            var req = ObjPool.Instance.Get<m_single_ai_tos>();
            req.args = targetUID.ToString();
            req.monster_id = uid;
            req.type = 5;
            NetworkClient.Send<m_single_ai_tos>(req);
            Complete();
        }
        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            uid = br.ReadInt64();
            targetUID = br.ReadInt64();
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(uid);
            bw.Write(targetUID);
        }

        #endregion


#if UNITY_EDITOR
        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as FocusAtkNode;
            if (node == null) return;
            uid = node.uid;
            targetUID = node.targetUID;
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 2";
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            UIEditLayout.LongField("怪物UID:", ref uid, o);
            UIEditLayout.LongField("目标UID:", ref targetUID, o);
            if (uid == 0)
            {
                UIEditLayout.HelpInfo("目标为本地英雄");
            }
        }

#endif
    }
}