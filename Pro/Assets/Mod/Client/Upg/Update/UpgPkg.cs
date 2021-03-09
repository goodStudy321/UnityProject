/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.6.3 14:34:11
 * 版本号文件内的数据格式:versionCode,versionName,是否强制(0:否,非0:是)
 ============================================================================*/

using System;
using System.IO;
using UnityEngine;
using System.Text;
using System.Threading;
using System.Collections;
using UnityEngine.Networking;


namespace Loong.Game
{

    using Lang = Phantom.Localization;

    /*
     * 1,每次更新包的时候直接更改此处的localVer
     * 2,只要服务器文件中的主版本号比本地文件中主版本号高,即可更新
     */

    /// <summary>
    /// 升级安装包
    /// </summary>
    public class UpgPkg : UpgBase
    {
        #region 字段
        /// <summary>
        /// 强制更新
        /// </summary>
        private bool force = false;

        /// <summary>
        /// 用户版本号
        /// </summary>
        private string verName = "";

        /// <summary>
        /// 缓存版本号文件路径
        /// </summary>
        private string tempVerPath = null;

        /// <summary>
        /// 缓存安装包路径
        /// </summary>
        private string tempPkgPath = null;

        /// <summary>
        /// 服务器安装包名称
        /// </summary>
        private string svrPkgName = null;

#if LOONG_DOWNLOAD_PACKAGE
        private DownloadBase download = new Download();
#else
        private DownloadBase download = null;
#endif
        #endregion

        #region 属性

        public override string VerFile
        {
            get { return UpgUtil.PkgVerFile; }
        }
        public override string Folder
        {
            get { return "Package"; }
        }
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        /// <summary>
        /// 检查是否需要重新下载 返回true时需要下载
        /// </summary>
        private bool CheckDownload()
        {
            if (!File.Exists(tempVerPath)) return true;
            if (!File.Exists(tempPkgPath)) return true;
            var tempVer = VerUtil.LoadFromFile(tempVerPath);
            if (tempVer == SvrVer)
            {
                var msg = string.Format("{0}:{1} need't download", tempVer, SvrVer);
                iTrace.Log("Loong", msg); return false;
            }
            if (tempVer > SvrVer)
            {
                var msg = string.Format("{0}>{1}", tempVer, SvrVer);
                iTrace.Error("Loong", msg);
            }
            else
            {
                DirUtil.DeleteSub(AssetPath.Cache);
            }
            return true;
        }
#if LOONG_DOWNLOAD_PACKAGE
        private void Downloaded(DownloadBase dl, bool suc)
        {
            if (suc)
            {
                FileTool.Save(tempVerPath, SvrVer.ToString());
                SetMsg("安装包下载完成!");
                ProcessInstallFty.Start(tempPkgPath);
            }
            else
            {
                iTrace.Error("Loong", string.Format("下载安装包:{0}失败", dl.Src));
            }
        }
#endif


        /// <summary>
        /// 下载提示
        /// </summary>
        private void DownloadTip()
        {
            string tip = null;
            if (force)
            {
                tip = Lang.Instance.GetDes(617034);
            }
            else
            {
                tip = Lang.Instance.GetDes(617035);
            }
            var msg = Lang.Instance.GetDes(617033);
            msg = string.Format(msg, verName, tip);
            Debug.LogFormat("Loong, {0}", msg);
            var msgBox = MsgBoxProxy.Instance;
            var b1 = Lang.Instance.GetDes(617036);
            var b2 = Lang.Instance.GetDes(690001);
            msgBox.Show(msg, b1, OpenAppStore, b2, Cancel);
            //var tip = force ? "强制" : "可选";
            //var msg = string.Format("获取到新版本{0}({1}更新),请前往前应用商店进行更新", verName, tip);
            //Debug.LogFormat("Loong, {0}", msg);
            //var msgBox = MsgBoxProxy.Instance;
            //msgBox.Show(msg, "前往", OpenAppStore, "取消", Cancel);
        }

        private void Cancel()
        {
            App.CancelUpg = true;
            if (force)
            {
                Quit();
            }
            else
            {
                Complete();
            }
        }


