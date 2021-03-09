//*****************************************************************************
// Copyright (C) 2020, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2020/4/8 14:54:11
// 以文件为粒度进行资源处理;即最终会将每个资源进行压缩处理并放入包内
//*****************************************************************************

using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Threading;
using System.Collections.Generic;
using Random = UnityEngine.Random;

namespace Loong.Edit
{

    public class EditPkgGranule : EditPkgSub
    {
        #region 字段

        #endregion

        #region 属性
        public override string Des => "一个文件1个包";
        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        /// <summary>
        /// 压缩所有资源
        /// </summary>
        protected void CompAll()
        {
            var target = BuildSettingsUtil.Target;
            AssetUpgUtil.Delete(target, 0);
            AssetUpgUtil.Collect(target, 0);
        }

        /// <summary>
        /// 拷贝所有压缩资源到流目录
        /// </summary>
        protected void CopyAll()
        {
            var data = AssetUpgUtil.Data;
            var srcDir = data.GetCompDir(0);
            if (Directory.Exists(srcDir))
            {
                var destDir = Application.streamingAssetsPath;
                EditDirUtil.Copy(srcDir, destDir);
            }
            else
            {
                UIEditTip.Error("Loong,{0} not exist!", srcDir);
            }
        }
        #endregion

        #region 公开方法
        public override void StartAll(int targetVer = 0)
        {
            var allSet = GetAllInfo(targetVer);
            var dic = AssetMf.Read(allSet);
            if (dic.Count < 1) return;
            ProgressBarUtil.Max = 50;
            var upgData = AssetUpgUtil.Data;


            //拷贝所有首包清单内的资源到流目录
            Md5Info info = null;
            var title = "拷贝到流目录";
            var compDir = upgData.GetCompDir();
            var streaming = AssetPathUtil.Streaming;
            ProgressBarUtil.Refresh();
            var baseEm = dic.GetEnumerator();
            var proLen = dic.Count;
            int idx = 0;
            while (baseEm.MoveNext())
            {
                ++idx;
                var cur = baseEm.Current;
                var k = cur.Key;
                info = cur.Value;
                ProgressBarUtil.Show(title, k, idx / proLen);
                var ver = info.Ver;
                var srcPath = string.Format("../{0}{1}/{2}", compDir, ver, k);
                var destPath = string.Format("{0}{1}", streaming, k);
                var dir = Path.GetDirectoryName(destPath);
                if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
                File.Copy(srcPath, destPath, true);

            }

            //拷贝总清单
            var srcMfPath = upgData.GetCompMd5Path(targetVer);
            var destMfPath = streaming + AssetMf.Name;
            File.Copy(srcMfPath, destMfPath, true);

            iTrace.Log("Loong", "copy all manifest, src:{0}, dest:{1}", srcMfPath, destMfPath);
            ProgressBarUtil.Clear();
            AssetDatabase.Refresh();
        }


        public override void StartSub(int targetVer = 0, bool containUpgs = true)
        {
            var baseDic = GetSubDic(targetVer, containUpgs);
            if (baseDic.Count < 1) return;
            ProgressBarUtil.Max = 50;
            var upgData = AssetUpgUtil.Data;
            var srcMfPath = upgData.GetCompMd5Path(targetVer);


            //拷贝所有首包清单内的资源到流目录
            Md5Info info = null;
            var title = "拷贝到流目录";
            var compDir = upgData.GetCompDir();
            var streaming = AssetPathUtil.Streaming;
            ProgressBarUtil.Refresh();
            var baseEm = baseDic.GetEnumerator();
            var proLen = baseDic.Count;
            int idx = 0;
            while (baseEm.MoveNext())
            {
                ++idx;
                var cur = baseEm.Current;
                var k = cur.Key;
                info = cur.Value;
                ProgressBarUtil.Show(title, k, idx / proLen);
                var ver = info.Ver;
                var srcPath = string.Format("../{0}{1}/{2}", compDir, ver, k);
                var destPath = string.Format("{0}{1}", streaming, k);
                var dir = Path.GetDirectoryName(destPath);
                if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
                File.Copy(srcPath, destPath, true);

            }

            //生成首包清单到流目录
            title = "生成首包清单";
            var temp = AssetPathUtil.Temp;
            var baseMfName = AssetMf.BaseName;
            var srcBaseMfPath = temp + baseMfName;
            var destBaseMfPath = streaming + baseMfName;
            ProgressBarUtil.Show(title, baseMfName, 1f);
            AssetMf.Write(baseDic, srcBaseMfPath);
            var comp = CompFty.Create();
            comp.Src = srcBaseMfPath;
            comp.Dest = destBaseMfPath;
            if (!comp.Execute())
            {
                Debug.LogErrorFormat("Loong, comp {0} fail", destBaseMfPath);
            }

            //拷贝总清单
            var destMfPath = streaming + AssetMf.Name;
            File.Copy(srcMfPath, destMfPath, true);
            ProgressBarUtil.Clear();
            AssetDatabase.Refresh();
        }

        #endregion
    }
}