using System;
using System.IO;
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
    /// BG:图片处理器
    /// </summary>
    public static class TextureProcessor
    {
        #region 字段
        /// <summary>
        /// 菜单优先级
        /// </summary>
        public const int Pri = MenuTool.AssetPri + 8;

        /// <summary>
        /// 菜单
        /// </summary>
        public const string menu = AssetProcessor.menu + "图片/";

        /// <summary>
        /// 资源下菜单
        /// </summary>
        public const string AMenu = AssetProcessor.AMenu + "图片/";
        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        /// <summary>
        /// 光照贴图设置
        /// </summary>
        private static void SetLightMap(AssetImporter assetImporter, string sfx, Texture2D tex)
        {
            TextureImporter textureImporter = assetImporter as TextureImporter;
            textureImporter.textureType = TextureImporterType.Lightmap;
            textureImporter.textureCompression = TextureImporterCompression.CompressedHQ;
            textureImporter.maxTextureSize = GetMaxSize(tex);
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 图片导入之前
        /// </summary>
        /// <param name="assetImporter">图片导入者</param>
        /// <param name="assetPath">图片导入路径</param>
        /// <param name="data">图片处理数据</param>
        public static void OnPre(AssetImporter assetImporter, string assetPath, TextureProcessorData data)
        {

        }

        /// <summary>
        /// 图片导入之后
        /// </summary>
        /// <param name="assetImporter">图片导入者</param>
        /// <param name="assetPath">图片导入路径</param>
        /// <param name="tex">导入的图片文件</param>
        /// <param name="data">图片处理数据</param>
        public static void OnPost(AssetImporter assetImporter, string assetPath, Texture2D tex, TextureProcessorData data)
        {
            string sfx = Suffix.Get(assetPath);
            if (sfx == Suffix.Exr) SetLightMap(assetImporter, sfx, tex);
            else Set(assetImporter, sfx, tex, TextureWrapMode.Clamp, FilterMode.Point);
        }

        /// <summary>
        /// 获取安卓平台图片格式设置
        /// </summary>
        /// <param name="sfx">后缀</param>
        /// <param name="trueColor">true:真彩色</param>
        /// <returns></returns>
        public static TextureImporterFormat GetAndroidFormat(string sfx, bool trueColor = false)
        {
            if (trueColor) return TextureImporterFormat.RGBA32;
            if (sfx == Suffix.Png) return TextureImporterFormat.ETC2_RGBA8;
            else if (sfx == Suffix.Tga) return TextureImporterFormat.ETC2_RGBA8;
            return TextureImporterFormat.ETC2_RGB4;
        }

        /// <summary>
        /// 获取iPhone平台图片格式设置
        /// </summary>
        /// <param name="sfx">后缀</param>
        /// <param name="trueColor">true:真彩色</param>
        /// <returns></returns>
        public static TextureImporterFormat GetIphoneFormat(string sfx, bool trueColor = false)
        {
            if (trueColor) return TextureImporterFormat.RGBA32;
            if (sfx == Suffix.Png) return TextureImporterFormat.PVRTC_RGBA4;
            else if (sfx == Suffix.Tga) return TextureImporterFormat.PVRTC_RGBA4;
            return TextureImporterFormat.PVRTC_RGB4;
        }

        /// <summary>
        /// 获取默认平台图片格式设置
        /// </summary>
        /// <param name="sfx">后缀</param>
        /// <param name="ui">true:真彩色</param>
        /// <returns></returns>
        public static TextureImporterFormat GetDefaultFormat(string sfx, bool ui = false)
        {
            if (ui) return TextureImporterFormat.RGBA32;
            if (sfx == Suffix.Png) return TextureImporterFormat.DXT5;
            else if (sfx == Suffix.Tga) return TextureImporterFormat.DXT5;
            return TextureImporterFormat.DXT1;
        }

        /// <summary>
        /// 获取平台的格式
        /// </summary>
        /// <param name="platform">平台字符</param>
        /// <param name="sfx">后缀</param>
        /// <param name="trueColor">true:真彩色</param>
        /// <returns></returns>
        public static TextureImporterFormat GetPlatformFormat(string platform, string sfx, bool trueColor = false)
        {
            var format = TextureImporterFormat.Automatic;
            switch (platform)
            {
                case "iPhone": format = GetIphoneFormat(sfx, trueColor); break;
                case "Android": format = GetAndroidFormat(sfx, trueColor); break;
                case "Standalone": format = GetDefaultFormat(sfx, trueColor); break;
                default:
                    break;
            }
            return format;
        }
        /// <summary>
        /// 获取图片2的n次方最近似的值
        /// </summary>
        public static int GetMaxSize(Texture2D texture)
        {
            int width = texture.width > texture.height ? texture.width : texture.height;
            return GetMaxSize(width);
        }

        public static int GetMaxSize(float size)
        {
            var width = (int)size;
            return GetMaxSize(width);
        }

        public static int GetMaxSize(int width)
        {
            if (!Mathf.IsPowerOfTwo(width)) width = Mathf.ClosestPowerOfTwo(width);
            return width;
        }

        /// <summary>
        /// 检查是否需要设置图片大小为2的n次方
        /// </summary>
        /// <param name="texture">图片</param>
        /// <returns></returns>
        public static bool CheckNeedNonPower(Texture2D texture)
        {
            if (!Mathf.IsPowerOfTwo(texture.width)) return true;
            if (!Mathf.IsPowerOfTwo(texture.height)) return true;
            return false;
        }

        /// <summary>
        /// 通用图片设置
        /// </summary>
        /// <param name="assetImporter">导入器</param>
        /// <param name="sfx">后缀</param>
        /// <param name="tex">图片</param>
        /// <param name="wrap">循环模式</param>
        /// <param name="filter">三位变换处理模式</param>
        /// <param name="trueColor">true:真彩色</param>
        /// <param name="type">导入类型</param>
        public static void Set(AssetImporter assetImporter, string sfx, Texture2D tex, TextureWrapMode wrap, FilterMode filter, bool trueColor = false, TextureImporterType type = TextureImporterType.Default)
        {
            var texImporter = assetImporter as TextureImporter;
            texImporter.ClearPlatformTextureSettings("Android");
            texImporter.ClearPlatformTextureSettings("iPhone");
            //texImporter.ClearPlatformTextureSettings("PC");
            texImporter.SaveAndReimport();

            texImporter.textureType = TextureImporterType.Default;
            if (CheckNeedNonPower(tex)) texImporter.npotScale = TextureImporterNPOTScale.ToNearest;
            //texImporter.alphaIsTransparency = (sfx == Suffix.Png) ? true : false;
            texImporter.isReadable = false;
            texImporter.mipmapEnabled = false;
            texImporter.wrapMode = TextureWrapMode.Clamp;
            texImporter.filterMode = filter;
            texImporter.anisoLevel = 1;
            int width = GetMaxSize(tex);
            texImporter.maxTextureSize = width;
            SetPlatformSetting(texImporter, sfx, "Android", width, trueColor);
            SetPlatformSetting(texImporter, sfx, "iPhone", width, trueColor);
            texImporter.SaveAndReimport();
        }

        /// <summary>
        /// 平台设置
        /// </summary>
        /// <param name="textureImporter">图片导入者</param>
        /// <param name="suffix">后缀</param>
        /// <param name="platform">平台</param>
        /// <param name="width">宽度</param>
        /// <param name="trueColor">true:真彩色</param>
        public static void SetPlatformSetting(TextureImporter textureImporter, string suffix, string platform, int width, bool trueColor = false)
        {
            var settings = new TextureImporterPlatformSettings();
            settings.name = platform;
            settings.format = GetPlatformFormat(platform, suffix, trueColor);
            settings.maxTextureSize = width;
            settings.overridden = true;
            textureImporter.SetPlatformTextureSettings(settings);
        }


        /// <summary>
        /// 设置贴图
        /// </summary>
        /// <param name="wrap">循环模式</param>
        /// <param name="filter">三位变换处理模式</param>
        /// <param name="trueColor">true:真彩色</param>
        /// <param name="type">图片使用类型</param>
        public static void Set(TextureWrapMode wrap, FilterMode filter, bool trueColor = false, TextureImporterType type = TextureImporterType.Default)
        {
            Object[] objs = Selection.GetFiltered(typeof(Texture2D), SelectionMode.DeepAssets);
            if (objs == null || objs.Length == 0)
            {
                UIEditTip.Error("没有选择任何图片"); return;
            }
            float length = objs.Length;
            for (int i = 0; i < length; i++)
            {
                ProgressBarUtil.Show("", "正在玩命设置中······", i / length);
                Object obj = objs[i];
                string path = AssetDatabase.GetAssetPath(obj);
                Texture2D tex = obj as Texture2D;
                AssetImporter importer = AssetImporter.GetAtPath(path);
                Set(importer, Suffix.Get(path), tex, wrap, filter, trueColor, type);
            }
            ProgressBarUtil.Clear();
            EditUtil.SaveAssets(false);
            UIEditTip.Log("总共设置了{0}张贴图", length);
        }

        /// <summary>
        /// 设置UI图片
        /// </summary>
        [MenuItem(menu + "设置UI", false, Pri)]
        [MenuItem(AMenu + "设置UI", false, Pri)]
        public static void SetUI()
        {
            Set(TextureWrapMode.Clamp, FilterMode.Bilinear, true);
        }

        /// <summary>
        /// 设置对应平台格式图标
        /// </summary>
        [MenuItem(menu + "设置对应平台格式图标", false, Pri + 1)]
        [MenuItem(AMenu + "设置对应平台格式图标", false, Pri + 1)]
        public static void SetCompressIcon()
        {
            Set(TextureWrapMode.Clamp, FilterMode.Bilinear, false);
        }

        /// <summary>
        /// 设置对应平台真彩色图标
        /// </summary>
        [MenuItem(menu + "设置对应平台真彩色图标", false, Pri + 2)]
        [MenuItem(AMenu + "设置对应平台真彩色图标", false, Pri + 2)]
        public static void SetTrueColorIcon()
        {
            Set(TextureWrapMode.Clamp, FilterMode.Bilinear, true);
        }

        /// <summary>
        /// 设置对应平台格式图标
        /// </summary>
        [MenuItem(menu + "设置对应平台格式图标(GUI,非2N次方)", false, Pri + 3)]
        [MenuItem(AMenu + "设置对应平台格式图标(GUI,非2N次方)", false, Pri + 3)]
        public static void SetCompressGUIIcon()
        {
            Set(TextureWrapMode.Clamp, FilterMode.Bilinear, false, TextureImporterType.GUI);
        }

        /// <summary>
        /// 设置对应平台真彩色图标
        /// </summary>
        [MenuItem(menu + "设置对应平台真彩色图标(GUI,非2N次方)", false, Pri + 4)]
        [MenuItem(AMenu + "设置对应平台真彩色图标(GUI,非2N次方)", false, Pri + 5)]
        public static void SetTrueColorGUIIcon()
        {
            Set(TextureWrapMode.Clamp, FilterMode.Bilinear, true, TextureImporterType.GUI);
        }


        /// <summary>
        /// 设置对应平台格式图片
        /// </summary>
        [MenuItem(menu + "设置对应平台格式图片", false, Pri + 6)]
        [MenuItem(AMenu + "设置对应平台格式图片", false, Pri + 6)]
        public static void SetCompressTex()
        {
            Set(TextureWrapMode.Repeat, FilterMode.Bilinear);
        }

        /// <summary>
        /// 设置对应平台真彩色图片
        /// </summary>
        [MenuItem(menu + "设置对应平台真彩色图片", false, Pri + 7)]
        [MenuItem(AMenu + "设置对应平台真彩色图片", false, Pri + 7)]
        public static void SetTrueColorTex()
        {
            Set(TextureWrapMode.Repeat, FilterMode.Bilinear, true);
        }
        #endregion
    }
}