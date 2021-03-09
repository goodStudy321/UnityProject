using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.8.10
    /// BG:场景九宫格管理
    /// </summary>
    public static class SceneGridMgr
    {
        #region 字段
        private static bool running = false;

        private static Transform root = null;

        private static SceneGrid current = null;

        /// <summary>
        /// 根结点名称
        /// </summary>
        public const string RootName = "SceneRoot";
        #endregion

        #region 属性

        /// <summary>
        /// 根结点
        /// </summary>
        public static Transform Root
        {
            get
            {
                if (root == null)
                {
                    GameObject go = GameObject.Find(RootName);
                    if (go != null) root = go.transform;
                }
                return root;
            }
        }

        /// <summary>
        /// true:运行
        /// </summary>
        public static bool Running
        {
            get { return running; }
            set { running = value; }
        }

        /// <summary>
        /// 当前九宫格
        /// </summary>
        public static SceneGrid Current
        {
            get { return current; }
            set { current = value; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        static SceneGridMgr()
        {
            UnitEventMgr.create += UpdateModel;
            PendantMgr.instance.FashionChangeDone += UpdateModel;
        }
        #endregion

        #region 私有方法

        private static void LoadCallback(Object obj)
        {
            Current = obj as SceneGrid;
        }

        /// <summary>
        /// 玩家模型更新
        /// </summary>
        /// <param name="unit"></param>
        private static void UpdateModel(Unit unit)
        {
            if (Current == null) return;
            if (unit.UnitUID != User.instance.MapData.UID) return;
            Current.Target = unit.UnitTrans;
        }

        /// <summary>
        /// 设置玩家
        /// </summary>
        private static void SetPlayer()
        {
            if (InputMgr.instance.mOwner == null) return;
            if (Current == null) return;
            Current.Target = InputMgr.instance.mOwner.UnitTrans;
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static void Update()
        {
            if (!running) return;
            if (current == null) return;
            current.Update();
        }

        /// <summary>
        /// 预加载
        /// </summary>
        public static void Preload(SceneInfo info)
        {
            if (info == null) return;
            if (string.IsNullOrEmpty(info.gridName))
            {
                //iTrace.eError("Loong", string.Format("ID为:{0}的场景资源表没有配置九宫格", info.id));
                return;
            }
            if (current != null) if (info.gridName == current.name) return;
            AssetMgr.Instance.Load(info.gridName, Suffix.Asset, LoadCallback);
        }

        /// <summary>
        /// 开始
        /// </summary>
        public static void Start()
        {
            if (Current == null)
            {
                return;
            }
            else if (Root == null)
            {
                string error = string.Format("没有发现根结点:{0}", RootName);
                iTrace.Error("Loong", error);
            }
            else if (Running)
            {
                iTrace.Error("Loong", "已经运行,无需重复启动");
            }
            else
            {
                SetPlayer();
                Running = true;
                Current.Init();
                iTrace.eLog("Loong", string.Format("启动九宫格:{0}", Current.name));
            }
        }

        public static void Dispose()
        {
            if (current != null) Object.Destroy(current);
            Current = null;
            Running = false;
        }
        #endregion
    }
}