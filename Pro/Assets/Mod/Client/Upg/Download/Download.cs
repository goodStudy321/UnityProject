/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.6.3 17:34:13
 * 支持断点续传;基于HTTP协议; 如果需要上传和下载的进度显示需要使用线程支持或者异步编程
 ============================================================================*/

using System;
using System.IO;
using System.Net;
using System.Text;
using UnityEngine;
using System.Threading;
using System.Diagnostics;
using Debug = UnityEngine.Debug;

namespace Loong.Game
{
    /// <summary>
    /// 通用的下载文件类
    /// </summary>
    public class Download : DownloadBase
    {
        #region 字段
        private byte[] buf = new byte[1024 * 4];

        private FileStream fs = null;

        private Stream respStream = null;

        private HttpWebRequest req = null;

        private HttpWebResponse resp = null;

        private Stopwatch sw = new Stopwatch();

        private Stopwatch aveSw = new Stopwatch();

        private StringBuilder sb = new StringBuilder();


        #endregion

        #region 属性


        #endregion

        #region 构造方法

        public Download()
        {

        }

        public Download(string src, string dest)
        {
            Src = src;
            Dest = dest;
        }

        #endregion

        #region 私有方法
        private void Start(object arg)
        {
            Execute();
        }

        private void SetProgress()
        {
            if (IPro == null) return;
            sb.Remove(0, sb.Length);
            sb.Append("玩命下载中 ");
            float cur = ByteUtil.GetMB(Size);
            float total = ByteUtil.GetMB(Total);
            sb.Append(cur.ToString("0.00")).Append("M/");
            sb.Append(total).Append("M");
            string msg = sb.ToString();
            IPro.SetMessage(msg);
            IPro.SetProgress(cur / total);
        }

        private float FormatSize(long value)
        {
            return ByteUtil.GetMB(value);
        }

        private FileStream Create(string dest)
        {
            FileStream fs = null;
            try
            {
                fs = new FileStream(dest, FileMode.Create, FileAccess.ReadWrite);
                fs.Flush();
            }
            catch (Exception)
            {
                if (fs != null)
                {
                    fs.Dispose();
                    fs = null;
                }
            }
            if (fs == null)
            {
                Thread.Sleep(50);
                fs = Create(dest);
            }
            return fs;
        }

        /// <summary>
        /// 无断点时
        /// </summary>
        private void SetFileStreamNoBroken()
        {
            FileTool.CheckDir(Dest);
            fs = Create(Dest);
        }
        /// <summary>
        /// 有断点时
        /// </summary>
        /// <param name="longSize">断点起始位置</param>
        private void SetFileStreamIsBroken(ref long longSize)
        {
            if (File.Exists(Dest))
            {
                fs = File.OpenWrite(Dest);
                longSize = fs.Length;
                var cur = fs.Seek(longSize, SeekOrigin.Current);
                //设置range值
                req.AddRange((int)longSize);
            }
            else
            {
                FileTool.CheckDir(Dest);
                fs = Create(Dest);
            }
        }


        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public override bool Connect()
        {
            if (IsStop) return false;
            bool success = true;
            try
            {
                req = HttpWebRequest.Create(Src) as HttpWebRequest;
                resp = req.GetResponse() as HttpWebResponse;
                Total = resp.ContentLength;
            }
            catch (Exception e)
            {
                Debug.LogWarningFormat("Loong, connect err:{0},src:{1}", e.Message, Src);
                Disconnect();
                success = false;
            }
            return success;
        }

        public override void Disconnect()
        {
            if (req != null)
            {
                req.Abort(); req = null;
            }
            if (resp != null)
            {
                resp.Close(); resp = null;
            }
        }

        public override bool Execute()
        {
            Reset();
            Running = true;
            bool suc = true;
            long longSize = 0;
            try
            {
                req = HttpWebRequest.Create(Src) as HttpWebRequest;
                req.Timeout = 20000;
                #region 判断服务器是否支持断点续传
                if (Broken)
                {
                    SetFileStreamIsBroken(ref longSize);
                    Debug.LogWarningFormat("Loong ,broken pos:{0}", longSize);
                }
                else
                {
                    SetFileStreamNoBroken();
                }
                resp = req.GetResponse() as HttpWebResponse;
                Total = resp.ContentLength + longSize;
                if (longSize == Total)
                {
                    Complete(true); return true;
                }
                while (true)
                {
                    if (File.Exists(Dest))
                    {
                        break;
                    }
                    else
                    {
                        Thread.Sleep(1);
                    }
                }
                #endregion
                long longTotal = Total;

                if (longTotal < 1)
                {
                    suc = false;
                }
                else if (longSize < longTotal)
                {
                    long tm = 0;
                    long rSpeed = 0;
                    long limit = Limit;
                    respStream = resp.GetResponseStream();
                    sw.Reset();
                    sw.Start();
                    aveSw.Reset();
                    aveSw.Start();
                    int readSize = 0;
                    long lreadSize = 0;
                    while ((readSize = respStream.Read(buf, 0, buf.Length)) > 0)
                    {
                        if (IsStop)
                        {
                            suc = false;
                            break;
                        }
                        fs.Write(buf, 0, readSize);
                        longSize += readSize;
                        Size = longSize;
                        if (ISetSize == null)
                        {
                            SetProgress();
                        }
                        else
                        {
                            ISetSize.SetSize(readSize);
                        }
                        lreadSize = readSize;
                        if (limit > 0)
                        {
                            tm = sw.ElapsedTicks;
                            if (tm < 1) tm = 1;
                            rSpeed = lreadSize * 10000000L / tm;
                            if (rSpeed > limit)
                            {
                                var dif = rSpeed - limit;
                                var added = dif * tm / 10000L;
                                var sleep = added / limit;
                                var ms = (int)sleep;
                                if (ms < 60000) Thread.Sleep(ms);
                            }
                        }
                        tm = sw.ElapsedTicks;
                        if (tm < 1) tm = 1;
                        Speed = lreadSize * 10000000L / tm;
                        sw.Reset();
                        sw.Start();
                    }
                    fs.Flush();
                    sw.Stop();
                    aveSw.Stop();
                    tm = aveSw.ElapsedTicks;
                    AveSpeed = Total * 10000000L / tm;
                    if (longSize != longTotal) suc = false;
                }
                else if (longSize == longTotal)
                {
                    Debug.LogWarning("Loong, downloaded:" + Src);
                    suc = true;
                }
                if (ISetSize == null)
                {
                    SetProgress();
                }
            }
            catch (Exception e)
            {
                suc = false;
                Debug.LogWarningFormat("Loong, download {0}, err:{1}", Src, e.Message);
            }
            finally
            {
                sw.Stop();
                aveSw.Stop();
                Running = false;
                Complete(suc);
            }
            return suc;
        }

        public override void Start()
        {
            while (!ThreadPool.QueueUserWorkItem(Start))
            {
                Thread.Sleep(10);
            }
        }


        public override void Close()
        {
            try
            {
                if (respStream != null)
                {
                    respStream.Dispose(); respStream = null;
                }
                if (fs != null)
                {
                    fs.Dispose(); fs = null;
                }

                base.Close();
                Disconnect();
            }
            catch
            {

            }
            
        }
        #endregion
    }
}