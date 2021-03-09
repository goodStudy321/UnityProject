using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.SceneManagement;

namespace Loong.Game
{

    /// <summary>
    /// AU:Loong
    /// TM:2013.6.6
    /// BG:相机管理
    /// </summary>
    public static class CameraMgr
    {
        #region 字段
        private static bool alock = false;

        private static Camera main = null;

        private static Transform tranself = null;

        private static Camera threeDUICam = null;

        //private static Camera effectCam = null;

        private static CameraOperationBase camOpration = null;

        public static CameraNewPostprocessing camPostprocessing = null;

        private static CameraShakeEffect camShake = null;

        private static CameraPull camPull = null;

        private static CameraInfo curInfo = null;

        //// LY add begin ////
        
        /// <summary>
        /// 原跟随节点
        /// </summary>
        private static Transform oriFollowTrans = null;
        /// <summary>
        /// 正在跟随子节点
        /// </summary>
        private static bool followChild = false;
        /// <summary>
        /// 
        /// </summary>
        private static string followName = "";

        //// LY add end ////


        /// <summary>
        /// 主相机初始深度
        /// </summary>
        private static float oriMainDepth = 0f;
        #endregion

        #region 属性
        /// <summary>
        /// 锁定/true:相机无法操作
        /// </summary>
        public static bool Lock
        {
            get { return alock; }
            set { alock = value; }
        }

        /// <summary>
        /// 主相机
        /// </summary>
        public static Camera Main
        {
            get { return main; }
        }

        /// <summary>
        /// 相机变换组件
        /// </summary>
        public static Transform transform
        {
            get { return tranself; }
        }

        /// <summary>
        /// 相机操作
        /// </summary>
        public static CameraOperationBase CamOperation
        {
            get { return camOpration; }
        }

        public static CameraNewPostprocessing CamPostprocessing
        {
            get { return camPostprocessing; }
        }

        /// <summary>
        /// 摄像机震动
        /// </summary>
        public static CameraShakeEffect CameraShake
        {
            get { return camShake; }
        }

        /// <summary>
        /// 摄像机拉扯
        /// </summary>
        public static CameraPull CameraPull
        {
            get { return camPull; }
        }

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        private static void AddLsnr()
        {
            EventMgr.Add(EventKey.CamOpen, Open);
            EventMgr.Add(EventKey.CamClose, Close);
        }

        private static void Open(params object[] args)
        {
            SetActive(true);
        }

        private static void Close(params object[] args)
        {
            SetActive(false);
        }

        public static void SetActive(bool active)
        {
            //if(Main != null) Main.enabled = active;
            //if (threeDUICam != null) threeDUICam.enabled = active;
            ////if (effectCam != null) effectCam.enabled = active;

            if (Main != null) Main.gameObject.SetActive(active);
            if (threeDUICam != null) threeDUICam.gameObject.SetActive(active);
        }


        

        private static void InitCameraPostprocessing()
        {
            if (main == null) return;
            camPostprocessing = new CameraNewPostprocessing(main/*, effectCam*/);
            camPostprocessing.Init();
            if (ChangeMissionCameraInfo(true) == true) { return;}
            if (GameSceneManager.instance.SceneInfo != null)
                UpdatePostprocessing(GameSceneManager.instance.SceneInfo.camSet);
        }

        /// <summary>
        /// 初始化震动摄像机
        /// </summary>
        private static void InitShakeCamera()
        {
            camShake = new CameraShakeEffect();
        }

        /// <summary>
        /// 初始化摄像机拉扯
        /// </summary>
        private static void InitPullCamera()
        {
            camPull = new CameraPull();
        }
        
        /// <summary>
        /// 设置3DUI相机
        /// </summary>
        private static void Set3DUICamera()
        {
            int threeDMask = 1 << LayerTool.OnlineRewards | 1 << LayerTool.NPC | 1 << LayerTool.ThreeDUI;
            threeDUICam = CamTool.AddCamera("3DUICam", main.depth + 3, threeDMask, main.farClipPlane);
            UITool.Add3DUICamera(threeDUICam, threeDMask);
            int notMask = threeDMask | 1 << LayerTool.UIModel/* | 1 << LayerTool.FX*/;
            main.cullingMask = ~notMask;
            threeDUICam.fieldOfView = main.fieldOfView;
        }

