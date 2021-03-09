/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2015/3/20 00:00:00
 * 1,加载时首先判断需要加载的资源是否已经存在于资源列表
 *    A,如果存在,没有设置在结束时解析回调,直接CallBack,并返回;
 *    B,如果不存在,则将需要加载的资源,添加到正在下载的资源列表;
 * 2,所有的资源下载完成时,会执行结束操作列表,并且在执行完后自动注销
 * 3,进度是以加载资源的粒度/数量计算的
 * 4,建议对Prefab通过预加载到对象池,再从对象池中获取
 * 5,对于接口的使用可以参考TestAssetMgr
 ============================================================================*/

using System;
using UnityEngine;
using LuaInterface;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Game
{

    public delegate void GbjHandler(GameObject go);


    /// <summary>
    /// 资源管理和加载类
    /// </summary>
    public static class AssetMgr
    {
        #region 字段

        private static IAssetLoad iAssetLoad = null;

        private static LoadResMode mode = LoadResMode.AB;

        #endregion

        #region 属性
        /// <summary>
        /// 加载资源模式
        /// 仅在编辑器下有效
        /// </summary>
        public static LoadResMode Mode
        {
            get { return mode; }
            set { mode = value; }
        }


        /// <summary>
        /// 资源加载接口
        /// </summary>
        public static IAssetLoad Instance
        {
            get { return iAssetLoad; }
        }

        #endregion

        #region 构造方法
        static AssetMgr()
        {

        }
        #endregion

        #region 私有方法

        private static IEnumerator YieldStart()
        {
            for (int i = 0; i < 2; i++)
            {
                yield return null;
            }
            iAssetLoad.Start();
        }

        /// <summary>
        /// 打开进度回调
        /// </summary>
        /// <param name="name"></param>
        private static void LoadCallback(string name)
        {
            if (!string.IsNullOrEmpty(name))
            {
                IProgress loading = null;
                if (!UILoading.Instance.Exist)
                {
                    LuaTable luaTable = UIMgr.Get(name);
                    UILoading.Instance.Refresh(luaTable);
                }
                loading = UILoading.Instance;
                //loading.SetMessage("加载资源中···");
                Instance.IPro = loading;
            }
            PreloadMgr.Execute();
            MonoEvent.Start(YieldStart());
            //Instance.Start();
        }

        private static void Unload(string name, string sfx)
        {
            Instance.Unload(name, sfx);
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public static void Init()
        {
            AssetLoadBase ins = null;
#if UNITY_EDITOR
            if (mode == LoadResMode.AB)
            {
                ins = new AssetLoadSync();
            }
            else
            {
                ins = new AssetLoadRes();
            }
#else
            ins = new AssetLoadSync();
#endif
            iAssetLoad = ins;
            ins.Init();
            AssetBridge.unload -= Unload;
            AssetBridge.unload += Unload;
        }

        /// <summary>
        /// 加载游戏物体,先从对象池中获取,如果没有再去加载
        /// </summary>
        /// <param name="name">名称,无后缀</param>
        /// <param name="callBack">回调,尽量不要使用匿名委托和Lamda表达式</param>
        public static void LoadPrefab(string name, GbjHandler callBack)
        {
            if (callBack == null) return;
            if (string.IsNullOrEmpty(name)) return;
            GameObject go = GbjPool.Instance.Get(name);
            if (go != null)
            {
                go.transform.parent = null;
                go.SetActive(true);
                QualityMgr.instance.ChangeGoQuality(go);
                callBack(go);
            }
            else
            {
                DelGbj dg = ObjPool.Instance.Get<DelGbj>();
                dg.handler += callBack;
                Instance.Load(name, Suffix.Prefab, dg.Callback);
            }
        }

        /// <summary>
        /// 启动加载,封装进度条
        /// </summary>
        /// <param name="uiName">进度条名称,对应类型必须继承接口IProgress</param>
        public static void Start(string uiName = "UILoading")
        {
            if (string.IsNullOrEmpty(uiName))
            {
                LoadCallback(null);
            }
            else
            {
                UIMgr.Open(uiName, LoadCallback);
            }
        }

        #endregion
    }
}