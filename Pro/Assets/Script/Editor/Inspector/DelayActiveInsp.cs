using System;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2018-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        6601e8f7-c246-469a-896d-3dd26459ca48
    */

    /// <summary>
    /// AU:Loong
    /// TM:2018/4/30 20:46:12
    /// BG:
    /// </summary>
    [CustomEditor(typeof(DelayActive))]
    public class DelayActiveInsp : Editor
    {
        #region 字段
        private DelayActive da = null;
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void OnEnable()
        {
            da = target as DelayActive;
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public override void OnInspectorGUI()
        {
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.FloatField("开始隐藏时间(秒):", ref da.begHiddenTime, da);
            UIEditLayout.Toggle("Active状态:", ref da.active, da);
            EditorGUILayout.EndVertical();
        }
        #endregion
    }
}