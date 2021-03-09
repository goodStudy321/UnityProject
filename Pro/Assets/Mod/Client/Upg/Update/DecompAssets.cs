#if LOONG_SPLIT_ZIP
/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.6.3 21:55:02
 * 是否解压缩的判定条件,满足其一即可
 * 1,不存在本地应用程序版本号文件
 * 2,本地版本号不等于内部应用程序版本号
 ============================================================================*/

using System;
using UnityEngine;
using System.IO;
using System.Collections.Generic;

namespace Loong.Game
{
    using Lang = Phantom.Localization;
    /// <summary>
    /// 解压内部多个资源包
    /// </summary>
    public class DecompAssets : DecompAssetBase
    {
#region 字段
        /// <summary>
        /// 解压成功计数
        /// </summary>
        private int unzipCnt = 0;

        /// <summary>
        /// 总数量
        /// </summary>
        private float total = 0;

        /// <summary>
        /// true:解压成功
        /// </summary>
        private bool success = true;

        private object ulock = new object();


        /// <summary>
        /// 解压接口列表
        /// </summary>
        private List<DecompBase> decomps = new List<DecompBase>();
#endregion

#region 属性

#endregion

#region 委托事件

#endregion

#region 构造方法

#endregion

#region 私有方法
        private bool SetTotal()
        {
            //total = App.Info.CompCount;
            return total > 0;
        }

        /// <summary>
        /// 解压结束
        /// </summary>
        /// <param name="unzip"></param>
        /// <param name="suc"></param>
        private void UnzipEnd(DecompBase unzip, bool suc)
        {
            lock (ulock)
            {
                if (!success) return;
                if (suc)
                {
                    ++unzipCnt;
                    if (unzipCnt >= total)
                    {
                        DecompComplete();
                    }
                }
                else
                {
                    if (success)
                    {
                        Stop();
                        success = false;
                        string err = unzip.Error;
                        if (err.Contains("Win") && (err.Contains("112") || err.Contains("39")))
                        {
                            MsgBoxProxy.Instance.Show(617015, 690000, Exit);
                            //MsgBoxProxy.Instance.Show("存储空间不足", "确定", Exit);
                        }
                        else
                        {
                            var btn = Lang.Instance.GetDes(690000);
                            MsgBoxProxy.Instance.Show(err, btn, Exit);
                            //MsgBoxProxy.Instance.Show("Error:" + err, "确定", Exit);
                        }
                        Debug.LogErrorFormat("Loong, unzip fail::{0}", err);
                    }
                }
            }
        }

        private void Run()
        {
            success = true;
            MonoEvent.update += Update;
            Debug.Log("Loong, 开始多线程解压");
            if (IPro != null)
            {
                var msg = Lang.Instance.GetDes(617013);
                //var msg = "首次进入初始化时间较长，请稍作等待(加载不消耗流量)";
                IPro.SetMessage(msg);
            }
            for (int i = 0; i < total; i++)
            {
                DecompBase it = decomps[i];
                it.Dest = AssetPath.Persistent;
                it.complete += UnzipEnd;
                it.RunThread();
            }
        }

        private void Update()
        {
            if (IPro == null) return;
            if (decomps.Count < total) return;
            float pro = 0;
            for (int i = 0; i < total; i++)
            {
                pro += decomps[i].Pro;
            }
            pro /= total;
            IPro.SetProgress(pro);
        }

#endregion

#region 保护方法
        protected override void Complete()
        {
            MonoEvent.update -= Update;
            base.Complete();
        }

#if UNITY_ANDROID
        protected override void Begin()
        {
            base.Begin();
            SetReadyInit();
            if (!SetTotal()) { Complete(); return; }
            bool sucReadStream = true;
            try
            {
                for (int i = 0; i < total; i++)
                {
                    string name = UpgUtil.GetZipName(i);
                    Stream stream = null;
                    if (Application.isEditor)
                    {
                        var path = Path.Combine(AssetPath.Streaming, name);
                        stream = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read, 1024 * 64, false);
                    }
                    else
                    {
                        stream = BetterStreamingAssets.OpenRead(name);
                    }
                    var it = DecompFty.Create();
                    it.SrcStream = stream;
                    decomps.Add(it);
                }
            }
            catch (Exception e)
            {
                Debug.LogErrorFormat("Loong ,decomAssets get fileStream err:{0}", e.Message);
                sucReadStream = false;
            }
            if (sucReadStream) Run();
        }
#else
		protected override void Begin()
        {
            if (IPro != null) IPro.SetMessage("准备初始化");
            if (!SetTotal()) { Complete(); return; }

            for (int i = 0; i < total; i++)
            {
                string name = UpgUtil.GetZipName(i);
                string zipPath = Path.Combine(AssetPath.Streaming, name);

                if (File.Exists(zipPath))
                {
                    var it = DecompFty.Create();
                    it.SrcStream = new FileStream(zipPath, FileMode.Open, FileAccess.Read, FileShare.Read, 1024 * 64, false);//File.OpenRead(zipPath);
                    decomps.Add(it);
                }
                else
                {
                    Debug.LogErrorFormat("Loong, decomAssets:{0},not exist", zipPath);
                    Complete();
                    return;
                }
            }
            Run();
        }
				
#endif


#endregion

#region 公开方法

        public override void Stop()
        {
            int length = decomps.Count;
            for (int i = 0; i < length; i++)
            {
                DecompBase it = decomps[i];
                it.IsStop = true;
            }
        }

        public override void Dispose()
        {
            base.Dispose();
            MonoEvent.update -= Update;
            int length = decomps.Count;
            for (int i = 0; i < length; i++)
            {
                var it = decomps[i];
                it.Dispose();
                ObjPool.Instance.Add(it);
            }
            decomps.Clear();
        }
#endregion
    }
}
#endif