        //private static void SetEffectCasmera()
        //{
        //    int effectMask = 1 << LayerTool.FX;
        //    effectCam = CamTool.AddCamera("FxCam", main.depth + 1, effectMask, main.farClipPlane);
        //    effectCam.fieldOfView = main.fieldOfView;
        //    effectCam.allowHDR = false;
        //    effectCam.allowMSAA = false;
        //}
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 初始化
        /// </summary>
        public static void Initialize()
        {
            main = CamTool.GetMain();
            tranself = main.transform;
            main.backgroundColor = Color.black;

            //// LY add begin ////
            //CheckAndGetShowRT();
            //// LY add end ////

            Set3DUICamera();
            //SetEffectCasmera();
            InitCameraPostprocessing();
            InitShakeCamera();
            InitPullCamera();
            Refresh();
            AddLsnr();
        }

        public static void LateUpdate()
        {
            if (alock) return;
            if (camOpration != null) camOpration.Update();
            if (camPull != null) camPull.Update();
            if (camShake != null && curInfo != null && curInfo.focus != 1) camShake.Update();
            if (curInfo != null && curInfo.focus == 1)
            {
                SetCameraData(curInfo);
            }
        }

        public static void SetCameraData(CameraInfo info)
        {
            if (!main) return;
            CameraInfo.vector3 pos = info.start.list[0];
            CameraInfo.vector3 euler = info.euler.list[0];
            if(pos != null)
                main.transform.position = new Vector3(pos.x, pos.y, pos.z) / 100;
            if(euler != null)
                main.transform.eulerAngles = new Vector3(euler.x, euler.y, euler.z) / 100;
        }

        /// <summary>
        /// 更新摄像机操作
        /// 传入主角 摄像机跟随主角
        /// </summary>
        public static void UpdateOperation(CameraType type, Transform trans, bool refresh = false)
        {
            if (trans == null)
                return;

            if (main == null) return;
            if (type == CameraType.Player)
            {
                if (camOpration == null)
                {
                    camOpration = new CameraPlayerNewOperation(main);
                }

                if(followChild == true)
                {
                    oriFollowTrans = trans;
                    GameObject findNode = Utility.FindNode(trans.gameObject, followName);
                    if (findNode == null)
                    {
#if UNITY_EDITOR
                        iTrace.Error("LY", "Can not find child node !!! ");
#endif
                        return;
                    }
                    (CamOperation as CameraPlayerNewOperation).ChangeFollowObj(findNode);
                    if (camPostprocessing != null)
                    {
                        camPostprocessing.UpdatePlayerObj(findNode.transform);
                    }
                }
                else
                {
                    (CamOperation as CameraPlayerNewOperation).UpdatePlayerObj(trans.gameObject, refresh);
                    if (camPostprocessing != null) camPostprocessing.UpdatePlayerObj(trans);

                    oriFollowTrans = trans;
                }
                
                //followChild = false;
            }
        }

        //// LY add begin ////

        /// <summary>
        /// 设置跟随子节点
        /// </summary>
        /// <param name="childName"></param>
        public static void FollowChildNode(string childName)
        {
            if (oriFollowTrans == null)
            {
#if UNITY_EDITOR
                iTrace.Log("LY", "No follow node !!! ");
#endif
                return;
            }

            GameObject findNode = Utility.FindNode(oriFollowTrans.gameObject, childName);
            if(findNode == null)
            {
#if UNITY_EDITOR
                iTrace.Error("LY", "Can not find child node !!! ");
#endif
                return;
            }

            followName = childName;
            (CamOperation as CameraPlayerNewOperation).ChangeFollowObj(findNode);
            if (camPostprocessing != null)
            {
                camPostprocessing.UpdatePlayerObj(findNode.transform);
            }

            followChild = true;
        }

        /// <summary>
        /// 重置原始节点跟随
        /// </summary>
        public static void ResetOriFollow()
        {
            if(followChild == false)
            {
                return;
            }
            if(oriFollowTrans == null)
            {
#if UNITY_EDITOR
                iTrace.Log("LY", "No original follow node !!! ");
#endif
                return;
            }

            (CamOperation as CameraPlayerNewOperation).UpdatePlayerObj(oriFollowTrans.gameObject, true);
            if (camPostprocessing != null)
            {
                camPostprocessing.UpdatePlayerObj(oriFollowTrans);
            }

            followChild = false;
            followName = "";
        }

        //// LY add end ////

