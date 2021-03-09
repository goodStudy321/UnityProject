/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2016/8/10 10:51:54
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    using StrDic = Dictionary<string, string>;

    /// <summary>
    /// 命令行设置基类
    /// </summary>
    public abstract class CmdSetting
    {
        #region 字段
        /// <summary>
        /// 版本号键
        /// </summary>
        public const string VerKey = "-Ver";

        #endregion

        #region 属性
        public virtual VerData Data
        {
            get { return null; }
        }
        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        /// <summary>
        /// 解析版本号
        /// </summary>
        /// <param name="arr"></param>
        /// <param name="majar"></param>
        /// <param name="minor"></param>
        /// <param name="build"></param>
        /// <param name="verCode"></param>
        private void ParseVer(string[] arr, ref int majar, ref int minor, ref int build, ref int verCode)
        {
            if (arr == null) return;
            var len = arr.Length;
            if (len > 3)
            {
                var str = arr[3];
                if (!int.TryParse(str, out verCode))
                {
                    Debug.LogErrorFormat("Loong,can't parse vercode num:{0} to int", str);
                }
            }

            if (len > 2)
            {
                var str = arr[2];
                if (!int.TryParse(str, out build))
                {
                    Debug.LogErrorFormat("Loong,can't parse build num:{0} to int", str);
                }
            }

            if (len > 1)
            {
                var str = arr[1];
                if (!int.TryParse(str, out minor))
                {
                    Debug.LogErrorFormat("Loong,can't parse minor num:{0} to int", str);
                }
            }

            if (len > 0)
            {
                var str = arr[0];
                if (!int.TryParse(str, out majar))
                {
                    Debug.LogErrorFormat("Loong,can't parse majar num:{0} to int", str);
                }
            }
        }

        #region 保护方法

        protected void SetVer(StrDic dic)
        {
            int major = 1;
            int minor = -1;
            int build = 0;
            int verCode = -1;
            if (dic.ContainsKey(VerKey))
            {
                string str = dic[VerKey];
                string[] arr = str.Split('_');
                ParseVer(arr, ref major, ref minor, ref build, ref verCode);
            }

            if (minor < 0)
            {
                int tempMajor = Data.Major;
                if (major != tempMajor)
                {
                    Data.Minor = 0;
                }
                ++Data.Minor;
            }
            else
            {
                Data.Minor = minor;
            }


            Data.Major = major;
            minor = Data.Minor;
            var verStr = string.Format("{0}.{1}.{2}", major, minor, build);
            PlayerSettings.bundleVersion = verStr;


            if (verCode < 0)
            {
                verCode = Data.VerCode + 10;
            }
            Data.VerCode = verCode;
            SetVerCode(verCode);
            Debug.LogFormat("set bundleVersion:{0},verCode:{1}", verStr, verCode);
        }


        /// <summary>
        /// 保存完整版本号配置 包含Ver和内部版本号
        /// </summary>
        protected void SaveFullVer()
        {
            var cur = Directory.GetCurrentDirectory();
            var target = EditorUserBuildSettings.activeBuildTarget.ToString();
            var path = string.Format("{0}/Release/{1}/Ver.txt", cur, target);
            var dir = Path.GetDirectoryName(path);
            if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
            var ver = PlayerSettings.bundleVersion;
            var verCode = GetVerCode();
            var fullVer = string.Format("{0}.{1}", ver, verCode);
            FileTool.Save(path, fullVer);

            var sDir = Application.streamingAssetsPath;
            var sPath = Path.Combine(sDir, UpgUtil.PkgVerFile);
            FileTool.Save(sPath, verCode);
        }

        /// <summary>
        /// 设置显示名称
        /// </summary>
        protected void SetDisplayName()
        {
            var displayName = BuildArgs.DisplayName;
            PlayerSettings.productName = displayName;
        }


        protected virtual void SetBackend()
        {
            var target = EditorUserBuildSettings.selectedBuildTargetGroup;
            PlayerSettings.SetScriptingBackend(target, BuildArgs.Backend);
        }

        /// <summary>
        /// 获取内部版本号
        /// </summary>
        /// <returns></returns>
        protected abstract string GetVerCode();


        /// <summary>
        /// 设置内部版本号
        /// </summary>
        protected abstract void SetVerCode(int ver);


        #endregion

        #region 公开方法
        /// <summary>
        /// 命令行参数字典
        /// </summary>
        /// <param name="dic"></param>
        public virtual void Execute(StrDic dic)
        {
            SetVer(dic);
            SaveFullVer();
            SetDisplayName();
            SetBackend();
        }

        #endregion
    }
}