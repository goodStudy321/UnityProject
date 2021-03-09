/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014/11/14 10:28:30
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// 资源升级视图
    /// </summary>
    public class AssetUpgView : EditViewBase
    {
        #region 字段
        /// <summary>
        /// 0:无 1:过滤 2:指定
        /// </summary>
        public int op = 0;
        /// <summary>
        /// 资源版本号
        /// </summary>
        public int version = 0;

        private int upVersion = 0;
        /// <summary>
        /// 平台
        /// </summary>
        [SerializeField]
        private BuildTarget target;


        [SerializeField]
        [HideInInspector]
        private string savedDir = null;


        [SerializeField]
        [HideInInspector]
        private bool useCompress = true;

        [SerializeField]
        [HideInInspector]
        private bool autoCompressZero = true;

        [SerializeField]
        [HideInInspector]
        private int compressType = 1;

        [SerializeField]
        [HideInInspector]
        private string compressSfx = ".zip";

        private bool foldoutCompress = false;

        private string[] ops = new string[] { "无", "过滤", "指定" };

        private string[] compTypes = new string[] { "Zip", "LzmaU" };

        public SubPathPage filterPage = new SubPathPage();

        public SubPathPage assignPage = new SubPathPage();

        #endregion


        #region 属性

        /// <summary>
        /// 升级信息存放目录
        /// </summary>
        public string SavedDir
        {
            get
            {
                if (string.IsNullOrEmpty(savedDir))
                {
                    string dir = ABTool.Data.Output;
                    savedDir = DirUtil.GetLast(dir);
                    savedDir = savedDir.Replace("\\", "/");
                    EditUtil.SetDirty(this);
                }
                return savedDir;
            }
        }

        /// <summary>
        /// 使用压缩
        /// </summary>
        public bool UseCompress
        {
            get { return useCompress; }
            set
            {
                useCompress = value;
                EditorUtility.SetDirty(this);
            }
        }

        /// <summary>
        /// 自动压缩0版本的资源
        /// </summary>
        public bool AutoCompressZero
        {
            get { return autoCompressZero; }
            set
            {
                autoCompressZero = value;
                EditorUtility.SetDirty(this);
            }
        }


        /// <summary>
        /// 压缩类型
        /// </summary>
        public string CompressType
        {
            get
            {
                if (compressType < 0) compressType = 0;
                var len = compTypes.Length;
                if (compressType >= len) compressType = len - 1;
                return compTypes[compressType];
            }
        }


        /// <summary>
        /// 压缩后缀名
        /// </summary>
        public string CompressSfx
        {
            get { return compressSfx; }
            set
            {
                compressSfx = value;
                EditorUtility.SetDirty(this);
            }
        }


        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        /// <summary>
        /// 检查版本号的有效性 如果版本号MD5文件已经存在 则返回false
        /// </summary>
        private bool CheckVersion(string platFolder)
        {
            string filePath = GetMd5Path(platFolder, version);
            if (File.Exists(filePath))
            {
                UIEditTip.Error("版本号文件已经存在:{0}", filePath);
                return false;
            }
            return true;
        }


        /// <summary>
        /// 检查资源目录的有效性
        /// </summary>
        private bool CheckAssetDir(string dir)
        {
            if (string.IsNullOrEmpty(dir))
            {
                UIEditTip.Error("选取的资源目录为空");
                return false;
            }
            return true;
        }

        /// <summary>
        /// 设置资源目录
        /// </summary>
        private void SetSavedDir()
        {
            string temp = EditorUtility.OpenFolderPanel("设置资源目录", Directory.GetCurrentDirectory(), "");
            if (!CheckAssetDir(temp)) return;
            ShowTip(string.Format("设置资源目录:{0}", temp));
            EditUtil.RegisterUndo("SetAssetDir", this);
            savedDir = temp;
        }

        /// <summary>
        /// 压缩指定版本号资源
        /// </summary>
        private void Compress()
        {
            string folder = EditUtil.GetPlatform();
            string destDir = GetUpgDir(folder, version);
            string zipDir = GetCompDir(folder, version);
            AssetUpgUtil.Compress(destDir, zipDir, version);
        }


        private void OpChange()
        {
            CheckOp();
        }

        private bool CheckOp()
        {
            if (op == 0) return true;
            string msg = GetTip();
            return DialogUtil.Show(null, msg);
        }

        private string GetTip()
        {
            string msg = null;
            if (op == 0)
            {
                msg = "更新?";
            }
            else if (op == 1)
            {
                msg = "过滤模式下,需保证过滤的文件没有被更新的文件引用";
            }
            else if (op == 2)
            {
                msg = "指定模式下,需保证指定的文件没有引用被过滤的文件";
            }
            return msg;
        }


        /// <summary>
        /// 设置基础数据
        /// </summary>
        private void BaseProp()
        {
            if (!UIEditTool.DrawHeader("基础属性", "AssetUpgradeBasicData", StyleTool.Host)) return;
            EditorGUILayout.BeginVertical(StyleTool.Group);
            foldoutCompress = EditorGUILayout.Foldout(foldoutCompress, "压缩文件属性");
            if (foldoutCompress)
            {
                EditorGUILayout.BeginVertical(StyleTool.Box);
                UIEditLayout.Toggle("使用压缩文件:", ref useCompress, this);
                UIEditLayout.Toggle("压缩0版本的资源:", ref autoCompressZero, this);
                UIEditLayout.Popup("压缩类型(方式):", ref compressType, compTypes, this);
                if (GUILayout.Button("压缩当前版本资源"))
                {
                    Compress();
                }
                EditorGUILayout.EndVertical();
            }
            EditorGUILayout.Space();
            UIEditLayout.UIntField("当前资源版本号:", ref version, this);
            UIEditLayout.SetFolder("更新信息保存目录", ref savedDir, this);
            EditorGUI.BeginChangeCheck();
            Enum newValue = EditorGUILayout.EnumPopup("平台:", target);
            if (EditorGUI.EndChangeCheck())
            {
                EditUtil.RegisterUndo("EnumPopupValue", this);
                target = (BuildTarget)newValue;
            }
            EditorGUILayout.EndVertical();

        }

        /// <summary>
        /// 绘制更新
        /// </summary>
        private void DrawUpdate()
        {
            if (!UIEditTool.DrawHeader("更新资源数据", "AssetUpgradeCollect", StyleTool.Host)) return;
            EditorGUILayout.BeginVertical(StyleTool.Group);
            EditorGUILayout.BeginHorizontal(StyleTool.Box);
            UIEditLayout.Popup("模式", ref op, ops, this, OpChange);
            EditorGUILayout.LabelField(string.Format("收集版本号为{0}的资源更新信息", version));
            if (GUILayout.Button("更新", UIOptUtil.btn)) ChkUpgrade();
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.Space();
            if (op == 1)
            {
                filterPage.OnGUI(this);
            }
            else if (op == 2)
            {
                assignPage.OnGUI(this);
            }
            EditorGUILayout.EndVertical();
        }

        /// <summary>
        /// 绘制删除
        /// </summary>
        private void DrawDelete()
        {
            if (!UIEditTool.DrawHeader("删除资源数据", "AssetUpgradeDelete", StyleTool.Host)) return;
            EditorGUILayout.BeginVertical(StyleTool.Group);
            EditorGUILayout.BeginHorizontal();
            EditorGUILayout.LabelField(string.Format("删除版本号为{0}的资源更新信息", version));
            if (GUILayout.Button("删除", GUILayout.Width(100)))
            {
                AssetUpgUtil.DeleteWithDialog(target);
            }
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.Space();
            EditorGUILayout.BeginHorizontal();
            upVersion = EditorGUILayout.IntField("版本号:", upVersion);
            EditorGUILayout.LabelField(string.Format("删除版本号为{0}以及之上版本的资源更新信息", upVersion));
            if (GUILayout.Button("删除", GUILayout.Width(100)))
            {
                AssetUpgUtil.DeleteUpWithDialog(target, upVersion);
            }
            EditorGUILayout.EndHorizontal();
            EditorGUILayout.EndVertical();
        }

        private HashSet<string> GetSet(List<string> lst)
        {
            if (lst == null || lst.Count < 1) return null;
            var set = new HashSet<string>();
            int length = lst.Count;
            for (int i = 0; i < length; i++)
            {
                var it = lst[i];
                if (set.Contains(it)) continue;
                set.Add(it);
            }
            return set;
        }

        private void ChkUpgrade()
        {
            var msg = GetTip();
            var mode = (AssetUpgMode)op;
            HashSet<string> filters = null;
            if (!TryGetFilters(mode, ref filters))
            {
                return;
            }
            if (DialogUtil.Show(null, msg))
            {
                AssetUpgUtil.Collect(target, version, mode, filters);
            }
        }

        private bool TryGetFilters(AssetUpgMode mode, ref HashSet<string> filters)
        {
            if (mode == AssetUpgMode.Filter)
            {
                var lst = filterPage.lst;
                if (lst == null || lst.Count < 1)
                {
                    UIEditTip.Error("未设置过滤文件");
                    return false;
                }
                filters = GetSet(lst);
            }
            else if (mode == AssetUpgMode.Assign)
            {
                var lst = assignPage.lst;
                if (lst == null || lst.Count < 1)
                {
                    UIEditTip.Error("未设置指定文件");
                    return false;
                }
                filters = GetSet(lst);
            }
            return true;
        }
        #endregion

        #region 保护方法

        protected override void Title()
        {
            BegTitle();
            if (TitleBtn("更新"))
            {
                ChkUpgrade();
            }
            else if (TitleBtn("帮助"))
            {
                EditorUtility.DisplayDialog("", "请打开资源更新文档", "确定");
            }
            EndTitle();
        }

        /// <summary>
        /// 绘制
        /// </summary>
        protected override void OnGUICustom()
        {
            BaseProp();
            EditorGUILayout.Space();
            DrawUpdate();
            EditorGUILayout.Space();
            DrawDelete();
        }

        #endregion

        #region 公开方法

        public bool Upgrade(BuildTarget target, int ver, AssetUpgMode mode)
        {
            HashSet<string> filters = null;
            if (!TryGetFilters(mode, ref filters))
            {
                return false;
            }
            AssetUpgUtil.Collect(target, ver, mode, filters);
            return true;
        }

        /// <summary>
        /// 初始化
        /// </summary>
        public override void Initialize()
        {
            target = EditorUserBuildSettings.activeBuildTarget;
            var dir = ABTool.Data.Output;
            dir = Path.GetFullPath(dir);
            var startIdx = dir.Length;
            var c = dir[dir.Length - 1];
            if (c != '/' && c != '\\') ++startIdx;
            filterPage.startIdx = startIdx;
            assignPage.startIdx = startIdx;
        }

        /// <summary>
        /// 检查文件夹有效性
        /// </summary>
        /// <param name="plat"></param>
        /// <returns></returns>
        public bool Check(string plat)
        {
            if (!CheckAssetDir(SavedDir)) return false;
            if (!CheckVersion(plat)) return false;
            return true;
        }


        /// <summary>
        /// 获取资源目录的清单文件
        /// </summary>
        /// <returns></returns>
        public string GetSrcMd5Path()
        {
            var nfPath = string.Format("{0}/{1}", ABTool.Data.Output, AssetUpgUtil.ManifestFileName);
            return nfPath;
        }

        /// <summary>
        /// 获取对应版本号的MD5文件
        /// </summary>
        public string GetMd5Path(string plat, int ver)
        {
            var upgFolder = GetUpgDir(plat, ver);
            var md5FilePath = string.Format("{0}/{1}", upgFolder, AssetUpgUtil.ManifestFileName);
            return md5FilePath;
        }

        /// <summary>
        /// 获取当前平台对应版本的MD5文件
        /// </summary>
        /// <param name="ver"></param>
        /// <returns></returns>
        public string GetMd5Path(int ver)
        {
            var plat = EditUtil.GetPlatform();
            return GetMd5Path(plat, ver);
        }

        /// <summary>
        /// 获取对应版本号的升级文件信息
        /// </summary>
        public string GetUpgInfoPath(string plat, int ver)
        {
            var upgFolder = GetUpgDir(plat, ver);
            var infoPath = string.Format("{0}/{1}", upgFolder, AssetUpgUtil.UpgInfoFileName);
            return infoPath;
        }

        /// <summary>
        /// 获取当前平台对应版本号的升级文件信息
        /// </summary>
        /// <param name="ver"></param>
        /// <returns></returns>
        public string GetUpgInfoPath(int ver)
        {
            var plat = EditUtil.GetPlatform();
            return GetUpgInfoPath(plat, ver);
        }

        /// <summary>
        /// 获取对应版本号的升级目录
        /// </summary>
        public string GetUpgDir(string plat, int ver)
        {
            var dir = string.Format("AssetUpg/{0}/{1}", plat, ver);
            dir = string.Format("{0}/{1}", SavedDir, dir);
            dir = dir.Replace("//", "/");
            return dir;
        }

        public string GetUpgDirRoot()
        {
            return string.Format("{0}/AssetUpg", SavedDir);
        }

        /// <summary>
        /// 获取当前平台对应版本号的升级目录
        /// </summary>
        /// <param name="ver"></param>
        /// <returns></returns>
        public string GetUpgDir(int ver)
        {
            var plat = EditUtil.GetPlatform();
            return GetUpgDir(plat, ver);
        }

        /// <summary>
        /// 获取对应版本号压缩路径
        /// </summary>
        /// <param name="plat"></param>
        /// <param name="ver"></param>
        /// <returns></returns>
        public string GetCompDir(string plat, int ver)
        {
            var dir = string.Format("AssetUpg/{0}/Compress/{1}", plat, ver);
            dir = Path.Combine(SavedDir, dir);
            return dir;
        }

        /// <summary>
        /// 获取压缩资源根目录
        /// </summary>
        /// <returns></returns>
        public string GetCompRoot()
        {
            var plat = EditUtil.GetPlatform();
            var dir = string.Format("AssetUpg/{0}/Compress/", plat);
            dir = Path.Combine(SavedDir, dir);
            return dir;
        }

        public string GetCompDir()
        {
            var plat = EditUtil.GetPlatform();
            return string.Format("AssetUpg/{0}/Compress/", plat);
        }

        /// <summary>
        /// 获取当前平台对应版本号的压缩目录
        /// </summary>
        /// <param name="ver"></param>
        /// <returns></returns>
        public string GetCompDir(int ver)
        {
            var plat = EditUtil.GetPlatform();
            return GetCompDir(plat, ver);
        }

        /// <summary>
        /// 获取压缩目录的清单路径
        /// </summary>
        /// <param name="plat"></param>
        /// <param name="ver"></param>
        /// <returns></returns>
        public string GetCompMd5Path(string plat, int ver)
        {
            var dir = GetCompDir(plat, ver);
            var path = string.Format("{0}/{1}", dir, AssetUpgUtil.ManifestFileName);
            return path;
        }

        /// <summary>
        /// 获取当前平台压缩目录的清单路径
        /// </summary>
        /// <param name="ver"></param>
        /// <returns></returns>
        public string GetCompMd5Path(int ver)
        {
            var plat = EditUtil.GetPlatform();
            return GetCompMd5Path(plat, ver);
        }

        #endregion
    }
}