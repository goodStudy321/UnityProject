/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2013/5/10 18:11:07
 ============================================================================*/

using System;
using System.IO;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// 安卓发布数据
    /// </summary>
    [Serializable]
    public class AndroidReleaseData
    {
        #region 字段
        [SerializeField]
        [HideInInspector]
        private string keyStoreName = "";

        [SerializeField]
        [HideInInspector]
        private string keyStorePass = "";

        [SerializeField]
        [HideInInspector]
        private string keyStorePass2 = "";

        [SerializeField]
        [HideInInspector]
        private string keyaliasName = "";

        [SerializeField]
        [HideInInspector]
        private string keyaliasPass = "";

        [SerializeField]
        [HideInInspector]
        private string keyaliasPass2 = "";

        [SerializeField]
        [HideInInspector]
        private bool use = false;
        #endregion

        #region 属性
        /// <summary>
        /// 密匙库名称
        /// </summary>
        public string KeyStoreName
        {
            get { return keyStoreName; }
            set { keyStoreName = value; }
        }

        /// <summary>
        /// 密匙库密码
        /// </summary>
        public string KeyStorePass
        {
            get { return keyStorePass; }
            set { keyStorePass = value; }
        }

        /// <summary>
        /// 密匙库核对密码
        /// </summary>
        public string KeyStorePass2
        {
            get { return keyStorePass2; }
            set { keyStorePass2 = value; }
        }


        /// <summary>
        /// 密匙别名名称
        /// </summary>
        public string KeyaliasName
        {
            get { return keyaliasName; }
            set { keyaliasName = value; }
        }

        /// <summary>
        /// 密匙别名密码
        /// </summary>
        public string KeyaliasPass
        {
            get { return keyaliasPass; }
            set { keyaliasPass = value; }
        }

        /// <summary>
        ///  密匙别名核对密码
        /// </summary>
        public string KeyaliasPass2
        {
            get { return keyaliasPass2; }
            set { keyaliasPass2 = value; }
        }

        /// <summary>
        /// 使用设置
        /// </summary>
        public bool Use
        {
            get { return use; }
            set { use = false; }
        }
        #endregion

        #region 构造方法
        /// <summary>
        /// 显式构造方法
        /// </summary>
        public AndroidReleaseData()
        {

        }
        #endregion

        #region 私有方法
        private void DrawKeyStore(Object obj)
        {
            if (!UIEditTool.DrawHeader("Android密匙设置", "AndroidKeyStore", StyleTool.Host)) return;
            UIEditLayout.Toggle("是否使用设置:", ref use, obj);
            if (!use) GUI.enabled = false;
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.SetPath("密匙路径:", ref keyStoreName, obj, "jks");
            UIEditLayout.TextField("密匙密码:", ref keyStorePass, obj);
            UIEditLayout.TextField("确认密码:", ref keyStorePass2, obj);
            if (keyStorePass != keyStorePass2) UIEditLayout.HelpError("密匙密码不同");
            EditorGUILayout.Space();
            UIEditLayout.TextField("别名名称:", ref keyaliasName, obj);
            UIEditLayout.TextField("别名密码:", ref keyaliasPass, obj);
            UIEditLayout.TextField("确认密码:", ref keyaliasPass2, obj);
            if (keyaliasPass != keyaliasPass2) UIEditLayout.HelpError("别名密码不同");
            GUI.enabled = true;
            EditorGUILayout.EndVertical();
        }

        private void SetKeyStore(string storeName, string storePass, string aliasName, string aliasPass)
        {
            PlayerSettings.Android.keystoreName = storeName;
            PlayerSettings.Android.keystorePass = storePass;
            PlayerSettings.Android.keyaliasName = aliasName;
            PlayerSettings.Android.keyaliasPass = aliasPass;
        }

        /// <summary>
        /// 应用密匙设置
        /// </summary>
        private void ApplyKeyStore()
        {
            if (CheckKeyStore())
            {
                SetKeyStore(keyStoreName, keyStorePass, keyaliasName.ToLower(), keyaliasPass);
            }
            else
            {
                SetKeyStore(null, null, null, null);
            }
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 检查密匙名称有效性
        /// </summary>
        /// <returns></returns>
        public bool CheckeyStoreName()
        {
            if (string.IsNullOrEmpty(keyStoreName)) return false;
            if (!File.Exists(keyStoreName)) return false;
            string sfx = Path.GetExtension(keyStoreName);
            if (sfx == ".keystore") return true;
            if (sfx == ".jks") return true;
            return false;
        }

        /// <summary>
        /// 检查密匙设置有效性
        /// </summary>
        /// <returns></returns>
        public bool CheckKeyStore()
        {
            if (!CheckeyStoreName()) return false;
            if (string.IsNullOrEmpty(keyStorePass)) return false;
            if (string.IsNullOrEmpty(keyStorePass2)) return false;
            if (string.IsNullOrEmpty(keyaliasPass)) return false;
            if (string.IsNullOrEmpty(keyaliasPass2)) return false;
            if (keyStorePass != keyStorePass2) return false;
            if (keyaliasPass != keyaliasPass2) return false;
            return true;
        }
        /// <summary>
        /// 绘制UI
        /// </summary>
        /// <param name="obj"></param>
        public void OnGUI(Object obj)
        {
            DrawKeyStore(obj);
        }

        /// <summary>
        /// 应用设置
        /// </summary>
        public void Apply()
        {
            if (!use) return;
            //ApplyKeyStore();
        }
        #endregion
    }
}