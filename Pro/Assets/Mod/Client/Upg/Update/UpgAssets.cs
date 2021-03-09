/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.6.3 20:09:25
 ============================================================================*/

using System;
using System.IO;
using System.Text;
using UnityEngine;
using System.Threading;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.Networking;


namespace Loong.Game
{
    using Lang = Phantom.Localization;
    using Md5Dic = Dictionary<string, Md5Info>;
    /// <summary>
    /// AU:Loong
    /// TM:2014.6.3
    /// BG:升级资源包
    /// </summary>
    public class UpgAssets : UpgBase
    {
        #region 字段

        private int lastVer = 0;

        private bool isQuiet = false;

        /// <summary>
        /// true:重启游戏
        /// </summary>
        private bool isRestart = false;

        /// <summary>
        /// 服务器清单路径
        /// </summary>
        private string svrMfPath = null;

        /// <summary>
        /// 缓存服务器未压缩清单文件路径
        /// </summary>
        private string tempMfPath = null;

        /// <summary>
        /// 缓存服务器压缩清单文件路径
        /// </summary>
        private string tempCompMfPath = null;

        /// <summary>
        /// 升级详细信息
        /// </summary>
        private UpgInfo upgInfo = null;

        /// <summary>
        /// 服务器文件字典
        /// </summary>
        private Md5Dic svrFileDic = null;

        /// <summary>
        /// 资源下载
        /// </summary>
        private AssetDl dl = new AssetDl();

        private DecompBase decomp = null;

        private List<Md5Info> infos = null;

        /// <summary>
        /// 静默更新阈值
        /// </summary>
        private long quietThreshold = 0;

        #endregion

        #region 属性
        public long Total
        {
            get { return dl.Total; }
        }

        /// <summary>
        /// 上一个版本
        /// </summary>
        public int LastVer
        {
            get { return lastVer; }
        }

        /// <summary>
        /// true:静默模式 ：1:无移动流量提示,2:各种提示和更新无关
        /// </summary>
        public bool IsQuiet
        {
            get { return isQuiet; }
            private set { isQuiet = value; }
        }


        public override string Folder
        {
            get { return "Assets"; }
        }

        public override string VerFile
        {
            get { return UpgUtil.AssetVerFile; }
        }
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        private void Upload()
        {
#if LOONG_ENABLE_UPG
            TechBuried.Instance.UpgAssets(this);
#endif
        }

        /// <summary>
        /// 设置服务器清单路径
        /// </summary>
        private void SetSvrMfPath()
        {
            svrMfPath = string.Format("{0}{1}/{2}", svrPrefix, SvrVer, AssetMf.Name);
        }

        /// <summary>
        /// 下载清单文件并保存到缓存目录
        /// </summary>
        /// <param name="cb">下载完成回调,参数不为空:下载失败</param>
        /// <returns></returns>
        private IEnumerator LoadMf(Action<string> cb)
        {

            SetSvrMfPath();
            using (UnityWebRequest request = UnityWebRequest.Get(svrMfPath))
            {
                yield return request.SendWebRequest();
                string err = request.error;
                if (string.IsNullOrEmpty(err))
                {
                    FileTool.SafeSaveBytes(tempMfPath, request.downloadHandler.data);
#if UNITY_EDITOR
                    Debug.LogFormat("Loong, download manifest:{0} suc", svrMfPath);
#endif
                }
                else
                {
                    Debug.LogWarningFormat("Loong, download manifest err:{0}, path:{1}", err, svrMfPath);
                }
                if (cb != null) cb(err);
            }
        }

        private void LoadMfCb(byte[] bytes)
        {
            if (bytes == null)
            {
                var msg = Lang.Instance.GetDes(GetMfFailDes());
                Failure(msg);
            }
            else
            {
                tempMfPath = GetTempMfPath();
                tempCompMfPath = GetTempMfPath("Comped");
                FileTool.SafeSaveBytes(tempCompMfPath, bytes);
                decomp.Src = tempCompMfPath;
                decomp.Dest = tempMfPath;
                if (decomp.Execute())
                {
                    Thread.Sleep(10);
                    Run();
                }
                else
                {
                    var msg = Lang.Instance.GetDes(GetMfFailDes());
                    Failure(msg);
                }
            }
        }

