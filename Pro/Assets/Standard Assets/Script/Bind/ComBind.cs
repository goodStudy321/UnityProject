using System;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Loong
{
    /*public delegate void ComActive(string name);*/

    /*
     * CO:            
     * Copyright:   2018-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        af910a4c-d5a4-43b6-8d24-fd05cc42da4e
    */

    /// <summary>
    /// AU:Loong
    /// TM:2018/2/4 17:34:36
    /// BG:局部组件绑定/通过键值确定游戏对象
    /// </summary>
    [AddComponentMenu("Loong/局部组件绑定")]
    public class ComBind : MonoBehaviour
    {
        #region 字段
        [SerializeField]
        [HideInInspector]
        private string key = "";
        #endregion

        #region 属性
        /// <summary>
        /// 键值
        /// </summary>
        public string Key
        {
            get { return key; }
        }
        #endregion

        #region 委托事件
        /*public static event ComActive enable = null;

        public static event ComActive disable = null;*/
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        /*/// <summary>
        /// 激活
        /// </summary>
        private void OnEnable()
        {
            if (string.IsNullOrEmpty(key)) return;
            if (enable == null) return;
            enable(key);
        }

        /// <summary>
        /// 隐藏
        /// </summary>
        private void OnDisable()
        {
            if (string.IsNullOrEmpty(key)) return;
            if (disable == null) return;
            disable(key);
        }*/
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        #endregion

#if UNITY_EDITOR
        /// <summary>
        /// 监视UI
        /// </summary>
        public void OnInspGUI()
        {
            EditorGUILayout.BeginVertical("groupBox");
            key = EditorGUILayout.TextField("键值:", key);
            if (string.IsNullOrEmpty(key))
            {
                EditorGUILayout.HelpBox("键值不能为空", MessageType.Error);
            }
            else
            {
                EditorGUILayout.HelpBox("确保键值是唯一的", MessageType.Info);
            }

            EditorGUILayout.EndVertical();
        }
#endif
    }
}