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
     * Copyright:   2016-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        a388533f-d243-4286-adeb-48a625b849d7
    */

    /// <summary>
    /// AU:Loong
    /// TM:2016/11/12 17:34:38
    /// BG:单位路径移动
    /// </summary>
    [Serializable]
    public class UnitPathNode : PathNodeBase
    {
        #region 字段
        private Unit unit = null;

        public long uid = 0;
        #endregion

        #region 属性

        #endregion

        #region 构造方法
        public UnitPathNode()
        {

        }
        #endregion

        #region 私有方法
        private void OnDead(Unit u)
        {
            if (u != unit) return;
            UnitEventMgr.die -= OnDead;
        }
        #endregion

        #region 保护方法


        protected override void ReadyCustom()
        {
            unit = UnitMgr.instance.FindUnitByUid(uid);
            if (unit == null)
            {
#if GAME_DEBUG
                Debug.LogError(Format("没有发现uid为:{0}的单位", uid));
#endif
                Complete();
            }
            else if (unit.Dead || unit.DestroyState)
            {
                Complete();
            }
            else
            {
                target = unit.UnitTrans;
                UnitEventMgr.die += OnDead;
                base.ReadyCustom();
            }

        }

        protected override void CompleteCustom()
        {
            base.CompleteCustom();

            if (unit == null) return;
            UnitEventMgr.die -= OnDead;
            Vector3 euler = unit.UnitTrans.eulerAngles;
            euler.Set(0, euler.y, 0);
            unit.UnitTrans.eulerAngles = euler;
        }
        #endregion

        #region 公开方法
        public override void Stop()
        {
            base.Stop();
            UnitEventMgr.die -= OnDead;
        }

        public override void Dispose()
        {
            base.Dispose();
            UnitEventMgr.die -= OnDead;
        }

        public override void Read(BinaryReader br)
        {
            base.Read(br);
            uid = br.ReadInt64();
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(uid);
        }
        #endregion

        #region 编辑器字段/属性/方法

#if UNITY_EDITOR

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            EditorGUILayout.BeginVertical("groupbox");
            UIEditLayout.LongField("单位UID:", ref uid, o);
            if (uid == 0) UIEditLayout.HelpError("请输入有效单位UID");
            EditorGUILayout.EndVertical();
        }
#endif
        #endregion
    }
}