        /// <summary>
        /// 获取清单失败描述
        /// </summary>
        /// <returns></returns>
        private uint GetMfFailDes()
        {
            return 617016;
            //var msg = "获取清单信息失败," + UpgUtil.GetCheckNetDes();
            //return msg;
        }

        /// <summary>
        /// 更新成功描述
        /// </summary>
        /// <returns></returns>
        private uint GetSucDes()
        {
            return (uint)(IsQuiet ? 617024 : 617025);
            //return IsQuiet ? "初始化成功" : "恭喜你,获取更新成功";
        }

        /// <summary>
        /// 发现新资源描述
        /// </summary>
        /// <returns></returns>
        private uint GetNewDes()
        {
            return (uint)(IsQuiet ? 617026 : 617027);
            //return IsQuiet ? "准备中,请稍候" : "发现新资源,请稍候";
        }

        /// <summary>
        /// 获取升级流量
        /// </summary>
        /// <returns></returns>
        private string GetFlowDes(long total)
        {
            var tt = ByteUtil.FmtByCalc(total, 100);
            var msg = Lang.Instance.GetDes(617028);
            msg = string.Format(msg, tt);
            //var msg = string.Format("检查到更新,继续将消耗:{0}M流量", tt);
            return msg;
        }

        private uint GetRestartDes()
        {
            return 617029;
            //return "为了更好的游戏体验!\n本次需要重启!";
        }

        /// <summary>
        /// 获取静默更新描述
        /// </summary>
        /// <returns></returns>
        private string GetQuietDes()
        {
            return Lang.Instance.GetDes(617030);
            //return "初始化中,请稍候";
        }


        /// <summary>
        /// 校验所有文件回调
        /// </summary>
        /// <param name="suc"></param>
        private void Downloaded(bool suc, string err)
        {
            if (suc)
            {
                SetPro(1f);
                Thread.Sleep(20);
                string verStr = SvrVer.ToString();
                FileTool.SafeSave(LocalVerPath, verStr);
#if GAME_DEBUG
                Debug.LogFormat("Loong, upgAssets suc,save localVer:{0}", verStr);
#endif
                var msg = Lang.Instance.GetDes(GetSucDes());
                SetMsg(msg);
                FileTool.SafeDelete(tempMfPath);
                FileTool.SafeDelete(tempCompMfPath);
                AssetMf.Delete(upgInfo.deleted);
                LocalVer = SvrVer;
                Thread.Sleep(200);
                Complete();
            }
            else
            {
                Failure();
                Error = err;
            }
            MonoEvent.AddOneShot(Upload);
#if GAME_DEBUG
            Elapsed.Stop();
            Debug.LogFormat("Loong, upgAssets, eplased time:{0}", Elapsed.Elapsed.TotalSeconds);
#endif
        }

        private void SetRestart(List<Md5Info> infos)
        {
            if (infos == null) return;
            int length = infos.Count;
            var targetName = UpgUtil.HotfixName;
            for (int i = 0; i < length; i++)
            {
                var info = infos[i];
                if (info.path == targetName)
                {
                    ListTool.Swap<Md5Info>(infos, 0, i);
                    isRestart = true; break;
                }
            }
        }

        private void Restart()
        {
            App.Restart();
        }

