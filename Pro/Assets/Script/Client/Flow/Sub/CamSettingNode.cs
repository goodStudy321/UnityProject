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
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        9fcb9458-6cae-4133-b188-81298b249a94
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/6/26 17:06:23
    /// BG:相机设置
    /// </summary>
    [System.Serializable]
    public class CamSettingNode : FlowChartNode
    {
        #region 字段
        /// <summary>
        /// 视锥
        /// </summary>
        public float fov = 40;

        /// <summary>
        /// 使用FOV
        /// </summary>
        public bool useFov = true;

        /// <summary>
        /// 改变Fov时间
        /// </summary>
        public float fovTime = 2f;

        /// <summary>
        /// 远裁切
        /// </summary>
        public float farClip = 1000;

        /// <summary>
        /// 近裁切
        /// </summary>
        public float nearClip = 0.3f;

        /// <summary>
        /// 使用位置
        /// </summary>
        public bool usePosition = true;

        /// <summary>
        /// 位置
        /// </summary>
        public Vector3 position = Vector3.zero;

        /// <summary>
        /// 改变位置时间
        /// </summary>
        public float positionTime = 2f;

        /// <summary>
        /// 使用欧拉角
        /// </summary>
        public bool useEulerAngle = true;

        /// <summary>
        /// 欧拉角
        /// </summary>
        public float eulerAngleTime = 2f;

        /// <summary>
        /// 改变角度时间
        /// </summary>
        public Vector3 eulerAngle = Vector3.zero;


        private GameObject go = null;
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
            if (CameraMgr.Main == null)
            {
                LogError("主相机为空");
            }
            else
            {
                Camera main = CameraMgr.Main;
                main.farClipPlane = farClip;
                main.nearClipPlane = nearClip;
                CameraPlayerNewOperation old = CameraMgr.CamOperation as CameraPlayerNewOperation;
                if (useFov)
                {
                    old.ChangeCameraFOV(fov, fovTime);
                }
                if (usePosition)
                {
                    old.ChangeCameraPos(position, positionTime);
                }
                if (useEulerAngle)
                {
                    old.ChangeCameraEuler(eulerAngle, eulerAngleTime);
                }
            }

            Complete();
        }
        #endregion

        #region 公开方法
        public override void Initialize()
        {
            base.Initialize();
            go = FindOrCreateGo(name);
        }

        public override void Read(BinaryReader br)
        {
            base.Read(br);
            fov = br.ReadSingle();
            useFov = br.ReadBoolean();
            fovTime = br.ReadSingle();
            farClip = br.ReadSingle();
            nearClip = br.ReadSingle();
            usePosition = br.ReadBoolean();
            ExVector.Read(ref position, br);
            positionTime = br.ReadSingle();
            useEulerAngle = br.ReadBoolean();
            eulerAngleTime = br.ReadSingle();
            ExVector.Read(ref eulerAngle, br);
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            bw.Write(fov);
            bw.Write(useFov);
            bw.Write(fovTime);
            bw.Write(farClip);
            bw.Write(nearClip);
            bw.Write(usePosition);
            position.Write(bw);
            bw.Write(positionTime);
            bw.Write(useEulerAngle);
            bw.Write(eulerAngleTime);
            eulerAngle.Write(bw);
        }
        #endregion

        #region 编辑器字段/属性/方法
#if UNITY_EDITOR

        private Camera cam = null;

        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as CamSettingNode;
            if (node == null) return;
            fov = node.fov;
            useFov = node.useFov;
            fovTime = node.fovTime;
            farClip = node.farClip;
            nearClip = node.nearClip;
            usePosition = node.usePosition;
            position = node.position;
            useEulerAngle = node.useEulerAngle;
            eulerAngle = node.eulerAngle;
            eulerAngleTime = node.eulerAngleTime;
        }

        protected override void EditDrawCtrlUI(Object o)
        {
            if (GUILayout.Button("开启相机"))
            {
                if (cam != null) cam.enabled = true;
            }
            else if (GUILayout.Button("关闭相机"))
            {
                if (cam != null) cam.enabled = false;
            }
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 4";
            go = FindOrCreateGo(name);
        }

        public override void EditDrawProperty(Object o)
        {
            EditorGUILayout.BeginVertical(StyleTool.Group);
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.Toggle("使用位置:", ref usePosition, o);
            if (usePosition)
            {
                UIEditLayout.Vector3Field("位置:", ref position, o);
                UIEditLayout.Slider("改变时间:", ref positionTime, 0, 20, o);
            }
            EditorGUILayout.EndVertical();

            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.Toggle("使用角度:", ref useEulerAngle, o);
            if (useEulerAngle)
            {
                UIEditLayout.Vector3Field("欧拉角:", ref eulerAngle, o);
                UIEditLayout.Slider("改变时间:", ref eulerAngleTime, 0, 20, o);
            }
            EditorGUILayout.EndVertical();

            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.Toggle("使用视锥:", ref useFov, o);
            if (useFov)
            {
                UIEditLayout.Slider("视锥:", ref fov, 0, 180, o);
                UIEditLayout.Slider("改变时间:", ref fovTime, 0, 20, o);
            }
            EditorGUILayout.EndVertical();

            EditorGUILayout.Space();
            UIEditLayout.FloatField("近裁切:", ref nearClip, o);
            UIEditLayout.FloatField("远裁切:", ref farClip, o);
            EditorGUILayout.EndVertical();
        }

        public override void EditDrawSceneGui(Object o)
        {
            base.EditDrawSceneGui(o);
            if (Application.isPlaying) return;
            if (cam == null)
            {
                cam = go.GetComponent<Camera>();
            }
            if (cam == null)
            {
                cam = go.AddComponent<Camera>();
                cam.hideFlags = HideFlags.DontSave;
                cam.depth = 666;
            }
            else
            {
                cam.fieldOfView = fov;
                cam.farClipPlane = farClip;
                cam.nearClipPlane = nearClip;
                cam.transform.position = position;
                cam.transform.eulerAngles = eulerAngle;
            }

        }
#endif
        #endregion
    }
}