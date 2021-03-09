using System;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{

    /// <summary>
    /// AU:Loong
    /// TM:2013.5.10
    /// BG:发布视图
    /// </summary>
    public class ReleaseView : EditViewBase
    {
        #region 字段
        [SerializeField]
        [HideInInspector]
        private bool debug = false;

        [SerializeField]
        [HideInInspector]
        private bool development = false;

        [SerializeField]
        [HideInInspector]
        private bool connectProfiler = false;

        [SerializeField]
        [HideInInspector]
        private string output = null;

        [SerializeField]
        [HideInInspector]
        private string iosSuccessPath = "";

        [SerializeField]
        [HideInInspector]
        private string osxSuccessPath = "";

        [SerializeField]
        [HideInInspector]
        private string androidSuccessPath = "";

        [SerializeField]
        [HideInInspector]
        private string windowSuccessPath = "";

        [SerializeField]
        [HideInInspector]
        private bool useFtp = false;

        //[SerializeField]
        //[HideInInspector]
        //private FtpView ftpSetting = new FtpView();


        [SerializeField]
        [HideInInspector]
        private AndroidReleaseData androidSetting = new AndroidReleaseData();


        #endregion

        #region 属性
        /// <summary>
        /// 允许调试
        /// </summary>
        public bool Debug
        {
            get { return debug; }
            set
            {
                debug = value;
                EditorUtility.SetDirty(this);
            }
        }

        /// <summary>
        /// 是否开发者
        /// </summary>
        public bool Development
        {
            get { return development; }
            set
            {
                development = value;
                EditorUtility.SetDirty(this);
            }
        }

        /// <summary>
        /// 是否自动连接到分析器
        /// </summary>
        public bool ConnectProfiler
        {
            get { return connectProfiler; }
            set { connectProfiler = value; }
        }

        /// <summary>
        /// 发布路径
        /// </summary>
        public string Output
        {
            get { return output; }
            set { output = value; }
        }

        /// <summary>
        /// Ios发布成功路径
        /// </summary>
        public string IosSuccessPath
        {
            get { return iosSuccessPath; }
            set { iosSuccessPath = value; }
        }
        /// <summary>
        /// Mac成功发布路径
        /// </summary>
        public string OsxSuccessPath
        {
            get { return osxSuccessPath; }
            set { osxSuccessPath = value; }
        }
        /// <summary>
        /// Android发布成功路径
        /// </summary>
        public string AndroidSuccessPath
        {
            get { return androidSuccessPath; }
            set { androidSuccessPath = value; }
        }

        /// <summary>
        /// Window发布成功路径
        /// </summary>
        public string WindowSuccessPath
        {
            get { return windowSuccessPath; }
            set { windowSuccessPath = value; }
        }
        /// <summary>
        /// 使用FTP上传
        /// </summary>
        public bool UseFtp
        {
            get { return useFtp; }
            set { useFtp = value; }
        }
        /// <summary>
        /// ftp设置
        /// </summary>
        //public FtpView FtpSetting
        //{
        //    get { return ftpSetting; }
        //}

        /// <summary>
        /// Android设置
        /// </summary>
        public AndroidReleaseData AndroidSetting
        {
            get { return androidSetting; }
            set { androidSetting = value; }
        }


        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        /// <summary>
        /// 设置属性
        /// </summary>
        private void SetpProperty()
        {
            if (!UIEditTool.DrawHeader("基础属性", "ReleaseViewProperty", StyleTool.Host)) return;
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.SetFolder("发布目录:", ref output, this);
            UIEditLayout.Toggle("发布成功后使用FTP上传:", ref useFtp, this);
            if (useFtp) EditorGUILayout.HelpBox("务必添加有效的FTP地址", MessageType.Warning);
            EditorGUILayout.EndVertical();
            EditorGUILayout.Space();
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.Toggle("允许调试(AllowingDebug)", ref debug, this);
            UIEditLayout.Toggle("是否开发者(Development)", ref development, this);
            UIEditLayout.Toggle("自动连接分析器(ConnectProfiler)", ref connectProfiler, this);
            EditorGUILayout.EndVertical();

        }


        /// <summary>
        /// 显示发布成功路径
        /// </summary>
        private void ShowSuccessPath()
        {
            if (!UIEditTool.DrawHeader("上一次发布成功路径", "ReleaseSuccessPath", StyleTool.Host)) return;
            EditorGUILayout.BeginVertical(StyleTool.Group);

            if (!string.IsNullOrEmpty(androidSuccessPath))
            {
                EditorGUILayout.LabelField("Android:", androidSuccessPath);
            }
            if (!string.IsNullOrEmpty(iosSuccessPath))
            {
                EditorGUILayout.LabelField("Ios:", iosSuccessPath);
            }
            if (!string.IsNullOrEmpty(windowSuccessPath))
            {
                EditorGUILayout.LabelField("Windows:", windowSuccessPath);
            }
            if (!string.IsNullOrEmpty(osxSuccessPath))
            {
                EditorGUILayout.LabelField("Osx:", osxSuccessPath);
            }
            EditorGUILayout.EndVertical();
        }

        #endregion

        #region 保护方法
        /// <summary>
        /// 绘制
        /// </summary>
        protected override void OnGUICustom()
        {
            SetpProperty();
            ShowSuccessPath();
            if (!useFtp) GUI.enabled = false;
            //ftpSetting.OnGUI(this);
            GUI.enabled = Win.Compile ? false : true;
            androidSetting.OnGUI(this);
        }
        #endregion

        #region 公开方法

        #endregion
    }
}