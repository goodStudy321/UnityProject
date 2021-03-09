//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/8/9 19:57:41
//=============================================================================

using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

using UIOPT = UnityEngine.GUILayoutOption;

namespace Loong.Game
{
    /// <summary>
    /// GUIBase
    /// </summary>
    public class GUIBase
    {
        #region 字段

        private bool enable = false;

        protected GUISkin skin = null;

        private Vector2 scroll = Vector3.zero;

        protected GUIStyleData btnData = new GUIStyleData();

        protected GUIStyleData lblData = new GUIStyleData();

        protected GUIStyleData textData = new GUIStyleData();

        protected GUILayoutOption[] btnOpts = new GUILayoutOption[2];

        private UIOPT[] scrollOpts = new UIOPT[] { GUILayout.Width(Screen.width) };

        #endregion

        #region 属性

        /// <summary>
        /// true:激活
        /// </summary>
        public bool Enable
        {
            get { return enable; }
            set
            {
                enable = value;
                if (value)
                {
                    OnEnable();
                    GUIMgr.HandlerOpen(this);
                }
                else
                {
                    OnDisable();
                    GUIMgr.HandlerClose(this);
                }
            }
        }

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法


        #endregion

        #region 保护方法

        protected void SetStyle(GUIStyle style, GUIStyleData data, int fontSize, Color normColor, FontStyle fs = FontStyle.Normal, TextAnchor anchor = TextAnchor.MiddleCenter)
        {

            data.fontSize = style.fontSize;
            style.fontSize = fontSize;

            data.normColor = normColor;
            style.normal.textColor = normColor;

            data.fontStyle = style.fontStyle;
            style.fontStyle = fs;

            data.anchor = style.alignment;
            style.alignment = anchor;
        }

        protected void SetStyle(GUIStyle style, GUIStyleData data)
        {
            style.fontSize = data.fontSize;
            style.fontStyle = data.fontStyle;
            style.alignment = data.anchor;
        }



        protected virtual void OnEnable()
        {

        }

        protected virtual void OnDisable()
        {

        }

        protected virtual void OnGUISelf()
        {

        }


        protected virtual void BegGUI()
        {
            skin = GUI.skin;
            SetLblData();
            SetBtnData();
            SetTextData();
        }

        protected virtual void EndGUI()
        {
            SetStyle(skin.label, lblData);
            SetStyle(skin.button, btnData);
            SetStyle(skin.textField, textData);

        }

        protected virtual void SetLblData()
        {
            SetStyle(skin.label, lblData, 30, Color.black);
        }

        protected virtual void SetBtnData()
        {
            SetStyle(skin.button, btnData, 30, Color.black);
        }

        protected virtual void SetTextData()
        {
            SetStyle(skin.textField, textData, 30, Color.black);
        }

        protected virtual bool Btn(string name)
        {
            return GUILayout.Button(name, btnOpts);
        }

        #endregion

        #region 公开方法


        public virtual void Init()
        {
            btnOpts[0] = GUILayout.Width(Screen.width);
            btnOpts[1] = GUILayout.Height(Screen.height * 0.5f);
        }


        public void OnGUI()
        {
            if (!enable) return;
            BegGUI();
            scroll = GUILayout.BeginScrollView(scroll, scrollOpts);
            OnGUISelf();
            GUILayout.FlexibleSpace();
            GUILayout.EndScrollView();
            EndGUI();
        }

        #endregion
    }
}