        //public static void UpdateCreateCamera(UInt16 cameraId)
        //{
        //    CameraInfo info = CameraInfoManager.instance.Find(cameraId);
        //    if (info == null) return;
        //    if (camOpration == null)
        //    {
        //        camOpration = new CameraPlayerNewOperation(main);
        //    }
        //    if (info.focus == 0)
        //    {
        //        if (camOpration != null)
        //            (camOpration as CameraPlayerNewOperation).UpdateCameraData(info);
        //    }
        //     else
        //    {
        //        SetCameraData(info);
        //    }
        //}

        /// <summary>
        /// 更新当前场景id的摄像机参数/后处理参数
        /// </summary>
        /// <param name="cameraId"> 摄像机配置ID </param>
        public static void UpdatePostprocessing(UInt16 cameraId)
        {
            if (camPostprocessing != null)
            {
                camPostprocessing.UpdateData();
            }

            CameraInfo info = CameraInfoManager.instance.Find(cameraId);
            if (info == null) return;
            curInfo = info;
            if (main != null)
            {
                main.fieldOfView = info.fov;
                threeDUICam.fieldOfView = info.fov;
                //effectCam.fieldOfView = info.fov;
                main.farClipPlane = threeDUICam.farClipPlane = info.far / 100.0f;
                main.nearClipPlane = threeDUICam.nearClipPlane = info.near / 100.0f;
            }
            if(info.focus == 0)
            {
                if (camOpration != null) (camOpration as CameraPlayerNewOperation).UpdateCameraData(info);
            }
            else
            {
                SetCameraData(info);
            }
            //if (camPostprocessing != null) camPostprocessing.UpdateData(info);
        }
        public static void UpdateMissionPostprocessing(UInt32 cameraId, float time)
        {
            CameraInfo info = CameraInfoManager.instance.Find((ushort)cameraId);
            if (info == null) return;
            curInfo = info;
            if (main != null)
            {
                main.farClipPlane = threeDUICam.farClipPlane = info.far / 100.0f;
                main.nearClipPlane = threeDUICam.nearClipPlane = info.near / 100.0f;
            }
            if (camOpration != null) (camOpration as CameraPlayerNewOperation).SetMissionCameraInfo(info, time);
        }

        public static void RefreshOperation()
        {
            SceneInfo scene = GameSceneManager.instance.SceneInfo;
            if (scene == null) return;
            SceneSubType type = (SceneSubType)scene.sceneSubType;
            if (type != SceneSubType.CampMap && type != SceneSubType.TopFight) return;
            CameraInfo info = CameraInfoManager.instance.Find(scene.camSet);
            if (info == null) return;
            if(info.focus == 0)
            {
                if (camOpration != null) (camOpration as CameraPlayerNewOperation).UpdateCameraData(info);
            }
            else
            {
                SetCameraData(info);
            }
        }


        /// <summary>
        /// 刷新
        /// </summary>
        public static void Refresh()
        {
            if (main != null)
            {
                if (threeDUICam != null && threeDUICam.fieldOfView != main.fieldOfView)
                    threeDUICam.fieldOfView = main.fieldOfView;
                //if (effectCam != null && effectCam.fieldOfView != main.fieldOfView)
                //    effectCam.fieldOfView = main.fieldOfView;
            }
        }

        /// LY add begin ///

        /// <summary>
        /// 开始模糊效果
        /// </summary>
        /// <param name="center">模糊中心</param>
        /// <param name="strength">模糊强度</param>
        public static void StartBlurEff(Vector2 center, float strength)
        {
            if (camPostprocessing == null)
            {
#if UNITY_EDITOR
                iTrace.Error("LY", "camPostprocessing is null !!! ");
#endif
                return;
            }

            camPostprocessing.StartBlurEffect(center, strength);
        }

        /// <summary>
        /// 停止模糊效果
        /// </summary>
        public static void StopBlurEff()
        {
            if (camPostprocessing == null)
            {
                iTrace.Error("LY", "camPostprocessing is null !!! ");
                return;
            }

            camPostprocessing.StopBlurEffect();
        }

        /// LY add end ///
        /// <summary>
        /// 清除拉扯摄像机数据
        /// </summary>
        public static void ClearPullCam()
        {
            camPull.Clear();
        }
        #endregion


        public static void Clear()
        {
            SetMainDepth(oriMainDepth);
        }

