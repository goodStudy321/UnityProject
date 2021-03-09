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
     * GUID:        a4b45fbf-07ae-48b1-82fc-5ab1f953df9c
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/6/5 19:33:29
    /// BG:场景触发器选择信息
    /// </summary>
    [Serializable]
    public class SceneTriggerSelectInfo : SelectInfo
    {
        #region 字段
        [SerializeField]
        private uint id = 0;

        [SerializeField]
        private string triggerName = "";
        #endregion

        #region 属性

        /// <summary>
        /// ID
        /// </summary>
        public uint ID
        {
            get { return id; }
            set { id = value; }
        }

        /// <summary>
        /// 流程数名称
        /// </summary>
        public string TriggerName
        {
            get { return triggerName; }
            set { triggerName = value; }
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
            EditorGUILayout.LabelField(TriggerName);
        }
        #endregion
    }
}