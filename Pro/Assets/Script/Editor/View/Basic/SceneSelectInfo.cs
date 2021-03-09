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
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        613b594c-94af-4943-9c65-c9e30480fd36
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/6/13 19:31:25
    /// BG:选择场景信息
    /// </summary>
    [Serializable]
    public class SceneSelectInfo : SelectInfo
    {
        #region 字段
        [SerializeField]
        private uint id = 0;

        [SerializeField]
        private string name = "";

        [SerializeField]
        private string resName = "";
        #endregion

        #region 属性
        /// <summary>
        /// 场景ID
        /// </summary>
        public uint ID
        {
            get { return id; }
            set { id = value; }
        }

        /// <summary>
        /// 场景名称
        /// </summary>
        public string Name
        {
            get { return name; }
            set { name = value; }
        }

        /// <summary>
        /// 资源名称
        /// </summary>
        public string ResName
        {
            get { return resName; }
            set { resName = value; }
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
            EditorGUILayout.LabelField(Name);
            EditorGUILayout.LabelField(ResName);
        }
        #endregion
    }
}