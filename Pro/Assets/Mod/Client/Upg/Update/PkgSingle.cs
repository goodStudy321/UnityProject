//*****************************************************************************
// Copyright (C) 2020, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2020/4/9 17:56:14
// 所有资源1个包处理
//*****************************************************************************

using System;
using System.IO;
using UnityEngine;
using System.Threading;
using System.Collections;
using System.Collections.Generic;
using System.Collections.Concurrent;

namespace Loong.Game
{
    /// <summary>
    /// DecompSingle
    /// </summary>
    public class PkgSingle : DecompAssetBase
    {
        #region 字段
        private object l1 = new object();

        private Stream stream = null;

        private bool writeOver = false;

        private string mainObbPath = null;

        private string dlmsg = null;

        private float timer = 0;

        private float curTimer = 0;
        private long curSize = 0;
        private int curTipCount = 0;

        /// <summary>
        /// 解压线程数量
        /// </summary>
        protected int threadMax = 6;

        /// <summary>
        /// 解压线程完成数量
        /// </summary>
        protected int threadCount = 0;

        /// <summary>
        /// 总资源数量
        /// </summary>
        protected float totalAssets = 0f;

        /// <summary>
        /// 下载类型
        /// </summary>
        private DownloadBase dl = new Download();

        /// <summary>
        /// 解压类型
        /// </summary>
        protected DecompBase decomp = null;

        /// <summary>
        /// 详细清单列表
        /// </summary>
        protected List<Md5Info> totals = new List<Md5Info>();

        /// <summary>
        /// 同步清单列表
        /// </summary>
        public ConcurrentQueue<Md5Info> syncs = new ConcurrentQueue<Md5Info>();

        /// <summary>
        /// 解压列表
        /// </summary>
        protected List<DecompPkgSingle> decomps = new List<DecompPkgSingle>();
        #endregion

        #region 属性

