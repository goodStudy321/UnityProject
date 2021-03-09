//=============================================================================
// Copyright (C) 2019, 金七情(Loong) jinqiqing@qq.com
// Created by Loong on 2019/7/29 19:31:33
//=============================================================================

using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// GuideView
    /// </summary>
    public class GuideView : EditViewBase
    {
        #region 字段
        public int id;
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void Trigger()
        {
            if (EditorApplication.isPlaying)
            {
                EventMgr.Trigger("E_GUIDE_TRIGGER", id);
                UIEditTip.Log("已触发ID为:{0}的引导", id);
            }
            else
            {
                UIEditTip.Error("运行时才能触发!");
            }
        }
        #endregion

        #region 保护方法

        protected override void Title()
        {
            BegTitle();
            if (TitleBtn("触发"))
            {
                DialogUtil.Show("", string.Format("触发ID为:{0}的引导?", id), Trigger);
            }
            EndTitle();
        }

        protected override void OnGUICustom()
        {
            EditorGUILayout.BeginVertical(StyleTool.Box);
            UIEditLayout.IntField("引导ID:", ref id, this);

            EditorGUILayout.EndVertical();
        }
        #endregion

        #region 公开方法

        #endregion
    }
}