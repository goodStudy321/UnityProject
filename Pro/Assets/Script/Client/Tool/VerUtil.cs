/*=============================================================================
 * Copyright (C) 2013, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2013.5.9 20:09:25
 ============================================================================*/
using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using UnityEngine.Networking;

namespace Loong.Game
{
    /// <summary>
    /// 版本号工具类
    /// </summary>
    public static class VerUtil
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private static int Parse(string err, string text, string path)
        {
            int ver = 0;
            if (!string.IsNullOrEmpty(err))
            {
                iTrace.Error("Loong", string.Format("get ver err:{0}, path:{1}", err, path));
            }
            else if (string.IsNullOrEmpty(text))
            {
                iTrace.Error("Loong", string.Format("no ver :{0}", path));
            }
            else
            {
                text = text.Trim();
                if (!int.TryParse(text, out ver))
                {
                    iTrace.Error("Loong", string.Format("can't parse {0} to int, path:{1}", text, path));
                }
            }
            return ver;
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 将字符串转换为版本号
        /// </summary>
        /// <param name="verStr">版本号字符</param>
        /// <param name="tip">错误提示</param>
        /// <returns></returns>
        public static Version Get(string verStr, string tip)
        {
            Version ver = null;
            try
            {
                ver = new Version(verStr);
            }
            catch (Exception e)
            {
                if (tip == null) tip = "";
                string err = string.Format("{0} parse:{1},err:{2}", tip, verStr, e.Message);
                iTrace.Error("Loong", err);
            }

            finally
            {
                if (ver == null) ver = Default();
            }
            return ver;
        }

        /// <summary>
        /// 从指定路径的文件获取版本号
        /// </summary>
        /// <param name="path">文件路径</param>
        /// <param name="cb">加载完成回调</param>
        /// <returns></returns>
        public static IEnumerator Load(string path, Action<Version, string> cb)
        {
            using (UnityWebRequest request = UnityWebRequest.Get(path))
            {
                yield return request.SendWebRequest();
                Version ver = null;
                string text = request.downloadHandler.text;
                string err = request.error;
                if (string.IsNullOrEmpty(err))
                {
                    if (string.IsNullOrEmpty(text))
                    {
                        ver = Default();
                    }
                    else
                    {
                        ver = Get(text.Trim(), string.Format("path:{0}", path));
                    }
                }
                else
                {
                    string error = WWWError.Instance.Get(err.Trim());
                    iTrace.Error("Loong", string.Format("get ver,err,{0},path:{1}", error, path));
                }
                if (cb != null) cb(ver, err);
            }
        }

        /// <summary>
        /// 获取默认版本号
        /// </summary>
        /// <returns></returns>
        public static Version Default()
        {
            return new Version(1, 0, 0, 0);
        }

        #region 整数版本号
        /// <summary>
        /// 从指定路径的文件获取版本号,版本号值仅有一个整数
        /// </summary>
        /// <param name="path">文件路径</param>
        /// <param name="cb">加载完成回调</param>
        /// <returns></returns>
        public static IEnumerator Load(string path, Action<int, string> cb)
        {
            if (cb == null) yield break;
            using (UnityWebRequest request = UnityWebRequest.Get(path))
            {
                yield return request.SendWebRequest();
                var err = request.error;
                int ver = Parse(err, request.downloadHandler.text, path);
                if (cb != null) cb(ver, err);
            }
        }


        public static int LoadFromFile(string path)
        {
            string str = FileTool.Load(path);
            int ver = Parse(null, str, path);
            return ver;
        }

        /// <summary>
        /// 通过www加载版本号
        /// </summary>
        /// <param name="path"></param>
        /// <returns></returns>
        public static int WWWLoad(string path)
        {
            if (string.IsNullOrEmpty(path)) return 0;
            int ver = 0;
            using (UnityWebRequest request = UnityWebRequest.Get(path))
            {
                var UWRAsynOp = request.SendWebRequest();
                while (!UWRAsynOp.isDone) continue;
                ver = Parse(request.error, request.downloadHandler.text, path);
            }
            return ver;
        }

        public static Version LoadVer(string path, string tip)
        {
            Version ver = null;
            string str = FileTool.Load(path);
            if (string.IsNullOrEmpty(str))
            {
                iTrace.Error("Loong", string.Format("no ver, path:{0}", path));
            }
            else
            {
                ver = Get(str, tip);
            }
            return ver;
        }
        #endregion
        #endregion
    }
}