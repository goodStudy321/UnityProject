using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using UIOPT = UnityEngine.GUILayoutOption;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        6c5f44ac-41b5-4d48-8df2-62bb4ffa85d9
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/6/15 19:31:35
    /// BG:Mono测试基类
    /// </summary>
    public class TestMonoBase : MonoBehaviour
    {
        #region 字段
        private int lblSize = 0;

        private int btnSize = 0;

        private int textSize = 0;

        private Vector2 scroll = Vector3.zero;

        /// <summary>
        /// 滚动视图选项
        /// </summary>
        private UIOPT[] scrollOpts = new UIOPT[] { GUILayout.Width(Screen.width) };

        /// <summary>
        /// 按钮排版选项
        /// </summary>
        protected UIOPT[] btnOpts = new UIOPT[] { GUILayout.Height(60) };

        /// <summary>
        /// 标签排版选项
        /// </summary>
        protected UIOPT[] lblOpts = new UIOPT[] { GUILayout.Height(40) };

        /// <summary>
        /// 文本排版选项
        /// </summary>
        protected UIOPT[] textOpts = new UIOPT[] { GUILayout.Height(80) };

        #endregion

        #region 属性

        #endregion

        #region 构造方法
        public TestMonoBase()
        {

        }
        #endregion

        #region 私有方法
        private void OnGUI()
        {
            lblSize = GUI.skin.label.fontSize;
            btnSize = GUI.skin.button.fontSize;
            textSize = GUI.skin.textField.fontSize;
            GUI.skin.button.fontSize = 25;
            GUI.skin.label.fontSize = 30;
            GUI.skin.textField.fontSize = 40;
            scroll = GUILayout.BeginScrollView(scroll, scrollOpts);
            OnGUICustom();
            GUILayout.FlexibleSpace();
            GUILayout.EndScrollView();
            GUI.skin.label.fontSize = lblSize;
            GUI.skin.button.fontSize = btnSize;
            GUI.skin.textField.fontSize = textSize;
        }
        #endregion

        #region 保护方法
        protected virtual void OnGUICustom()
        {

        }
        #endregion

        #region 公开方法

        #endregion

#if UNITY_EDITOR
        public virtual void OnSceneGUI()
        {

        }

        /// <summary>
        /// 绘制监视面板
        /// </summary>
        public virtual void OnInspectorGUI()
        {

        }
#endif
    }
}