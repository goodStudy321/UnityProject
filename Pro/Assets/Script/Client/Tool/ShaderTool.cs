using System;
using UnityEngine;
using System.Diagnostics;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.SceneManagement;
using Object = UnityEngine.Object;
using PigeonCoopToolkit.Effects.Trails;

namespace Loong.Game
{

    /// <summary>
    /// AU:Loong
    /// TM:2015.4.18
    /// BG:着色器工具
    /// </summary>
    public static class ShaderTool
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
        /// 重置材质球的Shader
        /// </summary>
        /// <param name="mat"></param>
        public static void ResetMat(Material mat)
        {
#if UNITY_EDITOR
            if (AssetMgr.Mode == LoadResMode.Asset) return;
#endif
            if (mat == null) return;
            int beforeRQ = mat.renderQueue;
            if (mat.shader == null) return;
            Shader shader = Shader.Find(mat.shader.name);
            if (shader == null) return;
            mat.shader = shader;
            if (beforeRQ > mat.renderQueue)
            {
                mat.renderQueue = beforeRQ;
            }
        }

        /// <summary>
        /// 编辑器下重置材质球的Shader
        /// </summary>
        /// <param name="mat"></param>
        [Conditional("UNITY_EDITOR")]
        public static void eResetMat(Material mat)
        {
            ResetMat(mat);
        }

        /// <summary>
        /// 重置材质球数组的Shader
        /// </summary>
        /// <param name="mats"></param>
        public static void ResetMats(Material[] mats)
        {
            if (mats == null) return;
            int length = mats.Length;
            for (int i = 0; i < length; i++)
            {
                ResetMat(mats[i]);
            }
        }

        /// <summary>
        /// 编辑器下重置材质球数组的Shader
        /// </summary>
        /// <param name="go">物体</param>
        [Conditional("UNITY_EDITOR")]
        public static void eResetMats(Material[] mats)
        {
            ResetMats(mats);
        }

        /// <summary>
        /// 重置物体的所有材质球的Shader
        /// </summary>
        /// <param name="go">物体</param>
        public static void ResetGbj(GameObject go)
        {
            if (go == null) return;
            Renderer[] renders = go.GetComponentsInChildren<Renderer>(true);
            if (renders != null && renders.Length > 0)
            {
                int length = renders.Length;
                for (int i = 0; i < length; i++)
                {
                    ResetMats(renders[i].sharedMaterials);
                }
            }

            //// LY add begin ////

            Trail[] trails = go.GetComponentsInChildren<Trail>(true);
            if(trails != null && trails.Length > 0)
            {
                for(int a = 0; a < trails.Length; a++)
                {
                    if(trails[a] != null)
                    {
                        ResetMat(trails[a].TrailData.TrailMaterial);
                    }
                }
            }

            //// LY add end ////
        }

        /// <summary>
        /// 编辑器下重置物体的所有材质球的Shader
        /// </summary>
        /// <param name="go">物体</param>
        [Conditional("UNITY_EDITOR")]
        public static void eResetGbj(GameObject go)
        {
            ResetGbj(go);
        }

        /// <summary>
        /// 重置天空盒材质球Shader
        /// </summary>
        public static void ResetSkybox()
        {
            ResetMat(RenderSettings.skybox);
        }

        /// <summary>
        /// 编辑器下重置天空盒材质球Shader
        /// </summary>
        [Conditional("UNITY_EDITOR")]
        public static void eResetSkybox()
        {
            ResetSkybox();
        }

        /// <summary>
        /// 重置场景中所有物体材质球的Shader
        /// </summary>
        /// <param name="scene">场景</param>
        public static void ResetScene(Scene scene)
        {
            if (!scene.isLoaded) return;
            ResetSkybox();
            GameObject[] gos = scene.GetRootGameObjects();
            if (gos == null) return;
            int length = gos.Length;
            for (int i = 0; i < length; i++)
            {
                ResetGbj(gos[i]);
            }
        }

        /// <summary>
        /// 编辑器下重置场景中所有物体材质球的Shader
        /// </summary>
        /// <param name="scene">场景</param>
        [Conditional("UNITY_EDITOR")]
        public static void eResetScene(Scene scene)
        {
            ResetScene(scene);
        }
        #endregion
    }
}