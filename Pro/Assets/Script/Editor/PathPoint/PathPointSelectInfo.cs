using System;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        735b056f-3f70-4767-be0a-72062619e0d3
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/4/10 12:21:33
    /// BG:点选择信息
    /// </summary>
    [Serializable]
    public class PathPointSelectInfo : SelectInfo
    {
        #region 字段
        [SerializeField]
        private ushort id;
        #endregion

        #region 属性

        public ushort ID
        {
            get { return id; }
            set { id = value; }
        }

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public override void OnGUI(UnityEngine.Object obj)
        {
            EditorGUILayout.LabelField(ID.ToString());
        }
        #endregion
    }
}