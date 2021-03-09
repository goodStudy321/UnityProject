using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using System.Text;
using UnityEditor;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Edit
{


    /// <summary>
    /// AU:Loong
    /// TM:2015.4.27
    /// BG:资源处理器
    /// </summary>
    public sealed class AssetProcessor : AssetPostprocessor
    {

        #region 字段
        private static AssetProcessorView view;

        /// <summary>
        /// 资源处理器菜单前缀
        /// </summary>
        public const string menu = MenuTool.Loong + "资源处理器/";

        /// <summary>
        /// 资源处理器资源下菜单前缀
        /// </summary>
        public const string AMenu = MenuTool.ALoong + "资源处理器/";

        /// <summary>
        /// AssetBundle 无标点后缀名
        /// </summary>
        public static readonly string variant = Suffix.AB.Replace(".", string.Empty);

        #endregion

        #region 属性
        /// <summary>
        /// 嗅探配置视图数据
        /// </summary>
        public static AssetProcessorView View
        {
            get
            {
                if (view == null)
                {
                    view = AssetDataUtil.Get<AssetProcessorView>();
                }
                return view;
            }
        }
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        /// <summary>
        /// 检查是否可以对资源进行嗅探处理
        /// </summary>
        /// <param name="data">资源处理</param>
        /// <param name="assetPath">资源路径</param>
        /// <returns></returns>
        private bool CheckProcessValid(ProcessorDataBase data, string assetPath)
        {
            if (!View.Use) return false;
            if (!data.Use) return false;
            if (data.Global) return true;
            if (assetPath.StartsWith(EditSceneView.prefix)) return true;
            return false;
        }
        #region 音频设置

        /// <summary>
        /// 音频导入 之前
        /// </summary>
        private void OnPreprocessAudio()
        {
            if (CheckProcessValid(View.AudioData, assetPath))
            {
                AudioProcessor.OnPre(assetImporter, assetPath, View.AudioData);
            }
        }
        /// <summary>
        /// 音频导入 之后
        /// </summary>
        /// <param name="audio"></param>
        private void OnPostprocessAudio(AudioClip audio)
        {
            if (CheckProcessValid(View.AudioData, assetPath))
            {
                AudioProcessor.OnPost(assetImporter, assetPath, audio, View.AudioData);
            }
        }

        #endregion

        #region 贴图设置

        /// <summary>
        /// 图片导入 之前
        /// </summary>
        private void OnPreprocessTexture()
        {
            if (CheckProcessValid(View.TextureData, assetPath))
            {
                TextureProcessor.OnPre(assetImporter, assetPath, View.TextureData);
            }
        }

        /// <summary>
        /// 图片导入 之后
        /// </summary>
        /// <param name="texture"></param>
        private void OnPostprocessTexture(Texture2D texture)
        {
            if (CheckProcessValid(View.TextureData, assetPath))
            {
                TextureProcessor.OnPost(assetImporter, assetPath, texture, View.TextureData);
            }
        }


        #endregion

        #region 模型设置

        /// <summary>
        /// 模型导入 之前
        /// </summary>
        private void OnPreprocessModel()
        {
            if (CheckProcessValid(View.ModelData, assetPath))
            {
                ModelProcessor.OnPre(assetImporter, assetPath, View.ModelData);
            }
        }
        /// <summary>
        /// 模型导入之后
        /// </summary>
        /// <param name="model"></param>
        private void OnPostprocessModel(GameObject model)
        {
            //if (CheckProcessValid(View.ModelData, assetPath))
            {
                ModelProcessor.OnPost(assetImporter, assetPath, model, View.ModelData);
            }
        }

        /// <summary>
        /// AssetBundle名称发生改变
        /// </summary>
        /// <param name="assetPath">资源路径</param>
        /// <param name="oldName">旧名称</param>
        /// <param name="newName">新名称</param>
        private void OnPostprocessAssetbundleNameChanged(string assetPath, string oldName, string newName)
        {
            ABNameChanged.Change(assetPath, oldName, newName);
        }
        #endregion

        #region 所有资源操作处理
        /// <summary>
        /// 所有资源导入 之后
        /// </summary>
        /// <param name="imports">导入的资源</param>
        /// <param name="deletes">删除的资源</param>
        /// <param name="moveTos">移动的资源,移动后的位置</param>
        /// <param name="moveFroms">移动的资源,移动前的位置</param>
        private static void OnPostprocessAllAssets(string[] imports, string[] deletes, string[] moveTos, string[] moveFroms)
        {
            CategoryProcessorAllAssets.Execute(imports, deletes, moveTos, moveFroms);
            AssetUtil.IsValidName(imports);
            AssetUtil.IsValidName(moveTos);

        }

        #endregion

        #region 材质操作处理
        /*/// <summary>
        /// 分配材质给模型
        /// </summary>
        private Material OnAssignMaterialModel(Material mat, Renderer render)
        {
            if (!View.Use) return null;
            iTrace.Log("Loong", string.Format("物体:{0},渲染组件{1},材质{2}", render.gameObject.name, render.name, mat.name));
            return null;
        }*/

        #endregion
        #endregion

        #region 保护方法
        #endregion

        #region 公开方法

        /// <summary>
        /// 根据路径获取后缀名检查是否需要处理
        /// </summary>
        public static bool CheckPath(string assetPath)
        {
            string suffix = Suffix.Get(assetPath);
            return CheckSuffix(suffix);
        }

        /// <summary>
        /// 根据后缀名检查是否需要处理
        /// </summary>
        public static bool CheckSuffix(string suffix)
        {
            if (!AssetUtil.IsValidSfx(suffix)) return false;
            if (View.Dic.ContainsKey(suffix)) return View.Dic[suffix];
            iTrace.Warning("Loong", string.Format("后缀:{0}没有添加到处理列表中", suffix));
            return false;

        }

        /// <summary>
        /// 删除AB文件和对应的清单文件
        /// </summary>
        /// <param name="outFolder">AB目录</param>
        /// <param name="fileName">文件名称</param>
        public static void Delete(string outFolder, string fileName)
        {
            string filePath = string.Format("{0}/{1}{2}", outFolder, fileName, Suffix.AB);
            string maniFestPath = string.Format("{0}.manifest", filePath);
            if (File.Exists(filePath)) File.Delete(filePath);
            if (File.Exists(maniFestPath)) File.Delete(maniFestPath);
            //iTrace.Log("Loong", string.Format("删除:filePath:{0},maniFestPath:{1}", filePath, maniFestPath));
        }

        /// <summary>
        /// 删除AB文件和对应的清单文件/自动查找AB目录
        /// </summary>
        /// <param name="fileName"></param>
        public static void Delete(string fileName)
        {
            string outfolder = EditUtil.GetPlatform();
            outfolder = string.Format("{0}/{1}", ABTool.Data.Output, outfolder);
            Delete(outfolder, fileName);
        }

        /// <summary>
        /// 删除AB文件和对应的清单文件
        /// </summary>
        /// <param name="assetPath">资源路径</param>
        public static void DeletePath(string assetPath)
        {
            string fileName = Path.GetFileName(assetPath);
            Delete(fileName);
        }
        #endregion

    }
}