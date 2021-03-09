/*=============================================================================
 * Copyright (C) 2018, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong on 2018/7/13 16:08:05
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using System.Text;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// 资源CDN视图
    /// </summary>
    public class AssetCdnView : EditViewBase
    {
        #region 字段

        private StringBuilder sb = new StringBuilder();

        public string ftpUrl = "133.186.220.246";
        //public string ftpUrl = "106.55.28.114";

        [SerializeField]
        [HideInInspector]
        private string ftpUserName = "kr_ftpuser";
        //private string ftpUserName = "zl_ftpuser";

        [SerializeField]
        [HideInInspector]
        private string ftpPassword = "kr_ftpuser123";
        //private string ftpPassword = "zl_ftpuser123";

        [SerializeField]
        [HideInInspector]
        private string httpUrl = UpgUtil.Host;

        [SerializeField]
        [HideInInspector]
        private string verifyDir = "../AssetVerify";

        /// <summary>
        /// 项目名
        /// </summary>
        [SerializeField]
        [HideInInspector]
        private string proName = null;

        /// <summary>
        /// 渠道ID
        /// </summary>
        [SerializeField]
        [HideInInspector]
        private int id = 0;

        /// <summary>
        /// true:调试
        /// </summary>
        [SerializeField]
        [HideInInspector]
        private bool debug = true;

        /// <summary>
        /// 目平台,0:Android 1,iOS
        /// </summary>
        [SerializeField]
        [HideInInspector]
        private int platOp = 0;

        /// <summary>
        /// 版本号
        /// </summary>
        [SerializeField]
        [HideInInspector]
        private int ver = 0;

        public string fullFtpUrl = "";
        public string fullHttpUrl = "";


        private string[] plats = new string[] { "Android", "iOS" };

        /// <summary>
        /// 生成CDN模板目录
        /// </summary>
        public string cdnTmpDir = "../";

        /// <summary>
        /// 资源刷新URL列表
        /// </summary>
        public string assetUrls = null;

        public bool foldoutAssetUrls = true;

        public AppVerInfo appVer = new AppVerInfo();

        public AssetVerInfo assetVer = new AssetVerInfo();

        public List<ChannelInfo> channels = new List<ChannelInfo>()
        {
            new ChannelInfo(0, AssetCdnUtil.Channels[0]),

            new ChannelInfo(1, AssetCdnUtil.Channels[1],"104287","107035"),

            new ChannelInfo(2, AssetCdnUtil.Channels[2],null,"112063"),

            new ChannelInfo(3, AssetCdnUtil.Channels[3],null,"112182"),
        };

        #endregion

        #region 属性
        /// <summary>
        /// 资源校验保存目录
        /// </summary>
        public string Dir
        {
            get { return verifyDir; }
            set
            {
                verifyDir = value;
                EditorUtility.SetDirty(this);
            }
        }


        public string ProName
        {
            get
            {
                if (string.IsNullOrEmpty(proName))
                {
                    return GetDefaultProName();
                }
                return proName;
            }
        }

        /// <summary>
        /// ftp用户名
        /// </summary>
        public string FtpUserName
        {
            get { return ftpUserName; }
            set
            {
                ftpUserName = value;
                EditorUtility.SetDirty(this);
            }
        }

        /// <summary>
        /// ftp密码
        /// </summary>
        public string FtpPassword
        {
            get { return ftpPassword; }
            set
            {
                ftpPassword = value;
                EditorUtility.SetDirty(this);
            }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        private string GetLocalDir(string plat, int ver)
        {
            string dir = null;
            var data = AssetUpgUtil.Data;
            if (data.UseCompress)
            {
                dir = data.GetCompDir(plat, ver);
            }
            else
            {
                dir = data.GetUpgDir(plat, ver);
            }
            return dir;
        }

        private void Upload()
        {
            SetUrl();
            string plat = GetPlat();
            string localDir = GetLocalDir(plat, ver);
            localDir = Path.GetFullPath(localDir);
            localDir = localDir.Replace('\\', '/');
            string msg = string.Format("上传:\n{0}\n到\n{1}?", localDir, fullFtpUrl);
            if (!EditorUtility.DisplayDialog("", msg, "确认", "取消")) return;
            AssetCdnUtil.Upload(fullFtpUrl, localDir);
        }

        private void Verify()
        {
            SetUrl();
            string msg = string.Format("校验IP:\n{0}\n的资源?", fullHttpUrl);
            if (!EditorUtility.DisplayDialog("", msg, "确认", "取消")) return;
            string plat = GetPlat();
            string localDir = GetLocalDir(plat, ver);
            AssetCdnUtil.Verify(fullHttpUrl, localDir);
        }

        /// <summary>
        /// 绘制基本属性
        /// </summary>
        private void DrawProp()
        {
            if (!UIEditTool.DrawHeader("FTP", "assetcdnprop", StyleTool.Host)) return;
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.TextField("FTP地址:", ref ftpUrl, this, SetUrl);
            UIEditLayout.TextField("FTP密码:", ref ftpUserName, this);
            UIEditLayout.TextField("FTP密码:", ref ftpPassword, this);
            EditorGUILayout.Space();
            UIEditLayout.TextField("HTTP(校验)地址:", ref httpUrl, this, SetAllUrls);
            EditorGUILayout.EndVertical();
        }

        /// <summary>
        /// 绘制版本号
        /// </summary>
        private void DrawVersion()
        {
            if (!UIEditTool.DrawHeader("安装包和资源版本号", "assetcdnappassetver", StyleTool.Host)) return;

            BegTitle();
            if (TitleBtn("重置安装包版本")) DialogUtil.Show("", "重置?", appVer.Reset);
            if (TitleBtn("重置资源版本")) DialogUtil.Show("", "重置?", assetVer.Reset);
            EndTitle();
            EditorGUILayout.BeginVertical(StyleTool.Group);
            appVer.OnGUI(this);
            EditorGUILayout.EndVertical();
            EditorGUILayout.BeginVertical(StyleTool.Group);
            assetVer.OnGUI(this);
            EditorGUILayout.EndVertical();

        }

        private void CreateInitCDNTmp()
        {
            CreateCDNTmp(appVer.GetInitStr(), assetVer.GetInitStr());
        }

        private void CreateCurCDNTmp()
        {
            CreateCDNTmp(appVer.ToString(), assetVer.ToString());
        }

        private void CreateCDNTmp(string appVer, string assetVer)
        {
            var msg = string.Format("安装包版本:{0}\n资源版本:{1}", appVer, assetVer);
            if (!EditorUtility.DisplayDialog("创建模板", msg, "确定", "取消")) return;
            var name = Path.GetFileName(cdnTmpDir);
            var saveDir = Path.GetDirectoryName(cdnTmpDir);
            var dir = EditorUtility.SaveFolderPanel("保存CDN模板", saveDir, name);
            if (string.IsNullOrEmpty(dir)) return;
            cdnTmpDir = Path.GetFullPath(dir);
            int length = channels.Count;
            var pkgFile = UpgUtil.PkgVerFile;
            var assetFile = UpgUtil.AssetVerFile;
            for (int i = 0; i < length; i++)
            {
                var it = channels[i];
                int platLen = plats.Length;
                for (int j = 0; j < platLen; j++)
                {
                    var plat = plats[j];
                    CreateVer(dir, assetFile, "Debug", "Assets", assetVer, plat, it);
                    CreateVer(dir, assetFile, "Release", "Assets", assetVer, plat, it);
                    CreateVer(dir, pkgFile, "Debug", "Package", appVer, plat, it);
                    CreateVer(dir, pkgFile, "Release", "Package", appVer, plat, it);
                }

            }
            UIEditTip.Log("创建完成");
        }

        private void CreateVer(string dir, string name, string debug, string assets, string ver, string plat, ChannelInfo chl)
        {
            var gcids = chl.GetGcids(plat);
            int length = gcids.Count;
            for (int i = 0; i < length; i++)
            {
                var gcid = gcids[i];
                var fn = GetVerFileName(name, gcid);
                var fullDir = string.Format("{0}/{1}/{2}/{3}/{4}", dir, chl.id, debug, plat, assets);
                if (!Directory.Exists(fullDir)) Directory.CreateDirectory(fullDir);
                var path = Path.Combine(fullDir, fn);
                FileTool.Save(path, ver, new UTF8Encoding(false));

            }
        }

        private void DrawChannel()
        {
            if (!UIEditTool.DrawHeader("渠道", "assetcdnchannels_header", StyleTool.Host)) return;
            BegTitle();
            if (TitleBtn("创建初始版本模板")) CreateInitCDNTmp();
            if (TitleBtn("创建当前版本模板")) CreateCurCDNTmp();
            EndTitle();
            UIEditLayout.SetFolder("上次保存模板目录:", ref cdnTmpDir, this);
            UIDrawTool.IDrawLst(this, channels, "assetcdnchnnels", "渠道列表");
        }


        /// <summary>
        /// 上传和校验
        /// </summary>
        private void DrawUploadVerify()
        {
            if (!UIEditTool.DrawHeader("上传和校验", "assetcdnuploadverify", StyleTool.Host)) return;
            BegTitle();
            if (TitleBtn("刷新IP")) SetUrl();
            if (TitleBtn("上传")) Upload();
            if (TitleBtn("校验")) Verify();
            EndTitle();
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.TextField("校验信息保存目录:", ref verifyDir, this);
            UIEditLayout.TextField("项目名:", ref proName, this, SetAllUrls);
            UIEditLayout.IntField("渠道ID:", ref id, this, SetAllUrls);

            UIEditLayout.Toggle("DEBUG:", ref debug, this, SetAllUrls);
            UIEditLayout.Popup("平台:", ref platOp, plats, this, SetAllUrls);
            UIEditLayout.IntField("版本:", ref ver, this, SetUrl);
            EditorGUILayout.EndVertical();

            EditorGUILayout.BeginVertical(StyleTool.Group);

            EditorGUILayout.TextField("完整Ftp路径:", fullFtpUrl);
            EditorGUILayout.TextField("完整Http路径:", fullHttpUrl);
            foldoutAssetUrls = EditorGUILayout.Foldout(foldoutAssetUrls, "刷新渠道ID路径列表");
            if (foldoutAssetUrls) EditorGUILayout.TextArea(assetUrls);
            EditorGUILayout.EndVertical();
        }

        private void SetAllUrls()
        {
            SetAssetUrls();
            SetUrl();
        }

        private void SetAssetUrls()
        {
            ChannelInfo chl = null;
            int length = channels.Count;
            for (int i = 0; i < length; i++)
            {
                var it = channels[i];
                if (it.id != id) continue;
                chl = it; break;
            }
            if (chl == null) return;
            var plat = GetPlat();
            var gcids = chl.GetGcids(plat);
            length = gcids.Count;
            if (length < 1) return;
            var pre = AssetCdnUtil.GetAssetUrl(httpUrl, proName, id, debug, plat);
            sb.Remove(0, sb.Length);
            for (int i = 0; i < length; i++)
            {
                var gcid = gcids[i];
                var fn = GetVerFileName(UpgUtil.AssetVerFile, gcid);
                sb.Append(pre).Append(fn).AppendLine();
            }
            assetUrls = sb.ToString();
        }
        #endregion

        #region 保护方法
        protected override void OnGUICustom()
        {
            DrawProp();
            DrawVersion();
            DrawChannel();
            DrawUploadVerify();
        }
        #endregion

        #region 公开方法
        public string GetVerFileName(string name, string gcid)
        {
            return (gcid == "null") ? name : (gcid + "_" + name);
        }


        public string GetPlat()
        {
            return plats[platOp];
        }
        public void SetUrl()
        {
            string plat = GetPlat();
            fullFtpUrl = AssetCdnUtil.GetAssetUrl(ftpUrl, proName, id, debug, plat, ver);
            fullHttpUrl = AssetCdnUtil.GetAssetUrl(httpUrl, proName, id, debug, plat, ver);
        }

        public override void Initialize()
        {
            base.Initialize();
            SetProName();
            SetUrl();
        }

        public void SetProName()
        {
            if (string.IsNullOrEmpty(proName)) proName = GetDefaultProName();
        }

        public string GetDefaultProName()
        {
            return UpgUtil.URL.Replace(UpgUtil.Host, "");
        }

        #endregion
    }
}