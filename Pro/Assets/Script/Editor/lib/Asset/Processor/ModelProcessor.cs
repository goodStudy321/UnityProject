using System;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2015.4.27
    /// BG:模型处理器
    /// </summary>
    public static class ModelProcessor
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 模型导入之前
        /// </summary>
        /// <param name="assetImporter">模型导入者</param>
        /// <param name="assetPath">模型路径</param>
        /// <param name="data">模型处理数据</param>
        public static void OnPre(AssetImporter assetImporter, string assetPath, ModelProcessorData data)
        {
            ModelImporter import = assetImporter as ModelImporter;
            import.importMaterials = data.ImportMat;
        }

        /// <summary>
        /// 模型导入之后
        /// </summary>
        /// <param name="assetImporter">模型导入者</param>
        /// <param name="assetPath">模型路径</param>
        /// <param name="model">模型</param>
        /// <param name="data">模型处理数据</param>
        public static void OnPost(AssetImporter assetImporter, string assetPath, GameObject model, ModelProcessorData data)
        {
            ModUtil.RemoveDefaultMat(model);
        }
        #endregion
    }
}