        public static MissionCameraInfo ChangeMissCamera()
        {
            uint missID = (uint)User.instance.MainMissionId;
            uint sceneID = 0;
            if (GameSceneManager.instance.SceneInfo != null)
            {
                sceneID = GameSceneManager.instance.SceneInfo.id;
            }
            MissionCameraInfo target = null;
            int size = MissionCameraInfoManager.instance.Size;
            for (int i = 0; i < size; i++)
            {
                MissionCameraInfo info = MissionCameraInfoManager.instance.Get(i);
                if (info != null)
                {
                    if (info.missId < missID && info.sceneId == sceneID)
                    {
                        target = info;
                    }
                }
            }
            return target;
        }


        /// <summary>
        /// 改變相機數據
        /// </summary>
        /// <returns></returns>
        public static bool ChangeMissionCameraInfo(bool needUpdatePost)
        {
            MissionCameraInfo target = ChangeMissCamera();
            if (target != null)
            {
                if (needUpdatePost = true && camPostprocessing != null)
                {
                    camPostprocessing.UpdateData();
                }
                UpdateMissionPostprocessing(target.cameraId, target.time);
                return true;
            }
            return false;
        }


        /// <summary>
        /// 设置主相机深度
        /// 深度为负值时,恢复到初始深度
        /// </summary>
        /// <param name="depth"></param>
        public static void SetMainDepth(float depth)
        {
            if (main == null) return;
            main.depth = (depth < 0f ? oriMainDepth : depth);
        }


        //// LY add begin ////
        //// 调整主摄像机分辨率相关 ////

        private static bool useSceneRT = false;
        /// <summary>
        /// 
        /// </summary>
        private static UITexture uiShowRt = null;
        /// <summary>
        /// 当前使用场景RT
        /// </summary>
        private static RenderTexture mCurRt = null;
        /// <summary>
        /// 当前使用渲染摄像机
        /// </summary>
        private static Camera mCurUseCam = null;

        /// <summary>
        /// 
        /// </summary>
        public static bool UseSceneRT
        {
            set {
                useSceneRT = value;
                if(useSceneRT == true)
                {

                }
            }
            get { return useSceneRT; }
        }
        
        /// <summary>
        /// 
        /// </summary>
        /// <param name="curCam"></param>
        /// <param name="isAnim">是否动画层级摄像机，设置到最高</param>
        public static void SetSceneRtToCurCam(Camera curCam, bool isAnim)
        {
            if(useSceneRT == false || curCam == null || mCurRt == null)
            {
                return;
            }

            //Debug.Log("---------------------------------------     " + curCam.name);
            if(mCurUseCam != null)
            {
                mCurUseCam.targetTexture = null;
            }
            mCurUseCam = curCam;
            mCurUseCam.targetTexture = mCurRt;

            if(isAnim == true)
            {
                UIMgr.SceneRtCam.depth = 92;
            }
            else
            {
                UIMgr.SceneRtCam.depth = -1;
            }

            if(UIMgr.RtPanelObj != null)
            {
                UIMgr.RtPanelObj.SetActive(false);
                UIMgr.RtPanelObj.SetActive(true);
            }
        }

        /// <summary>
        /// 创建场景渲染贴图
        /// </summary>
        /// <returns></returns>
        public static RenderTexture CreateSceneRT(int width, int height)
        {
            RenderTexture rt = new RenderTexture(width, height, 16, RenderTextureFormat.ARGB32);
            rt.antiAliasing = 1;
            rt.useMipMap = false;
            rt.wrapMode = TextureWrapMode.Clamp;
            rt.filterMode = FilterMode.Bilinear;
            rt.name = "SceneRT";
            GameObject.DontDestroyOnLoad(rt);

            return rt;
        }


        private static void CheckAndCreateSceneRT()
        {
            if (mCurRt != null)
                return;

            int sW = QualityMgr.ScaleWidth;
            int sH = QualityMgr.ScaleHeight;

            if(sW <= 0 || sH <= 0)
            {
                return;
            }

            mCurRt = CreateSceneRT(sW, sH);
        }

        public static void CheckAndGetShowRT()
        {
            CheckAndCreateSceneRT();

            if (mCurRt == null)
                return;

            if (uiShowRt != null)
            {
                SetSceneRtToCurCam(Main, false);
                return;
            }

            GameObject rtPanelObj = UIMgr.RtPanelObj;
            if (rtPanelObj == null)
                return;

            uiShowRt = rtPanelObj.transform.Find("SceneRT").GetComponent<UITexture>();
            uiShowRt.mainTexture = mCurRt;

            SetSceneRtToCurCam(Main, false);
        }

        //// LY add end ////
    }
}