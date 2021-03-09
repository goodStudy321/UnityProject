using System.IO;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using iTrace = Loong.Game.iTrace;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Phantom
{
    [System.Serializable]
    public class OpenDoor : FlowChartNode
    {
        #region 字段
        /// <summary>
        /// 门游戏对象
        /// </summary>
        private GameObject door = null;

        /// <summary>
        /// true:无特效
        /// </summary>
        public bool noEffect = false;

        public Vector3 dpos = Vector3.zero;

        public Vector3 euler = Vector3.zero;

        public Vector3 scale = Vector3.one;

        #endregion

        #region 属性

        public string DoorName
        {
            get { return "FX_Scherm"; }
        }

        #endregion

        #region 私有方法
        private void SetDoor()
        {
            var tran = door.transform;
            tran.position = dpos;
            tran.eulerAngles = euler;
            tran.localScale = scale;
        }

        private void LoadCb(GameObject go)
        {
            door = go;
            door.name = name;
            door.transform.parent = flowChart.Root;
            SetDoor();
            Reopen();
        }

        private void Reopen()
        {
            Open();
            Complete();
            TransTool.SetChildrenActive(door.transform, !noEffect);
        }

        #endregion

        #region 保护方法

        protected override void ReadyCustom()
        {
            if (door == null)
            {
                AssetMgr.LoadPrefab(DoorName, LoadCb);
            }
            else
            {
                Reopen();
            }
        }

        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            noEffect = br.ReadBoolean();
            ExVector.Read(ref dpos, br);
            ExVector.Read(ref euler, br);
            ExVector.Read(ref scale, br);
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(noEffect);
            dpos.Write(bw);
            euler.Write(bw);
            scale.Write(bw);
        }

        public void Open()
        {
            door.SetActive(true);
        }

        public void Close()
        {
            door.SetActive(false);
        }

        public override void Preload()
        {
            PreloadMgr.prefab.Add(DoorName);
        }

        #endregion

        #region 编辑器字段/属性/方法
#if UNITY_EDITOR

        private float editorTime;

        private ParticleSystem[] particles;
        public string AssetUrl
        {
            get { return "Assets/Pkg/Fx/Pref/FX_Scherm.prefab"; }
        }

        protected void EditLoadAsset()
        {
            var gbj = AssetDatabase.LoadAssetAtPath<GameObject>(AssetUrl);
            if (gbj == null)
            {
                iTrace.Log("Loong", string.Format("没有发现资源:{0}", AssetUrl));
            }
            else
            {
                door = GbjTool.Clone(gbj);
                var tran = door.transform;
                tran.parent = flowChart.Root;
                tran.position = dpos;
                tran.eulerAngles = euler;
                tran.localScale = scale;
                particles = door.GetComponentsInChildren<ParticleSystem>();
            }
        }
        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as OpenDoor;
            if (node == null) return;
            noEffect = node.noEffect;
            dpos = node.dpos;
            euler = node.euler;
            scale = node.scale;
        }

        public override void EditClickNode()
        {
            if (door == null) return;
            SceneViewUtil.Focus(door.transform.position);
            Selection.activeGameObject = door;
        }

        protected override void EditGizmosUpdate()
        {
            if (door == null) return;
            SetDoor();
            if (particles == null) return;
            editorTime += 0.01f;
            int length = particles.Length;
            for (int i = 0; i < length; i++)
            {
                particles[i].Simulate(editorTime, false);
            }

        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            EditLoadAsset();
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.Toggle("无特效:", ref noEffect, o);
            UIEditLayout.Vector3Field("位置:", ref dpos, o);
            UIEditLayout.Vector3Field("角度:", ref euler, o);
            UIEditLayout.Vector3Field("缩放:", ref scale, o);
            EditorGUILayout.EndVertical();
        }

        public override void EditDrawSceneGui(Object o)
        {
            base.EditDrawSceneGui(o);
            if (door != null)
            {
                dpos = door.transform.position;
                euler = door.transform.eulerAngles;
                scale = door.transform.localScale;
            }
        }
#endif
        #endregion
    }

}