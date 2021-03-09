/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.6.3 20:09:25
 ============================================================================*/

using System;
using System.Text;
using UnityEngine;
using System.Threading;
using System.Diagnostics;
using System.Collections;

namespace Loong.Game
{
    using Lang = Phantom.Localization;
    using UApp = Application;
    using NRB = NetworkReachability;
    using Debug = UnityEngine.Debug;

    /// <summary>
    /// 升级抽象基类
    /// </summary>
    public abstract class UpgBase : IDisposable, IError, IStart
    {
        #region 字段
        private int svrVer = 0;
        private int localVer = 0;
        private bool running;
        private string error = "";
        private string url = null;
        private IProgress iPro = null;

        private string localVerPath = null;

        private Stopwatch sw = new Stopwatch();

        /// <summary>
        ///服务器路径前缀
        /// </summary>
        protected string svrPrefix = null;
        protected string svrVerPath = null;

        /// <summary>
        /// 结束事件
        /// </summary>
        public event Action complete = null;

        #endregion

        #region 属性
        /// <summary>
        /// 版本号文件名
        /// </summary>
        public virtual string VerFile
        {
            get { return ""; }
        }

        /// <summary>
        /// 存放资源的文件夹
        /// </summary>
        public virtual string Folder
        {
            get { return ""; }
        }

        /// <summary>
        /// 本地版本号
        /// </summary>
        public int LocalVer
        {
            get { return localVer; }
            protected set { localVer = value; }
        }

        /// <summary>
        /// 服务器版本号
        /// </summary>
        public int SvrVer
        {
            get { return svrVer; }
            protected set { svrVer = value; }
        }

        /// <summary>
        /// true:运行中
        /// </summary>
        public bool Running
        {
            get { return running; }
            set { running = value; }
        }

        /// <summary>
        /// 错误信息
        /// </summary>
        public string Error
        {
            get { return error; }
            set { error = value; }
        }

        /// <summary>
        /// 耗时
        /// </summary>
        public Stopwatch Elapsed
        {
            get { return sw; }
        }


        /// <summary>
        /// IP地址
        /// </summary>
        public string Url
        {
            get { return url; }
            set
            {
                url = value;
                if (string.IsNullOrEmpty(svrPrefix))
                {
                    svrPrefix = GetSvrPrefix();
                }
                SetSvrVerPath();
            }
        }

        /// <summary>
        /// 本地版本号文件路径
        /// </summary>
        public string LocalVerPath
        {
            get { return localVerPath; }
            set { localVerPath = value; }
        }

        /// <summary>
        /// 进度接口
        /// </summary>
        public IProgress IPro
        {
            get { return iPro; }
            set { iPro = value; }
        }

        public string SvrPrefix
        {
            get { return svrPrefix; }
        }
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        /// <summary>
        /// 加载服务器版本号
        /// </summary>
        protected void SetSvrVer(int ver, string err)
        {
            SvrVer = ver;
            if (string.IsNullOrEmpty(err))
            {
                var tn = this.GetType().Name;
                var msg = string.Format("{0}, localVer:{1}, svrVer:{2}, ver:{3}", tn, LocalVer, SvrVer, ver);
                iTrace.Log("Loong", msg);

                if (SvrVer > LocalVer)
                {
                    ChkCarrier();
                }
                else
                {
                    Complete();
                }
            }
            else
            {
                var msg = Lang.Instance.GetDes(UpgUtil.GetVerFailDes());
                Failure(msg);
            }
        }

        #region 保护方法

        /// <summary>
        /// 执行结束回调
        /// </summary>
        protected virtual void Complete()
        {
            Running = false;
            if (complete == null) return;
            MonoEvent.AddOneShot(complete);
        }

        /// <summary>
        /// 设置信息
        /// </summary>
        protected void SetMsg(string value)
        {
            if (iPro != null) iPro.SetMessage(value);
        }

