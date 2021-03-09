//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/5/21 22:14:13
// Android解压颗粒化文件
//=============================================================================

using System;
using System.IO;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /// <summary>
    /// DecompiOSAssets
    /// </summary>
    public class DecompGranulesAndroid : DecompGranuleAssets
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
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
                Multi();
            }
        }

        private void LoadBaseMfCb(byte[] arr)
        {
            if (!SaveMf(arr, AssetMf.BaseName)) return;
            Multi();
        }
        #endregion

        #region 保护方法
        protected override void Begin()
        {
            srcMem = Device.Instance.AvaiMem;
            SetReadyInit();
            var srcMfPath = AssetPath.WwwStreaming + AssetMf.Name;
            WwwTool.LoadAsync(srcMfPath, LoadMfCb);
        }

        #endregion

        #region 公开方法

        #endregion
    }
}