        private void OpenAppStore()
        {
#if UNITY_IOS || UNITY_IPHONE
            AppStoreUtil.Open(App.Info.AID);
#else
            Debug.Log("Loong, select android upgPkg");
#endif
            Quit();
        }

        #endregion

        #region 保护方法

        protected string GetPkgName(int ver)
        {
#if UNITY_ANDROID
            var sfx = ".apk";
#else
            var sfx = ".ipa";

#endif
            var name = string.Format("xyjgx_{0}{1}", ver, sfx);
            return name;
        }

        protected override void Run()
        {
            SetMsg(617037);
            //SetMsg("发现新安装包, 准备下载");
            Thread.Sleep(500);
            string svrPkgPath = string.Format("{0}{1}", svrPrefix, svrPkgName);
            SetMsg(617038);
            //SetMsg("正在玩命下载新安装包中···");
            download.Src = svrPkgPath;
            download.Dest = tempPkgPath;
            download.IsStop = false;
            download.IPro = IPro;
            bool suc = download.Execute();
            Elapsed.Stop();
            iTrace.Log("Loong", string.Format("upgPkg elapsed time:{0}", Elapsed.Elapsed.TotalSeconds));
            if (suc)
            {
                Complete();
            }
            else
            {
                Failure();
            }
        }


        protected override void Begin()
        {
            base.Begin();
#if LOONG_DOWNLOAD_PACKAGE

            if (CheckDownload())
            {
                StartThread();
            }
            else
            {
                svrPkgName = GetPkgName(SvrVer);
                tempPkgPath = string.Format("{0}/{1}", AssetPath.Cache, svrPkgName);
                ProcessInstallFty.Start(tempPkgPath);
            }
#else
            DownloadTip();
#endif
        }

        protected override void LoadVer()
        {
            MonoEvent.Start(YieldLoadVer());
        }


        protected IEnumerator YieldLoadVer()
        {
            var path = svrVerPath;
            using (UnityWebRequest request = UnityWebRequest.Get(path))
            {
                yield return request.SendWebRequest();
                var err = request.error;
                var text = request.downloadHandler.text;
                int ver = 0;
                if (!string.IsNullOrEmpty(err))
                {
                    Debug.LogErrorFormat("Loong, get ver err:{0}, path:{1}", err, path);
                }
                else if (string.IsNullOrEmpty(text))
                {
                    Debug.LogErrorFormat("Loong, no ver :{0}", path);
                }
                else
                {
                    text = text.Trim();
                    var arr = text.Split(',');
                    int length = arr.Length;
                    if (length > 2)
                    {
                        int op = 0;
                        var str = arr[2];
                        if (!int.TryParse(str, out op))
                        {
                            Debug.LogErrorFormat("Loong,upgPkg verText, force not can parse:{0}, {1}", str, path);
                        }
                        else
                        {
                            Debug.LogFormat("Loong,upgPkg verText,force:{0}", op);
                        }
                        force = ((op == 0) ? false : true);
                    }

                    if (length > 1)
                    {
                        verName = arr[1];
                    }

                    var strVer = arr[0].Trim();
                    if (!int.TryParse(strVer, out ver))
                    {
                        Debug.LogErrorFormat("Loong,upgPkg verText, ver not can parse:{0}, {1}", strVer, text);
                    }
                }
                SetSvrVer(ver, err);
            }
        }

#if !LOONG_DOWNLOAD_PACKAGE
        protected override void ChkCarrier()
        {
            Begin();
        }
#endif


        protected override void SetSvrVerPath()
        {
            var cid = (App.IsReleaseDebug ? "Test_" : "");
            svrVerPath = string.Format("{0}{1}{2}", svrPrefix, cid, VerFile);
        }
        #endregion

        #region 公开方法

        public override void Init()
        {
            base.Init();
#if LOONG_DOWNLOAD_PACKAGE
            download.complete += Downloaded;
#endif
            LocalVer = App.VerCode;
            tempVerPath = string.Format("{0}{1}", AssetPath.Cache, VerFile);
        }


        public override void Update()
        {

        }

        public override void Stop()
        {
            base.Stop();
            if (download != null) download.Stop();
        }

        public override void Dispose()
        {
            base.Dispose();
            if (download != null) download.Dispose();
            download = null;
        }
        #endregion
    }
}