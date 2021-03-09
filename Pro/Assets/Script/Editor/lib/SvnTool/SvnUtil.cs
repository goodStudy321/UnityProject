/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2014/6/23 10:41:50
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// Svn工具
    /// </summary>
    public static class SvnUtil
    {
        #region 字段
        private static SvnView data = null;

        /// <summary>
        /// 菜单优先级
        /// </summary>
        public const int Pri = MenuTool.NormalPri + 20;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = MenuTool.Loong + "Svn工具/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = MenuTool.ALoong + "Svn工具/";
        #endregion

        #region 属性
        /// <summary>
        /// SVN配置数据
        /// </summary>
        public static SvnView Data
        {
            get
            {
                if (data == null) data = AssetDataUtil.Get<SvnView>();
                return data;
            }
        }
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 更新
        /// </summary>
        [MenuItem(menu + "根目录清理 &u", false, Pri + 1)]
        [MenuItem(AMenu + "根目录清理", false, Pri + 1)]
        public static void CleanUp()
        {
            CleanUp(2);
        }

        /// <summary>
        /// 清理
        /// </summary>
        /// <param name="closeonend">关闭窗口选项</param>
        public static void CleanUp(int closeonend)
        {
            if (Data.Check())
            {
                string closeonendStr = GetCloseonend(closeonend);
                string args1 = string.Format("/command:cleanup /path:{0} {1}", data.root, closeonendStr);
                ProcessUtil.Execute(GetPath(), args1, "SVN");
            }
            else
            {
                SvnWin.Open();
            }
        }


        /// <summary>
        /// 更新
        /// </summary>
        [MenuItem(menu + "根目录更新 %u", false, Pri + 2)]
        [MenuItem(AMenu + "根目录更新", false, Pri + 2)]
        public static void UpdateRoot()
        {
            Update(2);
        }

        /// <summary>
        /// 更新
        /// </summary>
        /// <param name="closeonend">关闭窗口选项</param>
        public static void Update(int closeonend)
        {
            if (Data.Check())
            {
                string closeonendStr = GetCloseonend(closeonend);
                string args1 = string.Format("/command:update /path:{0} {1}", data.root, closeonendStr);
                var path = GetPath();
                ProcessUtil.Execute(path, args1, "SVN");
                string args2 = string.Format("/command:resolve /path:{0} /noquestion {1}", data.root, closeonendStr);
                ProcessUtil.Execute(path, args2, "SVN");
            }
            else
            {
                SvnWin.Open();
            }
        }

        /// <summary>
        /// 提交
        /// </summary>
        /// <param name="path">路径</param>
        /// <param name="logMsg">日志信息</param>
        /// <param name="closeonend">关闭窗口选项</param>
        public static void Commit(string path, string logMsg = "无Log", int closeonend = 2)
        {
            if (string.IsNullOrEmpty(path)) return;
            if (File.Exists(path))
            {
                if (!Data.Check()) return;
                if (string.IsNullOrEmpty(logMsg)) logMsg = "无Log";
                string closeonendStr = GetCloseonend(closeonend);
                string args = string.Format("/command:commit /path:{0} /logmsg:{1} {2} -q /q -quiet /quiet", path, logMsg, closeonendStr);
                ProcessUtil.Execute(GetPath(), args, "SVN");
            }
            else
            {
                UIEditTip.Error("提交文件:{0}不存在", path);
            }
        }

        /// <summary>
        /// 添加
        /// </summary>
        /// <param name="path"></param>
        /// <param name="closeonend">关闭窗口选项</param>
        public static void Add(string path, int closeonend = 2)
        {
            if (string.IsNullOrEmpty(path)) return;
            if (File.Exists(path))
            {
                if (!Data.Check()) return;
                string closeonendStr = GetCloseonend(closeonend);
                string args = string.Format("/command:add /path:{0} {1}", path, closeonendStr);
                ProcessUtil.Execute(GetPath(), args, "SVN");
            }
            else
            {
                UIEditTip.Error("添加文件:{0}不存在", path);
            }
        }

        /// <summary>
        /// 获取关闭选项
        /// </summary>
        /// <param name="option"></param>
        /// <returns></returns>
        public static string GetCloseonend(int option)
        {
            string closeonend = "/closeonend:";
            if (option < 0 || option > 4) return null;
            closeonend = string.Format("{0}{1}", closeonend, option);
            return closeonend;
        }


        public static string GetPath()
        {
            var path = @"C:\Program Files\TortoiseSVN\bin\TortoiseProc.exe";
            if (File.Exists(path)) return path;
            path = @"D:\Program Files\TortoiseSVN\bin\TortoiseProc.exe";
            if (File.Exists(path)) return path;
            if (!string.IsNullOrEmpty(Data.svnExe)) return data.svnExe;
            return null;
        }
        #endregion
    }
}