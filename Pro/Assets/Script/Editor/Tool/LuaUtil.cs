/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2017/5/8 22:49:12
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Diagnostics;
using System.Collections.Generic;
using Object = UnityEngine.Object;
using Debug = UnityEngine.Debug;

namespace Loong.Edit
{
    /// <summary>
    /// lua工具
    /// </summary>
    public static class LuaUtil
    {
        #region 字段
        /// <summary>
        /// 优先级
        /// </summary>
        public const int Pri = MenuTool.NormalPri + 60;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = MenuTool.Loong + "Lua工具/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = MenuTool.ALoong + "Lua工具/";

        private static ElapsedTime et = new ElapsedTime();

        /// <summary>
        /// 使用AB
        /// </summary>
        public static bool UseAB = true;
        /// <summary>
        /// 工程内lua文件相对目录
        /// </summary>
        public const string ProAssetDir = "Assets/Lua";

        /// <summary>
        /// Lua源文件夹名
        /// </summary>
        public const string LuaCodeFolder = "LuaCode";

        /// <summary>
        /// Lua编码后的文件夹名
        /// </summary>
        public const string LuaEncodeFolder = "LuaJitCode";



        /// <summary>
        /// 使用编码选项菜单路径
        /// </summary>
        public const string UseEncodePath = menu + "UseEncode(使用编码后的文件)";


        #endregion

        #region 属性

