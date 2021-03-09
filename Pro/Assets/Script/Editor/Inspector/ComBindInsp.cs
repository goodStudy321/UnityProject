using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /*
     * CO:            
     * Copyright:   2018-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        f252bc07-d9ba-4c33-ab32-722727fb34bd
    */

    /// <summary>
    /// AU:Loong
    /// TM:2018/2/4 17:35:01
    /// BG:
    /// </summary>
    [CustomEditor(typeof(ComBind))]
    public class ComBindInsp : Editor
    {
        #region 字段
        private ComBind bind = null;
        #endregion

        #region 属性

        #endregion

        #region 私有方法
        private void OnEnable()
        {
            bind = target as ComBind;
        }
        #endregion

        #region 保护方法
        protected override void OnHeaderGUI()
        {
            EditorGUILayout.LabelField("组件绑定");
        }
        #endregion

        #region 公开方法
        public override void OnInspectorGUI()
        {
            bind.OnInspGUI();
        }
        #endregion
    }
}