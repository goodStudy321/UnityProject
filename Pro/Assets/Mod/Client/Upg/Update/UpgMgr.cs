/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.6.3
 * 为了流畅性使用后台线程处理解压和下载
 ============================================================================*/

using System;
using UnityEngine;

namespace Loong.Game
{
    using Lang = Phantom.Localization;

    /// <summary>
    /// 升级管理
    /// </summary>
    public class UpgMgr : IDisposable
    {

        #region 字段

        private string url;

        private UpgState state = UpgState.None;

        /// <summary>
        /// 更新安装包模块
        /// </summary>
        private UpgPkg upgPkg = new UpgPkg();

        private DecompAssetBase decomp = null;


        private UpgAssets upgAsset = new UpgAssets();


        public static readonly UpgMgr Instance = new UpgMgr();
        #endregion

        #region 属性

        /// <summary>
        /// ip地址
        /// </summary>
        public string URL
        {
            get { return url; }
            set { url = value; }
        }

        /// <summary>
        /// 运行状态
        /// </summary>
        public UpgState State
        {
            get { return state; }
            private set { state = value; }
        }

        /// <summary>
        /// 解压缩资源
        /// </summary>
        public DecompAssetBase Decomp
        {
            get { return decomp; }
        }

        /// <summary>
        /// 更新资源模块
        /// </summary>
        public UpgAssets UpgAssets
        {
            get { return upgAsset; }
        }

        /// <summary>
        /// 更新安装包
        /// </summary>
        public UpgPkg UpgPkg
        {
            get { return upgPkg; }
        }
        #endregion

        #region 事件
        /// <summary>
        /// 加载完成时的回调
        /// </summary>
        public event Action complete = null;
        #endregion

        #region 构造方法
        private UpgMgr()
        {

        }
        #endregion

        #region 私有方法

        private void Complete()
        {
            MonoEvent.update -= Update;
#if UNITY_EDITOR
            MonoEvent.onDestroy -= OnDestroy;
#endif
            AssetPath.Refresh();
            AssetMgr.Instance.Refresh();
            ProgressProxy.Instance.SetMessage(617031);
            //ProgressProxy.Instance.SetMessage("结束更新");
            if (complete != null) complete();
            Dispose();
            GC.Collect();
        }

        private void SetOver()
        {
            App.AssetVer = upgAsset.LocalVer;
            State = UpgState.Over;
            GC.Collect();
        }

        /// <summary>
        /// 重置
        /// </summary>
        private void Reset()
        {
            State = UpgState.None;
        }

        private void Update()
        {
            MsgBoxProxy.Instance.Update();
            ProgressProxy.Instance.Update();
            if (state == UpgState.Over)
            {
                Complete();
            }
            else
            {
                upgAsset.Update();
            }
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        public void Init()
        {
            upgAsset.Url = url;
            upgAsset.IPro = ProgressProxy.Instance;
            upgAsset.complete += SetOver;
            upgAsset.Init();

            if (decomp == null) decomp = PkgMgr.Instance.Create();
            decomp.Init();
            decomp.IPro = ProgressProxy.Instance;
            decomp.complete += upgAsset.Start;

            upgPkg.Url = url;
            upgPkg.IPro = ProgressProxy.Instance;
            upgPkg.complete += decomp.Start;

            upgPkg.Init();
            MonoEvent.update += Update;
#if UNITY_EDITOR
            MonoEvent.onDestroy += OnDestroy;
#endif
            UpgUtil.Init();
        }
        /// <summary>
        /// 启动更新
        /// </summary>
        public void Start()
        {
            if (string.IsNullOrEmpty(url))
            {
                iTrace.Error("Loong", "无IP");
            }
            if (state == UpgState.Run)
            {
                iTrace.Error("Loong", "已经启动更新");
            }
            else
            {
                State = UpgState.Run;
                ProgressProxy.Instance.Open();
                string msg = Lang.Instance.GetDes(617032);
                //string msg = "准备初始化";
                ProgressProxy.Instance.SetMessage(msg);
                iTrace.Log("Loong", msg);
                upgPkg.Start();
            }
        }

        /// <summary>
        /// 停止
        /// </summary>
        public void Stop()
        {
            if (state == UpgState.Stop) return;
            State = UpgState.Stop;
            upgPkg.Stop();
            upgAsset.Stop();

        }

        /// <summary>
        /// 释放
        /// </summary>
        public void Dispose()
        {
            Reset();
            decomp.Dispose();
            upgPkg.Dispose();
            upgAsset.Dispose();
            MonoEvent.update -= Update;
            complete = null;
        }

        public void OnDestroy()
        {
            decomp.Stop();
            upgPkg.Stop();
            upgAsset.Stop();
        }

        #endregion
    }

}