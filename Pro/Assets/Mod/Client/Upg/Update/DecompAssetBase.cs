//=============================================================================
// Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
// Created by Loong in 2014.6.3 14:19:39
// 1. 子类需重写Begin
//=============================================================================

using System;
using System.IO;
using UnityEngine;
using System.Diagnostics;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    using Lang = Phantom.Localization;

    using Debug = UnityEngine.Debug;
    using Md5Dic = Dictionary<string, Md5Info>;

    /// <summary>
    /// 解压内部资源基类
    /// </summary>
    public abstract class DecompAssetBase : IDisposable
    {
        #region 字段
        private int lastAppVer = -1;
        private IProgress ipro = null;
        private string assetVerPath;

        /// <summary>
        /// 初始内存
        /// </summary>
        protected int srcMem = 0;
        /// <summary>
        /// true:覆盖安装
        /// </summary>
        protected bool overlay = false;
        protected string localAppVerPath = null;
        /// <summary>
        /// 耗时
        /// </summary>
        protected ElapsedTime elapsed = new ElapsedTime();


        #endregion

        #region 属性

        /// <summary>
        /// 进度接口
        /// </summary>
        public IProgress IPro
        {
            get { return ipro; }
            set { ipro = value; }
        }

        #endregion

        #region 事件

        /// <summary>
        /// 结束事件
        /// </summary>
        public event Action complete = null;

        #endregion

        #region 构造方法
        public DecompAssetBase()
        {

        }
        #endregion

        #region 私有方法

        /// <summary>
        /// 拷贝上一个清单配置
        /// </summary>
        private void CopyLastMf()
        {
            if (!App.IsSubAssets) return;
            var dest = GetVerMfPath(lastAppVer);
            if (File.Exists(dest)) return;
            var mfPath = AssetMf.GetValidPath();
            if (mfPath == null) return;
            FileTool.SafeCopy(mfPath, dest);
            Debug.LogFormat("Loong, overlay install beg, copy last mf {0} to {1}", mfPath, dest);
        }


        /// <summary>
        /// 获取指定版本号的清单文件路径
        /// </summary>
        /// <param name="appVer">程序版本号</param>
        /// <returns></returns>
        private string GetVerMfPath(int appVer)
        {
            var name = AssetMf.Name;
            var dir = AssetPath.Persistent;
            return string.Format("{0}/{1}_{2}", dir, name, appVer);
        }
        #endregion

        #region 保护方法
        protected void Exit()
        {
            App.Quit();
        }

        protected void SaveVer()
        {
            FileTool.SafeSave(assetVerPath, App.Info.InAssetVer.ToString());
            FileTool.SafeSave(localAppVerPath, App.VerCode.ToString());
        }

        /// <summary>
        /// 解压成功
        /// </summary>
        protected void Success()
        {
            AssetMf.Init();
            UpgUtil.DeleteFail();
            if (!overlay) return;
            if (!App.IsSubAssets) return;
            var lastMfPath = GetVerMfPath(lastAppVer);
            var lastDic = AssetMf.Read(lastMfPath);
            if (lastDic == null) return;
            var dic = AssetMf.Dic;
            if (dic == null) return;
            string k = null;
            Md5Info curInfo = null;
            Md5Info lastInfo = null;
            var em = lastDic.GetEnumerator();
            while (em.MoveNext())
            {
                var it = em.Current;
                k = it.Key;
                if (!dic.ContainsKey(k)) continue;
                lastInfo = it.Value;
                curInfo = dic[k];
                if (curInfo.Ver != lastInfo.Ver) continue;
                if (lastInfo.MD5 != curInfo.MD5) continue;
                curInfo.Op = lastInfo.Op;
            }
            AssetMf.Save();
            FileTool.SafeDelete(lastMfPath);
            Debug.LogFormat("Loong, overlay install end, lastMfPath:{0}", lastMfPath);
        }

        /// <summary>
        /// 设置准备初始化
        /// </summary>
        protected void SetReadyInit()
        {
            SetMessage(617012);
            //SetMessage("准备初始化,请稍候");
        }


        protected void SetBeginInit()
        {
            SetMessage(617013);
            //SetMessage("首次进入初始化时间较长，请稍作等待(初始化不消耗流量)");
        }

        protected void SetMessage(string msg)
        {
            if (IPro != null)
            {
                IPro.SetMessage(msg);
            }
        }

        protected void SetMessage(uint id)
        {
            var msg = Lang.Instance.GetDes(id);
            if (IPro != null) IPro.SetMessage(msg);
        }

        /// <summary>
        /// 有文件需要解压完成
        /// 设置进度;保存版本号;抛出结束事件;垃圾回收
        /// </summary>
        protected void DecompComplete()
        {
            if (IPro != null)
            {
                var msg = Lang.Instance.GetDes(617014);
                //var msg = "初始化完成,校验中,请稍候";
                IPro.SetProgress(1f);
                IPro.SetMessage(msg);
            }
            SaveVer();
            Complete();
            GC.Collect();

        }

        /// <summary>
        /// 执行结束回调
        /// </summary>
        protected virtual void Complete()
        {
            //elapsed.End();
            Success();
            MonoEvent.AddOneShot(complete);
            if (App.IsDebug || App.IsEditor || App.IsReleaseDebug)
            {
                MonoEvent.AddOneShot(ShowLog);
            }
        }

        private void ShowLog()
        {
            var mem = Device.Instance.AvaiMem - srcMem;

            elapsed.End("{0}, mem:{1}", this.GetType().Name, mem);
        }

        /// <summary>
        /// 开始解压资源
        /// </summary>
        /// <returns></returns>
        protected virtual void Begin()
        {
            srcMem = Device.Instance.AvaiMem;
        }

        #endregion

        #region 公开方法
        /// <summary>
        /// 开始
        /// </summary>
        public void Start()
        {
            if (IPro != null) IPro.SetProgress(0);
            elapsed.Beg();
            if (File.Exists(localAppVerPath))
            {
                lastAppVer = VerUtil.LoadFromFile(localAppVerPath);
                Debug.LogFormat("Loong, in appVer:{0} lastAppVer:{1}", App.VerCode, lastAppVer);
                if (App.VerCode > lastAppVer)
                {
                    CopyLastMf();
                    overlay = true;
                    App.FirstInstall = true;
                    TechBuried.Instance.First();
                    Begin();
                }
                else
                {
                    Complete();
                }
            }
            else
            {
                App.FirstInstall = true;
                TechBuried.Instance.First();
                Begin();
            }
        }

        public virtual void Init()
        {
            string verFile = UpgUtil.AssetVerFile;
            string persistPath = Application.persistentDataPath;
            assetVerPath = persistPath + "/" + verFile;
            localAppVerPath = persistPath + "/AppVer.txt";
        }

        public virtual void Stop()
        {

        }

        public virtual void Dispose()
        {
            ipro = null;
            complete = null;
        }
        #endregion
    }
}