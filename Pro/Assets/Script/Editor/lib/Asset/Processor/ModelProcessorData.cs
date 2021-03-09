using System;
using Loong.Game;
using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.4.27
    /// BG:模型处理数据
    /// </summary>
    [Serializable]
    public class ModelProcessorData : ProcessorDataBase
    {
        #region 字段
        [SerializeField]
        [HideInInspector]
        private bool importMat = false;

        #endregion

        #region 属性

        /// <summary>
        /// 导入材质球
        /// </summary>
        public bool ImportMat
        {
            get { return importMat; }
            set { importMat = value; }
        }

        #endregion

        #region 构造方法

        #endregion

        #region 属性

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 绘制UI
        /// </summary>
        /// <param name="obj">所在对象</param>
        public override void OnGUI(Object obj)
        {
            if (!UIEditTool.DrawHeader("模型处理数据", "modelProcessorData", StyleTool.Host)) return;
            DrawBasic(obj);
            EditorGUILayout.BeginVertical(StyleTool.Group);
            UIEditLayout.Toggle("导入材质球:", ref importMat, obj);
            EditorGUILayout.EndVertical();
        }
        #endregion
    }
}