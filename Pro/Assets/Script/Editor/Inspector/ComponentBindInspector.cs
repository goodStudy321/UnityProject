using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;
using Loong.Game;

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.10.27
    /// BG:
    /// </summary>
    [CustomEditor(typeof(ComponentBind))]
    public class ComponentBindInspector : Editor
    {
        #region 字段
        private ComponentBind bind = null;
        #endregion

        #region 属性

        #endregion

        #region 私有方法
        private void OnEnable()
        {
            bind = target as ComponentBind;
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