        public bool WriteOver
        {
            get { return writeOver; }
            set { writeOver = value; }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void Update()
        {
            if (dl.Running)
            {
                if (IPro == null) return;
                if (Time.realtimeSinceStartup - timer > 1)
                {
                    var size = ByteUtil.GetSizeStr(dl.Size);
                    var total = ByteUtil.GetSizeStr(dl.Total);

                    var msg = string.Format("{0}{1}/{2}", dlmsg, size, total);
                    IPro.SetMessage(msg);
                    timer = Time.realtimeSinceStartup;

                }
 
                if (Time.realtimeSinceStartup - curTimer >= 5)
                {
                    var dif = dl.Size - curSize;
                    bool isEnough = dif < 1048576;
                    curSize = dl.Size;
                    curTimer = Time.realtimeSinceStartup;
                    if (isEnough) //(1M)
                    {
                        iTrace.Error("Loong", "Download Stop,downloadSiez:{0}, recordSize:{1},difSize:{2}", dl.Size, curSize, dif);
                        dl.Close();
                    }
                    
                }

                IPro.SetProgress(dl.Size / (dl.Total * 1f));
            }
            else
            {
                int count = 0;
                int len = decomps.Count;
                for (int i = 0; i < len; i++)
                {
                    var it = decomps[i];
                    count += it.decompCount;
                }
                if (totalAssets > 0)
                {
                    writeOver = (count < totalAssets ? false : true);
                }
                if (IPro == null) return;
                float pro = count / totalAssets;
                IPro.SetProgress(pro);

            }

        }

        /// <summary>
        /// 获取解压清单失败描述
        /// </summary>
        /// <returns></returns>
        private uint GetDecompMfErr()
        {
            return 617016;
            //return "获取清单失败,请检查是否禁止游戏读写权限或存储空间是否足够!";
        }

        /// <summary>
        /// 获取解压失败描述
        /// </summary>
        /// <returns></returns>
        private uint GetDecompErr()
        {
            return 617017;
            //return "初始化失败,请检查存储空间是否足够!";
        }

        /// <summary>
        /// 获取包内文件流
        /// </summary>
        /// <returns>如果返回为空,说明获取失败</returns>
        private Stream GetStream()
        {
            var path = mainObbPath;

            Stream fs = null;
            if (App.IsEditor)
            {
                fs = File.OpenRead(path);
            }
            else if (App.IsDebug)
            {
                var name = Path.GetFileName(path);
                fs = BetterStreamingAssets.OpenRead(name);
            }
            else if (File.Exists(path))
            {
                fs = File.OpenRead(path);
            }
            else
            {
                Debug.LogErrorFormat("Loong, pkg {0} not exist", path);
            }

            return fs;
        }

        /// <summary>
        /// 开始写入
        /// </summary>
        private void StartWrite(object o)
        {
            int len = totals.Count;
            var cache = AssetPath.Cache;
            var bufLen = 1024 * 4;
            var buf = new byte[bufLen];

            int size = 0;
            int readed = 0;
            int readSize = 0;
            int remain = 0;
            for (int i = 0; i < len; i++)
            {
                var info = totals[i];
                var path = cache + info.path;
                var dir = Path.GetDirectoryName(path);
                if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
                var fs = FileTool.SafeCreate(path);
                size = info.Sz;
                readed = 0;
                try
                {
                    while (true)
                    {
                        remain = size - readed;
                        readSize = (remain > bufLen ? bufLen : remain);
                        readSize = stream.Read(buf, 0, readSize);
                        fs.Write(buf, 0, readSize);
                        readed += readSize;
                        if (readed == size) break;
                    }
                    fs.Dispose();
                }
                catch (Exception e)
                {
                    ShowDecompErr();
                    Debug.LogErrorFormat("Loong, readPkg err:{0}", e.Message);
                    break;
                }
                syncs.Enqueue(info);
                Thread.Sleep(0);
            }
            stream.Dispose();
            stream = null;
        }

        private void StartDecomp()
        {
            if (App.IsDebug)
            {
                Debug.LogWarningFormat("Loong, decom total:{0}", totalAssets);
            }

            for (int i = 0; i < threadMax; i++)
            {
                var ds = decomps[i];
                ThreadUtil.Start(ds.Start, null, 10);
            }
        }


        private void ShowReadMfErr()
        {
            MsgBoxProxy.Instance.Show(617018, 690000, Exit);
            //MsgBoxProxy.Instance.Show("读取清单错误", "确定", Exit);
        }

        private bool SaveMf(byte[] arr, string name)
        {
            if (arr == null)
            {
                ShowReadMfErr(); return false;
            }
            var tempPath = AssetPath.Cache + name;
            FileTool.SaveSafeBytesDefaultEncoding(tempPath, arr);
            var destPath = AssetPath.Persistent + "/" + name;

            decomp.Src = tempPath;
            decomp.Dest = destPath;
            if (decomp.Execute())
            {
                return true;
            }
            else
            {
                if (App.IsDebug)
                {
                    Debug.LogFormat("Loong, decompmf fail name:{0}, src:{1}, dest:{2}", name, tempPath, destPath);
                }
                ShowDecompMfErr();
                return false;
            }
        }

        private void LoadMfCb(byte[] arr)
        {
            if (!SaveMf(arr, AssetMf.Name)) return;
            if (App.IsSubAssets)
            {
                var srcBaseMfPath = AssetPath.WwwStreaming + AssetMf.BaseName;
                WwwTool.LoadAsync(srcBaseMfPath, LoadBaseMfCb);
            }
            else
            {
                CheckDown();
            }
        }

        private void LoadBaseMfCb(byte[] arr)
        {
            if (!SaveMf(arr, AssetMf.BaseName)) return;
            CheckDown();
        }
        #endregion

        #region 保护方法
        /// <summary>
        /// 显示解压清单错误
        /// </summary>
        protected void ShowDecompMfErr()
        {
            var msg = GetDecompMfErr();
            MsgBoxProxy.Instance.Show(msg, 690000, Exit);
            //MsgBoxProxy.Instance.Show(msg, "确定", Exit);
        }

        /// <summary>
        /// 显示解压资源错误
        /// </summary>
        protected void ShowDecompErr()
        {
            var msg = GetDecompErr();
            MsgBoxProxy.Instance.Show(msg, 690000, Exit);
            //MsgBoxProxy.Instance.Show(msg, "确定", Exit);
        }

        protected void ShowStreamErr()
        {
            MsgBoxProxy.Instance.Show(617048, 690000, Exit);
        }

        /// <summary>
        /// 解压清单
        /// </summary>
        protected void Multi()
        {
            SetBeginInit();
            stream = GetStream();
            if (stream == null)
            {
                ShowStreamErr(); return;
            }

            var name = (App.IsSubAssets ? AssetMf.BaseName : AssetMf.Name);
            var path = AssetPath.Persistent + "/" + name;
            var set = AssetMf.ReadSet(path);
            totals = set.infos;
            totalAssets = totals.Count;
            ThreadUtil.Start(StartWrite);
            StartDecomp();
        }

        protected bool NeedDown()
        {
            var path = mainObbPath;
            if (App.IsEditor || !App.IsDebug)
            {
                if (File.Exists(path))
                {
                    var fi = new FileInfo(path);
                    if (fi.Length == App.Info.PkgSz)
                    {
                        var el = new ElapsedTime();
                        el.Beg();
                        var md5 = Md5Crypto.GenFileFast(path);
                        el.End();
                        var cfgMD5 = App.Info.PkgMD5;
                        if (md5 == cfgMD5)
                        {
                            iTrace.Log("Loong", "elapsed:{0}, path:{1}, same md5:{2}", el.Elapsed, path, md5);
                            return false;
                        }
                        else
                        {
                            iTrace.Log("Loong", "elapsed:{0},path:{1} md5:{2} ,but cfg md5:{3}", el.Elapsed, path, md5, cfgMD5);
                            return true;
                        }
                    }
                    else
                    {
                        return true;
                    }
                    //return (fi.Length != App.Info.PkgSz);
                }
                return true;
            }
            return false;
        }

        protected void StartDownObbThread()
        {
            curTimer = Time.realtimeSinceStartup;
            //iTrace.Error("Loong", "xxxxxxxxxxxxxxx:{0}, {1}", Time.realtimeSinceStartup, curTimer);
            timer = Time.realtimeSinceStartup;
            iTrace.Error("Loong", "DownObb 开始 开启线程");
            //ThreadUtil.Start(DownObb);
            try
            {
                Thread thread = new Thread(DownObbs);
                thread.IsBackground = true;
                thread.Priority = System.Threading.ThreadPriority.Highest;
                thread.Start();
            } catch(Exception e)
            {
                Debug.LogErrorFormat("Loong ,new thread err:{0}",  e.Message);
            }

        }


        protected void DownObbs()
        {
            //dl = new Download();
            var dest = mainObbPath;
            var name = Path.GetFileName(dest);
            dl.Dest = dest;

            var pre = UpgMgr.Instance.UpgPkg.SvrPrefix;
            var src = Path.Combine(pre, name);
            dl.Src = src;
            if (File.Exists(dest))
            {
                var fi = new FileInfo(dest);
                dl.Broken = fi.Length < App.Info.PkgSz;

            }
            iTrace.Error("Loong", "down obb:{0}, to:{1}, broken:{2}", src, dest, dl.Broken);
            if (dl.Execute())
            {
                Thread.Sleep(1);
                Multi();
            }
            else
            {
                iTrace.Error("Loong", "网络请求超时，自动进行下载 curTipCount:{0}", curTipCount);
                curTipCount += 1;
                if (curTipCount >=3)
                {
                    curTipCount = 0;
                    MsgBoxProxy.Instance.Show(620009, 690019, StartDownObbThread, 690020, Exit);
                }
                else
                {
                    MonoEvent.AddOneShot(StartDownObbThread);
                }
                //MsgBoxProxy.Instance.Show(620009, 690019, DownObb, 690020, Exit);
            }
        }

        private void CheckDown()
        {
            if (NeedDown())
            {
                if (CheckWifyNetwork())
                {
                    DownLoadObbPackage();
                }
                else
                {
                    MsgBoxProxy.Instance.Show(617051, 690000, DownLoadObbPackage, 690001, Exit);
                }

            }
            else
            {
                Multi();
            }
        }

        private void DownLoadObbPackage()
        {
            SetMessage(dlmsg);
            StartDownObbThread();
        }

        private bool CheckWifyNetwork()
        {
            string curNet = Device.Instance.NetType;
            iTrace.Log("Loong", "CheckCurNetwork: {0}", curNet);
            if (curNet == "wifi")
            {
                return true;
            }
            return false;
        }

        protected override void Begin()
        {
            base.Begin();
            srcMem = Device.Instance.AvaiMem;
            SetReadyInit();
            MonoEvent.update += Update;
            var srcMfPath = AssetPath.WwwStreaming + AssetMf.Name;
            WwwTool.LoadAsync(srcMfPath, LoadMfCb);
        }

        protected void Decomp(DecompPkgSingle ds, bool suc)
        {
            lock (l1)
            {
                if (suc)
                {
                    ++threadCount;
                    if (threadCount >= threadMax)
                    {
                        DecompComplete();
                    }
                }
                else
                {
                    //syncs.Clear();
                    ShowDecompErr();
                }
            }
        }

        protected override void Complete()
        {
            MonoEvent.update -= Update;
            base.Complete();
        }

        #endregion

        #region 公开方法

        public override void Init()
        {
            base.Init();
            LzmaUtil.Init();
            mainObbPath = ObbUtil.GetExterMain(App.VerCode);
            var root = ObbUtil.GetExterRoot();
            Debug.LogFormat("Loong, pkg path:{0}, exter:{1}", mainObbPath, root);
            dlmsg = Phantom.Localization.Instance.GetDes(617049);
            decomp = DecompFty.Create();
            for (int i = 0; i < threadMax; i++)
            {
                var it = DecompFty.Create();
                var ds = new DecompPkgSingle(this, it);
                ds.complete += Decomp;
                decomps.Add(ds);
            }
        }

        public override void Stop()
        {
            base.Stop();
            dl.Stop();
            //if (syncs != null) syncs.Clear();
        }

        public override void Dispose()
        {
            base.Dispose();
            dl.Stop();
            dl.Close();
            MonoEvent.update -= Update;
            //if (syncs != null) syncs.Clear();
            if (stream != null) stream.Dispose(); stream = null;
        }
        #endregion
    }
}