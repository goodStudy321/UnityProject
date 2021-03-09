using System.IO;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Debug = UnityEngine.Debug;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Phantom
{
    [System.Serializable]
    public class SpawnResNode : FlowChartNode
    {

        #region 字段
        /// <summary>
        /// 资源物体
        /// </summary>
        private GameObject assetGo = null;

        /// <summary>
        /// 是否UI
        /// </summary>
        public bool isUI;

        /// <summary>
        /// 键值
        /// </summary>
        public string key = "";

        /// <summary>
        /// 资源名称
        /// </summary>
        public string resName = "";

        /// <summary>
        /// 隐藏
        /// </summary>
        public bool hidden = false;

        /// <summary>
        /// 位置
        /// </summary>
        public Vector3 position = Vector3.zero;

        /// <summary>
        /// 角度
        /// </summary>
        public Vector3 eulerAngle = Vector3.zero;

        /// <summary>
        /// 缩放
        /// </summary>
        public Vector3 localScale = Vector3.one;


        #endregion

        #region 属性

        #endregion

        #region 私有方法
        private void LoadCallback(GameObject obj)
        {
            assetGo = obj;
            if (assetGo != null)
            {
                assetGo.SetActive(!hidden);
                Transform tran = assetGo.transform;
                if (isUI) tran.parent = UIMgr.Root;
                tran.localEulerAngles = eulerAngle;
                tran.localPosition = position;
                tran.localScale = localScale;

                if (!string.IsNullOrEmpty(key)) ComponentBind.Add(key, assetGo);
            }
            Complete();
        }
        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            if (string.IsNullOrEmpty(resName))
            {
                Debug.LogError(Format("资源名称为空"));
                Complete();
            }
            else
            {
                AssetMgr.LoadPrefab(resName, LoadCallback);
            }
        }
        #endregion

        #region 公开方法

        public override bool Check()
        {
            if (!string.IsNullOrEmpty(resName)) return true;
            Debug.LogError(Format("资源名称为空"));
            return false;
        }

        public override void Preload()
        {
            PreloadMgr.prefab.Add(resName);
        }

        public override void Dispose()
        {
            GbjPool.Instance.Add(assetGo);
        }

        public override void Read(BinaryReader br)
        {
            base.Read(br);
            isUI = br.ReadBoolean();
            ExString.Read(ref key, br);
            //key = br.ReadString();
            ExString.Read(ref resName, br);
            //resName = br.ReadString();
            hidden = br.ReadBoolean();
            ExVector.Read(ref position, br);
            ExVector.Read(ref eulerAngle, br);
            ExVector.Read(ref localScale, br);
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(isUI);
            ExString.Write(key, bw);
            //bw.Write(key);
            ExString.Write(resName, bw);
            //bw.Write(resName);
            bw.Write(hidden);
            position.Write(bw);
            eulerAngle.Write(bw);
            localScale.Write(bw);
        }
        #endregion


        #region 编辑器字段/属性/方法
#if UNITY_EDITOR
        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as SpawnResNode;
            if (node == null) return;
            isUI = node.isUI;
            key = node.key;
            resName = node.resName;
            position = node.position;
            eulerAngle = node.eulerAngle;
            localScale = node.localScale;
        }

        public override void EditCreate()
        {
            position = SceneViewUtil.GetCenterPosGround();
        }

        public override void EditDrawProperty(Object o)
        {
            base.EditDrawProperty(o);
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.HelpInfo("通过Ctrl+左键点击快速设置位置");
            UIEditLayout.Toggle("是否UI资源:", ref isUI, o);
            UIEditLayout.TextField("资源名称:", ref resName, o);
            UIEditLayout.Toggle("隐藏:", ref hidden, o);
            if (string.IsNullOrEmpty(resName)) UIEditLayout.HelpError("资源名称不能为空");
            EditorGUILayout.Space();
            UIEditLayout.Vector3Field("位置:", ref position, o);
            UIEditLayout.Vector3Field("角度:", ref eulerAngle, o);
            UIEditLayout.Vector3Field("缩放:", ref localScale, o);
            EditorGUILayout.Space();
            UIEditLayout.TextField("键值:", ref key, o);
            UIEditLayout.HelpWaring("通过键值可以快速的插值到创建的对象");
            EditorGUILayout.EndVertical();
        }

        public override void EditDrawSceneGui(Object o)
        {
            base.EditDrawSceneGui(o);
            UIVectorUtil.Set(o, ref position, "资源位置", e.control, 0);
            var insID = o.GetInstanceID();
            Handles.SphereHandleCap(insID, position, Quaternion.identity, 2, EventType.Repaint);
            Handles.ArrowHandleCap(insID, position, Quaternion.Euler(eulerAngle), 4f, EventType.Repaint);
        }

#endif
        #endregion

    }
}