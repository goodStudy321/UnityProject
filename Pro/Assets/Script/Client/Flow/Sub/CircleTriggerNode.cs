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
    /// AU:Loong
    /// TM:2016.02.20,10:29:46
    /// CO:nuolan1.ActionSoso1
    /// BG:圆形范围触发器
    /// </summary>
    [System.Serializable]
    public class CircleTriggerNode : MutexNode
    {
        #region 字段
        private Vector2 beg = Vector2.zero;
        private Vector2 end = Vector2.zero;

        protected Transform self = null;
        protected Transform target = null;

        public float radius = 5f;
        public int id = 1;

        #endregion

        #region 属性

        #endregion

        #region 私有方法
        private bool FindTarget()
        {
            List<Unit> units = UnitMgr.instance.UnitList;
            int length = units.Count;
            for (int i = 0; i < length; i++)
            {
                Unit unit = units[i];
                if (id == 1)
                {
                }
                else
                {
                    if (unit.ModelId == id)
                    {
                        target = unit.UnitTrans;
                    }
                }
                if (target != null) break;
            }

            if (target == null)
            {
                string tip = string.Format("没有查找到ID为{0}的目标", id);
                Debug.LogError(Format(tip));
                Complete(); return false;
            }
            return true;
        }


        #endregion

        #region 保护方法

        protected override void ReadyCustom()
        {
            if (!FindTarget()) return;
            UnitEventMgr.die += OnUnitDie;
        }

        protected override void ProcessUpdate()
        {
            if (target == null) return;
            beg.Set(self.position.x, self.position.z);
            end.Set(target.position.x, target.position.z);
            if (Vector2.Distance(beg, end) < radius)
            { Success(); }
        }

        protected override void CompleteCustom()
        {
            base.CompleteCustom();
            UnitEventMgr.die -= OnUnitDie;
        }

        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            radius = br.ReadSingle();
            id = br.ReadInt32();
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(radius);
            bw.Write(id);
        }

        public void OnUnitDie(Unit unit)
        {
            if (Transition != TransitionState.Update) return;
            CampType camp = (CampType)User.instance.MapData.Camp;
            if (unit.Camp != camp) return;
            if (unit.TypeId != id) return;
            Fail();
        }

        public override void Dispose()
        {
            UnitEventMgr.die -= OnUnitDie;
        }

        public override void Initialize()
        {
            base.Initialize();
            self = FindOrCreate(name);
        }
        #endregion
        #region 编辑器字段/属性/方法
#if UNITY_EDITOR

        private Vector3 euler = new Vector3(90, 0, 0);

        public override void EditInitialize()
        {
            base.EditInitialize();
            self = FindOrCreate(name);
        }

        public override void EditDrawSceneGui(Object o)
        {
            base.EditDrawSceneGui(o);
            Handles.CircleHandleCap(o.GetInstanceID(), self.position, Quaternion.Euler(euler), radius, EventType.Repaint);
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            EditorGUILayout.BeginVertical("box");
            EditorGUILayout.HelpBox("区域位置为本节点所在的位置", MessageType.Warning);
            EditorGUILayout.Space();
            EditorGUILayout.Space();
            id = EditorGUILayout.IntField("基础ID:", id);
            if (id == 1) EditorGUILayout.HelpBox("1代表默认为英雄单位", MessageType.Info);
            EditorGUILayout.Space();
            radius = EditorGUILayout.FloatField("半径/米:", radius);
            if (radius < 1) radius = 1;
            EditorGUILayout.EndVertical();
        }
#endif
        #endregion
    }
}