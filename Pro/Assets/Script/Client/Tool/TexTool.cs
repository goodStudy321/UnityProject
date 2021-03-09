using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2013.7.8
    /// BG:图片工具
    /// </summary>
    public static class TexTool
    {
        #region 字段
        private static Texture2D black = null;


        private static Texture2D transparent = null;

        #endregion

        #region 属性
        /// <summary>
        /// 半透明的黑色图片
        /// </summary>
        public static Texture2D Transparent
        {
            get
            {
                if (transparent == null)
                {
                    transparent = Create(8, 8, new Color(0f, 0f, 0f, 0.5f));
                    transparent.name = "TexTool.transparent";
                }
                return transparent;
            }
        }

        /// <summary>
        /// 不透明黑色图片
        /// </summary>
        public static Texture2D Black
        {
            get
            {
                if (black == null)
                {
                    black = Create(8, 8, Color.black);
                    black.name = "TexTool.black";
                }
                return black;
            }
        }
        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 创建一个具有指定大小/色彩的图片
        /// </summary>
        public static Texture2D Create(int width, int height, Color color)
        {
            Texture2D tex = new Texture2D(width, height);
            for (int i = 0; i < width; i++)
            {
                for (int j = 0; j < height; j++)
                {
                    tex.SetPixel(i, j, color);
                }
            }
            tex.Apply();
            return tex;
        }

        /// <summary>
        /// 截图
        /// </summary>
        /// <param name="rect">位置和大小</param>
        /// <param name="callback">回调</param>
        /// <returns></returns>
        public static IEnumerator ScreenShot(Rect rect, Action<Texture2D> callback)
        {
            if (callback == null) yield break;
            yield return new WaitForEndOfFrame();
            int width = (int)rect.width;
            int height = (int)rect.height;
            TextureFormat format = TextureFormat.RGB24;
            Texture2D tex = new Texture2D(width, height, format, false);
            tex.ReadPixels(rect, 0, 0);
            tex.Apply();
            tex.name = "ScreenShot";
            callback(tex);
        }

        public static Texture2D GetScreenShotByCam(Camera renCam)
        {
            if (renCam == null)
            {
                return null;
            }

            int rttWidth = (int)(Screen.width * 0.8f);
            int rttHeight = (int)(Screen.height * 0.8f);

            RenderTexture rt = new RenderTexture(rttWidth, rttHeight, 100, RenderTextureFormat.ARGB32);
            rt.useMipMap = false;
            renCam.targetTexture = rt;
            renCam.Render();
            RenderTexture.active = rt;
            //Debug.Log(RenderTexture.active);
            TextureFormat format = TextureFormat.RGB24;
            Texture2D tex = new Texture2D(rttWidth, rttHeight, format, false);
            tex.name = "ScreenShot";
            tex.ReadPixels(new Rect(0, 0, rt.width, rt.height), 0, 0);
            tex.Apply();
            RenderTexture.active = null;
            renCam.targetTexture = null;
            GameObject.DestroyImmediate(rt);
            return tex;
        }

        //public static IEnumerator GetScreenShotByCam(Camera renCam, Action<Texture2D> callback)
        //{
        //    if (renCam == null || callback == null)
        //    {
        //        yield break;
        //    }

        //    int rttWidth = Screen.width;
        //    int rttHeight = Screen.height;
        //    RenderTexture rt = new RenderTexture(rttWidth, rttHeight, 100, RenderTextureFormat.ARGB32);
        //    rt.useMipMap = false;
        //    renCam.targetTexture = rt;

        //    yield return new WaitForEndOfFrame();

        //    RenderTexture.active = rt;
        //    TextureFormat format = TextureFormat.RGB24;
        //    Texture2D tex = new Texture2D(rttWidth, rttHeight, format, false);
        //    tex.ReadPixels(new Rect(0, 0, rt.width, rt.height), 0, 0);
        //    tex.Apply();
        //    //renCam.targetTexture = null;
        //    tex.name = "ScreenShot";
        //    callback(tex);
        //}


        /// <summary>
        /// 获取图片格式
        /// </summary>
        /// <param name="platform"></param>
        /// <param name="alpha"></param>
        /// <returns></returns>
        public static TextureFormat GetFormat(RuntimePlatform platform, bool alpha = false)
        {
            switch (platform)
            {
                case RuntimePlatform.WindowsEditor:
                case RuntimePlatform.WindowsPlayer:
                    return alpha ? TextureFormat.DXT5 : TextureFormat.DXT1;
                case RuntimePlatform.Android:
                    return alpha ? TextureFormat.ETC2_RGBA8 : TextureFormat.ETC2_RGB;

                case RuntimePlatform.IPhonePlayer:
                    return alpha ? TextureFormat.PVRTC_RGBA4 : TextureFormat.PVRTC_RGB4;
                default:
                    return alpha ? TextureFormat.ARGB32 : TextureFormat.RGB24;
            }
        }
        #endregion
    }
}