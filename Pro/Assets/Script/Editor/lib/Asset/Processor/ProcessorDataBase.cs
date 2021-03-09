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
    /// TM:2015.4.27
    /// BG:处理数据
    /// </summary>
    [Serializable]
    public class ProcessorDataBase
    {
        #region 字段

        [HideInInspector]
        [SerializeField]
        private bool use = false;

        [HideInInspector]
        [SerializeField]
        private bool global = false;
        #endregion

        #region 属性

        /// <summary>
        /// 使用设置
        /// </summary>
        public bool Use
        {
            get { return use; }
            set { use = value; }
        }

        /// <summary>
        /// true:全局有效,false:仅对Assets/Scene/下有效
        /// </summary>
        public bool Global
        {
            get { return global; }
            set { global = value; }
        }
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        /// <summary>
        /// 绘制基础属性
        /// </summary>
        /// <param name="obj"></param>
        protected void DrawBasic(Object obj)
        {
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.Toggle("启用处理:", ref use, obj);
            EditorGUILayout.Space();
            UIEditLayout.Toggle("全局有效:", ref global, obj);
            if (global)
            {
                UIEditLayout.HelpInfo("对所有资源都检查处理");
            }
            else
            {
                UIEditLayout.HelpInfo("仅对Assets/Scene目录下资源检查处理");
            }
            EditorGUILayout.EndVertical();
        }
        #endregion

        #region 公开方法
        /// <summary>
        /// 绘制UI
        /// </summary>
        /// <param name="obj">所在对象</param>
        public virtual void OnGUI(Object obj)
        {

        }
        #endregion
    }
}