        protected void SetMsg(uint id)
        {
            var msg = Lang.Instance.GetDes(id);
            SetMsg(msg);
        }

        /// <summary>
        /// 设置进度
        /// </summary>
        protected void SetPro(float value)
        {
            if (iPro != null) iPro.SetProgress(value);
        }

        /// <summary>
        /// 设置提示
        /// </summary>
        /// <param name="value"></param>
        protected void SetTip(string value)
        {
            if (iPro != null) iPro.SetTip(value);
        }

        /// <summary>
        /// 退出
        /// </summary>
        protected void Quit()
        {
            App.Quit();
        }


        /// <summary>
        /// 失败时弹出对话框
        /// </summary>
        /// <param name="msg"></param>
        protected void Failure(string msg = null)
        {
            if (string.IsNullOrEmpty(msg))
            {
                msg = Lang.Instance.GetDes(UpgUtil.GetCheckNetDes());
            }
            var b1 = Lang.Instance.GetDes(690019);
            var b2 = Lang.Instance.GetDes(690001);

            MsgBoxProxy.Instance.Show(msg, b1, Start, b2, Quit);
            //if (string.IsNullOrEmpty(msg)) msg = UpgUtil.GetCheckNetDes();
            //MsgBoxProxy.Instance.Show(msg, "重试", Start, "取消", Quit);
            Running = false;
            SetMsg(msg);
        }

        /// <summary>
        /// 获取本地资源完整路径
        /// </summary>
        /// <param name="name">相对路径</param>
        /// <returns></returns>
        protected string GetLocalPath(string name)
        {
            string path = string.Format("{0}/{1}", AssetPath.Persistent, name);
            return path;
        }


        protected string GetSvrPrefix()
        {
            var path = UpgUtil.GetUrl(url, Folder);
            return path;
        }

        /// <summary>
        /// 开始准备线程运行
        /// </summary>
        protected abstract void Run();


        /// <summary>
        /// 开始更新
        /// </summary>
        protected virtual void Begin()
        {
            sw.Reset();
            sw.Start();
            Error = "";
        }


        /// <summary>
        /// 检查在更新开始之前是否使用流量
        /// </summary>
        protected virtual void ChkCarrier()
        {
            /*if (NetObserver.IsCarrier())
            {
                string msg = "检查到更新,继续将消耗流量";
                MsgBoxProxy.Instance.Show(msg, "确定", Begin, "取消", Quit);
            }
            else*/
            {
                Begin();
            }
        }

        /// <summary>
        /// 设置服务器版本号文件路径
        /// </summary>
        protected virtual void SetSvrVerPath()
        {
#if ANDROID_SDK_NONE || IOS_SDK_NONE
            svrVerPath = string.Format("{0}{1}", svrPrefix, VerFile);
#else
            var cid = (App.IsReleaseDebug ? "Test" : App.GameChannelID);
            svrVerPath = string.Format("{0}{1}_{2}", svrPrefix, cid, VerFile);
#endif
        }

        protected virtual void LoadVer()
        {
            MonoEvent.Start(VerUtil.Load(svrVerPath, SetSvrVer));
        }

        #endregion

        #region 公开方法

        /// <summary>
        /// 启动
        /// </summary>
        public virtual void Start()
        {
            if (NetObserver.NoNet())
            {
                Failure();
            }
            else
            {
                Clear();
                SetPro(0);
                var tn = this.GetType().Name;
                var rPath = svrVerPath.Substring(UpgUtil.Host.Length);
                Debug.LogFormat("Loong,{0} beg check:{1}", tn, rPath);
                LoadVer();
            }
        }

        public virtual void Clear()
        {

        }


        public virtual void Init()
        {

        }

        /// <summary>
        /// 更新
        /// </summary>
        public abstract void Update();

        /// <summary>
        /// 释放
        /// </summary>
        public virtual void Dispose()
        {

        }

        public virtual void Stop()
        {

        }

        public virtual void OnDestory()
        {

        }
        #endregion
    }
}