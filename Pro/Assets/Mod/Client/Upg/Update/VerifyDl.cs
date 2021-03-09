/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/7/11 17:24:40
 ============================================================================*/

using System;
using System.IO;
using UnityEngine;
using System.Threading;
using System.Collections;
using System.Diagnostics;
using System.Collections.Generic;
using Debug = UnityEngine.Debug;

namespace Loong.Game
{
    using Md5Dic = Dictionary<string, Md5Info>;

    /// <summary>
    /// 下载解压校验
    /// </summary>
    public class VerifyDl
    {
        #region 字段
        /// <summary>
        /// 当count>=total时完成
        /// </summary>
        private int count = 0;

        private int sleep = 2;

        private int dSleep = 4;

        private float total = 0;

        private IError iErr = null;

        private bool isStop = false;

        private bool useVerify = true;

        private IProgress iPro = null;

        /// <summary>
        /// 解压
        /// </summary>
        private DecompBase decomp = DecompFty.Create();

        private ElapsedTime et = new ElapsedTime();

        private VerifyState state = VerifyState.None;
        /// <summary>
        /// 校验队列
        /// </summary>
        private Queue<UpgItem> items = new Queue<UpgItem>();

        /// <summary>
        /// 缓存队列
        /// </summary>
        private Queue<UpgItem> pools = new Queue<UpgItem>();

        #endregion
        #region 属性
        public float Pro
        {
            get { return (count / total); }
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
        /// 解压沉睡时间
        /// </summary>
        public int DecompSleep
        {
            get { return dSleep; }
            set { dSleep = value; }
        }


        /// <summary>
        /// true:停止
        /// </summary>
        public bool IsStop
        {
            get { return isStop; }
            set { isStop = value; }
        }

        /// <summary>
        /// 错误信息设置接口
        /// </summary>
        public IError IErr
        {
            get { return iErr; }
            set { iErr = value; }
        }

        public IProgress IPro
        {
            get { return iPro; }
            set { iPro = value; }
        }

        public VerifyState State
        {
            get { return state; }
            set { state = value; }
        }


        public bool UseVerify
        {
            get { return useVerify; }
            set { useVerify = value; }
        }


        #endregion

        #region 委托事件
        /// <summary>
        /// 结束事件
        /// </summary>

        public event Action<bool> complete = null;

        /// <summary>
        /// 校验事件
        /// </summary>
        public event Action<UpgItem, bool> verify = null;
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法


        private void Complete(bool suc)
        {
            et.End("verify");
            if (suc)
            {
                State = VerifyState.Suc;
                Debug.Log("Loong, end verify, suc");
            }
            else
            {
                State = VerifyState.Fail;
                Debug.LogWarning("Loong, end verify, fail");
            }
            if (complete == null) return;
            complete(suc);
        }

        private void Verify(UpgItem it, bool suc)
        {
            if (verify != null) verify(it, suc);
        }

        private void Run(object obj)
        {
            et.Beg();
            State = VerifyState.Run;
            AssetOp ao = AssetOp.None;
            bool decompSuc = true;
            bool verifySuc = true;
            while (true)
            {
                Thread.Sleep(1);
                if (isStop)
                {
                    Complete(false);
                    break;
                }
                if (count >= total)
                {
                    Complete(true);
                    break;
                }
                if (items.Count < 1)
                {
                    if (isStop)
                    {
                        Complete(false);
                        break;
                    }
                    Thread.Sleep(10);
                    continue;
                }
                decompSuc = true;
                verifySuc = true;
                var it = Dequeue(items);
                if (it == null) continue;
                ao = (AssetOp)it.Info.Op;
                string dest = it.Dest;
                if (ao != AssetOp.Decompress)
                {
                    string src = it.Src;
                    decomp.Src = src;
                    decomp.Dest = dest;
                    decompSuc = decomp.Execute();
                    Thread.Sleep(dSleep);
                    FileTool.SafeDelete(src);
                    it.Info.Op = (byte)AssetOp.Decompress;
                }
                var info = it.Info;
                if (decompSuc)
                {
                    var path = info.path;
                    if (useVerify)
                    {
                        string tMd5 = info.MD5;
                        string sMd5 = Md5Crypto.GenFile(dest);
                        verifySuc = ((tMd5 == sMd5) ? true : false);
                        if (verifySuc)
                        {
                            Verify(path, dest, true, it);
                        }
                        else
                        {
                            info.Op = (byte)AssetOp.None;
                            Verify(it, verifySuc);
                            var err = string.Format("Verify: {0} fail,svrMD5{1},download md5:{2}", it.Src, tMd5, sMd5);
                            if (iErr != null) iErr.Error = err;
                            Debug.LogError(err);
                            Complete(false);
                            break;
                        }
                    }
                    else
                    {
                        Verify(path, dest, true, it);
                    }
                }
                else
                {
                    info.Op = (byte)AssetOp.None;
                    State = VerifyState.DecompFail;
                    Verify(it, false);
                    var err = string.Format("decomp: {0} fail", it.Src);
                    if (iErr != null) iErr.Error = err;
                    Debug.LogWarning(err);
                    Complete(false);
                    break;
                }
                Enqueue(pools, it);
            }
        }

        private void Verify(string path, string dest, bool verifySuc, UpgItem it)
        {
            var newPath = UpgUtil.GetLocalPath(path);
            //FileTool.CheckDir(newPath);
            Thread.Sleep(sleep);
            Copy(dest, newPath);
            Thread.Sleep(sleep);
            FileTool.SafeDelete(dest);
            Thread.Sleep(sleep);
            ++count;
            Verify(it, verifySuc);
            Thread.Sleep(sleep);
        }

        private void Copy(string src, string dest)
        {
            try
            {
                File.Copy(src, dest, true);
            }
            catch (Exception)
            {
                Thread.Sleep(50);
                Copy(src, dest);
            }
        }

        private void Begin()
        {
            count = 0;
            IsStop = false;
            State = VerifyState.None;
            while (!ThreadPool.QueueUserWorkItem(Run))
            {
                Thread.Sleep(10);
            }
        }

        /// <summary>
        /// 出栈
        /// </summary>
        /// <returns></returns>
        private UpgItem Dequeue(Queue<UpgItem> queues)
        {
            lock (queues)
            {
                UpgItem it = null;
                if (queues.Count > 0)
                {
                    it = queues.Dequeue();
                }
                return it;
            }
        }

        /// <summary>
        /// 入栈
        /// </summary>
        /// <returns></returns>
        private void Enqueue(Queue<UpgItem> queues, UpgItem it)
        {
            lock (queues)
            {
                queues.Enqueue(it);
            }
        }

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        public void Add(string compPath, Md5Info info)
        {
            var it = Dequeue(pools);
            if (it == null) it = new UpgItem();
            var dest = UpgUtil.GetDecompPath(info);
            it.Dest = dest;
            it.Info = info;
            it.Src = compPath;
            Enqueue(items, it);
        }


        /// <summary>
        /// 设置校验集合
        /// </summary>
        /// <param name="lst"></param>
        public void Set(List<Md5Info> lst)
        {
            total = lst.Count;
            count = 0;
        }

        /// <summary>
        /// 开始校验
        /// </summary>
        public void Start()
        {
            while (items.Count > 0)
            {
                var it = Dequeue(items);
                Enqueue(pools, it);
            }
            Begin();
        }

        public void Update()
        {
            if (state != VerifyState.Run) return;
            if (iPro == null) return;
            float pro = (count / total);
            IPro.SetCount(count);
            iPro.SetProgress(pro);
        }


        public void Stop()
        {
            IsStop = true;
        }

        #endregion
    }
}