using System;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.8.28
    /// BG:选择资源信息
    /// </summary>
    [Serializable]
    public class SelectAssetInfo : SelectInfo
    {
        #region 字段
        [SerializeField]
        private Object asset = null;

        #endregion

        #region 属性

        /// <summary>
        /// 资源
        /// </summary>
        public Object Asset
        {
            get { return asset; }
            set { asset = value; }
        }
        #endregion

        #region 构造方法
        public SelectAssetInfo()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public override void OnGUI(Object obj)
        {
            EditorGUILayout.LabelField(asset.name);
        }
        #endregion
    }
}