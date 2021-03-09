//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/15 16:58:16
//=============================================================================

using System;
using System.IO;
using Loong.Edit;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit.Confuse
{
    /// <summary>
    /// ConfuseMgr
    /// </summary>
    public static class ConfuseMgr
    {
        #region 字段

        private static ConfuseView data = null;

        public const int Pri = MenuTool.NormalPri + 80;

        public const string menu = MenuTool.Loong + "混淆/";

        public const string AMenu = MenuTool.ALoong + "混淆/";
        #endregion

        #region 属性

        public static ConfuseCfg Cfg
        {
            get { return Data.cfg; }
        }

        public static ConfuseCodeCfg CodeCfg
        {
            get { return Data.codeCfg; }
        }

        public static ConfuseUnusedCfg UnusedCfg
        {
            get { return Data.unusedCfg; }
        }

        public static ConfuseView Data
        {
            get
            {
                if (data == null)
                {
                    data = AssetDataUtil.Get<ConfuseView>();
                }
                return data;
            }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        private static int GetFreq()
        {
            var cfg = Cfg;
            var freq = BuildArgs.ConfuseFreq;
            if (freq < 0)
            {
                cfg.freq = 1;
            }
            else if (freq > 0)
            {
                cfg.freq = freq;
            }
            else if (cfg.freq > 0)
            {
                cfg.freq += 1;
            }
            EditUtil.SetDirty(Data);
            return cfg.freq;
        }

        private static int GetUnusedFileCount()
        {
            var cfg = UnusedCfg;
            var count = BuildArgs.ConfuseUnusedFileCount;
            if (count < 0)
            {
                cfg.fileCount = 0;
            }
            else if (count > 0)
            {
                cfg.fileCount = count;
            }
            else if (cfg.fileCount > 0)
            {
                cfg.fileCount += 2;
            }
            EditUtil.SetDirty(Data);
            return cfg.fileCount;
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        public static void CopyCode()
        {
            var curDir = Directory.GetCurrentDirectory();
            EditDirUtil.Copy(CodeCfg.cacheDir, curDir);
        }


        public static void CopyFile()
        {
            EditDirUtil.Copy(UnusedCfg.destDir, GetAssetDir());
        }


        public static void GenUnusedFiles()
        {
            DelUnusedFiles();
            var cfg = UnusedCfg;
            var dir = GetAssetDir();
            cfg.fileCount = GetUnusedFileCount();
            var gen = new ConfuseUnusedFile(dir, cfg);
            gen.Apply();
            AssetDatabase.Refresh();
            EditUtil.SetDirty(Data);
        }

        public static string GetAssetDir()
        {
            return Application.streamingAssetsPath;
        }


        public static void DelUnusedFiles()
        {
            var cfg = UnusedCfg;
            var dir = cfg.destDir;
            if (Directory.Exists(dir)) Directory.Delete(dir, true);
            dir = GetAssetDir();
            if (!Directory.Exists(dir)) return;
            var files = Directory.GetFiles(dir, "*", SearchOption.AllDirectories);
            int length = files.Length;
            for (int i = 0; i < length; i++)
            {
                var file = files[i];
                if (file.Contains(cfg.fileFlag))
                {
                    File.Delete(file);
                }
            }
            AssetDatabase.Refresh();
        }

        public static void GenCode()
        {
            DelCode();
            var code = new ConfuseCode(Data.cfg, Data.codeCfg);
            code.Apply();
        }

        public static void DelCode()
        {
            var codeDir = CodeCfg.cacheDir;
            if (!Directory.Exists(codeDir)) return;
            Directory.Delete(codeDir, true);
        }


        public static void GenUnuseCode()
        {
            DelUnuseCode();
            var unusedCode = new ConfuseUnusedCode(Data.cfg, Data.codeCfg);
            unusedCode.Apply();

            var replaceMain = new ConfuseReplaceMain(Data.codeCfg);
            replaceMain.Applay(unusedCode.CodeClasses);
        }

        public static void DelUnuseCode()
        {
            var cfg = CodeCfg;
            var proDir = "./" + cfg.unusedDir;
            proDir = Path.GetFullPath(proDir);
            if (Directory.Exists(proDir)) Directory.Delete(proDir, true);
            var exterDir = Path.Combine(cfg.cacheDir, cfg.unusedDir);
            if (Directory.Exists(exterDir)) Directory.Delete(exterDir, true);
        }

        public static void Apply()
        {
            int freq = GetFreq();
            Debug.LogWarningFormat("Loong, ConfuseFreq:{0}", freq);
            CodeUtil.Init();
            GenUnusedFiles();
            GenCode();
            GenUnuseCode();
            CopyFile();
            CopyCode();
        }

        public static void Delete()
        {
            DelUnusedFiles();
            DelCode();
        }

        public static void CheckFile()
        {
            var cfg = CodeCfg;
            var set = new Dictionary<string, string>();
            CodeUtil.Init();
            CodeUtil.GetDic(cfg.srcTypePath, set);
            CodeUtil.GetDic(cfg.destTypePath, set);
            CodeUtil.GetDic(cfg.funcNamePath, set);
            CodeUtil.GetDic(cfg.fieldNamePath, set);
        }



        [MenuItem(menu + "应用", false, Pri + 1)]
        [MenuItem(AMenu + "应用", false, Pri + 1)]
        public static void ApplyDialog()
        {
            DialogUtil.Show("", "应用?", Apply);
        }

        [MenuItem(menu + "删除", false, Pri + 2)]
        [MenuItem(AMenu + "删除", false, Pri + 2)]
        public static void DeleteDialog()
        {
            DialogUtil.Show("", "删除所有?", Delete);
        }

        [MenuItem(menu + "混淆代码", false, Pri + 3)]
        [MenuItem(AMenu + "混淆代码", false, Pri + 3)]
        public static void GenCodeDialog()
        {
            DialogUtil.Show("", "混淆代码?", GenCode);
        }

        [MenuItem(menu + "删除混淆代码", false, Pri + 4)]
        [MenuItem(AMenu + "删除混淆代码", false, Pri + 4)]
        public static void DelCodeDialog()
        {
            DialogUtil.Show("", "删除混淆代码?", DelCode);
        }

        [MenuItem(menu + "生成无用代码", false, Pri + 5)]
        [MenuItem(AMenu + "生成无用代码", false, Pri + 5)]
        public static void GenUnuseCodeDialog()
        {
            DialogUtil.Show("", "生成无用代码?", GenUnuseCode);
        }

        [MenuItem(menu + "删除无用代码", false, Pri + 6)]
        [MenuItem(AMenu + "删除无用代码", false, Pri + 6)]
        public static void DelUnuseCodeDialog()
        {
            DialogUtil.Show("", "删除无用代码?", DelUnuseCode);
        }


        [MenuItem(menu + "生成无用资源", false, Pri + 9)]
        [MenuItem(AMenu + "生成无用资源", false, Pri + 9)]
        public static void GenUnusedFilesDialog()
        {
            DialogUtil.Show("", "生成无用资源?", GenUnusedFiles);
        }

        [MenuItem(menu + "删除无用资源", false, Pri + 10)]
        [MenuItem(AMenu + "删除无用资源", false, Pri + 10)]
        public static void DelUnusedFilesDialog()
        {
            DialogUtil.Show("", "删除无用资源?", DelUnusedFiles);
        }

        [MenuItem(menu + "校验配置文件", false, Pri + 11)]
        [MenuItem(AMenu + "校验配置文件", false, Pri + 11)]
        public static void CheckFileDialog()
        {
            DialogUtil.Show("", "校验配置文件?", CheckFile);
        }


        public static void BatchApply()
        {
            if (BuildArgs.EnableConfuse)
            {
                Apply();
            }
        }
        #endregion
    }
}