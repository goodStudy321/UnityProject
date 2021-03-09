/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/8/5 14:21:50
 ============================================================================*/

using System;
using System.IO;
using System.Text;
using UnityEngine;
using System.Threading;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{

    using Lang = Phantom.Localization;

    using Md5Dic = Dictionary<string, Md5Info>;

    /// <summary>
    /// 资源下载
    /// </summary>
    public class AssetDl : IDownLoadSize, IError
    {
        #region 字段

        private int sleep = 3;
        private long size = 0;
        private long total = 0;
        private Md5Dic dic = null;
        private string url = null;
        private string error = null;
        private string totalStr = "0M";

        private bool canSetMsg = true;
        private IStart iStart = null;
        private IProgress iPro = null;
        private List<Md5Info> infos = null;

        private string downloadStr = null;

        /// <summary>
        /// 下载失败信息
        /// </summary>
        private Md5Dic failDic = null;

        /// <summary>
        /// 下载失败
        /// </summary>
        private string failPath = null;

        /// <summary>
        /// 强制保存的文件大小上限
        /// </summary>
        private int forceSize = 8 * 1024 * 1024;

        /// <summary>
        /// 校验模块
        /// </summary>
        private VerifyDl verify = new VerifyDl();

        /// <summary>
        /// 下载类型
        /// </summary>
        private DownloadBase dl = new Download();

        private ElapsedTime et = new ElapsedTime();
        /// <summary>
        /// 下载状态
        /// </summary>
        private DownloadState state = DownloadState.None;

        private StringBuilder sb = new StringBuilder();

        private StringBuilder proSb = new StringBuilder();

        private HashSet<string> dirSet = new HashSet<string>();
        #endregion

        #region 属性
        public float Pro
        {
            get
            {
                float ft = total;
                float pro = size / ft;
                return pro;
            }
        }

        /// <summary>
        /// 下载线程
        /// 一个文件完成后沉睡时间
        /// </summary>
        public int Sleep
        {
            get { return sleep; }
            set { sleep = value; }
        }


        /// <summary>
        /// 总大小 B
        /// </summary>
        public long Total
        {
            get { return total; }
        }

        /// <summary>
        /// 下载连接
        /// </summary>
        public string Url
        {
            get { return url; }
            set { url = value; }
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
        /// 校验字典
        /// </summary>
        public Md5Dic Dic
        {
            get { return dic; }
            set { dic = value; }
        }

        public VerifyDl VD
        {
            get { return verify; }
        }

        /// <summary>
        /// 下载列表
        /// </summary>
        public List<Md5Info> Infos
        {
            get { return infos; }
            set { infos = value; }
        }

        /// <summary>
        /// 开始接口
        /// </summary>
        public IStart IStart
        {
            get { return iStart; }
            set { iStart = value; }
        }


        public IProgress IPro
        {
            get { return iPro; }
            set { iPro = value; }
        }

        /// <summary>
        /// 下载器
        /// </summary>
        public DownloadBase Dl
        {
            get { return dl; }
        }

        /// <summary>
        /// 下载状态
        /// </summary>
        public DownloadState State
        {
            get { return state; }
            private set { state = value; }
        }


        public bool CanSetMsg
        {
            get { return canSetMsg; }
            set { canSetMsg = value; }
        }


        #endregion

        #region 委托事件
        /// <summary>
        /// 下载完成事件
        /// </summary>
        public event Action downloaded = null;

        /// <summary>
        /// 结束事件,bool:true,成功,false:失败,string:详细信息
        /// </summary>
        public event Action<bool, string> complte = null;

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        /// <summary>
        /// 获取服务器资源路径
        /// </summary>
        /// <param name="ver">版本号</param>
        /// <param name="name">相对路径</param>
        /// <returns></returns>
        protected string GetSvrPath(int ver, string name)
        {
            sb.Remove(0, sb.Length);
            sb.Append(url).Append(ver).Append("/").Append(name);
            string path = sb.ToString();
            return path;
        }

        /// <summary>
        /// 设置失败
        /// </summary>
        private void SetFail()
        {
            if (state == DownloadState.Run) return;
            if (verify.State == VerifyState.Run) return;
            string msg = "";
            if (state == DownloadState.Fail)
            {
                msg = Lang.Instance.GetDes(617000);
            }
            else if (verify.State == VerifyState.DecompFail)
            {
                msg = Lang.Instance.GetDes(617001);
            }
            else if (verify.State == VerifyState.Fail)
            {
                msg = Lang.Instance.GetDes(617002);
            }
            Debug.Log("Loong, download&verify asset fail " + msg);
            if (complte != null) complte(false, msg);
        }


        /// <summary>
        /// 加载失败信息
        /// </summary>
        private void LoadFail()
        {
            failPath = UpgUtil.GetFailPath();
            if (File.Exists(failPath))
            {
                failDic = AssetMf.Read(failPath);
            }
            if (failDic == null)
            {
                failDic = new Md5Dic();
            }
        }

        /// <summary>
        /// 开始下载
        /// </summary>
        private void Download(object obj)
        {
            et.Beg();
            ChkDirs();
            bool dlsuc = true;
            State = DownloadState.Run;
            int length = infos.Count;
            AssetOp ao = AssetOp.None;
            for (int i = 0; i < length; i++)
            {

                if (dl.IsStop) break;
                dl.Broken = false;
                var info = infos[i];
                ao = (AssetOp)info.Op;
                string path = info.path;
                string svrPath = GetSvrPath(info.Ver, path);
                string compPath = UpgUtil.GetCompPath(info);
                if (ao == AssetOp.None)
                {
                    if (failDic.ContainsKey(path))
                    {
                        var fi = failDic[path];
                        if ((fi.Ver == info.Ver) && (fi.MD5 == info.MD5))
                        {
                            if (File.Exists(compPath))
                            {
                                var ff = new FileInfo(compPath);
                                var fs = (int)ff.Length;
                                if (fs == info.Sz)
                                {
                                    verify.Add(compPath, info);
                                    continue;
                                }
                                else if (fs < info.Sz)
                                {
                                    dl.Broken = true;
                                }
                            }
                        }
                    }
                }
                else if (ao == AssetOp.Download)
                {
                    if (File.Exists(compPath))
                    {
                        var ff = new FileInfo(compPath);
                        var fs = (int)ff.Length;
                        if (fs == info.Sz)
                        {
                            verify.Add(compPath, info);
                            continue;
                        }
                    }
                }
                else if (ao == AssetOp.Decompress)
                {
                    string dest = UpgUtil.GetDecompPath(info);
                    if (File.Exists(dest))
                    {
                        verify.Add(compPath, info);
                        continue;
                    }
                }
                Thread.Sleep(sleep);
                info.Op = (byte)AssetOp.None;
                dl.Src = svrPath;
                dl.Dest = compPath;
                dlsuc = dl.Execute();
                if (dlsuc)
                {
                    info.Op = (byte)AssetOp.Download;

                    verify.Add(compPath, info);
#if UNITY_EDITOR
                    //Debug.Log(string.Format("Loong, download:{0} suc", dl.Src));
#endif
                    if (failDic.ContainsKey(path))
                    {
                        failDic.Remove(path);
                        AssetMf.Write(failDic, failPath);
                    }
                }
                else
                {
                    if (failDic.ContainsKey(path))
                    {
                        failDic[path] = info;
                        FileTool.SafeDelete(compPath);
                    }
                    else
                    {
                        failDic.Add(path, info);
                    }
                    State = DownloadState.Fail;
                    AssetMf.Write(failDic, failPath);
                    Error = string.Format("download:{0} fail", dl.Src);
                    Debug.LogWarningFormat("Loong, {0}", Error);
                    break;
                }
                if (iPro != null) iPro.SetCount(i);
            }
            if (dl.IsStop)
            {
                State = DownloadState.Stop;
                SetFail();
            }
            else if (state == DownloadState.Fail)
            {
                verify.Stop();
                SetFail();
            }
            else
            {
                State = DownloadState.Suc;
                MonoEvent.AddOneShot(downloaded);
                Debug.LogFormat("Loong, download {0} asset suc", length);
                Thread.Sleep(50);
                if (iPro != null) iPro.SetProgress(0);
                if (canSetMsg) SetMsg(GetVerifyDes());
            }
            et.End();
        }

        /// <summary>
        /// 校验文件回调
        /// </summary>
        /// <param name="suc"></param>
        private void Verifyed(UpgItem it, bool suc)
        {
            if (suc)
            {
                var k = it.Info.path;
                var info = dic[k];
                bool force = (info.Sz > forceSize ? true : false);
                AssetMf.Save(k, info, force);
            }
            else
            {
                dl.Stop();
            }
#if UNITY_EDITOR
            Debug.LogFormat("Loong, verifyed,{0}, suc:{1}", it.Info.path, suc);
#endif
        }

        /// <summary>
        /// 校验所有文件回调
        /// </summary>
        /// <param name="suc"></param>
        private void VerifyAll(bool suc)
        {
            if (suc)
            {
                Debug.Log("Loong, verifyed asset suc");
                FileTool.SafeDelete(failPath);
                AssetMf.Save();
                if (complte != null) complte(true, null);
            }
            else
            {
                SetFail();
            }
        }

        /// <summary>
        /// 启动下载线程
        /// </summary>
        private void RunDownload()
        {
            if (ThreadPool.QueueUserWorkItem(Download))
            {
                verify.Start();
            }
            else
            {
                Thread.Sleep(10);
                if (IStart != null) iStart.Start();
            }
        }

        private void SetMsg(string msg)
        {
            if (iPro != null) iPro.SetMessage(msg);
        }

        /// <summary>
        /// 检查目录
        /// </summary>
        private void ChkDirs()
        {
            dirSet.Clear();
            string dir = null;
            string path = null;
            string fullDir = null;
            int length = infos.Count;
            for (int i = 0; i < length; i++)
            {
                path = infos[i].path;
                dir = Path.GetDirectoryName(path);
                if (dirSet.Contains(dir)) continue;
                dirSet.Add(dir);
            }

            var persist = AssetPath.Persistent + "/";
            var dirs = new List<string>();
            dirs.Add(persist);
            dirs.Add(UpgUtil.CompDir);
            dirs.Add(UpgUtil.DecompDir);
            var dirLen = dirs.Count;
            var em = dirSet.GetEnumerator();
            while (em.MoveNext())
            {
                for (int i = 0; i < dirLen; i++)
                {
                    fullDir = dirs[i] + em.Current;
                    if (Directory.Exists(fullDir)) continue;
                    Directory.CreateDirectory(fullDir);
                }
            }
        }

        /// <summary>
        /// 获取安装校验描述
        /// </summary>
        /// <returns></returns>
        private string GetVerifyDes()
        {
            return Lang.Instance.GetDes(617003);
        }

        /// <summary>
        /// 获取下载描述
        /// </summary>
        /// <returns></returns>
        private string GetDownloadDes()
        {
            return Lang.Instance.GetDes(617004);
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 设置已下载大小
        /// </summary>
        /// <param name="value"></param>
        public void SetSize(int value)
        {
            size += value;
        }


        public void Init()
        {
            verify.IPro = IPro;
            verify.IErr = this;
            verify.verify += Verifyed;
            verify.complete += VerifyAll;
            downloadStr = GetDownloadDes();
        }

        public void Start()
        {
            size = 0;
            total = 0;
            totalStr = "0M";
            LoadFail();
            dl.IsStop = false;
            dl.ISetSize = this;
            verify.Set(infos);
            State = DownloadState.Run;
            SetTotal();
            RunDownload();
        }

        public void SetTotal()
        {
            total = GetTotal(infos);
            SetTotalStr();
        }

        public long GetTotal(List<Md5Info> infos)
        {
            if (infos == null) return 0L;
            long total = 0;
            int length = infos.Count;
            var ao = AssetOp.None;
            for (int i = 0; i < length; i++)
            {
                var info = infos[i];
                ao = (AssetOp)info.Op;
                if (ao != AssetOp.None) continue;
                total += info.Sz;
            }
            return total;
        }

        public void SetTotalNoFilter()
        {
            int length = infos.Count;
            for (int i = 0; i < length; i++)
            {
                var info = infos[i];
                total += info.Sz;
            }
            SetTotalStr();
        }

        public void SetTotalStr()
        {
            var tt = ByteUtil.FmtByCalc(total, 100);
            totalStr = string.Format("{0}M", tt);
            if (iPro != null) iPro.SetTotal(totalStr, infos.Count);
            Debug.LogWarningFormat("Loong, assetdl total size:{0}, count:{1}", total, infos.Count);
        }

        public void Update()
        {
            if (state == DownloadState.Run)
            {
                if (iPro == null) return;
                if (canSetMsg)
                {
                    proSb.Remove(0, proSb.Length);
                    proSb.Append(downloadStr);
                    float cur = ByteUtil.FmtByCalc(size, 100);
                    proSb.Append(cur).Append("M/");
                    proSb.Append(totalStr);
                    string msg = proSb.ToString();
                    iPro.SetMessage(msg);
                }
                float ft = total;
                float pro = size / ft;
                iPro.SetProgress(pro);
            }
            else if (state == DownloadState.Suc)
            {
                verify.Update();
            }
        }

        public void Stop()
        {
            dl.IsStop = true;
            verify.IsStop = true;
        }

        #endregion
    }
}