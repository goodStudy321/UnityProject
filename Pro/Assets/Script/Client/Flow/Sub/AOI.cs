using System.IO;
using Loong.Game;
using UnityEngine;
using System.Collections.Generic;
using Object = UnityEngine.Object;

#if UNITY_EDITOR
using UnityEditor;
#endif
namespace Phantom
{
    [System.Serializable]
    public class AOI : FlowChartNode
    {

        #region 字段

        private Rigidbody rig = null;

        private BoxCollider boxCol = null;

        /// <summary>
        /// 阵营类型
        /// </summary>
        public UnitCamp type = UnitCamp.Friend;
        /// <summary>
        /// 单位类型
        /// </summary>
        public UnitType unitType = UnitType.None;

        public GameObject go = null;

        public Vector3 size = Vector3.one;


        public Vector3 position = Vector3.zero;

        public Vector3 eulur = Vector3.zero;

        public Vector3 scale = Vector3.one;
        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        private void SetTrigger()
        {
            if (go == null) return;
            var trigger = go.AddComponent<OnTrigger>();
            trigger.enter += OnTriggerEnter;
            trigger.exit += OnTriggerExit;
        }

        private void SetPhysics()
        {
            if (go != null) return;
            go = FindOrCreateGo(name);
            rig = go.AddComponent<Rigidbody>();
            rig.useGravity = false;
            rig.constraints = RigidbodyConstraints.FreezeAll;

            var box = go.AddComponent<BoxCollider>();
            box.size = size;
            box.isTrigger = true;
            boxCol = box;

            var tran = go.transform;
            tran.position = position;
            tran.eulerAngles = eulur;
            tran.localScale = scale;
        }

        private void OnTriggerEnter(Collider collider)
        {
            if (Transition != TransitionState.Update) return;
            int layer = collider.gameObject.layer;
            if (layer != LayerTool.Unit) return;
            List<Unit> units = UnitMgr.instance.UnitList;
            int length = units.Count;
            CampType camp = (CampType)User.instance.MapData.Camp;
            for (int i = 0; i < length; i++)
            {
                Unit unit = units[i];
                if (!Object.ReferenceEquals(collider.gameObject, unit.UnitTrans.gameObject)) continue;
                if (type == UnitCamp.Friend)
                {
                    if (camp != unit.Camp)
                        return;
                }
                else
                {
                    if (camp == unit.Camp)
                        return;
                }
                if (unitType != UnitType.None) if (unit.mUnitAttInfo.UnitType != unitType) return;
                Complete(); return;
            }
        }

        private void OnTriggerExit(Collider collider)
        {
            if (Transition != TransitionState.Update) return;
            List<Unit> units = UnitMgr.instance.UnitList;
            int length = units.Count;
            bool findUnit = false;
            CampType camp = (CampType)User.instance.MapData.Camp;
            for (int i = 0; i < length; i++)
            {
                Unit unit = units[i];
                if (!Object.ReferenceEquals(collider.gameObject, unit.UnitTrans.gameObject)) continue;
                findUnit = true;
                if (type == UnitCamp.Friend)
                {
                    if (camp != unit.Camp)
                        return;
                }
                else
                {
                    if (camp == unit.Camp)
                        return;
                }
                if (unitType != UnitType.None) if (unit.mUnitAttInfo.UnitType != unitType) return;
            }
            if (!findUnit) return;
        }



        #endregion

        #region 保护方法

        protected override void ReadyCustom()
        {
            boxCol.enabled = true;
            rig.WakeUp();
        }

        protected override void CompleteCustom()
        {
            base.CompleteCustom();
            boxCol.enabled = false;
        }

        #endregion

        #region 公开方法

        public override void Initialize()
        {
            base.Initialize();
            SetPhysics();
            SetTrigger();
        }

        public override void Stop()
        {
            base.Stop();
            boxCol.enabled = false;
        }
        public override void Read(BinaryReader br)
        {
            base.Read(br);

            type = (UnitCamp)br.ReadInt32();
            unitType = (UnitType)br.ReadInt32();


            ExVector.Read(ref size, br);
            ExVector.Read(ref position, br);

            ExVector.Read(ref eulur, br);

            ExVector.Read(ref scale, br);
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write((int)type);
            bw.Write((int)unitType);
            size.Write(bw);
            position.Write(bw);

            eulur.Write(bw);

            scale.Write(bw);
        }

        #endregion

        #region 编辑器字段/属性/方法
#if UNITY_EDITOR

        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as AOI;
            if (node == null) return;
            type = node.type;
            unitType = node.unitType;
            size = node.size;
            pos = node.pos;
            eulur = node.eulur;
            scale = node.scale;
        }

        private Color color = new Color(0, 0, 0, 0.3f);

        public override void EditCreate()
        {
            position = SceneViewUtil.GetCenterPosGround();
        }
        public override void EditClickNode()
        {
            SceneViewUtil.Focus(position);
            Selection.activeGameObject = go;
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            SetPhysics();
            if (boxCol == null) boxCol = go.GetComponent<BoxCollider>();
            if (boxCol == null) boxCol = go.AddComponent<BoxCollider>();
            boxCol.isTrigger = true;
            boxCol.size = size;
        }

        protected override void EditGizmosUpdate()
        {
            if (boxCol == null)
            {
                SetPhysics();
                boxCol = go.GetComponent<BoxCollider>();
            }
            Matrix4x4 matrix = Gizmos.matrix;
            Gizmos.matrix = go.transform.localToWorldMatrix;
            switch (type)
            {
                case UnitCamp.Friend:
                    color.r = 0; color.g = 1; color.b = 0;
                    break;
                case UnitCamp.Enemy:
                    color.r = 1; color.g = 0; color.b = 0;
                    break;
                default:
                    break;
            }
            Gizmos.color = color;
            Gizmos.DrawCube(boxCol.center, boxCol.size);
            Gizmos.matrix = matrix;
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);

            EditorGUILayout.BeginVertical(GUI.skin.box);
            type = (UnitCamp)EditorGUILayout.Popup("阵营类型:", (int)type, DefineTool.unitCampArr);
            unitType = (UnitType)EditorGUILayout.Popup("单位类型:", (int)unitType, DefineTool.unitTypeArr);

            UIEditLayout.Vector3Field("碰撞盒大小:", ref size, o);
            UIEditLayout.Vector3Field("位置:", ref position, o);
            UIEditLayout.Vector3Field("角度:", ref eulur, o);
            UIEditLayout.Vector3Field("缩放:", ref scale, o);

            EditorGUILayout.EndVertical();
        }


        public override void EditDrawSceneGui(Object o)
        {
            base.EditDrawSceneGui(o);
            if (go != null)
            {
                position = go.transform.position;
                eulur = go.transform.eulerAngles;
                scale = go.transform.localScale;
            }
        }
#endif
        #endregion
    }
}