//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/5/21 16:53:28
// 解压颗粒化资源文件
// 1.先解压清单文件:
//   全部清单文件(Manifest.xml),首包清单(BaseManifest.xml,分包模式下)
// 2.多线程根据清单列表将内部文件解压到外部
//=============================================================================

using System;
using UnityEngine;
using System.Threading;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    public class DecompGranuleAssets : DecompAssetBase
    {
        #region 字段

        private object l1 = new object();

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

        protected DecompBase decomp = null;

        /// <summary>
        /// 详细清单列表
        /// </summary>
        protected List<Md5Info> syncLst = new List<Md5Info>();

        /// <summary>
        /// 解压列表
        /// </summary>
        protected List<DecompFromStreaming> decomps = new List<DecompFromStreaming>();

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        private void Update()
        {
            if (IPro == null) return;
            float pro = (totalAssets - syncLst.Count) / totalAssets;
            IPro.SetProgress(pro);
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
        /// 移除特殊文件
        /// </summary>
        /// <param name="infos"></param>
        private void RemoveSpecial(List<Md5Info> infos)
        {
            int length = infos.Count;
            for (int i = 0; i < length; i++)
            {
                var info = infos[i];
                var path = info.path;
                if (path == UpgUtil.HotfixName)
                {
                    ListTool.Remove<Md5Info>(infos, i);
                    break;
                }
            }
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
            if (App.IsDebug)
            {
                Debug.Log("Loong decomp manifest fail!");
            }
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

        /// <summary>
        /// 解压清单
        /// </summary>
        protected void Multi()
        {
            SetBeginInit();
            MonoEvent.update += Update;
            var name = (App.IsSubAssets ? AssetMf.BaseName : AssetMf.Name);
            var path = AssetPath.Persistent + "/" + name;
            var set = AssetMf.ReadSet(path);
            var infos = set.infos;
            RemoveSpecial(infos);
            totalAssets = infos.Count;
            syncLst = infos;
            if (App.IsDebug)
            {
                Debug.LogWarningFormat("Loong, decom total:{0}", totalAssets);
            }
            for (int i = 0; i < threadMax; i++)
            {
                decomps[i].infos = syncLst;
            }
            for (int i = 0; i < threadMax; i++)
            {
                var ds = decomps[i];
                while (!ThreadPool.QueueUserWorkItem(ds.Start))
                {
                    Thread.Sleep(10);
                }
            }
        }

        protected override void Begin()
        {
            base.Begin();
            var persist = AssetPath.Persistent + "/";
            var streaming = AssetPath.Streaming + "/";
            decomp.Src = streaming + AssetMf.Name;
            decomp.Dest = persist + AssetMf.Name;
            bool suc = decomp.Execute();
            if (App.IsSubAssets && suc)
            {
                decomp.Src = streaming + AssetMf.BaseName;
                decomp.Dest = persist + AssetMf.BaseName;
                suc = decomp.Execute();
            }
            if (suc)
            {
                Multi();
            }
            else
            {
                if (App.IsDebug)
                {
                    Debug.LogFormat("Loong, decompmf fail, src:{0}, dest:{1}", decomp.Src, decomp.Dest);
                }
                ShowDecompMfErr();
            }
        }

        protected void Decomp(DecompFromStreaming ds, bool suc)
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
                    syncLst.Clear();
                    ShowDecompErr();
                }
            }
        }

        protected DecompFromStreaming CreateGranule(DecompBase decomp)
        {
            if (App.IsEditor)
            {
                return new DecompiOSStreaming(decomp);
            }
#if UNITY_ANDROID
            else if (App.IsAndroid)
            {
                return new DecompAndroidStreaming(decomp);
            }
#endif
            return new DecompiOSStreaming(decomp);
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
            decomp = DecompFty.Create();
            for (int i = 0; i < threadMax; i++)
            {
                var it = DecompFty.Create();
                var ds = CreateGranule(it);
                ds.CompleteEvent += Decomp;
                decomps.Add(ds);
                if (App.IsDebug)
                {
                    Debug.LogWarningFormat("Loong, decom init:{0}", ds.guid);
                }
            }
        }

        public override void Stop()
        {
            base.Stop();
            if (syncLst != null) syncLst.Clear();
        }

        public override void Dispose()
        {
            base.Dispose();
            MonoEvent.update -= Update;
            if (syncLst != null) syncLst.Clear();
        }

        public int GetDecompedTotal()
        {
            var total = 0;
            int length = decomps.Count;
            for (int i = 0; i < length; i++)
            {
                total = total + decomps[i].count;
            }
            return total;
        }
        #endregion
    }
}