        public static bool UseEncode
        {
            get
            {
                return EditPrefsTool.GetBool(null, "UseLuaEncode", false);
            }
            set
            {
                EditPrefsTool.SetBool(null, "UseLuaEncode", value);
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

        public static string GetCodeDir(string folderName)
        {
            string pre = Path.GetDirectoryName(AssetPath.Output);
            pre = pre.Replace("\\", "/");
            string fullPath = pre + "/" + folderName;
            return fullPath;
        }

        /// <summary>
        /// 获取lua源代码目录
        /// </summary>
        /// <returns></returns>
        public static string GetLuaCodeDir()
        {
            return GetCodeDir(LuaCodeFolder);
        }

        /// <summary>
        /// 获取lua编码后的代码
        /// </summary>
        /// <returns></returns>
        public static string GetEncodeDir()
        {
            return GetCodeDir(LuaEncodeFolder);
        }

        /// <summary>
        /// 获取lua资源目录
        /// </summary>
        /// <returns></returns>
        public static string GetLuaAssetDir(bool useAB)
        {
            string dest = null;
            if (useAB)
            {
                string cur = Directory.GetCurrentDirectory();
                dest = Path.Combine(cur, ProAssetDir);
            }
            else
            {
                dest = AssetPath.Output + "/Lua";
            }
            return dest;
        }

        public static void CopyCode(string folder)
        {
            string src = GetCodeDir(folder);
            if (!Directory.Exists(src))
            {
                return;
            }
            string dest = GetLuaAssetDir(UseAB);
            string dest2 = GetLuaAssetDir(!UseAB);
            if (Directory.Exists(dest2))
            {
                Directory.Delete(dest2, true);
            }
            if (Directory.Exists(dest))
            {
                Directory.Delete(dest, true);
            }
            if (!Directory.Exists(dest))
            {
                Directory.CreateDirectory(dest);
            }
            if (UseAB)
            {
                CopyToPro(src, dest);
            }
            else
            {
                EditDirUtil.Copy(src, dest);
            }
            AssetDatabase.Refresh();
        }


        /// <summary>
        /// 拷贝lua到工程内
        /// </summary>
        public static void CopyToPro(string src, string dest)
        {
            if (!Directory.Exists(src)) return;
            if (!Directory.Exists(dest)) Directory.CreateDirectory(dest);
            var files = Directory.GetFiles(src, "*.*", SearchOption.AllDirectories);
            if (files == null) return;
            int srcLen = src.Length + 1;
            float length = files.Length;
            for (int i = 0; i < length; i++)
            {
                var path = files[i];
                var rPath = path.Substring(srcLen);
                ProgressBarUtil.Show("复制LUA", rPath, i / length);
                rPath = rPath + Suffix.Bytes;
                var nPath = Path.Combine(dest, rPath);
                string dir = Path.GetDirectoryName(nPath);
                if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
                File.Copy(path, nPath);
            }
            ProgressBarUtil.Clear();
            AssetDatabase.Refresh();
        }


        /// <summary>
        /// 编码lua文件
        /// </summary>
        public static void Encode()
        {
            string srcDir = GetLuaCodeDir();
            string destDir = GetEncodeDir();

            iTrace.Log("Loong", "srcDir:" + srcDir + ", destDir:" + destDir);

            SearchOption op = SearchOption.AllDirectories;
            string[] files = Directory.GetFiles(srcDir, "*.lua", op);
            if (files == null || files.Length < 1)
            {
                UIEditTip.Error("无文件"); return;
            }
            if (!Directory.Exists(destDir))
            {
                Directory.CreateDirectory(destDir);
            }
            float length = files.Length;
            for (int i = 0; i < length; i++)
            {
                string src = files[i];
                src = src.Replace("\\", "/");
                string rName = src.Substring(srcDir.Length);
                string dest = destDir + rName;
                Encode(src, dest);
                ProgressBarUtil.Show("编码lua文件", src, i / length);
            }

            ProgressBarUtil.Clear();
        }

        /// <summary>
        /// 编码lua文件
        /// </summary>
        /// <param name="srcPath">原文件路径</param>
        /// <param name="destPath">目标文件路径</param>
        public static void Encode(string srcPath, string destPath)
        {
            if (!File.Exists(srcPath)) return;
            string dir = Path.GetDirectoryName(destPath);
            if (!Directory.Exists(dir)) Directory.CreateDirectory(dir);
            string jitDir = Path.GetFullPath("../Luajit64/");
            if (!Directory.Exists(jitDir))
            {
                iTrace.Error("Loong", string.Format("jit目录:{0},不存在!", jitDir));
                return;
            }
            string curDir = Directory.GetCurrentDirectory();
            Directory.SetCurrentDirectory(jitDir);
            string exe = "";
            string args = "";
            if (Application.platform == RuntimePlatform.WindowsEditor)
            {
                exe = jitDir + "luajit64.exe";
                args = "-b " + srcPath + " " + destPath;
            }
            else if (Application.platform == RuntimePlatform.OSXEditor)
            {
                exe = jitDir + "luac";
                args = "-o " + destPath + " " + srcPath;
            }
            ProcessStartInfo info = new ProcessStartInfo();
            info.FileName = exe;
            info.Arguments = args;
            info.WindowStyle = ProcessWindowStyle.Hidden;
            info.ErrorDialog = true;
            info.UseShellExecute = true;
            Process pro = Process.Start(info);
            pro.WaitForExit();
            Directory.SetCurrentDirectory(curDir);

        }


        [MenuItem(UseEncodePath, false, Pri)]
        public static void SetUseEncode()
        {
            bool val = UseEncode;
            val = !val;
            UseEncode = val;
        }

        [MenuItem(UseEncodePath, true, Pri)]
        private static bool GetUseEncode()
        {
            bool val = UseEncode;
            Menu.SetChecked(UseEncodePath, val);
            return true;
        }

        /// <summary>
        /// 编码lua文件,有对话框提示
        /// </summary>
        [MenuItem(menu + "编码 &e", false, Pri + 1)]
        [MenuItem(AMenu + "编码", false, Pri + 1)]
        public static void EncodeWithDialog()
        {
            if (EditorUtility.DisplayDialog("", "编码lua文件", "是", "否"))
            {
                Encode();
            }
        }

        /// <summary>
        /// 拷贝原代码,带对话框
        /// </summary>
        /// <summary>
        [MenuItem(menu + "拷贝[未编码]文件到资源目录", false, Pri + 2)]
        [MenuItem(AMenu + "拷贝[未编码]文件到资源目录", false, Pri + 2)]
        public static void CopyLuaCodeWithDialog()
        {
            string title = "拷贝lua[未编码]文件到资源目录";
            if (EditorUtility.DisplayDialog("", title, "是", "否"))
            {
                CopyCode(LuaCodeFolder);
            }
        }

        /// <summary>
        /// 拷贝编码后的代码,带对话框
        /// </summary>
        [MenuItem(menu + "拷贝[编码]文件到资源目录", false, Pri + 3)]
        [MenuItem(AMenu + "拷贝[编码]文件到资源目录", false, Pri + 3)]
        public static void CopyEncodeWithDialog()
        {
            string title = "拷贝lua[编码]文件到资源目录";
            if (EditorUtility.DisplayDialog("", title, "是", "否"))
            {
                CopyCode(LuaEncodeFolder);
            }
        }

        /// <summary>
        /// 拷贝编码后的代码,带对话框
        /// </summary>
        [MenuItem(menu + "删除资源目录的lua文件", false, Pri + 4)]
        [MenuItem(AMenu + "删除资源目录的lua文件", false, Pri + 4)]
        public static void DeleteLuaAssets()
        {
            string title = "删除资源目录的lua文件?";
            if (EditorUtility.DisplayDialog("", title, "是", "否"))
            {
                string dir = GetLuaAssetDir(UseAB);
                if (Directory.Exists(dir))
                {
                    Directory.Delete(dir, true);
                    UIEditTip.Log("已删除");
                }
                else
                {
                    UIEditTip.Warning("不存在,无需删除");
                }
            }
        }

        /// <summary>
        /// 设置lua资源包名称
        /// </summary>
        [MenuItem(menu + "设置lua AB名称", false, Pri + 5)]
        [MenuItem(AMenu + "设置lua AB名称", false, Pri + 5)]
        public static void SetAB()
        {
            var dir = GetLuaAssetDir(true);
            var files = Directory.GetFiles(dir, "*", SearchOption.AllDirectories);
            if (files == null || files.Length < 1)
            {
                UIEditTip.Warning("无lua文件需要设置AB"); return;
            }
            ProgressBarUtil.Max = 30;
            float length = files.Length;
            for (int i = 0; i < length; i++)
            {
                var path = files[i];
                string sfx = Path.GetExtension(path);
                if (sfx == Suffix.Meta) continue;
                path = path.Replace('\\', '/');
                var rPath = FileUtil.GetProjectRelativePath(path);
                ProgressBarUtil.Show("设置LUA AB", rPath, i / length);
                ABNameUtil.Set(rPath);
            }
            AssetDatabase.Refresh();
            ProgressBarUtil.Clear();
            AssetDatabase.RemoveUnusedAssetBundleNames();
        }

        /// <summary>
        /// 拷贝并设置lua资源包名称
        /// </summary>
        [MenuItem(menu + "拷贝并设置lua AB名称", false, Pri + 6)]
        [MenuItem(AMenu + "拷贝并设置lua AB名称", false, Pri + 6)]
        public static void CopyAndSetAB()
        {
            CopyAndSetAB(UseEncode);
        }

        /// <summary>
        /// 拷贝并设置lua资源包名称
        /// </summary>
        /// <param name="useEncode">true:使用编码</param>
        public static void CopyAndSetAB(bool useEncode)
        {
            et.Beg();
            var dir = useEncode ? LuaEncodeFolder : LuaCodeFolder;
            CopyCode(dir);
            SetAB();
            et.End("Lua CopyAndSetAB");
        }

        /// <summary>
        /// 拷贝原代码
        /// </summary>
        /// <summary>
        public static void CopyLuaCode()
        {
            CopyCode(LuaCodeFolder);
        }

        /// <summary>
        /// 拷贝编码后的代码
        /// </summary>
        public static void CopyEncode()
        {
            CopyCode(LuaEncodeFolder);
        }

        #endregion
    }
}