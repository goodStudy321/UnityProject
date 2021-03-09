using System;
using Loong.Game;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        40335c44-f20c-433a-a854-d3b3caaed140
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/7/13 22:17:11
    /// BG:Mono测试基类监视
    /// </summary>
    [CustomEditor(typeof(TestMonoBase))]
    public class TestMonoBaseInspector : Editor
    {
        #region 字段
        private TestMonoBase mono = null;
        #endregion

        #region 属性

        #endregion

        #region 委托事件

        #endregion

        #region 构造方法
        public TestMonoBaseInspector()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        protected void OnEnable()
        {
            mono = target as TestMonoBase;
        }

        protected void OnSceneGUI()
        {
            mono.OnSceneGUI();
        }
        #endregion

        #region 公开方法
        public override void OnInspectorGUI()
        {
            mono.OnInspectorGUI();
        }
        #endregion
    }
}