        private IEnumerator LoadVer(string path)
        {
            using (UnityWebRequest request = UnityWebRequest.Get(path))
            {
                yield return request.SendWebRequest();
                var err = request.error;
                if (string.IsNullOrEmpty(err))
                {
                    var text = request.downloadHandler.text.Trim();
                    Debug.LogFormat("Loong, get assetVer text:{0}", text);
                    var arr = text.Split(',');
                    var len = arr.Length;
                    if (len > 2)
                    {
                        long.TryParse(arr[2], out quietThreshold);
                    }
                    if (len > 1)
                    {
                        int arg = 0;
                        int.TryParse(arr[1], out arg);
                        IsQuiet = ((arg == 1) ? true : false);
                    }
                    if (len > 0)
                    {
                        var ver = 0;
                        int.TryParse(arr[0], out ver);
                        SetSvrVer(ver, null);
                    }
                }
                else
                {
                    var msg = Lang.Instance.GetDes(UpgUtil.GetVerFailDes());
                    Failure(msg);
                }
            }
        }

        #endregion

        #region 保护方法

        protected override void LoadVer()
        {
            MonoEvent.Start(LoadVer(svrVerPath));
        }

        protected override void Run()
        {
            svrFileDic = AssetMf.Read(tempMfPath);
            upgInfo = AssetMf.GetInfo(svrFileDic);
            infos = upgInfo.GetFixes();
            if (!isRestart) SetRestart(infos);
            GC.Collect();
            if (infos == null || infos.Count < 1)
            {
                Debug.LogWarningFormat("Loong,LocalVer:{0}, SvrVer:{1} no upgassets", LocalVer, SvrVer);
                Complete();
            }
            else
            {
                var total = dl.GetTotal(infos);
                if (isRestart)
                {
                    IsQuiet = false;
                }
                else
                {
                    if (quietThreshold > 0 && IsQuiet)
                    {
                        IsQuiet = (total < quietThreshold);
                    }
                }
                if (IsQuiet)
                {
                    dl.CanSetMsg = false;
                    SetMsg(GetQuietDes());
                    RealRun();
                }
                else if (NetObserver.IsCarrier())
                {
                    var msg = GetFlowDes(total);
                    MsgBoxProxy.Instance.Show(msg, Lang.Instance.GetDes(690000), RealRun, Lang.Instance.GetDes(690001), Quit);
                }
                else
                {
                    RealRun();
                }
            }
        }

        protected void RealRun()
        {
            SetPro(0f);
            Running = true;
            dl.Dic = svrFileDic;
            dl.Infos = infos;
            dl.Start();
        }

        protected override void Begin()
        {
            base.Begin();
            var msg = Lang.Instance.GetDes(GetNewDes());
            SetMsg(msg);
            SetSvrMfPath();
            WwwTool.LoadAsync(svrMfPath, LoadMfCb);
        }


        protected override void Complete()
        {
            if (isRestart)
            {
                MsgBoxProxy.Instance.Show(617029, 690000, Restart);
                //var msg = GetRestartDes();
                //MsgBoxProxy.Instance.Show(msg, "确定", Restart);
            }
            else
            {
                base.Complete();
            }
        }

        #endregion

        #region 公开方法

        /// <summary>
        /// 获取缓存的服务器清单文件路径
        /// </summary>
        public string GetTempMfPath(string prefix = null)
        {
            if (prefix == null) prefix = "";
            var path = string.Format("{0}{1}{2}_{3}_{4}", AssetPath.Cache, prefix, App.VerCode, SvrVer, AssetMf.Name);
            return path;
        }


        public override void Init()
        {
            base.Init();
            dl.IPro = IPro;
            dl.IStart = this;
            dl.Url = svrPrefix;
            dl.complte += Downloaded;
            dl.Init();
            decomp = DecompFty.Create();
            LocalVerPath = string.Format("{0}/{1}", AssetPath.Persistent, VerFile);
        }

        public override void Start()
        {
            LocalVer = VerUtil.LoadFromFile(LocalVerPath);
            lastVer = LocalVer;
            base.Start();
        }

        public override void Update()
        {
            dl.Update();
        }

        public override void Stop()
        {
            dl.Stop();
        }

        #endregion
    }
}