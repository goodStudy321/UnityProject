using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2014-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        407c1fa9-9ec9-435f-a19d-452a6de73407
    */

    /// <summary>
    /// AU:Loong
    /// TM:2014/12/10 11:04:27
    /// BG:UI工具
    /// </summary>
    public static class UITool
    {
        #region 字段
        private static Camera mUICamera;
        #endregion

        #region 属性
        /// <summary>
        /// 在UI之上
        /// </summary>
        public static bool On
        {
            get
            {
                if (UICamera.selectedObject == null) return false;
                if (UICamera.selectedObject.name == "UI Root") return false;
                if (UICamera.selectedObject.layer == LayerTool.UI) return true;
                if (UICamera.selectedObject.layer == LayerTool.ThreeDUI) return true;
                return false;
            }
        }

        public static Camera UIRootCamera
        {
            get
            {
                return mUICamera;
            }
        }
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 设置NGUI标签
        /// </summary>
        /// <param name="root">根节点物体</param>
        /// <param name="path">路径</param>
        /// <param name="tip">提示</param>
        /// <param name="value">值</param>
        public static void SetLblValue(GameObject root, string path, string tip, string value)
        {
            SetLblValue(root.transform, path, tip, value);
        }

        /// <summary>
        /// 设置NGUI标签
        /// </summary>
        /// <param name="root">根节点变换组件</param>
        /// <param name="path">路径</param>
        /// <param name="tip">提示</param>
        /// <param name="value">值</param>
        public static void SetLblValue(Transform root, string path, string tip, string value)
        {
            UILabel label = ComTool.Get<UILabel>(root, path, tip, false);
            if (label != null) label.text = value;
        }

        /// <summary>
        /// 设置NGUI标签
        /// </summary>
        /// <param name="root">目标物体</param>
        /// <param name="value">值</param>
        public static void SetLblValue(GameObject target, string value)
        {
            SetLblValue(target.transform, value);
        }
        /// <summary>
        /// 设置NGUI标签
        /// </summary>
        /// <param name="root">目标变换组件</param>
        /// <param name="value">值</param>
        public static void SetLblValue(Transform target, string value)
        {
            UILabel label = target.GetComponent<UILabel>();
            if (label != null) label.text = value;
        }


        /// <summary>
        /// 设置NGUI精灵
        /// </summary>
        /// <param name="root">根节点变换组件</param>
        /// <param name="path">路径</param>
        /// <param name="tip">提示</param>
        /// <param name="value">精灵名称param>
        public static void SetSpriteName(Transform root, string path, string tip, string value)
        {
            UISprite sprite = ComTool.Get<UISprite>(root, path, tip, false);
            if (sprite != null) sprite.spriteName = value;
        }

        /// <summary>
        /// 设置精灵
        /// </summary>
        /// <param name="root">根节点物体</param>
        /// <param name="path">路径</param>
        /// <param name="tip">提示</param>
        /// <param name="value">精灵名称</param>
        public static void SetSpriteName(GameObject root, string path, string tip, string value)
        {
            SetSpriteName(root.transform, path, tip, value);
        }

        /// <summary>
        /// 设置NGUI精灵
        /// </summary>
        /// <param name="target">目标变换组件</param>
        /// <param name="value">精灵名称</param>
        public static void SetSpriteName(Transform target, string value)
        {
            UISprite sprite = target.GetComponent<UISprite>();
            if (sprite != null) sprite.spriteName = value;
        }

        /// <summary>
        /// 设置NGUI精灵
        /// </summary>
        /// <param name="target">目标物体</param>
        /// <param name="value">精灵名称</param>
        public static void SetSpriteName(GameObject root, string value)
        {
            SetSpriteName(root.transform, value);
        }

        /// <summary>
        /// 设置NGUI图片
        /// </summary>
        /// <param name="root">根节点变换组件</param>
        /// <param name="path">路径</param>
        /// <param name="value">图片param>
        /// <param name="tip">提示</param>
        public static void SetTex(Transform root, string path, Texture2D value, string tip)
        {
            UITexture tex = ComTool.Get<UITexture>(root, path, tip, false);
            if (tex != null) tex.mainTexture = value;
        }

        /// <summary>
        /// 设置NGUI图片
        /// </summary>
        /// <param name="root">根节点物体</param>
        /// <param name="path">路径</param>
        /// <param name="value">图片</param>
        /// <param name="tip">提示</param>
        public static void SetTex(GameObject root, string path, Texture2D value, string tip)
        {
            SetTex(root.transform, path, value, tip);
        }

        /// <summary>
        /// 设置NGUI按钮事件
        /// </summary>
        /// <param name="root">根节点变换组件</param>
        /// <param name="path">路径</param>
        /// <param name="tip">提示</param>
        /// <param name="click">注册事件</param>
        public static void SetBtnClick(Transform root, string path, string tip, EventDelegate.Callback click)
        {
            UIButton button = ComTool.Get<UIButton>(root, path, tip, true);
            if (button != null) EventDelegate.Add(button.onClick, click);
        }

        /// <summary>
        /// 设置NGUI按钮事件
        /// </summary>
        /// <param name="root">根节点物体</param>
        /// <param name="path">路径</param>
        /// <param name="tip">提示</param>
        /// <param name="click">注册事件</param>
        public static void SetBtnClick(GameObject root, string path, string tip, EventDelegate.Callback click)
        {
            SetBtnClick(root.transform, path, tip, click);
        }

        /// <summary>
        /// 设置NGUI按钮事件
        /// </summary>
        /// <param name="target">目标物体变换组件</param>
        /// <param name="click">注册事件</param>
        public static void SetBtnClick(Transform target, EventDelegate.Callback click)
        {
            UIButton button = ComTool.Get<UIButton>(target);
            if (button != null) EventDelegate.Add(button.onClick, click);
        }

        /// <summary>
        /// 设置NGUI按钮事件
        /// </summary>
        /// <param name="target">目标物体</param>
        /// <param name="click">注册事件</param>
        public static void SetBtnClick(GameObject target, EventDelegate.Callback click)
        {
            SetBtnClick(target.transform, click);
        }

        /// <summary>
        /// 设置NGUI监听点击事件
        /// </summary>
        /// <param name="root">根节点变换组件</param>
        /// <param name="path">路径</param>
        /// <param name="tip">提示</param>
        /// <param name="click">注册事件</param>
        public static void SetLsnrClick(Transform root, string path, string tip, UIEventListener.VoidDelegate click)
        {
            UIEventListener listener = ComTool.Get<UIEventListener>(root, path, tip, true);
            if (listener != null) listener.onClick += click;
        }

        /// <summary>
        /// 设置NGUI监听点击事件
        /// </summary>
        /// <param name="root">根节点物体</param>
        /// <param name="path">路径</param>
        /// <param name="tip">提示</param>
        /// <param name="click">注册事件</param>
        public static void SetLsnrClick(GameObject root, string path, string tip, UIEventListener.VoidDelegate click)
        {
            SetLsnrClick(root.transform, path, tip, click);
        }


        /// <summary>
        /// 在相机可视范围内设置模型大小
        /// </summary>
        /// <param name="target">目标模型</param>
        /// <param name="modelCam">模型相机</param>
        /// <param name="scaleFactor">缩放系数</param>
        public static void SetModelScale(Transform target, Camera modelCam, float scaleFactor = 1f)
        {
            float uiRootScale = UIMgr.Root.localScale.y;
            float modelScale = target.localScale.y;
            float modelHeight = 2; float modelWidth = 2;
            Collider collider = target.GetComponent<Collider>();
            if (collider != null) modelWidth = collider.bounds.size.x;
            Vector3 start = modelCam.ViewportToWorldPoint(new Vector3(0, 0, 0));
            Vector3 end = modelCam.ViewportToWorldPoint(new Vector3(1, 1, 0));
            float width = (end.x - start.x);
            float scale = width * modelScale / modelWidth;
            target.localScale = scale * Vector3.one * scaleFactor;

            target.transform.parent = modelCam.transform;
            target.transform.eulerAngles = Vector3.up * 180;
            modelHeight = collider.bounds.size.y;
            float height = (end.y - start.y);
            height = modelHeight - height * 0.5f;
            float y = -height / uiRootScale;
            float z = collider.bounds.size.z / uiRootScale;
            z += 100;
            target.localPosition = new Vector3(0, y, z);
        }


        /// <summary>
        /// 创建遮挡
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="parent">父物体</param>
        /// <param name="maskName">名称</param>
        /// <param name="depth">深度</param>
        /// <returns></returns>
        public static T CreateMask<T>(Transform parent, string maskName, int depth) where T : UIWidget
        {
            UIWidget widget = CreateMask(typeof(T), parent, maskName, depth);
            if (widget == null) return null;
            T t = widget as T;
            return t;
        }


        /// <summary>
        /// 创建遮挡
        /// </summary>
        /// <param name="typeName">类型名称</param>
        /// <param name="parent">父物体</param>
        /// <param name="maskName">名称</param>
        /// <param name="depth">深度</param>
        /// <returns></returns>
        public static UIWidget CreateMask(string typeName, Transform parent, string maskName, int depth)
        {
            if (string.IsNullOrEmpty(typeName)) return null;
            Type type = Type.GetType(typeName);
            return CreateMask(type, parent, maskName, depth);
        }

        /// <summary>
        /// 创建遮挡
        /// </summary>
        /// <param name="typeName">类型</param>
        /// <param name="parent">父物体</param>
        /// <param name="maskName">名称</param>
        /// <param name="depth">深度</param>
        /// <returns></returns>
        public static UIWidget CreateMask(Type type, Transform parent, string maskName, int depth)
        {
            if (type == null) return null;
            if (string.IsNullOrEmpty(maskName)) maskName = "mask";
            GameObject mask = new GameObject(maskName);
            mask.layer = LayerTool.UI;
            mask.transform.parent = parent;
            Component com = mask.AddComponent(type);
            if (com == null)
            {
                GameObject.Destroy(mask); return null;
            }
            UIWidget t = com as UIWidget;
            if (t != null)
            {
                t.depth = depth;
                t.transform.localScale = Vector3.one;
                t.transform.localPosition = Vector3.zero;
                t.updateAnchors = UIRect.AnchorUpdate.OnEnable;
                t.SetAnchor(parent.gameObject, -2, -2, 2, 2);
                NGUITools.AddWidgetCollider(mask);
            }
            return t;
        }

        /// <summary>
        /// 查找层级最高的UIPanel
        /// </summary>
        /// <param name="target"></param>
        /// <returns></returns>
        public static UIPanel GetMaxDepth(GameObject target)
        {
            UIPanel[] panels = target.GetComponentsInChildren<UIPanel>();
            if (panels == null) return null;
            UIPanel maxPanel = null;
            int depth = 0;
            int length = panels.Length;
            for (int i = 0; i < length; i++)
            {
                UIPanel pl = panels[i];
                if (pl.depth < depth) continue;
                depth = pl.depth;
                maxPanel = pl;
            }
            return maxPanel;
        }

        /// <summary>
        /// NGUI面板排序
        /// </summary>
        /// <param name="target">目标面板</param>
        /// <param name="depth">深度</param>
        /// <param name="factor">深度系数</param>
        public static void Sort(GameObject target, int depth, int factor)
        {
            if (target == null) return;
            UIPanel[] panels = target.GetComponentsInChildren<UIPanel>(true);
            if (panels == null || panels.Length == 0) return;
            Array.Sort(panels, UIPanel.CompareFunc);
            int length = panels.Length;
            int startDepth = depth * 20;
            for (int i = 0; i < length; i++)
            {
                UIPanel pnl = panels[i];
                pnl.depth = startDepth + i;
            }
        }

        /// <summary>
        /// 在相机上创建3DNGUI UICamera
        /// </summary>
        /// <param name="cam">相机</param>
        /// <param name="layer">事件层级</param>
        /// <param name="eventType">事件类型</param>
        public static void Add3DUICamera(Camera cam, int layer, UICamera.EventType eventType = UICamera.EventType.World_3D)
        {
            if (cam == null) return;
            UICamera uicam = ComTool.Get<UICamera>(cam.gameObject);
            uicam.eventReceiverMask = layer;
            uicam.eventType = eventType;
            uicam.eventsGoToColliders = true;
        }

        /// <summary>
        /// 创建UI根结点
        /// </summary>
        /// <param name="width">宽度</param>
        /// <param name="height">高度</param>
        /// <param name="camDepth">相机深度</param>
        /// <returns></returns>
        public static Transform CreateRoot(int width, int height, int camDepth)
        {
            int UILayer = LayerTool.UI;
            Transform root = null;
            GameObject go = GameObject.Find("UI Root");
            if (go == null) root = NGUITools.CreateUI(false, UILayer).gameObject.transform;
            else root = go.transform;

            UIRoot uiRoot = root.GetComponent<UIRoot>();
            uiRoot.fitWidth = true;
            uiRoot.scalingStyle = UIRoot.Scaling.ConstrainedOnMobiles;
            uiRoot.manualWidth = width;
            uiRoot.manualHeight = height;

            //UICamera uiCam = root.GetComponentInChildren<UICamera>();
            UICamera uiCam = root.Find("Camera").GetComponent<UICamera>();
            Camera cam = uiCam.cachedCamera;
            cam.clearFlags = CameraClearFlags.Depth;
            cam.cullingMask = 1 << UILayer;
            cam.gameObject.layer = UILayer;
            cam.depth = camDepth;
            uiCam.eventType = UICamera.EventType.UI_3D;
            uiCam.eventReceiverMask = 1 << UILayer;
            uiCam.eventsGoToColliders = true;
            mUICamera = cam;
            root.gameObject.layer = UILayer;
            root.position = new Vector3(0, 666, 0);
            
            return root;
        }

        //// LY add begin ////

        public static void CreateRTCom(Transform uiRootTrans)
        {
            Transform rtTrans = uiRootTrans.Find("RTCamera");
            if (rtTrans == null)
            {
                GameObject newObj = new GameObject("RTCamera");
                GameObject.DontDestroyOnLoad(newObj);
                rtTrans = newObj.transform;
                rtTrans.parent = uiRootTrans;
                rtTrans.localRotation = Quaternion.identity;
                rtTrans.localScale = Vector3.one;
            }
            rtTrans.localPosition = new Vector3(0, -3000, 0);
            GameObject rtObj = rtTrans.gameObject;
            rtObj.layer = LayerMask.NameToLayer("UI");

            Camera rtCam = rtObj.GetComponent<Camera>();
            if (rtCam == null)
            {
                rtCam = rtObj.AddComponent<Camera>();
            }
            rtCam.clearFlags = CameraClearFlags.SolidColor;
            rtCam.backgroundColor = Color.black;
            rtCam.cullingMask = 1 << LayerMask.NameToLayer("UI");
            rtCam.orthographic = true;
            rtCam.orthographicSize = 1;
            rtCam.nearClipPlane = -2;
            rtCam.farClipPlane = 2;
            rtCam.useOcclusionCulling = false;
            rtCam.allowHDR = false;
            rtCam.allowMSAA = false;
            rtCam.depth = -1;

            //UICamera rtUICam = rtObj.GetComponent<UICamera>();
            //if(rtUICam == null)
            //{
            //    rtUICam = rtObj.AddComponent<UICamera>();
            //}
            //rtUICam.eventsGoToColliders = true;
            //rtUICam.eventReceiverMask = 0/*1 << LayerMask.NameToLayer("Nothing")*/;

            Transform rtPanTrans = rtTrans.Find("RTPanel");   //ComTool.Get<UIPanel>(rtCam.transform, "RTPanel", "UI Root get sceneRt").transform;\
            if (rtPanTrans == null)
            {
                GameObject newObj = new GameObject("RTPanel");
                GameObject.DontDestroyOnLoad(newObj);
                rtPanTrans = newObj.transform;
                rtPanTrans.parent = rtTrans;
                rtPanTrans.localPosition = Vector3.zero;
                rtPanTrans.localRotation = Quaternion.identity;
                rtPanTrans.localScale = Vector3.one;
            }
            GameObject rtPanObj = rtPanTrans.gameObject;
            rtPanObj.layer = LayerMask.NameToLayer("UI");

            UIPanel rtPanel = rtPanObj.GetComponent<UIPanel>();
            if (rtPanel == null)
            {
                rtPanel = rtPanObj.AddComponent<UIPanel>();
            }
            rtPanel.depth = -1;

            Transform rTexTrans = rtPanTrans.Find("SceneRT");
            if (rTexTrans == null)
            {
                GameObject newObj = new GameObject("SceneRT");
                GameObject.DontDestroyOnLoad(newObj);
                rTexTrans = newObj.transform;
                rTexTrans.parent = rtPanTrans;
                rTexTrans.localPosition = Vector3.zero;
                rTexTrans.localRotation = Quaternion.identity;
                rTexTrans.localScale = Vector3.one;
            }
            GameObject rTexObj = rTexTrans.gameObject;
            rTexObj.layer = LayerMask.NameToLayer("UI");

            UITexture uiTex = rTexObj.GetComponent<UITexture>();
            if (uiTex == null)
            {
                uiTex = rTexObj.AddComponent<UITexture>();
            }
            uiTex.depth = 0;
            uiTex.updateAnchors = UIRect.AnchorUpdate.OnStart;
            uiTex.SetAnchor(rtPanObj, -2, -3002, 2, -2998);
        }

        //// LY add end ////

        /// <summary>
        /// 在相机下查找指定名称的游戏对象
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        public static GameObject Find(string name)
        {
            var hcamTran = UIMgr.HCam.transform;
            var tran = hcamTran.Find(name);
            if (tran != null) return tran.gameObject;
            var camTran = UIMgr.Cam.transform;
            tran = camTran.Find(name);
            if (tran != null) return tran.gameObject;
            var go = GbjPool.Instance.Get(name);
            return go;
        }

        /// <summary>
        /// 设置刘海适配
        /// </summary>
        /// <param name="widget"></param>
        /// <param name="reset"></param>
        /// <param name="oriLeft"></param>
        /// <param name="oriRight"></param>
        /// <param name="left"></param>
        public static void SetLiuHaiAbsolute(UIWidget widget, bool reset, int oriLeft, int oriRight, bool left = true)
        {
            if (!Device.Instance.IsLiuHai) return;
            if (widget == null) return;
            var lc = widget.leftAnchor;
            var rc = widget.rightAnchor;
            var wd = (reset ? 0 : 58);
            if (!left) wd *= -1;
            lc.absolute = oriLeft + wd;
            rc.absolute = oriRight + wd;
            widget.UpdateAnchors();
        }
        #endregion
    }
}