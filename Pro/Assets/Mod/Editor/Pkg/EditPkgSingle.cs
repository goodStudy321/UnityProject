//*****************************************************************************
// Copyright (C) 2020, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2020/4/8 15:06:30
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
    /// <summary>
    /// EditPkgSingle
    /// </summary>
    public class EditPkgSingle : EditPkgSub
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

        #endregion

        #region 保护方法


        protected void Start(Md5Set set)
        {
            if (set == null || set.infos.Count < 1) return;
            var infos = set.infos;
            var compDir = AssetUpgUtil.Data.GetCompRoot();
            if (!Directory.Exists(compDir))
            {
                UIEditTip.Error("{0} not exist", compDir); return;
            }

            var mainPath = EditObbUtil.GetBuildMainPath();
            FileTool.CheckDir(mainPath);

            float len = infos.Count;
            ProgressBarUtil.Max = 50;
            var mainStream = new FileStream(mainPath, FileMode.Create, FileAccess.ReadWrite);
            var bufLen = 1024 * 4;
            var buf = new byte[bufLen];
            var title = "写入中···";
            var readSize = 0;
            for (int i = 0; i < len; i++)
            {

                var info = infos[i];
                var key = info.path;
                var ver = info.Ver;
                var rPath = Path.Combine(ver.ToString(), key);
                var filePath = Path.Combine(compDir, rPath);
                if (!File.Exists(filePath))
                {
                    mainStream.Dispose();
                    EditApp.ExitBatch(ExitCode.UpgCompFileNotExist, "{0} not exist!", filePath); break;
                }

                var fs = File.OpenRead(filePath);
                while ((readSize = fs.Read(buf, 0, bufLen)) > 0)
                {
                    mainStream.Write(buf, 0, readSize);
                }
                fs.Dispose();


                ProgressBarUtil.Show(title, key, i / len);
            }
            mainStream.Dispose();
            ProgressBarUtil.Clear();


#if GAME_DEBUG
            var mainName = Path.GetFileName(mainPath);
            var mainStreamPath = AssetPathUtil.Streaming + mainName;
            File.Copy(mainPath, mainStreamPath, true);
            iTrace.Log("Loong", "{0}, {1}, {2}", Des, mainPath, mainStreamPath);
            AssetDatabase.Refresh();
#else
            iTrace.Log("Loong", "{0}, {1}", Des, mainPath);
#endif

        }
        #endregion

        #region 公开方法
        public override string Des => "所有文件1个包";


        public override void StartAll(int targetVer = 0)
        {
            CopyAllMf(targetVer);
            var info = GetAllInfo(targetVer);
            Start(info);
        }


        public override void StartSub(int targetVer = 0, bool containUpgs = true)
        {
            GetSubDic(targetVer, containUpgs);
            var info = GetSubInfo(targetVer, containUpgs);
            Start(info);
        }
        #endregion
    }
}