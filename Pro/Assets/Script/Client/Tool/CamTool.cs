using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.SceneManagement;
using Object = UnityEngine.Object;

namespace Loong.Game
{

    /// <summary>
    /// AU:Loong
    /// TM:2014.8.2
    /// BG:相机工具
    /// </summary>
    public static class CamTool
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法
        static CamTool()
        {
            SceneManager.sceneLoaded += CamTool.DeleteOtherMainOnSceneLoaded;

        }
        #endregion

        #region 私有方法
        /// <summary>
        /// 场景加载完成检查是否有其它的主相机并删除
        /// </summary>
        /// <param name="scene"></param>
        /// <param name="mode"></param>
        private static void DeleteOtherMainOnSceneLoaded(Scene scene, LoadSceneMode mode)
        {
            DeleteOtherMain();
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法


        /// <summary>
        /// 检查是否有其它的主相机并删除
        /// </summary>
        public static void DeleteOtherMain()
        {
            if (CameraMgr.Main == null) return;
            GameObject mainGo = CameraMgr.Main.gameObject;
            GameObject[] cameras = GameObject.FindGameObjectsWithTag(TagTool.MainCamera);
            if (cameras == null || cameras.Length == 0) return;
            int length = cameras.Length;
            for (int i = 0; i < length; i++)
            {
                GameObject go = cameras[i].gameObject;
                if (Object.ReferenceEquals(mainGo, go)) continue;
                iTrace.eLog("Loong", string.Format("删除重复的主相机:{0}", go.name));
                iTool.Destroy(go);
            }
        }

        /// <summary>
        /// 获取主相机/如果没有找到则创建
        /// </summary>
        public static Camera GetMain()
        {
            Camera main = Camera.main;
            if (main == null)
            {
                GameObject go = new GameObject(TagTool.MainCamera);
                main = go.AddComponent<Camera>();
                go.tag = TagTool.MainCamera;
            }
            Object.DontDestroyOnLoad(main.gameObject);
            main.gameObject.name = "Root<Camera>";
            main.clearFlags = CameraClearFlags.Skybox;
            main.useOcclusionCulling = true;
            main.farClipPlane = 80f;
            main.useOcclusionCulling = true;
            main.allowHDR = true;
            return main;
        }

        /// <summary>
        /// 获取指定相机在一定距离的视锥体高度
        /// </summary>
        /// <param name="camera">相机</param>
        /// <param name="distance">距离</param>
        /// <returns></returns>
        public static float FrustumHeight(Camera camera, float distance)
        {
            if (camera == null) return 0;
            if (distance < 0) return 0;
            float frustumHeight = 2.0f * distance * Mathf.Tan(camera.fieldOfView * 0.5f * Mathf.Deg2Rad);
            return frustumHeight;
        }

        /// <summary>
        /// 通过视锥体高度获取视锥体宽度
        /// </summary>
        /// <param name="frustumHeight">视锥体高度</param>
        /// <returns></returns>
        public static float FrustumWidth(Camera camera, float frustumHeight)
        {
            if (camera == null) return 0;
            float frustumWidth = frustumHeight * camera.aspect;
            return frustumWidth;
        }

        /// <summary>
        /// 在相机下创建指定距离的视锥体碰撞
        /// </summary>
        /// <param name="camera">相机</param>
        /// <param name="distance">距离</param>
        /// <param name="layer">视锥体层级</param>
        public static void CreateFrustum(Camera camera, float distance, int layer)
        {
            if (camera == null) return;
            if (distance < 1) return;
            GameObject go = new GameObject();
            go.name = "Frustum"; go.layer = layer;
            go.transform.parent = camera.transform;
            go.transform.localPosition = Vector3.forward * distance;
            go.AddComponent<BoxCollider>();
            float frustumHeight = FrustumHeight(camera, distance);
            float frustumWidth = FrustumWidth(camera, frustumHeight);
            go.transform.localScale = new Vector3(frustumWidth, frustumHeight, 1);
        }

        /// <summary>
        /// 添加渲染相机
        /// </summary>
        /// <param name="cameraName">相机名称</param>
        /// <param name="depth">层级</param>
        /// <param name="mask">渲染层</param>
        /// <param name="far">远裁切</param>
        /// <returns></returns>
        public static Camera AddCamera(string cameraName, float depth, int mask, float far, CameraClearFlags flag = CameraClearFlags.Depth)
        {
            if (Camera.main == null)
            { iTrace.Log("Loong", "添加渲染相机时主相机不能为空"); return null; }

            GameObject go = new GameObject(cameraName);
            Camera camera = go.AddComponent<Camera>();
            camera.cullingMask = mask;
            camera.farClipPlane = far;
            camera.fieldOfView = Camera.main.fieldOfView;
            camera.nearClipPlane = Camera.main.nearClipPlane;
            camera.clearFlags = flag;
            camera.depth = depth;
            camera.transform.parent = Camera.main.transform;
            camera.transform.localScale = Vector3.one;
            camera.transform.localPosition = Vector3.zero;
            camera.transform.localEulerAngles = Vector3.zero;
            return camera;
        }
    }
    #endregion
}