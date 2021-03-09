using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        9dea4dd0-ad82-482d-9f16-f87571f06a0e
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/3/13 10:35:21
    /// BG:网格工具
    /// </summary>
    public static class MeshTool
    {
        #region 字段
        private static Dictionary<string, Material> dic = new Dictionary<string, Material>();
        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        /// <summary>
        /// 获取批处理材质球
        /// </summary>
        /// <param name="mat">材质球</param>
        private static Material GetBatch(Material mat)
        {
            if (mat == null) return null;
            string matName = mat.name.Replace("(Instance)", "Batch");
            Material newMat = null;
            if (dic.ContainsKey(matName))
            {
                newMat = dic[matName];
            }
            else
            {
                newMat = new Material(mat.shader);
                newMat.CopyPropertiesFromMaterial(mat);
                newMat.enableInstancing = false;
                newMat.name = matName;
                dic.Add(matName, newMat);
            }
            return newMat;
        }

        /// <summary>
        /// 设置批处理渲染组件
        /// </summary>
        /// <param name="render">渲染组件</param>
        private static void SetBatch(Renderer render)
        {
            if (render == null) return;
            int length = render.materials.Length;
            for (int i = 0; i < length; i++)
            {
                Material mat = render.materials[i];
                Material newMat = GetBatch(mat);

                render.materials[i] = newMat;
                render.sharedMaterials[i] = newMat;
            }

            Material mat1 = GetBatch(render.material);
            render.material = render.sharedMaterial = mat1;
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 合并静态物体的网格/如果渲染组件上包含光照贴图的索引,则强制设为静态
        /// </summary>
        /// <param name="go"></param>
        public static void Combine(GameObject go)
        {
            if (go == null) return;
            Renderer[] renderers = go.GetComponentsInChildren<Renderer>();
            if (renderers == null) return;
            int length = renderers.Length;
            for (int i = 0; i < length; i++)
            {
                Renderer render = renderers[i];
                if (render.lightmapIndex != -1) render.gameObject.isStatic = true;
                if (!render.gameObject.isStatic) continue;
                SetBatch(render);
            }
            StaticBatchingUtility.Combine(go);
        }

        /// <summary>
        /// 释放
        /// </summary>
        public static void Dispose()
        {
            dic.Clear();
        }
    }
    #endregion
}