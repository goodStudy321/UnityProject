using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.3.12 
    /// BG:Ftp数据视图
    /// </summary>
    [Serializable]
    public class FtpView
    {
        #region 字段
        [SerializeField]
        [HideInInspector]
        private string ip = "";

        [SerializeField]
        [HideInInspector]
        private string remotePath = "";

        [SerializeField]
        [HideInInspector]
        private string useName = "";

        [SerializeField]
        [HideInInspector]
        private string passward = "";

        #endregion

        #region 属性

        /// <summary>
        /// 远程路径
        /// </summary>
        public string RemotePath
        {
            get { return remotePath; }
            set { remotePath = value; }
        }

        /// <summary>
        /// FTP地址
        /// </summary>
        public string IP
        {
            get { return ip; }
            set { ip = value; }
        }

        /// <summary>
        /// 用户名
        /// </summary>
        public string UseName
        {
            get { return useName; }
            set { useName = value; }
        }

        /// <summary>
        /// 密码
        /// </summary>
        public string Password
        {
            get { return passward; }
            set { passward = value; }
        }
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        /// <summary>
        /// 设置属性
        /// </summary>
        private void SetPropery(Object obj)
        {
            if (!UIEditTool.DrawHeader("FTP设置", "FtpViewProp", StyleTool.Host)) return;
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.TextField("Ftp地址(必填):", ref ip, obj);
            UIEditLayout.TextField("远程路径:", ref remotePath, obj);
            UIEditLayout.TextField("用户名:", ref useName, obj);
            UIEditLayout.TextField("密码:", ref passward, obj);

            EditorGUILayout.EndVertical();
        }
        #endregion

        #region 保护方法
        /// <summary>
        /// 绘制UI
        /// </summary>
        /// <param name="obj"></param>
        public void OnGUI(Object obj)
        {
            SetPropery(obj);
        }
        #endregion

        #region 公开方法
        /// <summary>
        /// 获取无效信息,返回空时:有效
        /// </summary>
        /// <returns></returns>
        public string GetInvalidMsg()
        {
            if (string.IsNullOrEmpty(ip))
            {
                return "IP为空";
            }
            return null;
        }
        #endregion
    }
}